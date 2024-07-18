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
import 'package:wayland/protocols/wayland.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// X primary selection emulation
///
/// The primary selection device manager is a singleton global object that
/// provides access to the primary selection. It allows to create
/// wp_primary_selection_source objects, as well as retrieving the per-seat
/// wp_primary_selection_device objects.
///
class ZwpPrimarySelectionDeviceManagerV1 extends Proxy {
  final Context innerContext;
  final version = 1;

  ZwpPrimarySelectionDeviceManagerV1(this.innerContext)
      : super(innerContext.allocateClientId()) {
    innerContext.register(this);
  }

  @override
  toString() {
    return "ZwpPrimarySelectionDeviceManagerV1 {name: 'zwp_primary_selection_device_manager_v1', id: '$objectId', version: '1',}";
  }

  /// create a new primary selection source
  ///
  /// Create a new primary selection source.
  ///
  /// [id]:
  ZwpPrimarySelectionSourceV1 createSource() {
    var id = ZwpPrimarySelectionSourceV1(innerContext);
    logLn("ZwpPrimarySelectionDeviceManagerV1::createSource  id: $id");
    var arguments = [id];
    var argTypes = <WaylandType>[WaylandType.newId];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 0])
            .buffer
            .asUint8List());
    bytesBuilder.add(Uint32List.fromList([id.objectId]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
    return id;
  }

  /// create a new primary selection device
  ///
  /// Create a new data device for a given seat.
  ///
  /// [id]:
  /// [seat]:
  ZwpPrimarySelectionDeviceV1 getDevice(Seat seat) {
    var id = ZwpPrimarySelectionDeviceV1(innerContext);
    logLn("ZwpPrimarySelectionDeviceManagerV1::getDevice  id: $id seat: $seat");
    var arguments = [id, seat];
    var argTypes = <WaylandType>[WaylandType.newId, WaylandType.object];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 1])
            .buffer
            .asUint8List());
    bytesBuilder.add(Uint32List.fromList([id.objectId]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([seat.objectId]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
    return id;
  }

  /// destroy the primary selection device manager
  ///
  /// Destroy the primary selection device manager.
  ///
  void destroy() {
    logLn("ZwpPrimarySelectionDeviceManagerV1::destroy ");
    var arguments = [];
    var argTypes = <WaylandType>[];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 2])
            .buffer
            .asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }
}

/// introduce a new wp_primary_selection_offer
///
/// Introduces a new wp_primary_selection_offer object that may be used
/// to receive the current primary selection. Immediately following this
/// event, the new wp_primary_selection_offer object will send
/// wp_primary_selection_offer.offer events to describe the offered mime
/// types.
///
class ZwpPrimarySelectionDeviceV1DataOfferEvent {
  ///
  final int offer;

  ZwpPrimarySelectionDeviceV1DataOfferEvent(
    this.offer,
  );

  @override
  toString() {
    return "ZwpPrimarySelectionDeviceV1DataOfferEvent (offer: $offer)";
  }
}

typedef ZwpPrimarySelectionDeviceV1DataOfferEventHandler = void Function(
    ZwpPrimarySelectionDeviceV1DataOfferEvent);

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
class ZwpPrimarySelectionDeviceV1SelectionEvent {
  ///
  final int id;

  ZwpPrimarySelectionDeviceV1SelectionEvent(
    this.id,
  );

  @override
  toString() {
    return "ZwpPrimarySelectionDeviceV1SelectionEvent (id: $id)";
  }
}

typedef ZwpPrimarySelectionDeviceV1SelectionEventHandler = void Function(
    ZwpPrimarySelectionDeviceV1SelectionEvent);

///
///
class ZwpPrimarySelectionDeviceV1 extends Proxy implements Dispatcher {
  final Context innerContext;
  final version = 1;

  ZwpPrimarySelectionDeviceV1(this.innerContext)
      : super(innerContext.allocateClientId()) {
    innerContext.register(this);
  }

  @override
  toString() {
    return "ZwpPrimarySelectionDeviceV1 {name: 'zwp_primary_selection_device_v1', id: '$objectId', version: '1',}";
  }

  /// set the primary selection
  ///
  /// Replaces the current selection. The previous owner of the primary
  /// selection will receive a wp_primary_selection_source.cancelled event.
  ///
  /// To unset the selection, set the source to NULL.
  ///
  /// [source]:
  /// [serial]: serial of the event that triggered this request
  void setSelection(ZwpPrimarySelectionSourceV1 source, int serial) {
    logLn(
        "ZwpPrimarySelectionDeviceV1::setSelection  source: $source serial: $serial");
    var arguments = [source, serial];
    var argTypes = <WaylandType>[WaylandType.object, WaylandType.uint];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 0])
            .buffer
            .asUint8List());
    bytesBuilder
        .add(Uint32List.fromList([source.objectId]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([serial]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// destroy the primary selection device
  ///
  /// Destroy the primary selection device.
  ///
  void destroy() {
    logLn("ZwpPrimarySelectionDeviceV1::destroy ");
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

  /// introduce a new wp_primary_selection_offer
  ///
  /// Introduces a new wp_primary_selection_offer object that may be used
  /// to receive the current primary selection. Immediately following this
  /// event, the new wp_primary_selection_offer object will send
  /// wp_primary_selection_offer.offer events to describe the offered mime
  /// types.
  ///
  /// Event handler for DataOffer
  /// - [offer]:
  void onDataOffer(ZwpPrimarySelectionDeviceV1DataOfferEventHandler handler) {
    _dataOfferHandler = handler;
  }

  ZwpPrimarySelectionDeviceV1DataOfferEventHandler? _dataOfferHandler;

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
  /// Event handler for Selection
  /// - [id]:
  void onSelection(ZwpPrimarySelectionDeviceV1SelectionEventHandler handler) {
    _selectionHandler = handler;
  }

  ZwpPrimarySelectionDeviceV1SelectionEventHandler? _selectionHandler;

  @override
  void dispatch(int opcode, int fd, Uint8List data) {
    logLn("ZwpPrimarySelectionDeviceV1.dispatch($opcode, $fd, $data)");
    switch (opcode) {
      case 0:
        if (_dataOfferHandler != null) {
          var offset = 0;
          final offer = innerContext
              .getProxy(
                  ByteData.view(data.buffer).getUint32(offset, Endian.little))
              .objectId;
          offset += 4;
          var event = ZwpPrimarySelectionDeviceV1DataOfferEvent(
            offer,
          );
          _dataOfferHandler!(event);
        }
        break;
      case 1:
        if (_selectionHandler != null) {
          var offset = 0;
          final id = innerContext
              .getProxy(
                  ByteData.view(data.buffer).getUint32(offset, Endian.little))
              .objectId;
          offset += 4;
          var event = ZwpPrimarySelectionDeviceV1SelectionEvent(
            id,
          );
          _selectionHandler!(event);
        }
        break;
    }
  }
}

/// advertise offered mime type
///
/// Sent immediately after creating announcing the
/// wp_primary_selection_offer through
/// wp_primary_selection_device.data_offer. One event is sent per offered
/// mime type.
///
class ZwpPrimarySelectionOfferV1OfferEvent {
  ///
  final String mimeType;

  ZwpPrimarySelectionOfferV1OfferEvent(
    this.mimeType,
  );

  @override
  toString() {
    return "ZwpPrimarySelectionOfferV1OfferEvent (mimeType: $mimeType)";
  }
}

typedef ZwpPrimarySelectionOfferV1OfferEventHandler = void Function(
    ZwpPrimarySelectionOfferV1OfferEvent);

/// offer to transfer primary selection contents
///
/// A wp_primary_selection_offer represents an offer to transfer the contents
/// of the primary selection clipboard to the client. Similar to
/// wl_data_offer, the offer also describes the mime types that the data can
/// be converted to and provides the mechanisms for transferring the data
/// directly to the client.
///
class ZwpPrimarySelectionOfferV1 extends Proxy implements Dispatcher {
  final Context innerContext;
  final version = 1;

  ZwpPrimarySelectionOfferV1(this.innerContext)
      : super(innerContext.allocateClientId()) {
    innerContext.register(this);
  }

  @override
  toString() {
    return "ZwpPrimarySelectionOfferV1 {name: 'zwp_primary_selection_offer_v1', id: '$objectId', version: '1',}";
  }

  /// request that the data is transferred
  ///
  /// To transfer the contents of the primary selection clipboard, the client
  /// issues this request and indicates the mime type that it wants to
  /// receive. The transfer happens through the passed file descriptor
  /// (typically created with the pipe system call). The source client writes
  /// the data in the mime type representation requested and then closes the
  /// file descriptor.
  ///
  /// The receiving client reads from the read end of the pipe until EOF and
  /// closes its end, at which point the transfer is complete.
  ///
  /// [mime_type]:
  /// [fd]:
  void receive(String mimeType, int fd) {
    logLn("ZwpPrimarySelectionOfferV1::receive  mimeType: $mimeType fd: $fd");
    var arguments = [mimeType, fd];
    var argTypes = <WaylandType>[WaylandType.string, WaylandType.fd];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 0])
            .buffer
            .asUint8List());
    final mimeTypeBytes = utf8.encode(mimeType);
    bytesBuilder.add(
        Uint32List.fromList([mimeTypeBytes.length + 1]).buffer.asUint8List());
    bytesBuilder.add(mimeTypeBytes);
    bytesBuilder.add([0]); // Null terminator
    while (bytesBuilder.length % 4 != 0) {
      bytesBuilder.add([0]);
    } // Padding
    // Handle file descriptor separately
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// destroy the primary selection offer
  ///
  /// Destroy the primary selection offer.
  ///
  void destroy() {
    logLn("ZwpPrimarySelectionOfferV1::destroy ");
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

  /// advertise offered mime type
  ///
  /// Sent immediately after creating announcing the
  /// wp_primary_selection_offer through
  /// wp_primary_selection_device.data_offer. One event is sent per offered
  /// mime type.
  ///
  /// Event handler for Offer
  /// - [mime_type]:
  void onOffer(ZwpPrimarySelectionOfferV1OfferEventHandler handler) {
    _offerHandler = handler;
  }

  ZwpPrimarySelectionOfferV1OfferEventHandler? _offerHandler;

  @override
  void dispatch(int opcode, int fd, Uint8List data) {
    logLn("ZwpPrimarySelectionOfferV1.dispatch($opcode, $fd, $data)");
    switch (opcode) {
      case 0:
        if (_offerHandler != null) {
          var offset = 0;
          final mimeTypeLength =
              ByteData.view(data.buffer).getUint32(offset, Endian.little);
          offset += 4;
          final mimeType =
              utf8.decode(data.sublist(offset, offset + mimeTypeLength - 1));
          offset += mimeTypeLength; // Skip the string bytes and null terminator
          while (offset % 4 != 0) {
            offset++;
          } // Padding
          var event = ZwpPrimarySelectionOfferV1OfferEvent(
            mimeType,
          );
          _offerHandler!(event);
        }
        break;
    }
  }
}

/// send the primary selection contents
///
/// Request for the current primary selection contents from the client.
/// Send the specified mime type over the passed file descriptor, then
/// close it.
///
class ZwpPrimarySelectionSourceV1SendEvent {
  ///
  final String mimeType;

  ///
  final int fd;

  ZwpPrimarySelectionSourceV1SendEvent(
    this.mimeType,
    this.fd,
  );

  @override
  toString() {
    return "ZwpPrimarySelectionSourceV1SendEvent (mimeType: $mimeType, fd: $fd)";
  }
}

typedef ZwpPrimarySelectionSourceV1SendEventHandler = void Function(
    ZwpPrimarySelectionSourceV1SendEvent);

/// request for primary selection contents was canceled
///
/// This primary selection source is no longer valid. The client should
/// clean up and destroy this primary selection source.
///
class ZwpPrimarySelectionSourceV1CancelledEvent {
  ZwpPrimarySelectionSourceV1CancelledEvent();

  @override
  toString() {
    return "ZwpPrimarySelectionSourceV1CancelledEvent ()";
  }
}

typedef ZwpPrimarySelectionSourceV1CancelledEventHandler = void Function(
    ZwpPrimarySelectionSourceV1CancelledEvent);

/// offer to replace the contents of the primary selection
///
/// The source side of a wp_primary_selection_offer, it provides a way to
/// describe the offered data and respond to requests to transfer the
/// requested contents of the primary selection clipboard.
///
class ZwpPrimarySelectionSourceV1 extends Proxy implements Dispatcher {
  final Context innerContext;
  final version = 1;

  ZwpPrimarySelectionSourceV1(this.innerContext)
      : super(innerContext.allocateClientId()) {
    innerContext.register(this);
  }

  @override
  toString() {
    return "ZwpPrimarySelectionSourceV1 {name: 'zwp_primary_selection_source_v1', id: '$objectId', version: '1',}";
  }

  /// add an offered mime type
  ///
  /// This request adds a mime type to the set of mime types advertised to
  /// targets. Can be called several times to offer multiple types.
  ///
  /// [mime_type]:
  void offer(String mimeType) {
    logLn("ZwpPrimarySelectionSourceV1::offer  mimeType: $mimeType");
    var arguments = [mimeType];
    var argTypes = <WaylandType>[WaylandType.string];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 0])
            .buffer
            .asUint8List());
    final mimeTypeBytes = utf8.encode(mimeType);
    bytesBuilder.add(
        Uint32List.fromList([mimeTypeBytes.length + 1]).buffer.asUint8List());
    bytesBuilder.add(mimeTypeBytes);
    bytesBuilder.add([0]); // Null terminator
    while (bytesBuilder.length % 4 != 0) {
      bytesBuilder.add([0]);
    } // Padding
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// destroy the primary selection source
  ///
  /// Destroy the primary selection source.
  ///
  void destroy() {
    logLn("ZwpPrimarySelectionSourceV1::destroy ");
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

  /// send the primary selection contents
  ///
  /// Request for the current primary selection contents from the client.
  /// Send the specified mime type over the passed file descriptor, then
  /// close it.
  ///
  /// Event handler for Send
  /// - [mime_type]:
  /// - [fd]:
  void onSend(ZwpPrimarySelectionSourceV1SendEventHandler handler) {
    _sendHandler = handler;
  }

  ZwpPrimarySelectionSourceV1SendEventHandler? _sendHandler;

  /// request for primary selection contents was canceled
  ///
  /// This primary selection source is no longer valid. The client should
  /// clean up and destroy this primary selection source.
  ///
  /// Event handler for Cancelled
  void onCancelled(ZwpPrimarySelectionSourceV1CancelledEventHandler handler) {
    _cancelledHandler = handler;
  }

  ZwpPrimarySelectionSourceV1CancelledEventHandler? _cancelledHandler;

  @override
  void dispatch(int opcode, int fd, Uint8List data) {
    logLn("ZwpPrimarySelectionSourceV1.dispatch($opcode, $fd, $data)");
    switch (opcode) {
      case 0:
        if (_sendHandler != null) {
          var offset = 0;
          final mimeTypeLength =
              ByteData.view(data.buffer).getUint32(offset, Endian.little);
          offset += 4;
          final mimeType =
              utf8.decode(data.sublist(offset, offset + mimeTypeLength - 1));
          offset += mimeTypeLength; // Skip the string bytes and null terminator
          while (offset % 4 != 0) {
            offset++;
          } // Padding
          final fd2 = fd;
          var event = ZwpPrimarySelectionSourceV1SendEvent(
            mimeType,
            fd2,
          );
          _sendHandler!(event);
        }
        break;
      case 1:
        if (_cancelledHandler != null) {
          _cancelledHandler!(ZwpPrimarySelectionSourceV1CancelledEvent());
        }
        break;
    }
  }
}