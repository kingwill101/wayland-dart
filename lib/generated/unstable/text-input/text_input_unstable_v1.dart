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
import 'dart:typed_data';
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

  ZwpTextInputV1(this.context) : super(context.allocateClientId());

  Future<void> activate(Seat seat, Surface surface) async {
    final message = WaylandMessage(
      context.allocateClientId(),
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
    context.sendMessage(message);
  }

  Future<void> deactivate(Seat seat) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      1,
      [
        seat,
      ],
      [
        WaylandType.object,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> showInputPanel() async {
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

  Future<void> hideInputPanel() async {
    final message = WaylandMessage(
      context.allocateClientId(),
      3,
      [
      ],
      [
      ],
    );
    context.sendMessage(message);
  }

  Future<void> reset() async {
    final message = WaylandMessage(
      context.allocateClientId(),
      4,
      [
      ],
      [
      ],
    );
    context.sendMessage(message);
  }

  Future<void> setSurroundingText(String text, int cursor, int anchor) async {
    final message = WaylandMessage(
      context.allocateClientId(),
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
    context.sendMessage(message);
  }

  Future<void> setContentType(int hint, int purpose) async {
    final message = WaylandMessage(
      context.allocateClientId(),
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
    context.sendMessage(message);
  }

  Future<void> setCursorRectangle(int x, int y, int width, int height) async {
    final message = WaylandMessage(
      context.allocateClientId(),
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
    context.sendMessage(message);
  }

  Future<void> setPreferredLanguage(String language) async {
    final message = WaylandMessage(
      context.allocateClientId(),
      8,
      [
        language,
      ],
      [
        WaylandType.string,
      ],
    );
    context.sendMessage(message);
  }

  Future<void> commitState(int serial) async {
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

  Future<void> invokeAction(int button, int index) async {
    final message = WaylandMessage(
      context.allocateClientId(),
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
    context.sendMessage(message);
  }

 /// enter event
/// 
/// Notify the text_input object when it received focus. Typically in
/// response to an activate request.
/// 
 void onenter(void Function(int surface) handler) {
   _enterHandler = handler;
 }

 void Function(int surface)? _enterHandler;

 /// leave event
/// 
/// Notify the text_input object when it lost focus. Either in response
/// to a deactivate request or when the assigned surface lost focus or was
/// destroyed.
/// 
 void onleave(void Function() handler) {
   _leaveHandler = handler;
 }

 void Function()? _leaveHandler;

 /// modifiers map
/// 
/// Transfer an array of 0-terminated modifier names. The position in
/// the array is the index of the modifier as used in the modifiers
/// bitmask in the keysym event.
/// 
 void onmodifiersMap(void Function(List<int> map) handler) {
   _modifiersMapHandler = handler;
 }

 void Function(List<int> map)? _modifiersMapHandler;

 /// state of the input panel
/// 
/// Notify when the visibility state of the input panel changed.
/// 
 void oninputPanelState(void Function(int state) handler) {
   _inputPanelStateHandler = handler;
 }

 void Function(int state)? _inputPanelStateHandler;

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
 void onpreeditString(void Function(int serial, String text, String commit) handler) {
   _preeditStringHandler = handler;
 }

 void Function(int serial, String text, String commit)? _preeditStringHandler;

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
 void onpreeditStyling(void Function(int index, int length, int style) handler) {
   _preeditStylingHandler = handler;
 }

 void Function(int index, int length, int style)? _preeditStylingHandler;

 /// pre-edit cursor
/// 
/// Sets the cursor position inside the composing text (as byte
/// offset) relative to the start of the composing text. When index is a
/// negative number no cursor is shown.
/// 
/// This event is handled as part of a following preedit_string event.
/// 
 void onpreeditCursor(void Function(int index) handler) {
   _preeditCursorHandler = handler;
 }

 void Function(int index)? _preeditCursorHandler;

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
 void oncommitString(void Function(int serial, String text) handler) {
   _commitStringHandler = handler;
 }

 void Function(int serial, String text)? _commitStringHandler;

 /// set cursor to new position
/// 
/// Notify when the cursor or anchor position should be modified.
/// 
/// This event should be handled as part of a following commit_string
/// event.
/// 
 void oncursorPosition(void Function(int index, int anchor) handler) {
   _cursorPositionHandler = handler;
 }

 void Function(int index, int anchor)? _cursorPositionHandler;

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
 void ondeleteSurroundingText(void Function(int index, int length) handler) {
   _deleteSurroundingTextHandler = handler;
 }

 void Function(int index, int length)? _deleteSurroundingTextHandler;

 /// keysym
/// 
/// Notify when a key event was sent. Key events should not be used
/// for normal text input operations, which should be done with
/// commit_string, delete_surrounding_text, etc. The key event follows
/// the wl_keyboard key event convention. Sym is an XKB keysym, state a
/// wl_keyboard key_state. Modifiers are a mask for effective modifiers
/// (where the modifier indices are set by the modifiers_map event)
/// 
 void onkeysym(void Function(int serial, int time, int sym, int state, int modifiers) handler) {
   _keysymHandler = handler;
 }

 void Function(int serial, int time, int sym, int state, int modifiers)? _keysymHandler;

 /// language
/// 
/// Sets the language of the input text. The "language" argument is an
/// RFC-3066 format language tag.
/// 
 void onlanguage(void Function(int serial, String language) handler) {
   _languageHandler = handler;
 }

 void Function(int serial, String language)? _languageHandler;

 /// text direction
/// 
/// Sets the text direction of input text.
/// 
/// It is mainly needed for showing an input cursor on the correct side of
/// the editor when there is no input done yet and making sure neutral
/// direction text is laid out properly.
/// 
 void ontextDirection(void Function(int serial, int direction) handler) {
   _textDirectionHandler = handler;
 }

 void Function(int serial, int direction)? _textDirectionHandler;

 @override
 void dispatch(int opcode, int fd, Uint8List data) {
   switch (opcode) {
     case 0:
       if (_enterHandler != null) {
         _enterHandler!(
           context.getProxy(ByteData.view(data.buffer).getUint32(0, Endian.host)).id,
         );
       }
       break;
     case 1:
       if (_leaveHandler != null) {
         _leaveHandler!(
         );
       }
       break;
     case 2:
       if (_modifiersMapHandler != null) {
         _modifiersMapHandler!(
           getArray(data, 0),
         );
       }
       break;
     case 3:
       if (_inputPanelStateHandler != null) {
         _inputPanelStateHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
         );
       }
       break;
     case 4:
       if (_preeditStringHandler != null) {
         _preeditStringHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
           getString(data, 4),
           getString(data, 8),
         );
       }
       break;
     case 5:
       if (_preeditStylingHandler != null) {
         _preeditStylingHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
           ByteData.view(data.buffer).getInt32(4, Endian.host),
           ByteData.view(data.buffer).getInt32(8, Endian.host),
         );
       }
       break;
     case 6:
       if (_preeditCursorHandler != null) {
         _preeditCursorHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
         );
       }
       break;
     case 7:
       if (_commitStringHandler != null) {
         _commitStringHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
           getString(data, 4),
         );
       }
       break;
     case 8:
       if (_cursorPositionHandler != null) {
         _cursorPositionHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
           ByteData.view(data.buffer).getInt32(4, Endian.host),
         );
       }
       break;
     case 9:
       if (_deleteSurroundingTextHandler != null) {
         _deleteSurroundingTextHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
           ByteData.view(data.buffer).getInt32(4, Endian.host),
         );
       }
       break;
     case 10:
       if (_keysymHandler != null) {
         _keysymHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
           ByteData.view(data.buffer).getInt32(4, Endian.host),
           ByteData.view(data.buffer).getInt32(8, Endian.host),
           ByteData.view(data.buffer).getInt32(12, Endian.host),
           ByteData.view(data.buffer).getInt32(16, Endian.host),
         );
       }
       break;
     case 11:
       if (_languageHandler != null) {
         _languageHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
           getString(data, 4),
         );
       }
       break;
     case 12:
       if (_textDirectionHandler != null) {
         _textDirectionHandler!(
           ByteData.view(data.buffer).getInt32(0, Endian.host),
           ByteData.view(data.buffer).getInt32(4, Endian.host),
         );
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

  ZwpTextInputManagerV1(this.context) : super(context.allocateClientId());

  Future<void> createTextInput() async {
  var id =  ZwpTextInputManagerV1(context);
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

}

