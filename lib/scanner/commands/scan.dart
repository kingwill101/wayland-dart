import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:wayland/scanner/generator.dart';
import 'package:wayland/scanner/types.dart';
import 'package:yaml/yaml.dart';

const protocolCacheDir = '.wayland-protocol-cache';

class ScanCommand extends Command {
  String inputFile = '';
  String outputFile = '';
  String packageName = '';
  String prefix = '';
  String suffix = '';
  late Protocol protocol;

  @override
  String get name => 'scan';

  @override
  String get description => 'Scan Wayland protocol XML and generate Dart code';

  ScanCommand() {
    argParser
      ..addOption('i',
          help: 'Remote url or local path of the protocol xml file')
      ..addOption('o',
          help: 'Path of the generated output dart file', defaultsTo: null)
      ..addOption('pkg', help: 'Dart package name', defaultsTo: 'wayland')
      ..addOption('prefix', help: 'Specify prefix to trim', defaultsTo: null)
      ..addOption('suffix', help: 'Specify suffix to trim', defaultsTo: null)
      ..addOption('clean',
          help: 'should first remove generated', defaultsTo: 'false')
      ..addOption('protocols',
          help: 'Specify yaml file to load protocols', defaultsTo: null)
      ..addOption('cache-dir', help: 'cache dir ', defaultsTo: protocolCacheDir)
      ..addOption('generation-dir',
          help: 'dir to store generated code', defaultsTo: 'lib/generated');
  }

  @override
  void run() async {
    inputFile = argResults?['i'] ?? '';
    outputFile = argResults?['o'] ?? '';
    packageName = argResults?['pkg'] ?? '';
    prefix = argResults?['prefix'] as String? ?? '';
    suffix = argResults?['suffix'] as String? ?? '';
    var generationDir = argResults?['generation-dir'] as String;

    if (argResults?['clean'] == 'true') {
      if (await Directory(generationDir).exists()) {
        await Directory(generationDir).delete(recursive: true);
      }
    }

    if (argResults?['protocols'] != null) {
      final yamlContent =
          await File(argResults?['protocols'] as String).readAsString();

      final yamlMap = loadYaml(yamlContent) as YamlMap;
      final protocolsList = yamlMap['protocols'] as YamlList;

      var imports = [];

      var generators = protocolsList.map((protocol) {
        final protocolMap = protocol as YamlMap;
        final importPath = "lib/generated/${protocolMap['output']}";
        imports.add(protocolMap['output']);

        // var deps = yamlMap['protocols'] as YamlList;
        List<String> dependencies = [];
        var yamlDeps = protocolMap['dependencies'] as YamlList?;

        if (yamlDeps != null) {
          for (var dep in yamlDeps) {
            dependencies.add(dep);
          }
        }


        return Generator(
            packageName: packageName,
            prefix: prefix,
            suffix: suffix,
            inputFile: protocolMap['input'],
            outputFile: importPath,
            imports: dependencies,
            cacheDir: protocolCacheDir);
      }).toList();

      await Future.wait(generators.map((generator) {
        return generator.run();
      }));

//       //generate generated.dart with all the imports exported
//       final generatedFile = File("lib/generated/generated.dart");
//       StringBuffer buffer = StringBuffer();
//       final generatedContent = '''
// // GENERATED CODE - DO NOT MODIFY BY HAND
// // ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides


// ''';
//       buffer.writeln(generatedContent);
//       imports.forEach((import) {
//         if (import.endsWith('wayland.dart')) {
//           return;
//         }
//         buffer.writeln("export '$import';");
//       });

//       if (await generatedFile.exists()) {
//         await generatedFile.delete();
//       } else {
//         await generatedFile.create(recursive: true);
//       }
//       await generatedFile.writeAsString(buffer.toString());

      return;
    }

    Generator generator = Generator(
        inputFile: inputFile,
        outputFile: "lib/generated/$outputFile",
        packageName: packageName,
        prefix: prefix,
        suffix: suffix,
        cacheDir: protocolCacheDir);
    generator.run();
  }

  parseProtocolsYaml(String yamlContent) {
    final yamlMap = loadYaml(yamlContent) as YamlMap;
    final protocolsList = yamlMap['protocols'] as YamlList;

    protocolsList.map((protocol) {
      final protocolMap = protocol as YamlMap;
      return Generator(
          // name: protocolMap['name'],
          packageName: packageName,
          inputFile: protocolMap['input'],
          outputFile: protocolMap['output'],
          cacheDir: protocolCacheDir);
    }).toList();
  }
}
