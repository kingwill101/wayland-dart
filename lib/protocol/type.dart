enum WaylandType {
  int,
  uint,
  fixed,
  object,
  newId,
  string,
  array,
  fd,
  enumeration,
}

WaylandType waylandStringToType(String type) {
    switch (type) {
      case 'int':
        return WaylandType.int;
      case 'uint':
        return WaylandType.uint;
      case 'fixed':
        return WaylandType.fixed;
      case 'object':
        return WaylandType.object;
      case 'new_id':
        return WaylandType.newId;
      case 'string':
        return WaylandType.string;
      case 'array':
        return WaylandType.array;
      case 'fd':
        return WaylandType.fd;
      case 'enum':
        return WaylandType.enumeration;
      default:
        throw ArgumentError('Invalid WaylandType: $type');
    }
  }