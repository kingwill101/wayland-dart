/// Disk free/used via libc `statvfs` (no `df` subprocess).
library;

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

final DynamicLibrary _libc =
    DynamicLibrary.open(Platform.isLinux ? 'libc.so.6' : 'libc.dylib');

// struct statvfs layout on Linux x86_64 / aarch64 (glibc):
//   f_bsize, f_frsize, f_blocks, f_bfree, f_bavail, f_files, f_ffree,
//   f_favail, f_fsid, f_flag, f_namemax, __f_spare[6]
// Use unsigned long-sized fields; pad to cover __f_spare.
final class _StatVfs extends Struct {
  @Uint64()
  external int fBsize;
  @Uint64()
  external int fFrsize;
  @Uint64()
  external int fBlocks;
  @Uint64()
  external int fBfree;
  @Uint64()
  external int fBavail;
  @Uint64()
  external int fFiles;
  @Uint64()
  external int fFfree;
  @Uint64()
  external int fFavail;
  @Uint64()
  external int fFsid;
  @Uint64()
  external int fFlag;
  @Uint64()
  external int fNamemax;
  // __f_spare[6] — keep space so we don't overrun if libc writes spare.
  @Array(6)
  external Array<Uint64> spare;
}

final int Function(Pointer<Utf8>, Pointer<_StatVfs>) _statvfs = _libc
    .lookup<NativeFunction<Int32 Function(Pointer<Utf8>, Pointer<_StatVfs>)>>(
        'statvfs')
    .asFunction();

class DiskUsage {
  final int totalBytes;
  final int usedBytes;
  final int availBytes;
  final int usedPercent;

  const DiskUsage({
    required this.totalBytes,
    required this.usedBytes,
    required this.availBytes,
    required this.usedPercent,
  });
}

/// Human size like df -h (powers of 1024, one decimal when needed).
String formatBytesHuman(int bytes) {
  if (bytes < 0) bytes = 0;
  const units = ['B', 'K', 'M', 'G', 'T', 'P'];
  var v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  if (i == 0) return '${v.round()}${units[i]}';
  if (v >= 100 || v == v.roundToDouble()) {
    return '${v.round()}${units[i]}';
  }
  return '${v.toStringAsFixed(1)}${units[i]}';
}

/// Returns disk usage for [path], or null on error / non-Linux layout mismatch.
DiskUsage? statVfsPath(String path) {
  final p = path.toNativeUtf8();
  final buf = calloc<_StatVfs>();
  try {
    final rc = _statvfs(p, buf);
    if (rc != 0) return null;
    final fr = buf.ref.fFrsize != 0 ? buf.ref.fFrsize : buf.ref.fBsize;
    if (fr <= 0 || buf.ref.fBlocks <= 0) return null;
    final total = buf.ref.fBlocks * fr;
    final avail = buf.ref.fBavail * fr;
    // Used = total - free (including reserved), matching df Used column.
    final free = buf.ref.fBfree * fr;
    final used = total > free ? total - free : 0;
    final denom = total > avail ? total - avail : total;
    final pct = denom > 0 ? ((used * 100) / denom).round().clamp(0, 100) : 0;
    return DiskUsage(
      totalBytes: total,
      usedBytes: used,
      availBytes: avail,
      usedPercent: pct,
    );
  } catch (_) {
    return null;
  } finally {
    calloc.free(p);
    calloc.free(buf);
  }
}
