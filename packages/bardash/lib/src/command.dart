import 'dart:io';

/// Run a waybar-style `on-click` command string.
///
/// - Expands a leading `~/`
/// - Runs via `/bin/sh` so shebang-less one-liners (ML4W `settings/*.sh`) work
/// - Inherits the full process environment (DISPLAY, WAYLAND_DISPLAY, PATH, …)
/// - Detached so the bar never blocks on long-lived apps
void runBarCommand(String cmd) {
  final trimmed = cmd.trim();
  if (trimmed.isEmpty) return;

  final home = Platform.environment['HOME'] ?? '';
  final expanded = trimmed.replaceFirst(RegExp(r'^~(?=/|$)'), home);

  try {
    final env = Map<String, String>.from(Platform.environment);
    // Ensure common desktop vars exist when bardash was started oddly.
    env.putIfAbsent('HOME', () => home);

    // Single path to an existing file → run as a shell *script* (`sh file`),
    // not `sh -c file` (that exec's the path as a binary and breaks shebang-less
    // ML4W one-liners like a file containing only `firefox`).
    final asFile = File(expanded);
    if (!expanded.contains(RegExp(r'\s')) && asFile.existsSync()) {
      Process.start(
        '/bin/sh',
        [expanded],
        environment: env,
        mode: ProcessStartMode.detached,
        workingDirectory: home.isNotEmpty ? home : null,
      );
      return;
    }

    // Full shell command line (e.g. `rofi -show drun -replace`).
    Process.start(
      '/bin/sh',
      ['-c', expanded],
      environment: env,
      mode: ProcessStartMode.detached,
      workingDirectory: home.isNotEmpty ? home : null,
    );
  } catch (e) {
    stderr.writeln('[bardash] command failed: $expanded ($e)');
  }
}
