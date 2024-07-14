import 'dart:typed_data';

import 'package:wayland/protocol/context.dart';

class Proxy {
  final int id;

  Proxy(this.id);
}

class UnknownProxy extends Proxy {
  UnknownProxy(int id, Context context) : super(id);
}

abstract class Dispatcher {
  void dispatch(int opcode, int fd, Uint8List data);
}
