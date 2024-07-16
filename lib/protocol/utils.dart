import 'dart:convert';
import 'dart:typed_data';

String getString(Uint8List data, int offset) {
  final length = ByteData.view(data.buffer).getUint32(offset, Endian.little);
  offset += 4;
  final stringBytes = data.sublist(offset, offset + length - 1); // -1 to remove null terminator
  return utf8.decode(stringBytes);
}

  Uint8List getArray(Uint8List data, int offset) {
    final length = ByteData.view(data.buffer).getUint32(offset, Endian.host);
    return data.sublist(offset + 4, offset + 4 + length);
  }

double fixedToDouble(int fixed) {
  return fixed / 256.0;
}


String toLowerCamel(String s, {String prefix = '', String suffix = ''}) {
  // Remove prefix and suffix if they exist
  s = s.replaceFirst(RegExp('^$prefix'), '');
  s = s.replaceFirst(RegExp('$suffix\$'), '');

  // Split by underscores
  List<String> parts = s.split('_').where((ss) => ss.isNotEmpty).toList();

  // Handle the case where there are no underscores
  if (parts.length == 1) {
    s = parts.first;
  } else {
    if (parts.first.isEmpty) {
      s = parts[1];
    } else if (parts[1].isEmpty && parts[0].isNotEmpty) {
      return parts[0];
    } else {
      // Capitalize each part except the first one
      String firstPart = parts.first.toLowerCase();
      List<String> capitalizedParts = parts
          .skip(1)
          .map((part) =>
      part[0].toUpperCase() + part.substring(1).toLowerCase())
          .toList();

      // Combine the first part with the capitalized parts
      s = firstPart + capitalizedParts.join('');
    }
  }

  return s;
}

String toCamel(String s, {String prefix = '', String suffix = ''}) {
  final camel = toLowerCamel(s, prefix: prefix, suffix: suffix);
  return camel[0].toLowerCase() + camel.substring(1);
}

String toUpper(String s, {String prefix = '', String suffix = ''}) {
  final camel = toLowerCamel(s, prefix: prefix, suffix: suffix);
  return camel[0].toUpperCase() + camel.substring(1);
}

String comment(String s) {
  return s.split('\n').map((line) => '/// ${line.trim()}').join('\n');
}
