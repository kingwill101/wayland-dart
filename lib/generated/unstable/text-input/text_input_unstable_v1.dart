// Generated by dart-wayland-scanner
// https://github.com/your-repo/dart-wayland-scanner
// XML file : https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/unstable/text-input/text-input-unstable-v1.xml
//
// text_input_unstable_v1 Protocol Copyright: 
/// 
/// Copyright © 2012, 2013 Intel Corporation
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

/// enter event
/// 
/// Notify the text_input object when it received focus. Typically in
/// response to an activate request.
/// 
class ZwpTextInputV1EnterEvent {
/// 
  final int surface;

  ZwpTextInputV1EnterEvent(
this.surface,

);

@override
String toString(){
  return """ZwpTextInputV1EnterEvent: {
    surface: $surface,
  }""";
}

}

typedef ZwpTextInputV1EnterEventHandler = void Function(ZwpTextInputV1EnterEvent);

/// leave event
/// 
/// Notify the text_input object when it lost focus. Either in response
/// to a deactivate request or when the assigned surface lost focus or was
/// destroyed.
/// 
class ZwpTextInputV1LeaveEvent {
  ZwpTextInputV1LeaveEvent(
);

@override
String toString(){
  return """ZwpTextInputV1LeaveEvent: {
  }""";
}

}

typedef ZwpTextInputV1LeaveEventHandler = void Function(ZwpTextInputV1LeaveEvent);

/// modifiers map
/// 
/// Transfer an array of 0-terminated modifier names. The position in
/// the array is the index of the modifier as used in the modifiers
/// bitmask in the keysym event.
/// 
class ZwpTextInputV1ModifiersMapEvent {
/// 
  final List<int> map;

  ZwpTextInputV1ModifiersMapEvent(
this.map,

);

@override
String toString(){
  return """ZwpTextInputV1ModifiersMapEvent: {
    map: $map,
  }""";
}

}

typedef ZwpTextInputV1ModifiersMapEventHandler = void Function(ZwpTextInputV1ModifiersMapEvent);

/// state of the input panel
/// 
/// Notify when the visibility state of the input panel changed.
/// 
class ZwpTextInputV1InputPanelStateEvent {
/// 
  final int state;

  ZwpTextInputV1InputPanelStateEvent(
this.state,

);

@override
String toString(){
  return """ZwpTextInputV1InputPanelStateEvent: {
    state: $state,
  }""";
}

}

typedef ZwpTextInputV1InputPanelStateEventHandler = void Function(ZwpTextInputV1InputPanelStateEvent);

/// pre-edit
/// 
/// Notify when a new composing text (pre-edit) should be set around the
/// current cursor position. Any previously set composing text should
/// be removed.
/// 
/// The commit text can be used to replace the preedit text on reset
/// (for example on unfocus).
/// 
/// The text input should also handle all preedit_style and preedit_cursor
/// events occurring directly before preedit_string.
/// 
class ZwpTextInputV1PreeditStringEvent {
/// serial of the latest known text input state
  final int serial;

/// 
  final String text;

/// 
  final String commit;

  ZwpTextInputV1PreeditStringEvent(
this.serial,

this.text,

this.commit,

);

@override
String toString(){
  return """ZwpTextInputV1PreeditStringEvent: {
    serial: $serial,
    text: $text,
    commit: $commit,
  }""";
}

}

typedef ZwpTextInputV1PreeditStringEventHandler = void Function(ZwpTextInputV1PreeditStringEvent);

/// pre-edit styling
/// 
/// Sets styling information on composing text. The style is applied for
/// length bytes from index relative to the beginning of the composing
/// text (as byte offset). Multiple styles can
/// be applied to a composing text by sending multiple preedit_styling
/// events.
/// 
/// This event is handled as part of a following preedit_string event.
/// 
class ZwpTextInputV1PreeditStylingEvent {
/// 
  final int index;

/// 
  final int length;

/// 
  final int style;

  ZwpTextInputV1PreeditStylingEvent(
this.index,

this.length,

this.style,

);

@override
String toString(){
  return """ZwpTextInputV1PreeditStylingEvent: {
    index: $index,
    length: $length,
    style: $style,
  }""";
}

}

typedef ZwpTextInputV1PreeditStylingEventHandler = void Function(ZwpTextInputV1PreeditStylingEvent);

/// pre-edit cursor
/// 
/// Sets the cursor position inside the composing text (as byte
/// offset) relative to the start of the composing text. When index is a
/// negative number no cursor is shown.
/// 
/// This event is handled as part of a following preedit_string event.
/// 
class ZwpTextInputV1PreeditCursorEvent {
/// 
  final int index;

  ZwpTextInputV1PreeditCursorEvent(
this.index,

);

@override
String toString(){
  return """ZwpTextInputV1PreeditCursorEvent: {
    index: $index,
  }""";
}

}

typedef ZwpTextInputV1PreeditCursorEventHandler = void Function(ZwpTextInputV1PreeditCursorEvent);

/// commit
/// 
/// Notify when text should be inserted into the editor widget. The text to
/// commit could be either just a single character after a key press or the
/// result of some composing (pre-edit). It could also be an empty text
/// when some text should be removed (see delete_surrounding_text) or when
/// the input cursor should be moved (see cursor_position).
/// 
/// Any previously set composing text should be removed.
/// 
class ZwpTextInputV1CommitStringEvent {
/// serial of the latest known text input state
  final int serial;

/// 
  final String text;

  ZwpTextInputV1CommitStringEvent(
this.serial,

this.text,

);

@override
String toString(){
  return """ZwpTextInputV1CommitStringEvent: {
    serial: $serial,
    text: $text,
  }""";
}

}

typedef ZwpTextInputV1CommitStringEventHandler = void Function(ZwpTextInputV1CommitStringEvent);

/// set cursor to new position
/// 
/// Notify when the cursor or anchor position should be modified.
/// 
/// This event should be handled as part of a following commit_string
/// event.
/// 
class ZwpTextInputV1CursorPositionEvent {
/// 
  final int index;

/// 
  final int anchor;

  ZwpTextInputV1CursorPositionEvent(
this.index,

this.anchor,

);

@override
String toString(){
  return """ZwpTextInputV1CursorPositionEvent: {
    index: $index,
    anchor: $anchor,
  }""";
}

}

typedef ZwpTextInputV1CursorPositionEventHandler = void Function(ZwpTextInputV1CursorPositionEvent);

/// delete surrounding text
/// 
/// Notify when the text around the current cursor position should be
/// deleted.
/// 
/// Index is relative to the current cursor (in bytes).
/// Length is the length of deleted text (in bytes).
/// 
/// This event should be handled as part of a following commit_string
/// event.
/// 
class ZwpTextInputV1DeleteSurroundingTextEvent {
/// 
  final int index;

/// 
  final int length;

  ZwpTextInputV1DeleteSurroundingTextEvent(
this.index,

this.length,

);

@override
String toString(){
  return """ZwpTextInputV1DeleteSurroundingTextEvent: {
    index: $index,
    length: $length,
  }""";
}

}

typedef ZwpTextInputV1DeleteSurroundingTextEventHandler = void Function(ZwpTextInputV1DeleteSurroundingTextEvent);

/// keysym
/// 
/// Notify when a key event was sent. Key events should not be used
/// for normal text input operations, which should be done with
/// commit_string, delete_surrounding_text, etc. The key event follows
/// the wl_keyboard key event convention. Sym is an XKB keysym, state a
/// wl_keyboard key_state. Modifiers are a mask for effective modifiers
/// (where the modifier indices are set by the modifiers_map event)
/// 
class ZwpTextInputV1KeysymEvent {
/// serial of the latest known text input state
  final int serial;

/// 
  final int time;

/// 
  final int sym;

/// 
  final int state;

/// 
  final int modifiers;

  ZwpTextInputV1KeysymEvent(
this.serial,

this.time,

this.sym,

this.state,

this.modifiers,

);

@override
String toString(){
  return """ZwpTextInputV1KeysymEvent: {
    serial: $serial,
    time: $time,
    sym: $sym,
    state: $state,
    modifiers: $modifiers,
  }""";
}

}

typedef ZwpTextInputV1KeysymEventHandler = void Function(ZwpTextInputV1KeysymEvent);

/// language
/// 
/// Sets the language of the input text. The "language" argument is an
/// RFC-3066 format language tag.
/// 
class ZwpTextInputV1LanguageEvent {
/// serial of the latest known text input state
  final int serial;

/// 
  final String language;

  ZwpTextInputV1LanguageEvent(
this.serial,

this.language,

);

@override
String toString(){
  return """ZwpTextInputV1LanguageEvent: {
    serial: $serial,
    language: $language,
  }""";
}

}

typedef ZwpTextInputV1LanguageEventHandler = void Function(ZwpTextInputV1LanguageEvent);

/// text direction
/// 
/// Sets the text direction of input text.
/// 
/// It is mainly needed for showing an input cursor on the correct side of
/// the editor when there is no input done yet and making sure neutral
/// direction text is laid out properly.
/// 
class ZwpTextInputV1TextDirectionEvent {
/// serial of the latest known text input state
  final int serial;

/// 
  final int direction;

  ZwpTextInputV1TextDirectionEvent(
this.serial,

this.direction,

);

@override
String toString(){
  return """ZwpTextInputV1TextDirectionEvent: {
    serial: $serial,
    direction: $direction,
  }""";
}

}

typedef ZwpTextInputV1TextDirectionEventHandler = void Function(ZwpTextInputV1TextDirectionEvent);


/// text input
/// 
/// An object used for text input. Adds support for text input and input
/// methods to applications. A text_input object is created from a
/// wl_text_input_manager and corresponds typically to a text entry in an
/// application.
/// 
/// Requests are used to activate/deactivate the text_input object and set
/// state information like surrounding and selected text or the content type.
/// The information about entered text is sent to the text_input object via
/// the pre-edit and commit events. Using this interface removes the need
/// for applications to directly process hardware key events and compose text
/// out of them.
/// 
/// Text is generally UTF-8 encoded, indices and lengths are in bytes.
/// 
/// Serials are used to synchronize the state between the text input and
/// an input method. New serials are sent by the text input in the
/// commit_state request and are used by the input method to indicate
/// the known text input state in events like preedit_string, commit_string,
/// and keysym. The text input can then ignore events from the input method
/// which are based on an outdated state (for example after a reset).
/// 
/// Warning! The protocol described in this file is experimental and
/// backward incompatible changes may be made. Backward compatible changes
/// may be added together with the corresponding interface version bump.
/// Backward incompatible changes are done by bumping the version number in
/// the protocol and interface names and resetting the interface version.
/// Once the protocol is to be declared stable, the 'z' prefix and the
/// version number in the protocol and interface names are removed and the
/// interface version number is reset.
/// 
class ZwpTextInputV1 extends Proxy implements Dispatcher{
  final Context context;

  ZwpTextInputV1(this.context) : super(context.allocateClientId()){
    context.register(this);
  }

/// request activation
/// 
/// Requests the text_input object to be activated (typically when the
/// text entry gets focus).
/// 
/// The seat argument is a wl_seat which maintains the focus for this
/// activation. The surface argument is a wl_surface assigned to the
/// text_input object and tracked for focus lost. The enter event
/// is emitted on successful activation.
/// 
/// [seat]:
/// [surface]:
  Future<void> activate(Seat seat, Surface surface) async {
    print("ZwpTextInputV1::activate  seat: $seat surface: $surface");
    final message = WaylandMessage(
      objectId,
      0,
      [
        seat,
        surface,
      ],
      [
        WaylandType.object,
        WaylandType.object,
      ],
    );
    await context.sendMessage(message);
  }

/// request deactivation
/// 
/// Requests the text_input object to be deactivated (typically when the
/// text entry lost focus). The seat argument is a wl_seat which was used
/// for activation.
/// 
/// [seat]:
  Future<void> deactivate(Seat seat) async {
    print("ZwpTextInputV1::deactivate  seat: $seat");
    final message = WaylandMessage(
      objectId,
      1,
      [
        seat,
      ],
      [
        WaylandType.object,
      ],
    );
    await context.sendMessage(message);
  }

/// show input panels
/// 
/// Requests input panels (virtual keyboard) to show.
/// 
  Future<void> showInputPanel() async {
    print("ZwpTextInputV1::showInputPanel ");
    final message = WaylandMessage(
      objectId,
      2,
      [
      ],
      [
      ],
    );
    await context.sendMessage(message);
  }

/// hide input panels
/// 
/// Requests input panels (virtual keyboard) to hide.
/// 
  Future<void> hideInputPanel() async {
    print("ZwpTextInputV1::hideInputPanel ");
    final message = WaylandMessage(
      objectId,
      3,
      [
      ],
      [
      ],
    );
    await context.sendMessage(message);
  }

/// reset
/// 
/// Should be called by an editor widget when the input state should be
/// reset, for example after the text was changed outside of the normal
/// input method flow.
/// 
  Future<void> reset() async {
    print("ZwpTextInputV1::reset ");
    final message = WaylandMessage(
      objectId,
      4,
      [
      ],
      [
      ],
    );
    await context.sendMessage(message);
  }

/// sets the surrounding text
/// 
/// Sets the plain surrounding text around the input position. Text is
/// UTF-8 encoded. Cursor is the byte offset within the
/// surrounding text. Anchor is the byte offset of the
/// selection anchor within the surrounding text. If there is no selected
/// text anchor, then it is the same as cursor.
/// 
/// [text]:
/// [cursor]:
/// [anchor]:
  Future<void> setSurroundingText(String text, int cursor, int anchor) async {
    print("ZwpTextInputV1::setSurroundingText  text: $text cursor: $cursor anchor: $anchor");
    final message = WaylandMessage(
      objectId,
      5,
      [
        text,
        cursor,
        anchor,
      ],
      [
        WaylandType.string,
        WaylandType.uint,
        WaylandType.uint,
      ],
    );
    await context.sendMessage(message);
  }

/// set content purpose and hint
/// 
/// Sets the content purpose and content hint. While the purpose is the
/// basic purpose of an input field, the hint flags allow to modify some
/// of the behavior.
/// 
/// When no content type is explicitly set, a normal content purpose with
/// default hints (auto completion, auto correction, auto capitalization)
/// should be assumed.
/// 
/// [hint]:
/// [purpose]:
  Future<void> setContentType(int hint, int purpose) async {
    print("ZwpTextInputV1::setContentType  hint: $hint purpose: $purpose");
    final message = WaylandMessage(
      objectId,
      6,
      [
        hint,
        purpose,
      ],
      [
        WaylandType.uint,
        WaylandType.uint,
      ],
    );
    await context.sendMessage(message);
  }

/// 
/// 
/// [x]:
/// [y]:
/// [width]:
/// [height]:
  Future<void> setCursorRectangle(int x, int y, int width, int height) async {
    print("ZwpTextInputV1::setCursorRectangle  x: $x y: $y width: $width height: $height");
    final message = WaylandMessage(
      objectId,
      7,
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
    await context.sendMessage(message);
  }

/// sets preferred language
/// 
/// Sets a specific language. This allows for example a virtual keyboard to
/// show a language specific layout. The "language" argument is an RFC-3066
/// format language tag.
/// 
/// It could be used for example in a word processor to indicate the
/// language of the currently edited document or in an instant message
/// application which tracks languages of contacts.
/// 
/// [language]:
  Future<void> setPreferredLanguage(String language) async {
    print("ZwpTextInputV1::setPreferredLanguage  language: $language");
    final message = WaylandMessage(
      objectId,
      8,
      [
        language,
      ],
      [
        WaylandType.string,
      ],
    );
    await context.sendMessage(message);
  }

/// 
/// 
/// [serial]: used to identify the known state
  Future<void> commitState(int serial) async {
    print("ZwpTextInputV1::commitState  serial: $serial");
    final message = WaylandMessage(
      objectId,
      9,
      [
        serial,
      ],
      [
        WaylandType.uint,
      ],
    );
    await context.sendMessage(message);
  }

/// 
/// 
/// [button]:
/// [index]:
  Future<void> invokeAction(int button, int index) async {
    print("ZwpTextInputV1::invokeAction  button: $button index: $index");
    final message = WaylandMessage(
      objectId,
      10,
      [
        button,
        index,
      ],
      [
        WaylandType.uint,
        WaylandType.uint,
      ],
    );
    await context.sendMessage(message);
  }

/// enter event
/// 
/// Notify the text_input object when it received focus. Typically in
/// response to an activate request.
/// 
/// Event handler for Enter
/// - [surface]:
 void onEnter(ZwpTextInputV1EnterEventHandler handler) {
   _enterHandler = handler;
 }

 ZwpTextInputV1EnterEventHandler? _enterHandler;

/// leave event
/// 
/// Notify the text_input object when it lost focus. Either in response
/// to a deactivate request or when the assigned surface lost focus or was
/// destroyed.
/// 
/// Event handler for Leave
 void onLeave(ZwpTextInputV1LeaveEventHandler handler) {
   _leaveHandler = handler;
 }

 ZwpTextInputV1LeaveEventHandler? _leaveHandler;

/// modifiers map
/// 
/// Transfer an array of 0-terminated modifier names. The position in
/// the array is the index of the modifier as used in the modifiers
/// bitmask in the keysym event.
/// 
/// Event handler for ModifiersMap
/// - [map]:
 void onModifiersMap(ZwpTextInputV1ModifiersMapEventHandler handler) {
   _modifiersMapHandler = handler;
 }

 ZwpTextInputV1ModifiersMapEventHandler? _modifiersMapHandler;

/// state of the input panel
/// 
/// Notify when the visibility state of the input panel changed.
/// 
/// Event handler for InputPanelState
/// - [state]:
 void onInputPanelState(ZwpTextInputV1InputPanelStateEventHandler handler) {
   _inputPanelStateHandler = handler;
 }

 ZwpTextInputV1InputPanelStateEventHandler? _inputPanelStateHandler;

/// pre-edit
/// 
/// Notify when a new composing text (pre-edit) should be set around the
/// current cursor position. Any previously set composing text should
/// be removed.
/// 
/// The commit text can be used to replace the preedit text on reset
/// (for example on unfocus).
/// 
/// The text input should also handle all preedit_style and preedit_cursor
/// events occurring directly before preedit_string.
/// 
/// Event handler for PreeditString
/// - [serial]: serial of the latest known text input state
/// - [text]:
/// - [commit]:
 void onPreeditString(ZwpTextInputV1PreeditStringEventHandler handler) {
   _preeditStringHandler = handler;
 }

 ZwpTextInputV1PreeditStringEventHandler? _preeditStringHandler;

/// pre-edit styling
/// 
/// Sets styling information on composing text. The style is applied for
/// length bytes from index relative to the beginning of the composing
/// text (as byte offset). Multiple styles can
/// be applied to a composing text by sending multiple preedit_styling
/// events.
/// 
/// This event is handled as part of a following preedit_string event.
/// 
/// Event handler for PreeditStyling
/// - [index]:
/// - [length]:
/// - [style]:
 void onPreeditStyling(ZwpTextInputV1PreeditStylingEventHandler handler) {
   _preeditStylingHandler = handler;
 }

 ZwpTextInputV1PreeditStylingEventHandler? _preeditStylingHandler;

/// pre-edit cursor
/// 
/// Sets the cursor position inside the composing text (as byte
/// offset) relative to the start of the composing text. When index is a
/// negative number no cursor is shown.
/// 
/// This event is handled as part of a following preedit_string event.
/// 
/// Event handler for PreeditCursor
/// - [index]:
 void onPreeditCursor(ZwpTextInputV1PreeditCursorEventHandler handler) {
   _preeditCursorHandler = handler;
 }

 ZwpTextInputV1PreeditCursorEventHandler? _preeditCursorHandler;

/// commit
/// 
/// Notify when text should be inserted into the editor widget. The text to
/// commit could be either just a single character after a key press or the
/// result of some composing (pre-edit). It could also be an empty text
/// when some text should be removed (see delete_surrounding_text) or when
/// the input cursor should be moved (see cursor_position).
/// 
/// Any previously set composing text should be removed.
/// 
/// Event handler for CommitString
/// - [serial]: serial of the latest known text input state
/// - [text]:
 void onCommitString(ZwpTextInputV1CommitStringEventHandler handler) {
   _commitStringHandler = handler;
 }

 ZwpTextInputV1CommitStringEventHandler? _commitStringHandler;

/// set cursor to new position
/// 
/// Notify when the cursor or anchor position should be modified.
/// 
/// This event should be handled as part of a following commit_string
/// event.
/// 
/// Event handler for CursorPosition
/// - [index]:
/// - [anchor]:
 void onCursorPosition(ZwpTextInputV1CursorPositionEventHandler handler) {
   _cursorPositionHandler = handler;
 }

 ZwpTextInputV1CursorPositionEventHandler? _cursorPositionHandler;

/// delete surrounding text
/// 
/// Notify when the text around the current cursor position should be
/// deleted.
/// 
/// Index is relative to the current cursor (in bytes).
/// Length is the length of deleted text (in bytes).
/// 
/// This event should be handled as part of a following commit_string
/// event.
/// 
/// Event handler for DeleteSurroundingText
/// - [index]:
/// - [length]:
 void onDeleteSurroundingText(ZwpTextInputV1DeleteSurroundingTextEventHandler handler) {
   _deleteSurroundingTextHandler = handler;
 }

 ZwpTextInputV1DeleteSurroundingTextEventHandler? _deleteSurroundingTextHandler;

/// keysym
/// 
/// Notify when a key event was sent. Key events should not be used
/// for normal text input operations, which should be done with
/// commit_string, delete_surrounding_text, etc. The key event follows
/// the wl_keyboard key event convention. Sym is an XKB keysym, state a
/// wl_keyboard key_state. Modifiers are a mask for effective modifiers
/// (where the modifier indices are set by the modifiers_map event)
/// 
/// Event handler for Keysym
/// - [serial]: serial of the latest known text input state
/// - [time]:
/// - [sym]:
/// - [state]:
/// - [modifiers]:
 void onKeysym(ZwpTextInputV1KeysymEventHandler handler) {
   _keysymHandler = handler;
 }

 ZwpTextInputV1KeysymEventHandler? _keysymHandler;

/// language
/// 
/// Sets the language of the input text. The "language" argument is an
/// RFC-3066 format language tag.
/// 
/// Event handler for Language
/// - [serial]: serial of the latest known text input state
/// - [language]:
 void onLanguage(ZwpTextInputV1LanguageEventHandler handler) {
   _languageHandler = handler;
 }

 ZwpTextInputV1LanguageEventHandler? _languageHandler;

/// text direction
/// 
/// Sets the text direction of input text.
/// 
/// It is mainly needed for showing an input cursor on the correct side of
/// the editor when there is no input done yet and making sure neutral
/// direction text is laid out properly.
/// 
/// Event handler for TextDirection
/// - [serial]: serial of the latest known text input state
/// - [direction]:
 void onTextDirection(ZwpTextInputV1TextDirectionEventHandler handler) {
   _textDirectionHandler = handler;
 }

 ZwpTextInputV1TextDirectionEventHandler? _textDirectionHandler;

 @override
 void dispatch(int opcode, int fd, Uint8List data) {
   switch (opcode) {
     case 0:
       if (_enterHandler != null) {
var event = ZwpTextInputV1EnterEvent(
           context.getProxy(ByteData.view(data.buffer).getUint32(0, Endian.little)).objectId,
        );
         _enterHandler!(event);
       }
       break;
     case 1:
       if (_leaveHandler != null) {
var event = ZwpTextInputV1LeaveEvent(
        );
         _leaveHandler!(event);
       }
       break;
     case 2:
       if (_modifiersMapHandler != null) {
var event = ZwpTextInputV1ModifiersMapEvent(
           getArray(data, 0),
        );
         _modifiersMapHandler!(event);
       }
       break;
     case 3:
       if (_inputPanelStateHandler != null) {
var event = ZwpTextInputV1InputPanelStateEvent(
           ByteData.view(data.buffer).getUint32(0, Endian.little),
        );
         _inputPanelStateHandler!(event);
       }
       break;
     case 4:
       if (_preeditStringHandler != null) {
var event = ZwpTextInputV1PreeditStringEvent(
           ByteData.view(data.buffer).getUint32(0, Endian.little),
           getString(data, 4),
           getString(data, 8),
        );
         _preeditStringHandler!(event);
       }
       break;
     case 5:
       if (_preeditStylingHandler != null) {
var event = ZwpTextInputV1PreeditStylingEvent(
           ByteData.view(data.buffer).getUint32(0, Endian.little),
           ByteData.view(data.buffer).getUint32(4, Endian.little),
           ByteData.view(data.buffer).getUint32(8, Endian.little),
        );
         _preeditStylingHandler!(event);
       }
       break;
     case 6:
       if (_preeditCursorHandler != null) {
var event = ZwpTextInputV1PreeditCursorEvent(
           ByteData.view(data.buffer).getInt32(0, Endian.little),
        );
         _preeditCursorHandler!(event);
       }
       break;
     case 7:
       if (_commitStringHandler != null) {
var event = ZwpTextInputV1CommitStringEvent(
           ByteData.view(data.buffer).getUint32(0, Endian.little),
           getString(data, 4),
        );
         _commitStringHandler!(event);
       }
       break;
     case 8:
       if (_cursorPositionHandler != null) {
var event = ZwpTextInputV1CursorPositionEvent(
           ByteData.view(data.buffer).getInt32(0, Endian.little),
           ByteData.view(data.buffer).getInt32(4, Endian.little),
        );
         _cursorPositionHandler!(event);
       }
       break;
     case 9:
       if (_deleteSurroundingTextHandler != null) {
var event = ZwpTextInputV1DeleteSurroundingTextEvent(
           ByteData.view(data.buffer).getInt32(0, Endian.little),
           ByteData.view(data.buffer).getUint32(4, Endian.little),
        );
         _deleteSurroundingTextHandler!(event);
       }
       break;
     case 10:
       if (_keysymHandler != null) {
var event = ZwpTextInputV1KeysymEvent(
           ByteData.view(data.buffer).getUint32(0, Endian.little),
           ByteData.view(data.buffer).getUint32(4, Endian.little),
           ByteData.view(data.buffer).getUint32(8, Endian.little),
           ByteData.view(data.buffer).getUint32(12, Endian.little),
           ByteData.view(data.buffer).getUint32(16, Endian.little),
        );
         _keysymHandler!(event);
       }
       break;
     case 11:
       if (_languageHandler != null) {
var event = ZwpTextInputV1LanguageEvent(
           ByteData.view(data.buffer).getUint32(0, Endian.little),
           getString(data, 4),
        );
         _languageHandler!(event);
       }
       break;
     case 12:
       if (_textDirectionHandler != null) {
var event = ZwpTextInputV1TextDirectionEvent(
           ByteData.view(data.buffer).getUint32(0, Endian.little),
           ByteData.view(data.buffer).getUint32(4, Endian.little),
        );
         _textDirectionHandler!(event);
       }
       break;
   }
 }
}

/// content hint
/// 
/// Content hint is a bitmask to allow to modify the behavior of the text
/// input.
/// 

enum ZwpTextInputV1contentHint {
/// no special behaviour
  none,
/// auto completion, correction and capitalization
  defaulted,
/// hidden and sensitive text
  password,
/// suggest word completions
  autoCompletion,
/// suggest word corrections
  autoCorrection,
/// switch to uppercase letters at the start of a sentence
  autoCapitalization,
/// prefer lowercase letters
  lowercase,
/// prefer uppercase letters
  uppercase,
/// prefer casing for titles and headings (can be language dependent)
  titlecase,
/// characters should be hidden
  hiddenText,
/// typed text should not be stored
  sensitiveData,
/// just latin characters should be entered
  latin,
/// the text input is multiline
  multiline,
}

/// content purpose
/// 
/// The content purpose allows to specify the primary purpose of a text
/// input.
/// 
/// This allows an input method to show special purpose input panels with
/// extra characters or to disallow some characters.
/// 

enum ZwpTextInputV1contentPurpose {
/// default input, allowing all characters
  normal,
/// allow only alphabetic characters
  alpha,
/// allow only digits
  digits,
/// input a number (including decimal separator and sign)
  number,
/// input a phone number
  phone,
/// input an URL
  url,
/// input an email address
  email,
/// input a name of a person
  name,
/// input a password (combine with password or sensitive_data hint)
  password,
/// input a date
  date,
/// input a time
  time,
/// input a date and time
  datetime,
/// input for a terminal
  terminal,
}

/// 
/// 

enum ZwpTextInputV1preeditStyle {
/// default style for composing text
  defaulted,
/// style should be the same as in non-composing text
  none,
/// 
  active,
/// 
  inactive,
/// 
  highlight,
/// 
  underline,
/// 
  selection,
/// 
  incorrect,
}

/// 
/// 

enum ZwpTextInputV1textDirection {
/// automatic text direction based on text and language
  auto,
/// left-to-right
  ltr,
/// right-to-left
  rtl,
}



/// text input manager
/// 
/// A factory for text_input objects. This object is a global singleton.
/// 
class ZwpTextInputManagerV1 extends Proxy{
  final Context context;

  ZwpTextInputManagerV1(this.context) : super(context.allocateClientId()){
    context.register(this);
  }

/// create text input
/// 
/// Creates a new text_input object.
/// 
/// [id]:
  Future<ZwpTextInputV1> createTextInput() async {
  var id =  ZwpTextInputV1(context);
    print("ZwpTextInputManagerV1::createTextInput  id: $id");
    final message = WaylandMessage(
      objectId,
      0,
      [
        id,
      ],
      [
        WaylandType.newId,
      ],
    );
    await context.sendMessage(message);
    return id;
  }

}
