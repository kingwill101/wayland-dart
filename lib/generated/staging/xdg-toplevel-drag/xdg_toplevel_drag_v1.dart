// Generated by dart-wayland-scanner
// https://github.com/your-repo/dart-wayland-scanner
// XML file : https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/staging/xdg-toplevel-drag/xdg-toplevel-drag-v1.xml
//
// xdg_toplevel_drag_v1 Protocol Copyright: 
/// 
/// Copyright 2023 David Redondo
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
import 'package:wayland/generated/stable/xdg-shell/xdg_shell.dart';
import 'dart:typed_data';
/// Move a window during a drag
/// 
/// This protocol enhances normal drag and drop with the ability to move a
/// window at the same time. This allows having detachable parts of a window
/// that when dragged out of it become a new window and can be dragged over
/// an existing window to be reattached.
/// 
/// A typical workflow would be when the user starts dragging on top of a
/// detachable part of a window, the client would create a wl_data_source and
/// a xdg_toplevel_drag_v1 object and start the drag as normal via
/// wl_data_device.start_drag. Once the client determines that the detachable
/// window contents should be detached from the originating window, it creates
/// a new xdg_toplevel with these contents and issues a
/// xdg_toplevel_drag_v1.attach request before mapping it. From now on the new
/// window is moved by the compositor during the drag as if the client called
/// xdg_toplevel.move.
/// 
/// Dragging an existing window is similar. The client creates a
/// xdg_toplevel_drag_v1 object and attaches the existing toplevel before
/// starting the drag.
/// 
/// Clients use the existing drag and drop mechanism to detect when a window
/// can be docked or undocked. If the client wants to snap a window into a
/// parent window it should delete or unmap the dragged top-level. If the
/// contents should be detached again it attaches a new toplevel as described
/// above. If a drag operation is cancelled without being dropped, clients
/// should revert to the previous state, deleting any newly created windows
/// as appropriate. When a drag operation ends as indicated by
/// wl_data_source.dnd_drop_performed the dragged toplevel window's final
/// position is determined as if a xdg_toplevel_move operation ended.
/// 
/// Warning! The protocol described in this file is currently in the testing
/// phase. Backward compatible changes may be added together with the
/// corresponding interface version bump. Backward incompatible changes can
/// only be done by creating a new major version of the extension.
/// 
class XdgToplevelDragManagerV1 extends Proxy{
  final Context context;

  XdgToplevelDragManagerV1(this.context) : super(context.allocateClientId());

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

  Future<void> getXdgToplevelDrag(DataSource dataSource) async {
  var id =  XdgToplevelDragManagerV1(context);
    final message = WaylandMessage(
      context.allocateClientId(),
      1,
      [
        id,
        dataSource,
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

enum XdgToplevelDragManagerV1error {
  /// data_source already used for toplevel drag
  invalidSource,
}

/// Object representing a toplevel move during a drag
/// 
/// 
class XdgToplevelDragV1 extends Proxy{
  final Context context;

  XdgToplevelDragV1(this.context) : super(context.allocateClientId());

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

  Future<void> attach(XdgToplevel toplevel, int xOffset, int yOffset) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      1,
      [
        toplevel,
        xOffset,
        yOffset,
      ],
      [
        WaylandType.object,
        WaylandType.int,
        WaylandType.int,
      ],
    );
    context.sendMessage(message);
  }

}

/// 
/// 

enum XdgToplevelDragV1error {
  /// valid toplevel already attached
  toplevelAttached,
  /// drag has not ended
  ongoingDrag,
}

