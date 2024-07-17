// Generated by dart-wayland-scanner
// https://github.com/your-repo/dart-wayland-scanner
// XML file : https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/staging/ext-idle-notify/ext-idle-notify-v1.xml
//
// ext_idle_notify_v1 Protocol Copyright: 
/// 
/// Copyright © 2015 Martin Gräßlin
/// Copyright © 2022 Simon Ser
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


/// idle notification manager
/// 
/// This interface allows clients to monitor user idle status.
/// 
/// After binding to this global, clients can create ext_idle_notification_v1
/// objects to get notified when the user is idle for a given amount of time.
/// 
class ExtIdleNotifierV1 extends Proxy{
  final Context context;

  ExtIdleNotifierV1(this.context) : super(context.allocateClientId()){
    context.register(this);
  }

/// destroy the manager
/// 
/// Destroy the manager object. All objects created via this interface
/// remain valid.
/// 
  Future<void> destroy() async {
    print("ExtIdleNotifierV1::destroy ");
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

/// create a notification object
/// 
/// Create a new idle notification object.
/// 
/// The notification object has a minimum timeout duration and is tied to a
/// seat. The client will be notified if the seat is inactive for at least
/// the provided timeout. See ext_idle_notification_v1 for more details.
/// 
/// A zero timeout is valid and means the client wants to be notified as
/// soon as possible when the seat is inactive.
/// 
/// [id]:
/// [timeout]: minimum idle timeout in msec
/// [seat]:
  Future<ExtIdleNotificationV1> getIdleNotification(int timeout, Seat seat) async {
  var id =  ExtIdleNotificationV1(context);
    print("ExtIdleNotifierV1::getIdleNotification  id: $id timeout: $timeout seat: $seat");
    final message = WaylandMessage(
      objectId,
      1,
      [
        id,
        timeout,
        seat,
      ],
      [
        WaylandType.newId,
        WaylandType.uint,
        WaylandType.object,
      ],
    );
    await context.sendMessage(message);
    return id;
  }

}


/// notification object is idle
/// 
/// This event is sent when the notification object becomes idle.
/// 
/// It's a compositor protocol error to send this event twice without a
/// resumed event in-between.
/// 
class ExtIdleNotificationV1IdledEvent {
  ExtIdleNotificationV1IdledEvent(
);

@override
String toString(){
  return """ExtIdleNotificationV1IdledEvent: {
  }""";
}

}

typedef ExtIdleNotificationV1IdledEventHandler = void Function(ExtIdleNotificationV1IdledEvent);

/// notification object is no longer idle
/// 
/// This event is sent when the notification object stops being idle.
/// 
/// It's a compositor protocol error to send this event twice without an
/// idled event in-between. It's a compositor protocol error to send this
/// event prior to any idled event.
/// 
class ExtIdleNotificationV1ResumedEvent {
  ExtIdleNotificationV1ResumedEvent(
);

@override
String toString(){
  return """ExtIdleNotificationV1ResumedEvent: {
  }""";
}

}

typedef ExtIdleNotificationV1ResumedEventHandler = void Function(ExtIdleNotificationV1ResumedEvent);


/// idle notification
/// 
/// This interface is used by the compositor to send idle notification events
/// to clients.
/// 
/// Initially the notification object is not idle. The notification object
/// becomes idle when no user activity has happened for at least the timeout
/// duration, starting from the creation of the notification object. User
/// activity may include input events or a presence sensor, but is
/// compositor-specific. If an idle inhibitor is active (e.g. another client
/// has created a zwp_idle_inhibitor_v1 on a visible surface), the compositor
/// must not make the notification object idle.
/// 
/// When the notification object becomes idle, an idled event is sent. When
/// user activity starts again, the notification object stops being idle,
/// a resumed event is sent and the timeout is restarted.
/// 
class ExtIdleNotificationV1 extends Proxy implements Dispatcher{
  final Context context;

  ExtIdleNotificationV1(this.context) : super(context.allocateClientId()){
    context.register(this);
  }

/// destroy the notification object
/// 
/// Destroy the notification object.
/// 
  Future<void> destroy() async {
    print("ExtIdleNotificationV1::destroy ");
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

/// notification object is idle
/// 
/// This event is sent when the notification object becomes idle.
/// 
/// It's a compositor protocol error to send this event twice without a
/// resumed event in-between.
/// 
/// Event handler for Idled
 void onIdled(ExtIdleNotificationV1IdledEventHandler handler) {
   _idledHandler = handler;
 }

 ExtIdleNotificationV1IdledEventHandler? _idledHandler;

/// notification object is no longer idle
/// 
/// This event is sent when the notification object stops being idle.
/// 
/// It's a compositor protocol error to send this event twice without an
/// idled event in-between. It's a compositor protocol error to send this
/// event prior to any idled event.
/// 
/// Event handler for Resumed
 void onResumed(ExtIdleNotificationV1ResumedEventHandler handler) {
   _resumedHandler = handler;
 }

 ExtIdleNotificationV1ResumedEventHandler? _resumedHandler;

 @override
 void dispatch(int opcode, int fd, Uint8List data) {
   switch (opcode) {
     case 0:
       if (_idledHandler != null) {
var event = ExtIdleNotificationV1IdledEvent(
        );
         _idledHandler!(event);
       }
       break;
     case 1:
       if (_resumedHandler != null) {
var event = ExtIdleNotificationV1ResumedEvent(
        );
         _resumedHandler!(event);
       }
       break;
   }
 }
}
