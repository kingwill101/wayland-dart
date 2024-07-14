// Generated by dart-wayland-scanner
// https://github.com/your-repo/dart-wayland-scanner
// XML file : https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/staging/xdg-dialog/xdg-dialog-v1.xml
//
// xdg_dialog_v1 Protocol Copyright: 
/// 
/// Copyright © 2023 Carlos Garnacho
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
/// create dialogs related to other toplevels
/// 
/// The xdg_wm_dialog_v1 interface is exposed as a global object allowing
/// to register surfaces with a xdg_toplevel role as "dialogs" relative to
/// another toplevel.
/// 
/// The compositor may let this relation influence how the surface is
/// placed, displayed or interacted with.
/// 
/// Warning! The protocol described in this file is currently in the testing
/// phase. Backward compatible changes may be added together with the
/// corresponding interface version bump. Backward incompatible changes can
/// only be done by creating a new major version of the extension.
/// 
class XdgWmDialogV1 extends Proxy{
  final Context context;

  XdgWmDialogV1(this.context) : super(context.allocateClientId());

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

  Future<void> getXdgDialog(XdgToplevel toplevel) async {
  var id =  XdgWmDialogV1(context);
    final message = WaylandMessage(
      context.allocateClientId(),
      1,
      [
        id,
        toplevel,
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

enum XdgWmDialogV1error {
  /// the xdg_toplevel object has already been used to create a xdg_dialog_v1
  alreadyUsed,
}

/// dialog object
/// 
/// A xdg_dialog_v1 object is an ancillary object tied to a xdg_toplevel. Its
/// purpose is hinting the compositor that the toplevel is a "dialog" (e.g. a
/// temporary window) relative to another toplevel (see
/// xdg_toplevel.set_parent). If the xdg_toplevel is destroyed, the xdg_dialog_v1
/// becomes inert.
/// 
/// Through this object, the client may provide additional hints about
/// the purpose of the secondary toplevel. This interface has no effect
/// on toplevels that are not attached to a parent toplevel.
/// 
class XdgDialogV1 extends Proxy{
  final Context context;

  XdgDialogV1(this.context) : super(context.allocateClientId());

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

  Future<void> setModal() async {
    final message = WaylandMessage(
      context.allocateClientId(),
      1,
      [
      ],
      [
      ],
    );
    context.sendMessage(message);
  }

  Future<void> unsetModal() async {
    final message = WaylandMessage(
      context.allocateClientId(),
      2,
      [
      ],
      [
      ],
    );
    context.sendMessage(message);
  }

}

