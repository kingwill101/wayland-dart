// Generated by dart-wayland-scanner
// https://github.com/your-repo/dart-wayland-scanner
// XML file : https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/unstable/input-timestamps/input-timestamps-unstable-v1.xml
//
// input_timestamps_unstable_v1 Protocol Copyright: 
/// 
/// Copyright © 2017 Collabora, Ltd.
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a
/// copy of this software and associated documentation files (the "Software"),
/// to deal in the Software without restriction, including without limitation
/// the rights to use, copy, modify, merge, publish, distribute, sublicense,
/// and/or sell copies of the Software, and to permit persons to whom the
/// Software is furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice (including the next
/// paragraph) shall be included in all copies or substantial portions of the
/// Software.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
/// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
/// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
/// DEALINGS IN THE SOFTWARE.
/// 

library client;

import 'package:wayland/wayland.dart';
import 'package:wayland/generated/wayland.dart';
import 'dart:async';
import 'dart:typed_data';


/// context object for high-resolution input timestamps
/// 
/// A global interface used for requesting high-resolution timestamps
/// for input events.
/// 
class ZwpInputTimestampsManagerV1 extends Proxy{
  final Context context;

  ZwpInputTimestampsManagerV1(this.context) : super(context.allocateClientId()){
    context.register(this);
  }

/// destroy the input timestamps manager object
/// 
/// Informs the server that the client will no longer be using this
/// protocol object. Existing objects created by this object are not
/// affected.
/// 
  Future<void> destroy() async {
    print("ZwpInputTimestampsManagerV1::destroy ");
    final message = WaylandMessage(
      objectId,
      0,
      [
      ],
      [
      ],
    );
    await context.sendMessage(message);
  }

/// subscribe to high-resolution keyboard timestamp events
/// 
/// Creates a new input timestamps object that represents a subscription
/// to high-resolution timestamp events for all wl_keyboard events that
/// carry a timestamp.
/// 
/// If the associated wl_keyboard object is invalidated, either through
/// client action (e.g. release) or server-side changes, the input
/// timestamps object becomes inert and the client should destroy it
/// by calling zwp_input_timestamps_v1.destroy.
/// 
/// [id]:
/// [keyboard]: the wl_keyboard object for which to get timestamp events
  Future<ZwpInputTimestampsV1> getKeyboardTimestamps(Keyboard keyboard) async {
  var id =  ZwpInputTimestampsV1(context);
    print("ZwpInputTimestampsManagerV1::getKeyboardTimestamps  id: $id keyboard: $keyboard");
    final message = WaylandMessage(
      objectId,
      1,
      [
        id,
        keyboard,
      ],
      [
        WaylandType.newId,
        WaylandType.object,
      ],
    );
    await context.sendMessage(message);
    return id;
  }

/// subscribe to high-resolution pointer timestamp events
/// 
/// Creates a new input timestamps object that represents a subscription
/// to high-resolution timestamp events for all wl_pointer events that
/// carry a timestamp.
/// 
/// If the associated wl_pointer object is invalidated, either through
/// client action (e.g. release) or server-side changes, the input
/// timestamps object becomes inert and the client should destroy it
/// by calling zwp_input_timestamps_v1.destroy.
/// 
/// [id]:
/// [pointer]: the wl_pointer object for which to get timestamp events
  Future<ZwpInputTimestampsV1> getPointerTimestamps(Pointer pointer) async {
  var id =  ZwpInputTimestampsV1(context);
    print("ZwpInputTimestampsManagerV1::getPointerTimestamps  id: $id pointer: $pointer");
    final message = WaylandMessage(
      objectId,
      2,
      [
        id,
        pointer,
      ],
      [
        WaylandType.newId,
        WaylandType.object,
      ],
    );
    await context.sendMessage(message);
    return id;
  }

/// subscribe to high-resolution touch timestamp events
/// 
/// Creates a new input timestamps object that represents a subscription
/// to high-resolution timestamp events for all wl_touch events that
/// carry a timestamp.
/// 
/// If the associated wl_touch object becomes invalid, either through
/// client action (e.g. release) or server-side changes, the input
/// timestamps object becomes inert and the client should destroy it
/// by calling zwp_input_timestamps_v1.destroy.
/// 
/// [id]:
/// [touch]: the wl_touch object for which to get timestamp events
  Future<ZwpInputTimestampsV1> getTouchTimestamps(Touch touch) async {
  var id =  ZwpInputTimestampsV1(context);
    print("ZwpInputTimestampsManagerV1::getTouchTimestamps  id: $id touch: $touch");
    final message = WaylandMessage(
      objectId,
      3,
      [
        id,
        touch,
      ],
      [
        WaylandType.newId,
        WaylandType.object,
      ],
    );
    await context.sendMessage(message);
    return id;
  }

}


/// high-resolution timestamp event
/// 
/// The timestamp event is associated with the first subsequent input event
/// carrying a timestamp which belongs to the set of input events this
/// object is subscribed to.
/// 
/// The timestamp provided by this event is a high-resolution version of
/// the timestamp argument of the associated input event. The provided
/// timestamp is in the same clock domain and is at least as accurate as
/// the associated input event timestamp.
/// 
/// The timestamp is expressed as tv_sec_hi, tv_sec_lo, tv_nsec triples,
/// each component being an unsigned 32-bit value. Whole seconds are in
/// tv_sec which is a 64-bit value combined from tv_sec_hi and tv_sec_lo,
/// and the additional fractional part in tv_nsec as nanoseconds. Hence,
/// for valid timestamps tv_nsec must be in [0, 999999999].
/// 
class ZwpInputTimestampsV1TimestampEvent {
/// high 32 bits of the seconds part of the timestamp
  final int tvSecHi;

/// low 32 bits of the seconds part of the timestamp
  final int tvSecLo;

/// nanoseconds part of the timestamp
  final int tvNsec;

  ZwpInputTimestampsV1TimestampEvent(
this.tvSecHi,

this.tvSecLo,

this.tvNsec,

);

@override
String toString(){
  return """ZwpInputTimestampsV1TimestampEvent: {
    tvSecHi: $tvSecHi,
    tvSecLo: $tvSecLo,
    tvNsec: $tvNsec,
  }""";
}

}

typedef ZwpInputTimestampsV1TimestampEventHandler = void Function(ZwpInputTimestampsV1TimestampEvent);


/// context object for input timestamps
/// 
/// Provides high-resolution timestamp events for a set of subscribed input
/// events. The set of subscribed input events is determined by the
/// zwp_input_timestamps_manager_v1 request used to create this object.
/// 
class ZwpInputTimestampsV1 extends Proxy implements Dispatcher{
  final Context context;

  ZwpInputTimestampsV1(this.context) : super(context.allocateClientId()){
    context.register(this);
  }

/// destroy the input timestamps object
/// 
/// Informs the server that the client will no longer be using this
/// protocol object. After the server processes the request, no more
/// timestamp events will be emitted.
/// 
  Future<void> destroy() async {
    print("ZwpInputTimestampsV1::destroy ");
    final message = WaylandMessage(
      objectId,
      0,
      [
      ],
      [
      ],
    );
    await context.sendMessage(message);
  }

/// high-resolution timestamp event
/// 
/// The timestamp event is associated with the first subsequent input event
/// carrying a timestamp which belongs to the set of input events this
/// object is subscribed to.
/// 
/// The timestamp provided by this event is a high-resolution version of
/// the timestamp argument of the associated input event. The provided
/// timestamp is in the same clock domain and is at least as accurate as
/// the associated input event timestamp.
/// 
/// The timestamp is expressed as tv_sec_hi, tv_sec_lo, tv_nsec triples,
/// each component being an unsigned 32-bit value. Whole seconds are in
/// tv_sec which is a 64-bit value combined from tv_sec_hi and tv_sec_lo,
/// and the additional fractional part in tv_nsec as nanoseconds. Hence,
/// for valid timestamps tv_nsec must be in [0, 999999999].
/// 
/// Event handler for Timestamp
/// - [tv_sec_hi]: high 32 bits of the seconds part of the timestamp
/// - [tv_sec_lo]: low 32 bits of the seconds part of the timestamp
/// - [tv_nsec]: nanoseconds part of the timestamp
 void onTimestamp(ZwpInputTimestampsV1TimestampEventHandler handler) {
   _timestampHandler = handler;
 }

 ZwpInputTimestampsV1TimestampEventHandler? _timestampHandler;

 @override
 void dispatch(int opcode, int fd, Uint8List data) {
   switch (opcode) {
     case 0:
       if (_timestampHandler != null) {
var event = ZwpInputTimestampsV1TimestampEvent(
           ByteData.view(data.buffer).getUint32(0, Endian.little),
           ByteData.view(data.buffer).getUint32(4, Endian.little),
           ByteData.view(data.buffer).getUint32(8, Endian.little),
        );
         _timestampHandler!(event);
       }
       break;
   }
 }
}
