import 'dart:io' show Platform;

/// Enables verbose toolkit diagnostics without making normal rendering pay the
/// cost of writing a line to stderr for every frame.
final bool toolkitDebugLogs =
    Platform.environment['WINDOW_TOOLKIT_DEBUG'] == '1' ||
    Platform.environment['WAYLAND_DEBUG_RENDER'] == '1';
