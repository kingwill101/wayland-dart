// Generated by dart-wayland-scanner
// https://github.com/your-repo/dart-wayland-scanner
// XML file : https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/staging/content-type/content-type-v1.xml
//
// content_type_v1 Protocol Copyright: 
/// 
/// Copyright © 2021 Emmanuel Gil Peyrot
/// Copyright © 2022 Xaver Hugl
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
/// surface content type manager
/// 
/// This interface allows a client to describe the kind of content a surface
/// will display, to allow the compositor to optimize its behavior for it.
/// 
/// Warning! The protocol described in this file is currently in the testing
/// phase. Backward compatible changes may be added together with the
/// corresponding interface version bump. Backward incompatible changes can
/// only be done by creating a new major version of the extension.
/// 
class WpContentTypeManagerV1 extends Proxy{
  final Context context;

  WpContentTypeManagerV1(this.context) : super(context.allocateClientId());

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

  Future<void> getSurfaceContentType(Surface surface) async {
  var id =  WpContentTypeManagerV1(context);
    final message = WaylandMessage(
      context.allocateClientId(),
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
    context.sendMessage(message);
  }

}

/// 
/// 

enum WpContentTypeManagerV1error {
  /// wl_surface already has a content type object
  alreadyConstructed,
}

/// content type object for a surface
/// 
/// The content type object allows the compositor to optimize for the kind
/// of content shown on the surface. A compositor may for example use it to
/// set relevant drm properties like "content type".
/// 
/// The client may request to switch to another content type at any time.
/// When the associated surface gets destroyed, this object becomes inert and
/// the client should destroy it.
/// 
class WpContentTypeV1 extends Proxy{
  final Context context;

  WpContentTypeV1(this.context) : super(context.allocateClientId());

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

  Future<void> setContentType(int contentType) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      1,
      [
        contentType,
      ],
      [
        WaylandType.uint,
      ],
    );
    context.sendMessage(message);
  }

}

/// possible content types
/// 
/// These values describe the available content types for a surface.
/// 

enum WpContentTypeV1type {
  /// 
  none,
  /// 
  photo,
  /// 
  video,
  /// 
  game,
}

