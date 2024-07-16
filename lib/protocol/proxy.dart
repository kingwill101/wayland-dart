import 'dart:typed_data';

import 'package:wayland/protocol/context.dart';

class Proxy {
  int _id;

  set id(int id) {
    _id = id;
  }

  int get objectId => _id;

  Proxy(this._id);
}

class UnknownProxy extends Proxy {
  UnknownProxy(int id, Context context) : super(id);
}

abstract class Dispatcher {
  void dispatch(int opcode, int fd, Uint8List data);
}
