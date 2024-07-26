import 'dart:io';

log(String a) {
  print(a);
}

logLn(Object a) {
  final debug = Platform.environment['WAYLAND_DEBUG'] ?? '';
  if (debug.isEmpty) return;
  print('$a\n');
}
