// Generated by dart-wayland-scanner
// https://github.com/your-repo/dart-wayland-scanner
// XML file : https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/staging/xdg-toplevel-icon/xdg-toplevel-icon-v1.xml
//
// xdg_toplevel_icon_v1 Protocol Copyright:
///
/// Copyright © 2023-2024 Matthias Klumpp
/// Copyright ©      2024 David Edmundson
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
import 'package:wayland/protocols/stable/xdg-shell/xdg_shell.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// describes a supported & preferred icon size
///
/// This event indicates an icon size the compositor prefers to be
/// available if the client has scalable icons and can render to any size.
///
/// When the 'xdg_toplevel_icon_manager_v1' object is created, the
/// compositor may send one or more 'icon_size' events to describe the list
/// of preferred icon sizes. If the compositor has no size preference, it
/// may not send any 'icon_size' event, and it is up to the client to
/// decide a suitable icon size.
///
/// A sequence of 'icon_size' events must be finished with a 'done' event.
/// If the compositor has no size preferences, it must still send the
/// 'done' event, without any preceding 'icon_size' events.
///
class XdgToplevelIconManagerV1IconSizeEvent {
  /// the edge size of the square icon in surface-local coordinates, e.g. 64
  final int size;

  XdgToplevelIconManagerV1IconSizeEvent(
    this.size,
  );

  @override
  toString() {
    return "XdgToplevelIconManagerV1IconSizeEvent (size: $size)";
  }
}

typedef XdgToplevelIconManagerV1IconSizeEventHandler = void Function(
    XdgToplevelIconManagerV1IconSizeEvent);

/// all information has been sent
///
/// This event is sent after all 'icon_size' events have been sent.
///
class XdgToplevelIconManagerV1DoneEvent {
  XdgToplevelIconManagerV1DoneEvent();

  @override
  toString() {
    return "XdgToplevelIconManagerV1DoneEvent ()";
  }
}

typedef XdgToplevelIconManagerV1DoneEventHandler = void Function(
    XdgToplevelIconManagerV1DoneEvent);

/// interface to manage toplevel icons
///
/// This interface allows clients to create toplevel window icons and set
/// them on toplevel windows to be displayed to the user.
///
class XdgToplevelIconManagerV1 extends Proxy implements Dispatcher {
  final Context innerContext;
  final version = 1;

  XdgToplevelIconManagerV1(this.innerContext)
      : super(innerContext.allocateClientId()) {
    innerContext.register(this);
  }

  @override
  toString() {
    return "XdgToplevelIconManagerV1 {name: 'xdg_toplevel_icon_manager_v1', id: '$objectId', version: '1',}";
  }

  /// destroy the toplevel icon manager
  ///
  /// Destroy the toplevel icon manager.
  /// This does not destroy objects created with the manager.
  ///
  void destroy() {
    logLn("XdgToplevelIconManagerV1::destroy ");
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

  /// create a new icon instance
  ///
  /// Creates a new icon object. This icon can then be attached to a
  /// xdg_toplevel via the 'set_icon' request.
  ///
  /// [id]:
  XdgToplevelIconV1 createIcon() {
    var id = XdgToplevelIconV1(innerContext);
    logLn("XdgToplevelIconManagerV1::createIcon  id: $id");
    var arguments = [id];
    var argTypes = <WaylandType>[WaylandType.newId];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 1])
            .buffer
            .asUint8List());
    bytesBuilder.add(Uint32List.fromList([id.objectId]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
    return id;
  }

  /// set an icon on a toplevel window
  ///
  /// This request assigns the icon 'icon' to 'toplevel', or clears the
  /// toplevel icon if 'icon' was null.
  /// This state is double-buffered and is applied on the next
  /// wl_surface.commit of the toplevel.
  ///
  /// After making this call, the xdg_toplevel_icon_v1 provided as 'icon'
  /// can be destroyed by the client without 'toplevel' losing its icon.
  /// The xdg_toplevel_icon_v1 is immutable from this point, and any
  /// future attempts to change it must raise the
  /// 'xdg_toplevel_icon_v1.immutable' protocol error.
  ///
  /// The compositor must set the toplevel icon from either the pixel data
  /// the icon provides, or by loading a stock icon using the icon name.
  /// See the description of 'xdg_toplevel_icon_v1' for details.
  ///
  /// If 'icon' is set to null, the icon of the respective toplevel is reset
  /// to its default icon (usually the icon of the application, derived from
  /// its desktop-entry file, or a placeholder icon).
  /// If this request is passed an icon with no pixel buffers or icon name
  /// assigned, the icon must be reset just like if 'icon' was null.
  ///
  /// [toplevel]: the toplevel to act on
  /// [icon]:
  void setIcon(XdgToplevel toplevel, XdgToplevelIconV1 icon) {
    logLn("XdgToplevelIconManagerV1::setIcon  toplevel: $toplevel icon: $icon");
    var arguments = [toplevel, icon];
    var argTypes = <WaylandType>[WaylandType.object, WaylandType.object];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 2])
            .buffer
            .asUint8List());
    bytesBuilder
        .add(Uint32List.fromList([toplevel.objectId]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([icon.objectId]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// describes a supported & preferred icon size
  ///
  /// This event indicates an icon size the compositor prefers to be
  /// available if the client has scalable icons and can render to any size.
  ///
  /// When the 'xdg_toplevel_icon_manager_v1' object is created, the
  /// compositor may send one or more 'icon_size' events to describe the list
  /// of preferred icon sizes. If the compositor has no size preference, it
  /// may not send any 'icon_size' event, and it is up to the client to
  /// decide a suitable icon size.
  ///
  /// A sequence of 'icon_size' events must be finished with a 'done' event.
  /// If the compositor has no size preferences, it must still send the
  /// 'done' event, without any preceding 'icon_size' events.
  ///
  /// Event handler for IconSize
  /// - [size]: the edge size of the square icon in surface-local coordinates, e.g. 64
  void onIconSize(XdgToplevelIconManagerV1IconSizeEventHandler handler) {
    _iconSizeHandler = handler;
  }

  XdgToplevelIconManagerV1IconSizeEventHandler? _iconSizeHandler;

  /// all information has been sent
  ///
  /// This event is sent after all 'icon_size' events have been sent.
  ///
  /// Event handler for Done
  void onDone(XdgToplevelIconManagerV1DoneEventHandler handler) {
    _doneHandler = handler;
  }

  XdgToplevelIconManagerV1DoneEventHandler? _doneHandler;

  @override
  void dispatch(int opcode, int fd, Uint8List data) {
    logLn("XdgToplevelIconManagerV1.dispatch($opcode, $fd, $data)");
    switch (opcode) {
      case 0:
        if (_iconSizeHandler != null) {
          var offset = 0;
          final size =
              ByteData.view(data.buffer).getInt32(offset, Endian.little);
          offset += 4;
          var event = XdgToplevelIconManagerV1IconSizeEvent(
            size,
          );
          _iconSizeHandler!(event);
        }
        break;
      case 1:
        if (_doneHandler != null) {
          _doneHandler!(XdgToplevelIconManagerV1DoneEvent());
        }
        break;
    }
  }
}

/// a toplevel window icon
///
/// This interface defines a toplevel icon.
/// An icon can have a name, and multiple buffers.
/// In order to be applied, the icon must have either a name, or at least
/// one buffer assigned. Applying an empty icon (with no buffer or name) to
/// a toplevel should reset its icon to the default icon.
///
/// It is up to compositor policy whether to prefer using a buffer or loading
/// an icon via its name. See 'set_name' and 'add_buffer' for details.
///
class XdgToplevelIconV1 extends Proxy {
  final Context innerContext;
  final version = 1;

  XdgToplevelIconV1(this.innerContext)
      : super(innerContext.allocateClientId()) {
    innerContext.register(this);
  }

  @override
  toString() {
    return "XdgToplevelIconV1 {name: 'xdg_toplevel_icon_v1', id: '$objectId', version: '1',}";
  }

  /// destroy the icon object
  ///
  /// Destroys the 'xdg_toplevel_icon_v1' object.
  /// The icon must still remain set on every toplevel it was assigned to,
  /// until the toplevel icon is reset explicitly.
  ///
  void destroy() {
    logLn("XdgToplevelIconV1::destroy ");
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

  /// set an icon name
  ///
  /// This request assigns an icon name to this icon.
  /// Any previously set name is overridden.
  ///
  /// The compositor must resolve 'icon_name' according to the lookup rules
  /// described in the XDG icon theme specification[1] using the
  /// environment's current icon theme.
  ///
  /// If the compositor does not support icon names or cannot resolve
  /// 'icon_name' according to the XDG icon theme specification it must
  /// fall back to using pixel buffer data instead.
  ///
  /// If this request is made after the icon has been assigned to a toplevel
  /// via 'set_icon', a 'immutable' error must be raised.
  ///
  /// [1]: https://specifications.freedesktop.org/icon-theme-spec/icon-theme-spec-latest.html
  ///
  /// [icon_name]:
  void setName(String iconName) {
    logLn("XdgToplevelIconV1::setName  iconName: $iconName");
    var arguments = [iconName];
    var argTypes = <WaylandType>[WaylandType.string];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 1])
            .buffer
            .asUint8List());
    final iconNameBytes = utf8.encode(iconName);
    bytesBuilder.add(
        Uint32List.fromList([iconNameBytes.length + 1]).buffer.asUint8List());
    bytesBuilder.add(iconNameBytes);
    bytesBuilder.add([0]); // Null terminator
    while (bytesBuilder.length % 4 != 0) {
      bytesBuilder.add([0]);
    } // Padding
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// add icon data from a pixel buffer
  ///
  /// This request adds pixel data supplied as wl_buffer to the icon.
  ///
  /// The client should add pixel data for all icon sizes and scales that
  /// it can provide, or which are explicitly requested by the compositor
  /// via 'icon_size' events on xdg_toplevel_icon_manager_v1.
  ///
  /// The wl_buffer supplying pixel data as 'buffer' must be backed by wl_shm
  /// and must be a square (width and height being equal).
  /// If any of these buffer requirements are not fulfilled, a 'invalid_buffer'
  /// error must be raised.
  ///
  /// If this icon instance already has a buffer of the same size and scale
  /// from a previous 'add_buffer' request, data from the last request
  /// overrides the preexisting pixel data.
  ///
  /// The wl_buffer must be kept alive for as long as the xdg_toplevel_icon
  /// it is associated with is not destroyed. The buffer contents must not be
  /// modified after it was assigned to the icon.
  ///
  /// If this request is made after the icon has been assigned to a toplevel
  /// via 'set_icon', a 'immutable' error must be raised.
  ///
  /// [buffer]:
  /// [scale]: the scaling factor of the icon, e.g. 1
  void addBuffer(Buffer buffer, int scale) {
    logLn("XdgToplevelIconV1::addBuffer  buffer: $buffer scale: $scale");
    var arguments = [buffer, scale];
    var argTypes = <WaylandType>[WaylandType.object, WaylandType.int];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 2])
            .buffer
            .asUint8List());
    bytesBuilder
        .add(Uint32List.fromList([buffer.objectId]).buffer.asUint8List());
    bytesBuilder.add(Int32List.fromList([scale]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }
}

///
///

enum XdgToplevelIconV1Error {
  /// the provided buffer does not satisfy requirements
  invalidBuffer("invalid_buffer", 1),

  /// the icon has already been assigned to a toplevel and must not be changed
  immutable("immutable", 2);

  const XdgToplevelIconV1Error(this.enumName, this.enumValue);
  final int enumValue;
  final String enumName;
  @override
  toString() {
    return "XdgToplevelIconV1Error {name: $enumName, value: $enumValue}";
  }
}
