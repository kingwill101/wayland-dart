import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:wayland/src/scanner/commands/scan.dart';

void main(List<String> arguments) async {
  final runner =
      CommandRunner('wayland_scanner', 'Wayland protocol scanner for Dart')
        ..addCommand(ScanCommand());

  try {
    await runner.run(arguments);
  } catch (error) {
    print('Error: $error');
    exit(64);
  }
}



