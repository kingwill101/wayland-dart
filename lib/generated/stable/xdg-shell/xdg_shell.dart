// Generated by dart-wayland-scanner
// https://github.com/your-repo/dart-wayland-scanner
// XML file : https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/stable/xdg-shell/xdg-shell.xml
//
// xdg_shell Protocol Copyright: 
/// 
/// Copyright © 2008-2013 Kristian Høgsberg
/// Copyright © 2013      Rafael Antognolli
/// Copyright © 2013      Jasper St. Pierre
/// Copyright © 2010-2013 Intel Corporation
/// Copyright © 2015-2017 Samsung Electronics Co., Ltd
/// Copyright © 2015-2017 Red Hat Inc.
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
/// create desktop-style surfaces
/// 
/// The xdg_wm_base interface is exposed as a global object enabling clients
/// to turn their wl_surfaces into windows in a desktop environment. It
/// defines the basic functionality needed for clients and the compositor to
/// create windows that can be dragged, resized, maximized, etc, as well as
/// creating transient windows such as popup menus.
/// 
class XdgWmBase extends Proxy implements Dispatcher{
  final Context context;

  XdgWmBase(this.context) : super(context.allocateClientId());

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

  Future<void> createPositioner() async {
  var id =  XdgWmBase(context);
    final message = WaylandMessage(
      context.allocateClientId(),
      1,
      [
        id,
      ],
      [
        WaylandType.newId,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> getXdgSurface(Surface surface) async {
  var id =  XdgWmBase(context);
    final message = WaylandMessage(
      context.allocateClientId(),
      2,
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

  Future<void> pong(int serial) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      3,
      [
        serial,
      ],
      [
        WaylandType.uint,
      ],
    );
    context.sendMessage(message);
  }

 /// check if the client is alive
/// 
/// The ping event asks the client if it's still alive. Pass the
/// serial specified in the event back to the compositor by sending
/// a "pong" request back with the specified serial. See xdg_wm_base.pong.
/// 
/// Compositors can use this to determine if the client is still
/// alive. It's unspecified what will happen if the client doesn't
/// respond to the ping request, or in what timeframe. Clients should
/// try to respond in a reasonable amount of time. The “unresponsive”
/// error is provided for compositors that wish to disconnect unresponsive
/// clients.
/// 
/// A compositor is free to ping in any way it wants, but a client must
/// always respond to any xdg_wm_base object it created.
/// 
 void onping(void Function(int serial) handler) {
   _pingHandler = handler;
 }

 void Function(int serial)? _pingHandler;

 @override
 void dispatch(int opcode, int fd, Uint8List data) {
   switch (opcode) {
     case 0:
       if (_pingHandler != null) {
         _pingHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
         );
       }
       break;
   }
 }
}

/// 
/// 

enum XdgWmBaseerror {
  /// given wl_surface has another role
  role,
  /// xdg_wm_base was destroyed before children
  defunctSurfaces,
  /// the client tried to map or destroy a non-topmost popup
  notTheTopmostPopup,
  /// the client specified an invalid popup parent surface
  invalidPopupParent,
  /// the client provided an invalid surface state
  invalidSurfaceState,
  /// the client provided an invalid positioner
  invalidPositioner,
  /// the client didn’t respond to a ping event in time
  unresponsive,
}

/// child surface positioner
/// 
/// The xdg_positioner provides a collection of rules for the placement of a
/// child surface relative to a parent surface. Rules can be defined to ensure
/// the child surface remains within the visible area's borders, and to
/// specify how the child surface changes its position, such as sliding along
/// an axis, or flipping around a rectangle. These positioner-created rules are
/// constrained by the requirement that a child surface must intersect with or
/// be at least partially adjacent to its parent surface.
/// 
/// See the various requests for details about possible rules.
/// 
/// At the time of the request, the compositor makes a copy of the rules
/// specified by the xdg_positioner. Thus, after the request is complete the
/// xdg_positioner object can be destroyed or reused; further changes to the
/// object will have no effect on previous usages.
/// 
/// For an xdg_positioner object to be considered complete, it must have a
/// non-zero size set by set_size, and a non-zero anchor rectangle set by
/// set_anchor_rect. Passing an incomplete xdg_positioner object when
/// positioning a surface raises an invalid_positioner error.
/// 
class XdgPositioner extends Proxy{
  final Context context;

  XdgPositioner(this.context) : super(context.allocateClientId());

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

  Future<void> setSize(int width, int height) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      1,
      [
        width,
        height,
      ],
      [
        WaylandType.int,
        WaylandType.int,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setAnchorRect(int x, int y, int width, int height) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      2,
      [
        x,
        y,
        width,
        height,
      ],
      [
        WaylandType.int,
        WaylandType.int,
        WaylandType.int,
        WaylandType.int,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setAnchor(int anchor) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      3,
      [
        anchor,
      ],
      [
        WaylandType.uint,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setGravity(int gravity) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      4,
      [
        gravity,
      ],
      [
        WaylandType.uint,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setConstraintAdjustment(int constraintAdjustment) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      5,
      [
        constraintAdjustment,
      ],
      [
        WaylandType.uint,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setOffset(int x, int y) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      6,
      [
        x,
        y,
      ],
      [
        WaylandType.int,
        WaylandType.int,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setReactive() async {
    final message = WaylandMessage(
      context.allocateClientId(),
      7,
      [
      ],
      [
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setParentSize(int parentWidth, int parentHeight) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      8,
      [
        parentWidth,
        parentHeight,
      ],
      [
        WaylandType.int,
        WaylandType.int,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setParentConfigure(int serial) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      9,
      [
        serial,
      ],
      [
        WaylandType.uint,
      ],
    );
    context.sendMessage(message);
  }

}

/// 
/// 

enum XdgPositionererror {
  /// invalid input provided
  invalidInput,
}

/// 
/// 

enum XdgPositioneranchor {
  /// 
  none,
  /// 
  top,
  /// 
  bottom,
  /// 
  left,
  /// 
  right,
  /// 
  topLeft,
  /// 
  bottomLeft,
  /// 
  topRight,
  /// 
  bottomRight,
}

/// 
/// 

enum XdgPositionergravity {
  /// 
  none,
  /// 
  top,
  /// 
  bottom,
  /// 
  left,
  /// 
  right,
  /// 
  topLeft,
  /// 
  bottomLeft,
  /// 
  topRight,
  /// 
  bottomRight,
}

/// constraint adjustments
/// 
/// The constraint adjustment value define ways the compositor will adjust
/// the position of the surface, if the unadjusted position would result
/// in the surface being partly constrained.
/// 
/// Whether a surface is considered 'constrained' is left to the compositor
/// to determine. For example, the surface may be partly outside the
/// compositor's defined 'work area', thus necessitating the child surface's
/// position be adjusted until it is entirely inside the work area.
/// 
/// The adjustments can be combined, according to a defined precedence: 1)
/// Flip, 2) Slide, 3) Resize.
/// 

enum XdgPositionerconstraintAdjustment {
  /// 
  none,
  /// 
  slideX,
  /// 
  slideY,
  /// 
  flipX,
  /// 
  flipY,
  /// 
  resizeX,
  /// 
  resizeY,
}

/// desktop user interface surface base interface
/// 
/// An interface that may be implemented by a wl_surface, for
/// implementations that provide a desktop-style user interface.
/// 
/// It provides a base set of functionality required to construct user
/// interface elements requiring management by the compositor, such as
/// toplevel windows, menus, etc. The types of functionality are split into
/// xdg_surface roles.
/// 
/// Creating an xdg_surface does not set the role for a wl_surface. In order
/// to map an xdg_surface, the client must create a role-specific object
/// using, e.g., get_toplevel, get_popup. The wl_surface for any given
/// xdg_surface can have at most one role, and may not be assigned any role
/// not based on xdg_surface.
/// 
/// A role must be assigned before any other requests are made to the
/// xdg_surface object.
/// 
/// The client must call wl_surface.commit on the corresponding wl_surface
/// for the xdg_surface state to take effect.
/// 
/// Creating an xdg_surface from a wl_surface which has a buffer attached or
/// committed is a client error, and any attempts by a client to attach or
/// manipulate a buffer prior to the first xdg_surface.configure call must
/// also be treated as errors.
/// 
/// After creating a role-specific object and setting it up, the client must
/// perform an initial commit without any buffer attached. The compositor
/// will reply with initial wl_surface state such as
/// wl_surface.preferred_buffer_scale followed by an xdg_surface.configure
/// event. The client must acknowledge it and is then allowed to attach a
/// buffer to map the surface.
/// 
/// Mapping an xdg_surface-based role surface is defined as making it
/// possible for the surface to be shown by the compositor. Note that
/// a mapped surface is not guaranteed to be visible once it is mapped.
/// 
/// For an xdg_surface to be mapped by the compositor, the following
/// conditions must be met:
/// (1) the client has assigned an xdg_surface-based role to the surface
/// (2) the client has set and committed the xdg_surface state and the
/// role-dependent state to the surface
/// (3) the client has committed a buffer to the surface
/// 
/// A newly-unmapped surface is considered to have met condition (1) out
/// of the 3 required conditions for mapping a surface if its role surface
/// has not been destroyed, i.e. the client must perform the initial commit
/// again before attaching a buffer.
/// 
class XdgSurface extends Proxy implements Dispatcher{
  final Context context;

  XdgSurface(this.context) : super(context.allocateClientId());

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

  Future<void> getToplevel() async {
  var id =  XdgSurface(context);
    final message = WaylandMessage(
      context.allocateClientId(),
      1,
      [
        id,
      ],
      [
        WaylandType.newId,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> getPopup(XdgSurface parent, XdgPositioner positioner) async {
  var id =  XdgSurface(context);
    final message = WaylandMessage(
      context.allocateClientId(),
      2,
      [
        id,
        parent,
        positioner,
      ],
      [
        WaylandType.newId,
        WaylandType.object,
        WaylandType.object,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setWindowGeometry(int x, int y, int width, int height) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      3,
      [
        x,
        y,
        width,
        height,
      ],
      [
        WaylandType.int,
        WaylandType.int,
        WaylandType.int,
        WaylandType.int,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> ackConfigure(int serial) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      4,
      [
        serial,
      ],
      [
        WaylandType.uint,
      ],
    );
    context.sendMessage(message);
  }

 /// suggest a surface change
/// 
/// The configure event marks the end of a configure sequence. A configure
/// sequence is a set of one or more events configuring the state of the
/// xdg_surface, including the final xdg_surface.configure event.
/// 
/// Where applicable, xdg_surface surface roles will during a configure
/// sequence extend this event as a latched state sent as events before the
/// xdg_surface.configure event. Such events should be considered to make up
/// a set of atomically applied configuration states, where the
/// xdg_surface.configure commits the accumulated state.
/// 
/// Clients should arrange their surface for the new states, and then send
/// an ack_configure request with the serial sent in this configure event at
/// some point before committing the new surface.
/// 
/// If the client receives multiple configure events before it can respond
/// to one, it is free to discard all but the last event it received.
/// 
 void onconfigure(void Function(int serial) handler) {
   _configureHandler = handler;
 }

 void Function(int serial)? _configureHandler;

 @override
 void dispatch(int opcode, int fd, Uint8List data) {
   switch (opcode) {
     case 0:
       if (_configureHandler != null) {
         _configureHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
         );
       }
       break;
   }
 }
}

/// 
/// 

enum XdgSurfaceerror {
  /// Surface was not fully constructed
  notConstructed,
  /// Surface was already constructed
  alreadyConstructed,
  /// Attaching a buffer to an unconfigured surface
  unconfiguredBuffer,
  /// Invalid serial number when acking a configure event
  invalidSerial,
  /// Width or height was zero or negative
  invalidSize,
  /// Surface was destroyed before its role object
  defunctRoleObject,
}

/// toplevel surface
/// 
/// This interface defines an xdg_surface role which allows a surface to,
/// among other things, set window-like properties such as maximize,
/// fullscreen, and minimize, set application-specific metadata like title and
/// id, and well as trigger user interactive operations such as interactive
/// resize and move.
/// 
/// A xdg_toplevel by default is responsible for providing the full intended
/// visual representation of the toplevel, which depending on the window
/// state, may mean things like a title bar, window controls and drop shadow.
/// 
/// Unmapping an xdg_toplevel means that the surface cannot be shown
/// by the compositor until it is explicitly mapped again.
/// All active operations (e.g., move, resize) are canceled and all
/// attributes (e.g. title, state, stacking, ...) are discarded for
/// an xdg_toplevel surface when it is unmapped. The xdg_toplevel returns to
/// the state it had right after xdg_surface.get_toplevel. The client
/// can re-map the toplevel by performing a commit without any buffer
/// attached, waiting for a configure event and handling it as usual (see
/// xdg_surface description).
/// 
/// Attaching a null buffer to a toplevel unmaps the surface.
/// 
class XdgToplevel extends Proxy implements Dispatcher{
  final Context context;

  XdgToplevel(this.context) : super(context.allocateClientId());

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

  Future<void> setParent(XdgToplevel parent) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      1,
      [
        parent,
      ],
      [
        WaylandType.object,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setTitle(String title) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      2,
      [
        title,
      ],
      [
        WaylandType.string,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setAppId(String appId) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      3,
      [
        appId,
      ],
      [
        WaylandType.string,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> showWindowMenu(Seat seat, int serial, int x, int y) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      4,
      [
        seat,
        serial,
        x,
        y,
      ],
      [
        WaylandType.object,
        WaylandType.uint,
        WaylandType.int,
        WaylandType.int,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> move(Seat seat, int serial) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      5,
      [
        seat,
        serial,
      ],
      [
        WaylandType.object,
        WaylandType.uint,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> resize(Seat seat, int serial, int edges) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      6,
      [
        seat,
        serial,
        edges,
      ],
      [
        WaylandType.object,
        WaylandType.uint,
        WaylandType.uint,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setMaxSize(int width, int height) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      7,
      [
        width,
        height,
      ],
      [
        WaylandType.int,
        WaylandType.int,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setMinSize(int width, int height) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      8,
      [
        width,
        height,
      ],
      [
        WaylandType.int,
        WaylandType.int,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setMaximized() async {
    final message = WaylandMessage(
      context.allocateClientId(),
      9,
      [
      ],
      [
      ],
    );
    context.sendMessage(message);
  }

  Future<void> unsetMaximized() async {
    final message = WaylandMessage(
      context.allocateClientId(),
      10,
      [
      ],
      [
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setFullscreen(Output output) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      11,
      [
        output,
      ],
      [
        WaylandType.object,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> unsetFullscreen() async {
    final message = WaylandMessage(
      context.allocateClientId(),
      12,
      [
      ],
      [
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setMinimized() async {
    final message = WaylandMessage(
      context.allocateClientId(),
      13,
      [
      ],
      [
      ],
    );
    context.sendMessage(message);
  }

 /// suggest a surface change
/// 
/// This configure event asks the client to resize its toplevel surface or
/// to change its state. The configured state should not be applied
/// immediately. See xdg_surface.configure for details.
/// 
/// The width and height arguments specify a hint to the window
/// about how its surface should be resized in window geometry
/// coordinates. See set_window_geometry.
/// 
/// If the width or height arguments are zero, it means the client
/// should decide its own window dimension. This may happen when the
/// compositor needs to configure the state of the surface but doesn't
/// have any information about any previous or expected dimension.
/// 
/// The states listed in the event specify how the width/height
/// arguments should be interpreted, and possibly how it should be
/// drawn.
/// 
/// Clients must send an ack_configure in response to this event. See
/// xdg_surface.configure and xdg_surface.ack_configure for details.
/// 
 void onconfigure(void Function(int width, int height, List<int> states) handler) {
   _configureHandler = handler;
 }

 void Function(int width, int height, List<int> states)? _configureHandler;

 /// surface wants to be closed
/// 
/// The close event is sent by the compositor when the user
/// wants the surface to be closed. This should be equivalent to
/// the user clicking the close button in client-side decorations,
/// if your application has any.
/// 
/// This is only a request that the user intends to close the
/// window. The client may choose to ignore this request, or show
/// a dialog to ask the user to save their data, etc.
/// 
 void onclose(void Function() handler) {
   _closeHandler = handler;
 }

 void Function()? _closeHandler;

 /// recommended window geometry bounds
/// 
/// The configure_bounds event may be sent prior to a xdg_toplevel.configure
/// event to communicate the bounds a window geometry size is recommended
/// to constrain to.
/// 
/// The passed width and height are in surface coordinate space. If width
/// and height are 0, it means bounds is unknown and equivalent to as if no
/// configure_bounds event was ever sent for this surface.
/// 
/// The bounds can for example correspond to the size of a monitor excluding
/// any panels or other shell components, so that a surface isn't created in
/// a way that it cannot fit.
/// 
/// The bounds may change at any point, and in such a case, a new
/// xdg_toplevel.configure_bounds will be sent, followed by
/// xdg_toplevel.configure and xdg_surface.configure.
/// 
 void onconfigureBounds(void Function(int width, int height) handler) {
   _configureBoundsHandler = handler;
 }

 void Function(int width, int height)? _configureBoundsHandler;

 /// compositor capabilities
/// 
/// This event advertises the capabilities supported by the compositor. If
/// a capability isn't supported, clients should hide or disable the UI
/// elements that expose this functionality. For instance, if the
/// compositor doesn't advertise support for minimized toplevels, a button
/// triggering the set_minimized request should not be displayed.
/// 
/// The compositor will ignore requests it doesn't support. For instance,
/// a compositor which doesn't advertise support for minimized will ignore
/// set_minimized requests.
/// 
/// Compositors must send this event once before the first
/// xdg_surface.configure event. When the capabilities change, compositors
/// must send this event again and then send an xdg_surface.configure
/// event.
/// 
/// The configured state should not be applied immediately. See
/// xdg_surface.configure for details.
/// 
/// The capabilities are sent as an array of 32-bit unsigned integers in
/// native endianness.
/// 
 void onwmCapabilities(void Function(List<int> capabilities) handler) {
   _wmCapabilitiesHandler = handler;
 }

 void Function(List<int> capabilities)? _wmCapabilitiesHandler;

 @override
 void dispatch(int opcode, int fd, Uint8List data) {
   switch (opcode) {
     case 0:
       if (_configureHandler != null) {
         _configureHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
           ByteData.view(data.buffer).getInt32(4, Endian.host),
           getArray(data, 8),
         );
       }
       break;
     case 1:
       if (_closeHandler != null) {
         _closeHandler!(
         );
       }
       break;
     case 2:
       if (_configureBoundsHandler != null) {
         _configureBoundsHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
           ByteData.view(data.buffer).getInt32(4, Endian.host),
         );
       }
       break;
     case 3:
       if (_wmCapabilitiesHandler != null) {
         _wmCapabilitiesHandler!(
           getArray(data, 0),
         );
       }
       break;
   }
 }
}

/// 
/// 

enum XdgToplevelerror {
  /// provided value is        not a valid variant of the resize_edge enum
  invalidResizeEdge,
  /// invalid parent toplevel
  invalidParent,
  /// client provided an invalid min or max size
  invalidSize,
}

/// edge values for resizing
/// 
/// These values are used to indicate which edge of a surface
/// is being dragged in a resize operation.
/// 

enum XdgToplevelresizeEdge {
  /// 
  none,
  /// 
  top,
  /// 
  bottom,
  /// 
  left,
  /// 
  topLeft,
  /// 
  bottomLeft,
  /// 
  right,
  /// 
  topRight,
  /// 
  bottomRight,
}

/// types of state on the surface
/// 
/// The different state values used on the surface. This is designed for
/// state values like maximized, fullscreen. It is paired with the
/// configure event to ensure that both the client and the compositor
/// setting the state can be synchronized.
/// 
/// States set in this way are double-buffered, see wl_surface.commit.
/// 

enum XdgToplevelstate {
  /// the surface is maximized
  maximized,
  /// the surface is fullscreen
  fullscreen,
  /// the surface is being resized
  resizing,
  /// the surface is now activated
  activated,
  /// 
  tiledLeft,
  /// 
  tiledRight,
  /// 
  tiledTop,
  /// 
  tiledBottom,
  /// 
  suspended,
}

/// 
/// 

enum XdgToplevelwmCapabilities {
  /// show_window_menu is available
  windowMenu,
  /// set_maximized and unset_maximized are available
  maximize,
  /// set_fullscreen and unset_fullscreen are available
  fullscreen,
  /// set_minimized is available
  minimize,
}

/// short-lived, popup surfaces for menus
/// 
/// A popup surface is a short-lived, temporary surface. It can be used to
/// implement for example menus, popovers, tooltips and other similar user
/// interface concepts.
/// 
/// A popup can be made to take an explicit grab. See xdg_popup.grab for
/// details.
/// 
/// When the popup is dismissed, a popup_done event will be sent out, and at
/// the same time the surface will be unmapped. See the xdg_popup.popup_done
/// event for details.
/// 
/// Explicitly destroying the xdg_popup object will also dismiss the popup and
/// unmap the surface. Clients that want to dismiss the popup when another
/// surface of their own is clicked should dismiss the popup using the destroy
/// request.
/// 
/// A newly created xdg_popup will be stacked on top of all previously created
/// xdg_popup surfaces associated with the same xdg_toplevel.
/// 
/// The parent of an xdg_popup must be mapped (see the xdg_surface
/// description) before the xdg_popup itself.
/// 
/// The client must call wl_surface.commit on the corresponding wl_surface
/// for the xdg_popup state to take effect.
/// 
class XdgPopup extends Proxy implements Dispatcher{
  final Context context;

  XdgPopup(this.context) : super(context.allocateClientId());

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

  Future<void> grab(Seat seat, int serial) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      1,
      [
        seat,
        serial,
      ],
      [
        WaylandType.object,
        WaylandType.uint,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> reposition(XdgPositioner positioner, int token) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      2,
      [
        positioner,
        token,
      ],
      [
        WaylandType.object,
        WaylandType.uint,
      ],
    );
    context.sendMessage(message);
  }

 /// configure the popup surface
/// 
/// This event asks the popup surface to configure itself given the
/// configuration. The configured state should not be applied immediately.
/// See xdg_surface.configure for details.
/// 
/// The x and y arguments represent the position the popup was placed at
/// given the xdg_positioner rule, relative to the upper left corner of the
/// window geometry of the parent surface.
/// 
/// For version 2 or older, the configure event for an xdg_popup is only
/// ever sent once for the initial configuration. Starting with version 3,
/// it may be sent again if the popup is setup with an xdg_positioner with
/// set_reactive requested, or in response to xdg_popup.reposition requests.
/// 
 void onconfigure(void Function(int x, int y, int width, int height) handler) {
   _configureHandler = handler;
 }

 void Function(int x, int y, int width, int height)? _configureHandler;

 /// popup interaction is done
/// 
/// The popup_done event is sent out when a popup is dismissed by the
/// compositor. The client should destroy the xdg_popup object at this
/// point.
/// 
 void onpopupDone(void Function() handler) {
   _popupDoneHandler = handler;
 }

 void Function()? _popupDoneHandler;

 /// signal the completion of a repositioned request
/// 
/// The repositioned event is sent as part of a popup configuration
/// sequence, together with xdg_popup.configure and lastly
/// xdg_surface.configure to notify the completion of a reposition request.
/// 
/// The repositioned event is to notify about the completion of a
/// xdg_popup.reposition request. The token argument is the token passed
/// in the xdg_popup.reposition request.
/// 
/// Immediately after this event is emitted, xdg_popup.configure and
/// xdg_surface.configure will be sent with the updated size and position,
/// as well as a new configure serial.
/// 
/// The client should optionally update the content of the popup, but must
/// acknowledge the new popup configuration for the new position to take
/// effect. See xdg_surface.ack_configure for details.
/// 
 void onrepositioned(void Function(int token) handler) {
   _repositionedHandler = handler;
 }

 void Function(int token)? _repositionedHandler;

 @override
 void dispatch(int opcode, int fd, Uint8List data) {
   switch (opcode) {
     case 0:
       if (_configureHandler != null) {
         _configureHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
           ByteData.view(data.buffer).getInt32(4, Endian.host),
           ByteData.view(data.buffer).getInt32(8, Endian.host),
           ByteData.view(data.buffer).getInt32(12, Endian.host),
         );
       }
       break;
     case 1:
       if (_popupDoneHandler != null) {
         _popupDoneHandler!(
         );
       }
       break;
     case 2:
       if (_repositionedHandler != null) {
         _repositionedHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
         );
       }
       break;
   }
 }
}

/// 
/// 

enum XdgPopuperror {
  /// tried to grab after being mapped
  invalidGrab,
}

