// Generated by dart-wayland-scanner
// https://github.com/your-repo/dart-wayland-scanner
// XML file : https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/staging/xwayland-shell/xwayland-shell-v1.xml
//
// xwayland_shell_v1 Protocol Copyright:
///
/// Copyright © 2022 Joshua Ashton
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

/// context object for Xwayland shell
///
/// xwayland_shell_v1 is a singleton global object that
/// provides the ability to create a xwayland_surface_v1 object
/// for a given wl_surface.
///
/// This interface is intended to be bound by the Xwayland server.
///
/// A compositor must not allow clients other than Xwayland to
/// bind to this interface. A compositor should hide this global
/// from other clients' wl_registry.
/// A client the compositor does not consider to be an Xwayland
/// server attempting to bind this interface will result in
/// an implementation-defined error.
///
/// An Xwayland server that has bound this interface must not
/// set the `WL_SURFACE_ID` atom on a window.
///
class XwaylandShellV1 extends Proxy {
  final Context innerContext;
  final version = 1;

  XwaylandShellV1(this.innerContext) : super(innerContext.allocateClientId()) {
    innerContext.register(this);
  }

  @override
  toString() {
    return "XwaylandShellV1 {name: 'xwayland_shell_v1', id: '$objectId', version: '1',}";
  }

  /// destroy the Xwayland shell object
  ///
  /// Destroy the xwayland_shell_v1 object.
  ///
  /// The child objects created via this interface are unaffected.
  ///
  void destroy() {
    logLn("XwaylandShellV1::destroy ");
    var arguments = [];
    var argTypes = <WaylandType>[];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 0])
            .buffer
            .asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// assign the xwayland_surface surface role
  ///
  /// Create an xwayland_surface_v1 interface for a given wl_surface
  /// object and gives it the xwayland_surface role.
  ///
  /// It is illegal to create an xwayland_surface_v1 for a wl_surface
  /// which already has an assigned role and this will result in the
  /// `role` protocol error.
  ///
  /// See the documentation of xwayland_surface_v1 for more details
  /// about what an xwayland_surface_v1 is and how it is used.
  ///
  /// [id]:
  /// [surface]:
  XwaylandSurfaceV1 getXwaylandSurface(Surface surface) {
    var id = XwaylandSurfaceV1(innerContext);
    logLn("XwaylandShellV1::getXwaylandSurface  id: $id surface: $surface");
    var arguments = [id, surface];
    var argTypes = <WaylandType>[WaylandType.newId, WaylandType.object];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 1])
            .buffer
            .asUint8List());
    bytesBuilder.add(Uint32List.fromList([id.objectId]).buffer.asUint8List());
    bytesBuilder
        .add(Uint32List.fromList([surface.objectId]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
    return id;
  }
}

///
///

enum XwaylandShellV1Error {
  /// given wl_surface has another role
  role("role", 0);

  const XwaylandShellV1Error(this.enumName, this.enumValue);
  final int enumValue;
  final String enumName;
  @override
  toString() {
    return "XwaylandShellV1Error {name: $enumName, value: $enumValue}";
  }
}

/// interface for associating Xwayland windows to wl_surfaces
///
/// An Xwayland surface is a surface managed by an Xwayland server.
/// It is used for associating surfaces to Xwayland windows.
///
/// The Xwayland server associated with actions in this interface is
/// determined by the Wayland client making the request.
///
/// The client must call wl_surface.commit on the corresponding wl_surface
/// for the xwayland_surface_v1 state to take effect.
///
class XwaylandSurfaceV1 extends Proxy {
  final Context innerContext;
  final version = 1;

  XwaylandSurfaceV1(this.innerContext)
      : super(innerContext.allocateClientId()) {
    innerContext.register(this);
  }

  @override
  toString() {
    return "XwaylandSurfaceV1 {name: 'xwayland_surface_v1', id: '$objectId', version: '1',}";
  }

  /// associates a Xwayland window to a wl_surface
  ///
  /// Associates an Xwayland window to a wl_surface.
  /// The association state is double-buffered, see wl_surface.commit.
  ///
  /// The `serial_lo` and `serial_hi` parameters specify a non-zero
  /// monotonic serial number which is entirely unique and provided by the
  /// Xwayland server equal to the serial value provided by a client message
  /// with a message type of the `WL_SURFACE_SERIAL` atom on the X11 window
  /// for this surface to be associated to.
  ///
  /// The serial value in the `WL_SURFACE_SERIAL` client message is specified
  /// as having the lo-bits specified in `l[0]` and the hi-bits specified
  /// in `l[1]`.
  ///
  /// If the serial value provided by `serial_lo` and `serial_hi` is not
  /// valid, the `invalid_serial` protocol error will be raised.
  ///
  /// An X11 window may be associated with multiple surfaces throughout its
  /// lifespan. (eg. unmapping and remapping a window).
  ///
  /// For each wl_surface, this state must not be committed more than once,
  /// otherwise the `already_associated` protocol error will be raised.
  ///
  /// [serial_lo]: The lower 32-bits of the serial number associated with the X11 window
  /// [serial_hi]: The upper 32-bits of the serial number associated with the X11 window
  void setSerial(int serialLo, int serialHi) {
    logLn(
        "XwaylandSurfaceV1::setSerial  serialLo: $serialLo serialHi: $serialHi");
    var arguments = [serialLo, serialHi];
    var argTypes = <WaylandType>[WaylandType.uint, WaylandType.uint];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 0])
            .buffer
            .asUint8List());
    bytesBuilder.add(Uint32List.fromList([serialLo]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([serialHi]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// destroy the Xwayland surface object
  ///
  /// Destroy the xwayland_surface_v1 object.
  ///
  /// Any already existing associations are unaffected by this action.
  ///
  void destroy() {
    logLn("XwaylandSurfaceV1::destroy ");
    var arguments = [];
    var argTypes = <WaylandType>[];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 1])
            .buffer
            .asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }
}

///
///

enum XwaylandSurfaceV1Error {
  /// given wl_surface is already associated with an X11 window
  alreadyAssociated("already_associated", 0),

  /// serial was not valid
  invalidSerial("invalid_serial", 1);

  const XwaylandSurfaceV1Error(this.enumName, this.enumValue);
  final int enumValue;
  final String enumName;
  @override
  toString() {
    return "XwaylandSurfaceV1Error {name: $enumName, value: $enumValue}";
  }
}
