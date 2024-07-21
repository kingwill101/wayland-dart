// Generated by dart-wayland-scanner
// https://github.com/your-repo/dart-wayland-scanner
// XML file : https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/unstable/relative-pointer/relative-pointer-unstable-v1.xml
//
// relative_pointer_unstable_v1 Protocol Copyright: 
/// 
/// Copyright © 2014      Jonas Ådahl
/// Copyright © 2015      Red Hat Inc.
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
import 'package:wayland/protocols/wayland.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:result_dart/result_dart.dart';


/// get relative pointer objects
/// 
/// A global interface used for getting the relative pointer object for a
/// given pointer.
/// 
class ZwpRelativePointerManagerV1 extends Proxy{
  final Context innerContext;
  final version = 1;

  ZwpRelativePointerManagerV1(this.innerContext) : super(innerContext.allocateClientId()){
    innerContext.register(this);
  }


@override
toString(){
return "ZwpRelativePointerManagerV1 {name: 'zwp_relative_pointer_manager_v1', id: '$objectId', version: '1',}";
}

/// destroy the relative pointer manager object
/// 
/// Used by the client to notify the server that it will no longer use this
/// relative pointer manager object.
/// 
  Result<void,Object> destroy() {
innerContext.unRegister(this);
    logLn("ZwpRelativePointerManagerV1::destroy ");
var arguments = [];var argTypes = <WaylandType>[];
var calclulatedSize  = calculateSize(argTypes, arguments);
final bytesBuilder = BytesBuilder();
bytesBuilder.add(Uint32List.fromList([objectId, (calclulatedSize << 16) | 0]).buffer.asUint8List());
    try{
    innerContext.sendMessage(bytesBuilder.toBytes(), );
    }catch (e) {
      logLn("Exception in ZwpRelativePointerManagerV1::destroy: $e");
   return Failure(e);
    }
    return Success(Object());
  }

/// get a relative pointer object
/// 
/// Create a relative pointer interface given a wl_pointer object. See the
/// wp_relative_pointer interface for more details.
/// 
/// [id]:
/// [pointer]:
  Result<ZwpRelativePointerV1,Object> getRelativePointer(Pointer pointer) {
  var id =  ZwpRelativePointerV1(innerContext);
    logLn("ZwpRelativePointerManagerV1::getRelativePointer  id: $id pointer: $pointer");
var arguments = [id, pointer];var argTypes = <WaylandType>[WaylandType.newId, WaylandType.object];
var calclulatedSize  = calculateSize(argTypes, arguments);
final bytesBuilder = BytesBuilder();
bytesBuilder.add(Uint32List.fromList([objectId, (calclulatedSize << 16) | 1]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([id.objectId]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([pointer.objectId]).buffer.asUint8List());
    try{
    innerContext.sendMessage(bytesBuilder.toBytes(), );
    }catch (e) {
      logLn("Exception in ZwpRelativePointerManagerV1::getRelativePointer: $e");
   return Failure(e);
    }
    return Success(id);
  }

}


/// relative pointer motion
/// 
/// Relative x/y pointer motion from the pointer of the seat associated with
/// this object.
/// 
/// A relative motion is in the same dimension as regular wl_pointer motion
/// events, except they do not represent an absolute position. For example,
/// moving a pointer from (x, y) to (x', y') would have the equivalent
/// relative motion (x' - x, y' - y). If a pointer motion caused the
/// absolute pointer position to be clipped by for example the edge of the
/// monitor, the relative motion is unaffected by the clipping and will
/// represent the unclipped motion.
/// 
/// This event also contains non-accelerated motion deltas. The
/// non-accelerated delta is, when applicable, the regular pointer motion
/// delta as it was before having applied motion acceleration and other
/// transformations such as normalization.
/// 
/// Note that the non-accelerated delta does not represent 'raw' events as
/// they were read from some device. Pointer motion acceleration is device-
/// and configuration-specific and non-accelerated deltas and accelerated
/// deltas may have the same value on some devices.
/// 
/// Relative motions are not coupled to wl_pointer.motion events, and can be
/// sent in combination with such events, but also independently. There may
/// also be scenarios where wl_pointer.motion is sent, but there is no
/// relative motion. The order of an absolute and relative motion event
/// originating from the same physical motion is not guaranteed.
/// 
/// If the client needs button events or focus state, it can receive them
/// from a wl_pointer object of the same seat that the wp_relative_pointer
/// object is associated with.
/// 
class ZwpRelativePointerV1RelativeMotionEvent {
/// high 32 bits of a 64 bit timestamp with microsecond granularity
  final int utimeHi;

/// low 32 bits of a 64 bit timestamp with microsecond granularity
  final int utimeLo;

/// the x component of the motion vector
  final double dx;

/// the y component of the motion vector
  final double dy;

/// the x component of the unaccelerated motion vector
  final double dxUnaccel;

/// the y component of the unaccelerated motion vector
  final double dyUnaccel;

  ZwpRelativePointerV1RelativeMotionEvent(
this.utimeHi,

this.utimeLo,

this.dx,

this.dy,

this.dxUnaccel,

this.dyUnaccel,

);

@override
toString(){
return "ZwpRelativePointerV1RelativeMotionEvent (utimeHi: $utimeHi, utimeLo: $utimeLo, dx: $dx, ..., dxUnaccel: $dxUnaccel, dyUnaccel: $dyUnaccel)";
}
}

typedef ZwpRelativePointerV1RelativeMotionEventHandler = void Function(ZwpRelativePointerV1RelativeMotionEvent);


/// relative pointer object
/// 
/// A wp_relative_pointer object is an extension to the wl_pointer interface
/// used for emitting relative pointer events. It shares the same focus as
/// wl_pointer objects of the same seat and will only emit events when it has
/// focus.
/// 
class ZwpRelativePointerV1 extends Proxy implements Dispatcher{
  final Context innerContext;
  final version = 1;

  ZwpRelativePointerV1(this.innerContext) : super(innerContext.allocateClientId()){
    innerContext.register(this);
  }


@override
toString(){
return "ZwpRelativePointerV1 {name: 'zwp_relative_pointer_v1', id: '$objectId', version: '1',}";
}

/// release the relative pointer object
/// 
  Result<void,Object> destroy() {
innerContext.unRegister(this);
    logLn("ZwpRelativePointerV1::destroy ");
var arguments = [];var argTypes = <WaylandType>[];
var calclulatedSize  = calculateSize(argTypes, arguments);
final bytesBuilder = BytesBuilder();
bytesBuilder.add(Uint32List.fromList([objectId, (calclulatedSize << 16) | 0]).buffer.asUint8List());
    try{
    innerContext.sendMessage(bytesBuilder.toBytes(), );
    }catch (e) {
      logLn("Exception in ZwpRelativePointerV1::destroy: $e");
   return Failure(e);
    }
    return Success(Object());
  }

/// relative pointer motion
/// 
/// Relative x/y pointer motion from the pointer of the seat associated with
/// this object.
/// 
/// A relative motion is in the same dimension as regular wl_pointer motion
/// events, except they do not represent an absolute position. For example,
/// moving a pointer from (x, y) to (x', y') would have the equivalent
/// relative motion (x' - x, y' - y). If a pointer motion caused the
/// absolute pointer position to be clipped by for example the edge of the
/// monitor, the relative motion is unaffected by the clipping and will
/// represent the unclipped motion.
/// 
/// This event also contains non-accelerated motion deltas. The
/// non-accelerated delta is, when applicable, the regular pointer motion
/// delta as it was before having applied motion acceleration and other
/// transformations such as normalization.
/// 
/// Note that the non-accelerated delta does not represent 'raw' events as
/// they were read from some device. Pointer motion acceleration is device-
/// and configuration-specific and non-accelerated deltas and accelerated
/// deltas may have the same value on some devices.
/// 
/// Relative motions are not coupled to wl_pointer.motion events, and can be
/// sent in combination with such events, but also independently. There may
/// also be scenarios where wl_pointer.motion is sent, but there is no
/// relative motion. The order of an absolute and relative motion event
/// originating from the same physical motion is not guaranteed.
/// 
/// If the client needs button events or focus state, it can receive them
/// from a wl_pointer object of the same seat that the wp_relative_pointer
/// object is associated with.
/// 
/// Event handler for RelativeMotion
/// - [utime_hi]: high 32 bits of a 64 bit timestamp with microsecond granularity
/// - [utime_lo]: low 32 bits of a 64 bit timestamp with microsecond granularity
/// - [dx]: the x component of the motion vector
/// - [dy]: the y component of the motion vector
/// - [dx_unaccel]: the x component of the unaccelerated motion vector
/// - [dy_unaccel]: the y component of the unaccelerated motion vector
 void onRelativeMotion(ZwpRelativePointerV1RelativeMotionEventHandler handler) {
   _relativeMotionHandler = handler;
 }

 ZwpRelativePointerV1RelativeMotionEventHandler? _relativeMotionHandler;

 @override
 void dispatch(int opcode, int fd, Uint8List data) {
logLn("ZwpRelativePointerV1.dispatch($opcode, $fd, $data)");
   switch (opcode) {     case 0:

       if (_relativeMotionHandler != null) {
var offset = 0;
final utimeHi = ByteData.view(data.buffer).getUint32(offset, Endian.little);
offset += 4;
final utimeLo = ByteData.view(data.buffer).getUint32(offset, Endian.little);
offset += 4;
final dx = fixedToDouble(ByteData.view(data.buffer).getInt32(offset, Endian.little));
offset += 4;
final dy = fixedToDouble(ByteData.view(data.buffer).getInt32(offset, Endian.little));
offset += 4;
final dxUnaccel = fixedToDouble(ByteData.view(data.buffer).getInt32(offset, Endian.little));
offset += 4;
final dyUnaccel = fixedToDouble(ByteData.view(data.buffer).getInt32(offset, Endian.little));
offset += 4;
var event = ZwpRelativePointerV1RelativeMotionEvent(
utimeHi,
utimeLo,
dx,
dy,
dxUnaccel,
dyUnaccel,
        );
         _relativeMotionHandler!(event);
       }
       break;
   }
 }
}

