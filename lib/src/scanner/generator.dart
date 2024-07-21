import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:wayland/src/protocol/log.dart';
import 'package:wayland/src/protocol/strings.dart';
import 'package:wayland/src/protocol/type.dart';
import 'package:wayland/src/scanner/types.dart';
import 'package:xml/xml.dart';

const String newLine = '\n';

class Generator {
  final String inputFile;
  final String outputFile;
  final String packageName;
  final String prefix;
  final String suffix;
  final String cacheDir;
  final String packageDirectory;
  final List<String> imports;
  late Protocol protocol;

  final bool format;

  Generator(
      {this.inputFile = '',
      this.outputFile = '',
      this.packageName = '',
      this.prefix = '',
      this.suffix = '',
      this.imports = const [],
      this.format = false,
      this.packageDirectory = 'protocols',
      this.cacheDir = '.wayland-protocol-cache'});

  Directory getCacheDir() {
    if (Directory.current.path.endsWith('bin')) {
      return Directory(joinAll([Directory.current.parent.path, cacheDir]));
    }

    final cachePath = Directory(cacheDir);
    if (!cachePath.existsSync()) {
      cachePath.createSync();
    }
    return cachePath;
  }

  Future<void> run() async {
    if (inputFile.isEmpty || outputFile.isEmpty) {
      throw Exception('inbut file or output file is empty');
    }

    final xmlContent = await getInputFile(inputFile);
    final document = XmlDocument.parse(xmlContent);
    protocol = Protocol.fromXml(document.rootElement);

    final output = StringBuffer();

    // Header
    output.writeln('// Generated by dart-wayland-scanner');
    output.writeln('// https://github.com/your-repo/dart-wayland-scanner');
    output.writeln('// XML file : $inputFile');
    output.writeln('//');
    output.writeln('// ${protocol.name} Protocol Copyright: ');
    output.writeln(protocol.copyright.comments());
    output.writeln();

    output.writeln('library $packageName;');
    output.writeln();

    output.writeln("import 'package:wayland/wayland.dart';");

    if (protocol.name != 'wayland') {
      output
          .writeln("import 'package:wayland/$packageDirectory/wayland.dart';");
    }

    for (final imp in imports) {
      output.writeln("import 'package:wayland/$packageDirectory/$imp';");
    }

    output.writeln("import 'dart:async';");
    output.writeln("import 'dart:convert';");
    output.writeln("import 'dart:typed_data';");
    output.writeln("import 'package:result_dart/result_dart.dart';");

    // Interfaces
    for (final interface in protocol.interfaces) {
      writeInterface(output, interface);
    }

    var outFile = File(outputFile);

    if (!outFile.existsSync()) {
      outFile.createSync(recursive: true);
    }

    await outFile.writeAsString(output.toString());
    if (format) await tryFmt(outFile.absolute.path);
    logLn('Generated Dart code written to $outputFile');
  }

  Future tryFmt(String path) async {
    var dart = await findDartExecutable();

    if (dart == null) {
      logLn('Could not find dart executable');
      return;
    }
    await Process.run(dart, ['format', "--fix", path]);
  }

  Future<String?> findDartExecutable() async {
    try {
      var result = await Process.run('which', ['dart']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      } else {
        logLn(
            'Could not find dart executable: ${result.stderr.toString().trim()}');
        return null;
      }
    } catch (e) {
      logLn('Could not find dart executable');
    }
    return null;
  }

  Future<String> getInputFile(String file) async {
    String cacheDir = getCacheDir().path;

    if (file.startsWith('http')) {
      file = file.replaceFirst('http://', 'https://');

      final cacheFile = File(join(cacheDir, basename(file)));

      if (cacheFile.existsSync()) {
        return await cacheFile.readAsString();
      }

      final response = await http.get(Uri.parse(file));
      var content = response.body;

      cacheFile.writeAsString(content);

      return content;
    } else {
      return await File(file).readAsString();
    }
  }

  String fixName(String name) {
    final illegalArgs = <String, String>{
      'class': 'clazz',
      'class_': 'clazz',
      'default': 'defaulted',
      'enum': 'enumm',
    };
    if (illegalArgs.containsKey(name)) {
      return illegalArgs[name]!;
    }
    return name;
  }

  void writeEnum(StringBuffer output, String ifaceName, Enum enum_) {
    final enumName = enum_.name.upper(prefix: prefix, suffix: suffix);

    output.writeln(comment(' ${enum_.description.summary}'));
    output.writeln(comment(enum_.description.text));
    output.writeln();
    final fullEnumName = "$ifaceName$enumName";

    output.writeln('enum $fullEnumName {');

    for (final entry in enum_.entries.indexed) {
      var entryName =
          fixName(entry.$2.name.lowerCamel(prefix: prefix, suffix: suffix));

      // Check if the result is a number and prefix with 'W' if it is
      if (int.tryParse(entryName) != null) {
        entryName = 'w$entryName';
      }

      output.writeAll([
        entry.$2.summary.comments(),
        '  $entryName("${entry.$2.name}", ${entry.$2.value})${entry.$1 == enum_.entries.length - 1 ? ';' : ','}'
      ], newLine);
    }

    output.writeln();
    output.writeAll([
      'const $fullEnumName(this.enumName, this.enumValue);',
      'final int enumValue;',
      'final String enumName;',
    ], newLine);
    output.writeln();
    output.writeAll([
      "@override",
      "toString(){",
      'return "$fullEnumName {name: \$enumName, value: \$enumValue}";',
      '}',
    ], newLine);
    output.writeln();
    output.writeln('}');
    output.writeln();
  }

  String getDartType(String type, String interface) {
    switch (type) {
      case 'int':
      case 'uint':
        return 'int';
      case 'fixed':
        return 'double';
      case 'string':
        return 'String';
      case 'object':
      case 'new_id':
        return 'int';
      case 'array':
        return 'List<int>';
      case 'fd':
        return 'int';
      default:
        return 'dynamic';
    }
  }

  void writeEventClasses(StringBuffer output, Interface interface) {
    final ifaceName = toUpper(
      interface.name,
      prefix: prefix,
      suffix: suffix,
    );
    for (final event in interface.events) {
      if (event.description.summary.isNotEmpty) {
        output.writeln(comment(event.description.summary));
      }
      if (event.description.text.isNotEmpty) {
        output.writeln(comment(event.description.text));
      }

      final eventClassName = '$ifaceName${toUpper(event.name)}Event';
      output.writeln('class $eventClassName {');
      for (final arg in event.args) {
        output.writeln(comment(arg.summary));
        output.writeln(
            '  final ${getDartType(arg.type, ifaceName)} ${toLowerCamel(fixName(arg.name))};');
        output.writeln();
      }
      output.writeln('  $eventClassName(');
      for (final arg in event.args) {
        output.writeln('this.${toLowerCamel(fixName(arg.name))},');
        output.writeln();
      }
      output.writeln(');');

      output.writeln();
      output.writeAll([
        "@override",
        "toString(){",
        'return "$eventClassName ${event.args.map((arg) => "${fixName(arg.name.lowerCamel())}: \$${fixName(arg.name.lowerCamel())}")}";',
        '}',
      ], newLine);
      output.writeln();

      output.writeln('}');

      output.writeln();

      output.writeln(
          'typedef $ifaceName${event.name.upper()}EventHandler = void Function($ifaceName${event.name.upper()}Event);');
      output.writeln();
    }
  }

  void writeInterface(StringBuffer output, Interface interface) {
    final ifaceName = interface.name.upper(prefix: prefix, suffix: suffix);
    output.writeln();
    writeEventClasses(output, interface);
    output.writeln();

    output.writeln(comment(interface.description.summary));
    output.writeln(comment(interface.description.text));

    output.write('class $ifaceName extends Proxy');

    if (interface.events.isNotEmpty) {
      output.write(' implements Dispatcher');
    }
    output.write('{');
    output.writeln('');
    output.writeln('  final Context innerContext;');
    output.writeln('  final version = ${interface.version};');
    output.writeln();
    output.writeln(
        '  $ifaceName(this.innerContext) : super(innerContext.allocateClientId()){');
    output.writeln('    innerContext.register(this);');
    output.writeln('  }');
    output.writeln();

    output.writeln();
    output.writeAll([
      "@override",
      "toString(){",
      'return "$ifaceName {name: \'${interface.name}\', id: \'\$objectId\', version: \'${toLowerCamel(fixName(interface.version.toString()))}\',}";',
      '}',
    ], newLine);
    output.writeln();

    output.writeln();

    // Implement requests
    for (var i = 0; i < interface.requests.length; i++) {
      final request = interface.requests[i];
      writeRequestImpl(output, ifaceName, i, request);
    }

    // Events
    for (final event in interface.events) {
      writeEvent(output, ifaceName, event);
    }

    writeEventDispatcher(output, ifaceName, interface);

    output.writeln('}');
    output.writeln();

    // Enums
    for (final enum_ in interface.enums) {
      writeEnum(output, ifaceName, enum_);
    }
  }

  void writeRequestImpl(
      StringBuffer output, String ifaceName, int opcode, Request request) {
    final requestName = toCamel(request.name, prefix: prefix, suffix: suffix);

    String returnType = 'void';
    String returnVal = '';

    final params = <String>[];
    final args = <String>[];
    final args2 = <Arg>[];

    for (final arg in request.args) {
      final argName =
          fixName(toLowerCamel(arg.name, prefix: prefix, suffix: suffix));
      var argType = getDartType(arg.type, arg.interface);

      if (arg.type == 'new_id' && arg.interface.isNotEmpty) {
        returnType = toUpper(arg.interface, prefix: prefix, suffix: suffix);
        returnVal = argName;
        args2.add(arg);
        continue;
      }

      if (arg.type == 'object') {
        if (arg.interface.isNotEmpty) {
          argType = toUpper(arg.interface, prefix: prefix, suffix: suffix);
        } else {
          argType = toUpper(argName, prefix: prefix, suffix: suffix);
        }
      }

      params.add('$argType $argName');
      args2.add(arg);
    }

    // Add additional parameters for 'new_id' with empty interface
    for (int i = 0; i < request.args.length; i++) {
      final arg = request.args[i];
      if (arg.type == 'new_id' && arg.interface.isEmpty) {
        params.insert(i, 'int version');
        params.insert(i, 'String interface');

        args2.insert(
            i,
            Arg(
              name: 'version',
              type: 'int',
              summary: '',
              interface: 'uint',
              enum_: '',
              description: Description(text: '', summary: ''),
              allowNull: false,
            ));

        args2.insert(
            i,
            Arg(
              name: 'interface',
              type: 'string',
              summary: '',
              interface: 'string',
              enum_: '',
              description: Description(text: '', summary: ''),
              allowNull: false,
            ));
      }
    }

    output.writeln(comment('  ${request.description.summary}'));
    output.writeln(comment(request.description.text));

    for (final arg in request.args) {
      output.writeln(comment('  [${arg.name}]: ${arg.summary}'));
    }

    // Generate the request method implementation
    output.write(
        '  Result<$returnType,Object> $requestName(${params.join(', ')}) {');
    output.writeln();

    if (request.isDestructor) {
      output.writeln('innerContext.unRegister(this);');
    }

    for (final arg in args2) {
      final argName =
          fixName(toLowerCamel(arg.name, prefix: prefix, suffix: suffix));

      if (arg.type == 'new_id' && arg.interface.isNotEmpty) {
        output.writeln(
            '  var $argName =  ${toUpper(arg.interface, prefix: prefix, suffix: suffix)}(innerContext);');
        args.add(argName);
      } else {
        args.add(argName);
      }
    }

    output.write('    logLn("$ifaceName::$requestName ');
    for (final arg in args) {
      output.write(' $arg: \$$arg');
    }
    output.writeln('");');

    var argNoFd = args2.where((a) => a.type != "fd");
    output.write(
        'var arguments = [${argNoFd.map((a) => fixName(a.name.lowerCamel())).join(', ')}];');

    output.writeln(
        'var argTypes = <WaylandType>[${argNoFd.map((a) => waylandStringToType(a.type).toString()).join(', ')}];');

    output
        .writeln('var calclulatedSize  = calculateSize(argTypes, arguments);');
    output.writeln('final bytesBuilder = BytesBuilder();'); // Renamed variable

    output.writeln(
        'bytesBuilder.add(Uint32List.fromList([objectId, (calclulatedSize << 16) | $opcode]).buffer.asUint8List());');

    var argTypes = [];

    for (final arg in args2) {
      argTypes.add(waylandStringToType(arg.type).toString());
    }
    String fd = '';

    for (final arg in args2) {
      final argName =
          fixName(arg.name.lowerCamel(prefix: prefix, suffix: suffix));

      switch (arg.type) {
        case 'int':
          output.writeln(
              '    bytesBuilder.add(Int32List.fromList([$argName]).buffer.asUint8List());');
          break;
        case 'uint':
          output.writeln(
              '    bytesBuilder.add(Uint32List.fromList([$argName]).buffer.asUint8List());');
          break;
        case 'fixed':
          output.writeln(
              '    bytesBuilder.add(Int32List.fromList([doubleToFixed($argName)]).buffer.asUint8List());');
          break;
        case 'string':
          output.writeln('    final ${argName}Bytes = utf8.encode($argName);');
          output.writeln(
              '    bytesBuilder.add(Uint32List.fromList([${argName}Bytes.length + 1]).buffer.asUint8List());');
          output.writeln('    bytesBuilder.add(${argName}Bytes);');
          output.writeln('    bytesBuilder.add([0]); // Null terminator');
          output.writeln(
              '    while (bytesBuilder.length % 4 != 0) { bytesBuilder.add([0]); } // Padding');
          break;
        case 'object':
        case 'new_id':
          if (arg.interface.isNotEmpty) {
            output.writeln(
                '    bytesBuilder.add(Uint32List.fromList([$argName.objectId]).buffer.asUint8List());');
          } else {
            output.writeln(
                '    bytesBuilder.add(Uint32List.fromList([$argName]).buffer.asUint8List());');
          }
          break;
        case 'array':
          output.writeln(
              '    bytesBuilder.add(Uint32List.fromList([$argName.length]).buffer.asUint8List());');
          output.writeln('    bytesBuilder.add($argName);');
          output.writeln(
              '    while (bytesBuilder.length % 4 != 0) { bytesBuilder.add([0]); } // Padding');
          break;
        case 'fd':
          fd = argName;
          break;
        default:
          output.writeln('    // Unhandled type: ${arg.type}');
      }
    }

    output.writeln('    try{');
    output
        .writeln('    innerContext.sendMessage(bytesBuilder.toBytes(), $fd);');
    output.writeln('    }catch (e) {');
    output
        .writeln('      logLn("Exception in $ifaceName::$requestName: \$e");');

    output.writeln('   return Failure(e);');
    output.writeln('    }');

    if (returnVal.isNotEmpty) {
      output.writeln('    return Success($returnVal);');
    } else {
      output.writeln('    return Success(Object());');
    }
    output.writeln('  }');
    output.writeln();
  }

  void writeEvent(StringBuffer output, String ifaceName, Event event) {
    var eventName = toUpper(event.name, prefix: prefix, suffix: suffix);

    output.writeln(event.description.summary.comments());
    output.writeln(event.description.text.comments());

    output.writeln('Event handler for $eventName'.comments());

    for (final arg in event.args) {
      output.writeln(comment(' - [${arg.name}]: ${arg.summary}'));
    }

    final params = <String>[];
    for (final arg in event.args) {
      final argName = toLowerCamel(arg.name, prefix: prefix, suffix: suffix);
      final argType = getDartType(arg.type, arg.interface);
      params.add('$argType $argName');
    }

    // // Generate the event handler method signature
    output.writeln(
        ' void on$eventName($ifaceName${toUpper(event.name)}EventHandler handler) {');

    output.writeln(
      '   _${toCamel(eventName, prefix: prefix, suffix: suffix)}Handler = handler;',
    );
    output.writeln(' }');
    output.writeln();

    // Generate the private handler field
    output.writeln(
        ' $ifaceName${toUpper(event.name)}EventHandler? _${toCamel(eventName)}Handler;');
    output.writeln();
  }

  void writeEventDispatcher(
      StringBuffer output, String ifaceName, Interface iface) {
    if (iface.events.isEmpty) return;
    output.writeAll([
      ' @override',
      ' void dispatch(int opcode, int fd, Uint8List data) {',
      'logLn("$ifaceName.dispatch(\$opcode, \$fd, \$data)");',
      '   switch (opcode) {',
    ], newLine);
    for (var i = 0; i < iface.events.length; i++) {
      final event = iface.events[i];
      final eventName = toCamel(event.name, prefix: prefix, suffix: suffix);
      bool hasFd = false;

      for (final arg in event.args) {
        if (arg.type == 'fd') {
          hasFd = true;
          break;
        }
      }

      output.writeln('     case $i:');
      if (hasFd) {
        output.writeAll(["if(fd != -1){", "}"], newLine);
      }
      output.writeln();
      output.writeln(
          '       if (_${toLowerCamel(eventName, prefix: prefix, suffix: suffix)}Handler != null) {');
      if (event.args.isNotEmpty) {
        output.writeln('var offset = 0;');
        for (final arg in event.args) {
          var argName = toLowerCamel(arg.name, prefix: prefix, suffix: suffix);
          var lengthVarName = '${argName}Length';

          // Ensure the variable name does not conflict with the dispatch parameters
          if (argName == 'opcode' || argName == 'fd' || argName == 'data') {
            argName = '${argName}2';
          }

          // Ensure the length variable name does not conflict with the argument name
          if (argName == lengthVarName) {
            lengthVarName = '${argName}Len';
          }

          switch (arg.type) {
            case 'int':
              output.writeln(
                  'final $argName = ByteData.view(data.buffer).getInt32(offset, Endian.little);');
              output.writeln('offset += 4;');
              break;
            case 'uint':
              output.writeln(
                  'final $argName = ByteData.view(data.buffer).getUint32(offset, Endian.little);');
              output.writeln('offset += 4;');
              break;
            case 'fixed':
              output.writeln(
                  'final $argName = fixedToDouble(ByteData.view(data.buffer).getInt32(offset, Endian.little));');
              output.writeln('offset += 4;');
              break;
            case 'string':
              output.writeln(
                  'final ${argName}Length = ByteData.view(data.buffer).getUint32(offset, Endian.little);');
              output.writeln('offset += 4;');
              output.writeln(
                  'final $argName = utf8.decode(data.sublist(offset, offset + ${argName}Length - 1));');
              output.writeln(
                  'offset += ${argName}Length; // Skip the string bytes and null terminator');
              output
                  .writeln('while (offset % 4 != 0) { offset++; } // Padding');
              break;
            case 'object':
            case 'new_id':
              output.writeln(
                  'final $argName = innerContext.getProxy(ByteData.view(data.buffer).getUint32(offset, Endian.little)).objectId;');
              output.writeln('offset += 4;');
              break;
            case 'array':
              output.writeln('final $argName = getArray(data, offset);');
              output.writeln(
                  'var arrayLength = ByteData.view(data.buffer).getUint32(offset, Endian.little);');
              output.writeln('offset += 4 + arrayLength;');
              output
                  .writeln('while (offset % 4 != 0) { offset++; } // Padding');
              break;
            case 'fd':
              output.writeln('final $argName = fd;');
              break;
            default:
              output.writeln('// Unhandled type: ${arg.type}');
          }
        }

        output.writeln('var event = $ifaceName${toUpper(event.name)}Event(');
        for (final arg in event.args) {
          var argName = toLowerCamel(arg.name, prefix: prefix, suffix: suffix);
          if (argName == 'opcode' || argName == 'fd' || argName == 'data') {
            argName = '${argName}2';
          }
          output.writeln('$argName,');
        }
        output.writeln('        );');

        output.writeln(
            '         _${toLowerCamel(eventName, prefix: prefix, suffix: suffix)}Handler!(event);');
      } else {
        output.writeln(
            '         _${toLowerCamel(eventName, prefix: prefix, suffix: suffix)}Handler!($ifaceName${event.name.upper()}Event());');
      }

      output.writeln('       }');
      output.writeln('       break;');
    }

    output.writeln('   }');
    output.writeln(' }');
  }
}
