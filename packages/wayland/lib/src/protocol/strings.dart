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
          .map(
              (part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
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

extension StringExtension on String {
  String toCamelCase() {
    return toCamel(this);
  }

  String lowerCamel({String prefix = '', String suffix = ''}) {
    return toLowerCamel(this, prefix: prefix, suffix: suffix);
  }

  String camel({String prefix = '', String suffix = ''}) {
    return toCamel(this, prefix: prefix, suffix: suffix);
  }

  String upper({String prefix = '', String suffix = ''}) {
    return toUpper(this, prefix: prefix, suffix: suffix);
  }

  String comments() {
    return comment(this);
  }
}
