/// Dart reimplementation of the Omarchy speed-test approach.
///
/// Steps:
/// 1. Discover active interface via `ip route get 1.1.1.1`.
/// 2. Discover test endpoints via Fast.com token API.
/// 3. Run parallel download/upload workers in-process.
/// 4. Sample `/sys/class/net/<iface>/statistics/{rx,tx}_bytes` every second
///    and derive Mbps from the delta.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class SpeedtestResult {
  final double downloadMbps;
  final double uploadMbps;
  final double pingMs;
  final String? serverName;
  final String? method;
  final String? error;

  const SpeedtestResult({
    required this.downloadMbps,
    required this.uploadMbps,
    required this.pingMs,
    this.serverName,
    this.method,
    this.error,
  });

  bool get hasError => error != null && error!.isNotEmpty;
}

class SpeedTestEngine {
  SpeedTestEngine._();

  static const _fastApiUrl =
      'https://api.fast.com/netflix/speedtest/v2?https=true&token=YXNkZmFzZGxmbnNkYWZoYXNkZmhrYWxm&urlCount=3';
  static const _probe = '1.1.1.1';
  static const _defaultParallel = 4;
  static const _defaultWindow = Duration(seconds: 4);
  static const _uploadChunkSize = 64 * 1024;

  static Future<SpeedtestResult> run({
    int parallel = _defaultParallel,
    Duration downloadWindow = _defaultWindow,
    Duration uploadWindow = _defaultWindow,
    void Function(double mbps)? onLive,
    void Function(String phase)? onPhase,
  }) async {
    final iface = _activeInterface();
    if (iface.isEmpty) {
      return const SpeedtestResult(
        downloadMbps: 0,
        uploadMbps: 0,
        pingMs: 0,
        method: 'omarchy',
        error: 'no active interface',
      );
    }

    late final List<String> urls;
    try {
      urls = await _fastUrls();
    } on Exception catch (e) {
      return SpeedtestResult(
        downloadMbps: 0,
        uploadMbps: 0,
        pingMs: 0,
        method: 'fast.com',
        error: 'endpoint discovery failed: $e',
      );
    }
    if (urls.isEmpty) {
      return const SpeedtestResult(
        downloadMbps: 0,
        uploadMbps: 0,
        pingMs: 0,
        method: 'fast.com',
        error: 'no fast.com endpoints',
      );
    }

    final rxPath = '/sys/class/net/$iface/statistics/rx_bytes';
    final txPath = '/sys/class/net/$iface/statistics/tx_bytes';

    double dl;
    try {
      onPhase?.call('download');
      dl = await _measureDirection(
        direction: 'down',
        urls: urls,
        parallel: parallel,
        window: downloadWindow,
        counterPath: rxPath,
        onLive: onLive,
      );
    } on Exception catch (e) {
      return SpeedtestResult(
        downloadMbps: 0,
        uploadMbps: 0,
        pingMs: 0,
        method: 'fast.com',
        error: 'download failed: $e',
      );
    }

    double ul;
    try {
      onPhase?.call('upload');
      ul = await _measureDirection(
        direction: 'up',
        urls: urls,
        parallel: parallel,
        window: uploadWindow,
        counterPath: txPath,
        onLive: onLive,
      );
    } on Exception catch (_) {
      ul = 0;
    }

    return SpeedtestResult(
      downloadMbps: dl,
      uploadMbps: ul,
      pingMs: 0,
      method: 'fast.com',
    );
  }

  static Future<double> _measureDirection({
    required String direction,
    required List<String> urls,
    required int parallel,
    required Duration window,
    required String counterPath,
    void Function(double mbps)? onLive,
  }) async {
    final connections = max(1, min(parallel, urls.length));
    final workers = urls.sublist(0, connections);
    final pids = <Future<void>>[];

    for (final url in workers) {
      pids.add(direction == 'down' ? _downloadWorker(url) : _uploadWorker(url));
    }

    final before = await _readCounter(counterPath);
    final samples = <double>[];
    var previous = before;
    var previousAt = DateTime.now();
    final deadline = DateTime.now().add(window);

    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 1));
      final after = await _readCounter(counterPath);
      final now = DateTime.now();
      if (after < 0 || previous < 0 || after < previous) break;
      final seconds = now.difference(previousAt).inMicroseconds / 1000000;
      if (seconds <= 0) continue;
      samples.add((after - previous) * 8 / 1_000_000 / seconds);
      onLive?.call(samples.last);
      previous = after;
      previousAt = now;
    }

    for (final job in pids) {
      try {
        unawaited(job);
      } on Exception catch (_) {}
    }

    if (samples.isEmpty) {
      throw StateError('$direction produced no traffic samples');
    }
    return samples.reduce(max);
  }

  static Future<void> _downloadWorker(String url) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    client.idleTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('User-Agent', 'bardash-speedtest/1.0');
      req.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      final resp = await req.close();
      if (resp.statusCode < 200 || resp.statusCode >= 400) {
        throw HttpException('HTTP ${resp.statusCode}', uri: Uri.parse(url));
      }
      await for (final _ in resp) {
        // discard body but keep the pipe full
      }
    } on Exception catch (_) {
      // allow partial download
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> _uploadWorker(String url) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    client.idleTimeout = const Duration(seconds: 8);
    try {
      final req = await client.postUrl(Uri.parse(url));
      req.headers.set('Content-Type', 'application/octet-stream');
      req.headers.set('User-Agent', 'bardash-speedtest/1.0');
      req.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      final rnd = Random.secure();
      final chunk = List<int>.generate(
        _uploadChunkSize,
        (_) => rnd.nextInt(256),
      );
      final deadline = DateTime.now().add(const Duration(seconds: 8));
      while (DateTime.now().isBefore(deadline)) {
        req.add(chunk);
        await req.flush();
      }
      await req.close();
    } on Exception catch (_) {
      // allow partial upload
    } finally {
      client.close(force: true);
    }
  }

  static Future<List<String>> _fastUrls() async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.parse(_fastApiUrl));
      req.headers.set('User-Agent', 'bardash-speedtest/1.0');
      final resp = await req.close();
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw HttpException(
          'HTTP ${resp.statusCode}',
          uri: Uri.parse(_fastApiUrl),
        );
      }
      final body = await resp.transform(utf8.decoder).join();
      final map = jsonDecode(body) as Map<String, dynamic>;
      final targets = map['targets'] as List<dynamic>?;
      if (targets == null) return <String>[];
      final out = <String>[];
      for (final t in targets) {
        if (t is Map && t['url'] is String) {
          final u = (t['url'] as String).trim();
          if (u.isNotEmpty) out.add(u);
        }
      }
      return out;
    } finally {
      client.close(force: true);
    }
  }

  static Future<int> _readCounter(String path) async {
    try {
      return int.parse((await File(path).readAsString()).trim());
    } on Exception catch (_) {
      return -1;
    }
  }

  static String _activeInterface() {
    try {
      final p = Process.runSync('ip', [
        'route',
        'get',
        _probe,
      ], runInShell: false);
      if (p.exitCode != 0) return '';
      final parts = (p.stdout as String).trim().split(RegExp(r'\s+'));
      for (var i = 0; i < parts.length - 1; i++) {
        if (parts[i] == 'dev') return parts[i + 1];
      }
    } catch (_) {}
    return '';
  }
}
