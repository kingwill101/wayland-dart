// Generated by dart-wayland-scanner
// https://github.com/your-repo/dart-wayland-scanner
// XML file : https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/staging/fractional-scale/fractional-scale-v1.xml
//
// fractional_scale_v1 Protocol Copyright: 
/// 
/// Copyright © 2022 Kenny Levinsen
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


/// fractional surface scale information
/// 
/// A global interface for requesting surfaces to use fractional scales.
/// 
class WpFractionalScaleManagerV1 extends Proxy{
  final Context context;

  WpFractionalScaleManagerV1(this.context) : super(context.allocateClientId()){
    context.register(this);
  }

/// unbind the fractional surface scale interface
/// 
/// Informs the server that the client will not be using this protocol
/// object anymore. This does not affect any other objects,
/// wp_fractional_scale_v1 objects included.
/// 
  Future<void> destroy() async {
    print("WpFractionalScaleManagerV1::destroy ");
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

/// extend surface interface for scale information
/// 
/// Create an add-on object for the the wl_surface to let the compositor
/// request fractional scales. If the given wl_surface already has a
/// wp_fractional_scale_v1 object associated, the fractional_scale_exists
/// protocol error is raised.
/// 
/// [id]: the new surface scale info interface id
/// [surface]: the surface
  Future<WpFractionalScaleV1> getFractionalScale(Surface surface) async {
  var id =  WpFractionalScaleV1(context);
    print("WpFractionalScaleManagerV1::getFractionalScale  id: $id surface: $surface");
    final message = WaylandMessage(
      objectId,
      1,
      [
        id,
        surface,
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

/// 
/// 

enum WpFractionalScaleManagerV1error {
/// the surface already has a fractional_scale object associated
  fractionalScaleExists,
}


/// notify of new preferred scale
/// 
/// Notification of a new preferred scale for this surface that the
/// compositor suggests that the client should use.
/// 
/// The sent scale is the numerator of a fraction with a denominator of 120.
/// 
class WpFractionalScaleV1PreferredScaleEvent {
/// the new preferred scale
  final int scale;

  WpFractionalScaleV1PreferredScaleEvent(
this.scale,

);

@override
String toString(){
  return """WpFractionalScaleV1PreferredScaleEvent: {
    scale: $scale,
  }""";
}

}

typedef WpFractionalScaleV1PreferredScaleEventHandler = void Function(WpFractionalScaleV1PreferredScaleEvent);


/// fractional scale interface to a wl_surface
/// 
/// An additional interface to a wl_surface object which allows the compositor
/// to inform the client of the preferred scale.
/// 
class WpFractionalScaleV1 extends Proxy implements Dispatcher{
  final Context context;

  WpFractionalScaleV1(this.context) : super(context.allocateClientId()){
    context.register(this);
  }

/// remove surface scale information for surface
/// 
/// Destroy the fractional scale object. When this object is destroyed,
/// preferred_scale events will no longer be sent.
/// 
  Future<void> destroy() async {
    print("WpFractionalScaleV1::destroy ");
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

/// notify of new preferred scale
/// 
/// Notification of a new preferred scale for this surface that the
/// compositor suggests that the client should use.
/// 
/// The sent scale is the numerator of a fraction with a denominator of 120.
/// 
/// Event handler for PreferredScale
/// - [scale]: the new preferred scale
 void onPreferredScale(WpFractionalScaleV1PreferredScaleEventHandler handler) {
   _preferredScaleHandler = handler;
 }

 WpFractionalScaleV1PreferredScaleEventHandler? _preferredScaleHandler;

 @override
 void dispatch(int opcode, int fd, Uint8List data) {
   switch (opcode) {
     case 0:
       if (_preferredScaleHandler != null) {
var event = WpFractionalScaleV1PreferredScaleEvent(
           ByteData.view(data.buffer).getUint32(0, Endian.little),
        );
         _preferredScaleHandler!(event);
       }
       break;
   }
 }
}
