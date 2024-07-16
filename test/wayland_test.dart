import 'package:test/test.dart';
import 'package:wayland/wayland.dart';

void main() {
  test('WaylandMessage serialization for Registry bind', () {
    final message = WaylandMessage(
      2, // objectId
      0, // opcode for bind
      [
        56666, // name
        'wl_shm', // interface
        1, // version
        4, // new object id
      ],
      [
        WaylandType.uint,
        WaylandType.string,
        WaylandType.uint,
        WaylandType.newId,
      ],
    );

    final serialized = message.serialize();

    expect(serialized, equals([
      2, 0, 0, 0, // object id
      0, 0, 32, 0, // size and opcode
      90, 221, 0, 0, // name (56666 in little-endian)
      6, 0, 0, 0, // string length
      119, 108, 95, 115, 104, 109, 0, 0, // "wl_shm" null-terminated
      1, 0, 0, 0, // version
      4, 0, 0, 0, // new object id
    ]));
  });
}