// Generated by dart-wayland-scanner
// https://github.com/your-repo/dart-wayland-scanner
// XML file : https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/unstable/primary-selection/primary-selection-unstable-v1.xml
//
// wp_primary_selection_unstable_v1 Protocol Copyright: 
/// 
/// Copyright © 2015, 2016 Red Hat
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
/// X primary selection emulation
/// 
/// The primary selection device manager is a singleton global object that
/// provides access to the primary selection. It allows to create
/// wp_primary_selection_source objects, as well as retrieving the per-seat
/// wp_primary_selection_device objects.
/// 
class ZwpPrimarySelectionDeviceManagerV1 extends Proxy{
  final Context context;

  ZwpPrimarySelectionDeviceManagerV1(this.context) : super(context.allocateClientId());

  Future<void> createSource() async {
  var id =  ZwpPrimarySelectionDeviceManagerV1(context);
    final message = WaylandMessage(
      context.allocateClientId(),
      0,
      [
        id,
      ],
      [
        WaylandType.newId,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> getDevice(Seat seat) async {
  var id =  ZwpPrimarySelectionDeviceManagerV1(context);
    final message = WaylandMessage(
      context.allocateClientId(),
      1,
      [
        id,
        seat,
      ],
      [
        WaylandType.newId,
        WaylandType.object,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> destroy() async {
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

/// 
/// 
class ZwpPrimarySelectionDeviceV1 extends Proxy implements Dispatcher{
  final Context context;

  ZwpPrimarySelectionDeviceV1(this.context) : super(context.allocateClientId());

  Future<void> setSelection(ZwpPrimarySelectionSourceV1 source, int serial) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      0,
      [
        source,
        serial,
      ],
      [
        WaylandType.object,
        WaylandType.uint,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> destroy() async {
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

 /// introduce a new wp_primary_selection_offer
/// 
/// Introduces a new wp_primary_selection_offer object that may be used
/// to receive the current primary selection. Immediately following this
/// event, the new wp_primary_selection_offer object will send
/// wp_primary_selection_offer.offer events to describe the offered mime
/// types.
/// 
 void ondataOffer(void Function(int offer) handler) {
   _dataOfferHandler = handler;
 }

 void Function(int offer)? _dataOfferHandler;

 /// advertise a new primary selection
/// 
/// The wp_primary_selection_device.selection event is sent to notify the
/// client of a new primary selection. This event is sent after the
/// wp_primary_selection.data_offer event introducing this object, and after
/// the offer has announced its mimetypes through
/// wp_primary_selection_offer.offer.
/// 
/// The data_offer is valid until a new offer or NULL is received
/// or until the client loses keyboard focus. The client must destroy the
/// previous selection data_offer, if any, upon receiving this event.
/// 
 void onselection(void Function(int id) handler) {
   _selectionHandler = handler;
 }

 void Function(int id)? _selectionHandler;

 @override
 void dispatch(int opcode, int fd, Uint8List data) {
   switch (opcode) {
     case 0:
       if (_dataOfferHandler != null) {
         _dataOfferHandler!(
           context.getProxy(ByteData.view(data.buffer).getUint32(0, Endian.host)).id,
         );
       }
       break;
     case 1:
       if (_selectionHandler != null) {
         _selectionHandler!(
           context.getProxy(ByteData.view(data.buffer).getUint32(0, Endian.host)).id,
         );
       }
       break;
   }
 }
}

/// offer to transfer primary selection contents
/// 
/// A wp_primary_selection_offer represents an offer to transfer the contents
/// of the primary selection clipboard to the client. Similar to
/// wl_data_offer, the offer also describes the mime types that the data can
/// be converted to and provides the mechanisms for transferring the data
/// directly to the client.
/// 
class ZwpPrimarySelectionOfferV1 extends Proxy implements Dispatcher{
  final Context context;

  ZwpPrimarySelectionOfferV1(this.context) : super(context.allocateClientId());

  Future<void> receive(String mimeType, int fd) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      0,
      [
        mimeType,
        fd,
      ],
      [
        WaylandType.string,
        WaylandType.fd,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> destroy() async {
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

 /// advertise offered mime type
/// 
/// Sent immediately after creating announcing the
/// wp_primary_selection_offer through
/// wp_primary_selection_device.data_offer. One event is sent per offered
/// mime type.
/// 
 void onoffer(void Function(String mimeType) handler) {
   _offerHandler = handler;
 }

 void Function(String mimeType)? _offerHandler;

 @override
 void dispatch(int opcode, int fd, Uint8List data) {
   switch (opcode) {
     case 0:
       if (_offerHandler != null) {
         _offerHandler!(
           getString(data, 0),
         );
       }
       break;
   }
 }
}

/// offer to replace the contents of the primary selection
/// 
/// The source side of a wp_primary_selection_offer, it provides a way to
/// describe the offered data and respond to requests to transfer the
/// requested contents of the primary selection clipboard.
/// 
class ZwpPrimarySelectionSourceV1 extends Proxy implements Dispatcher{
  final Context context;

  ZwpPrimarySelectionSourceV1(this.context) : super(context.allocateClientId());

  Future<void> offer(String mimeType) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      0,
      [
        mimeType,
      ],
      [
        WaylandType.string,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> destroy() async {
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

 /// send the primary selection contents
/// 
/// Request for the current primary selection contents from the client.
/// Send the specified mime type over the passed file descriptor, then
/// close it.
/// 
 void onsend(void Function(String mimeType, int fd) handler) {
   _sendHandler = handler;
 }

 void Function(String mimeType, int fd)? _sendHandler;

 /// request for primary selection contents was canceled
/// 
/// This primary selection source is no longer valid. The client should
/// clean up and destroy this primary selection source.
/// 
 void oncancelled(void Function() handler) {
   _cancelledHandler = handler;
 }

 void Function()? _cancelledHandler;

 @override
 void dispatch(int opcode, int fd, Uint8List data) {
   switch (opcode) {
     case 0:
       if (_sendHandler != null) {
         _sendHandler!(
           getString(data, 0),
           fd,
         );
       }
       break;
     case 1:
       if (_cancelledHandler != null) {
         _cancelledHandler!(
         );
       }
       break;
   }
 }
}

