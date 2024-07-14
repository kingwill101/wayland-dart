// Generated by dart-wayland-scanner
// https://github.com/your-repo/dart-wayland-scanner
// XML file : https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/unstable/xwayland-keyboard-grab/xwayland-keyboard-grab-unstable-v1.xml
//
// xwayland_keyboard_grab_unstable_v1 Protocol Copyright: 
/// 
/// Copyright © 2017 Red Hat Inc.
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
import 'dart:typed_data';
/// context object for keyboard grab manager
/// 
/// A global interface used for grabbing the keyboard.
/// 
class ZwpXwaylandKeyboardGrabManagerV1 extends Proxy{
  final Context context;

  ZwpXwaylandKeyboardGrabManagerV1(this.context) : super(context.allocateClientId());

  Future<void> destroy() async {
    final message = WaylandMessage(
      context.allocateClientId(),
      0,
      [
      ],
      [
      ],
    );
    context.sendMessage(message);
  }

  Future<void> grabKeyboard(Surface surface, Seat seat) async {
  var id =  ZwpXwaylandKeyboardGrabManagerV1(context);
    final message = WaylandMessage(
      context.allocateClientId(),
      1,
      [
        id,
        surface,
        seat,
      ],
      [
        WaylandType.newId,
        WaylandType.object,
        WaylandType.object,
      ],
    );
    context.sendMessage(message);
  }

}

/// interface for grabbing the keyboard
/// 
/// A global interface used for grabbing the keyboard.
/// 
class ZwpXwaylandKeyboardGrabV1 extends Proxy{
  final Context context;

  ZwpXwaylandKeyboardGrabV1(this.context) : super(context.allocateClientId());

  Future<void> destroy() async {
    final message = WaylandMessage(
      context.allocateClientId(),
      0,
      [
      ],
      [
      ],
    );
    context.sendMessage(message);
  }

}

