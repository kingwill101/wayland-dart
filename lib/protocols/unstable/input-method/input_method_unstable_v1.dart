// Generated by dart-wayland-scanner
// https://github.com/your-repo/dart-wayland-scanner
// XML file : https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/unstable/input-method/input-method-unstable-v1.xml
//
// input_method_unstable_v1 Protocol Copyright:
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
import 'package:wayland/protocols/wayland.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// surrounding text event
///
/// The plain surrounding text around the input position. Cursor is the
/// position in bytes within the surrounding text relative to the beginning
/// of the text. Anchor is the position in bytes of the selection anchor
/// within the surrounding text relative to the beginning of the text. If
/// there is no selected text then anchor is the same as cursor.
///
class ZwpInputMethodContextV1SurroundingTextEvent {
  ///
  final String text;

  ///
  final int cursor;

  ///
  final int anchor;

  ZwpInputMethodContextV1SurroundingTextEvent(
    this.text,
    this.cursor,
    this.anchor,
  );

  @override
  toString() {
    return "ZwpInputMethodContextV1SurroundingTextEvent (text: $text, cursor: $cursor, anchor: $anchor)";
  }
}

typedef ZwpInputMethodContextV1SurroundingTextEventHandler = void Function(
    ZwpInputMethodContextV1SurroundingTextEvent);

class ZwpInputMethodContextV1ResetEvent {
  ZwpInputMethodContextV1ResetEvent();

  @override
  toString() {
    return "ZwpInputMethodContextV1ResetEvent ()";
  }
}

typedef ZwpInputMethodContextV1ResetEventHandler = void Function(
    ZwpInputMethodContextV1ResetEvent);

class ZwpInputMethodContextV1ContentTypeEvent {
  ///
  final int hint;

  ///
  final int purpose;

  ZwpInputMethodContextV1ContentTypeEvent(
    this.hint,
    this.purpose,
  );

  @override
  toString() {
    return "ZwpInputMethodContextV1ContentTypeEvent (hint: $hint, purpose: $purpose)";
  }
}

typedef ZwpInputMethodContextV1ContentTypeEventHandler = void Function(
    ZwpInputMethodContextV1ContentTypeEvent);

class ZwpInputMethodContextV1InvokeActionEvent {
  ///
  final int button;

  ///
  final int index;

  ZwpInputMethodContextV1InvokeActionEvent(
    this.button,
    this.index,
  );

  @override
  toString() {
    return "ZwpInputMethodContextV1InvokeActionEvent (button: $button, index: $index)";
  }
}

typedef ZwpInputMethodContextV1InvokeActionEventHandler = void Function(
    ZwpInputMethodContextV1InvokeActionEvent);

class ZwpInputMethodContextV1CommitStateEvent {
  /// serial of text input state
  final int serial;

  ZwpInputMethodContextV1CommitStateEvent(
    this.serial,
  );

  @override
  toString() {
    return "ZwpInputMethodContextV1CommitStateEvent (serial: $serial)";
  }
}

typedef ZwpInputMethodContextV1CommitStateEventHandler = void Function(
    ZwpInputMethodContextV1CommitStateEvent);

class ZwpInputMethodContextV1PreferredLanguageEvent {
  ///
  final String language;

  ZwpInputMethodContextV1PreferredLanguageEvent(
    this.language,
  );

  @override
  toString() {
    return "ZwpInputMethodContextV1PreferredLanguageEvent (language: $language)";
  }
}

typedef ZwpInputMethodContextV1PreferredLanguageEventHandler = void Function(
    ZwpInputMethodContextV1PreferredLanguageEvent);

/// input method context
///
/// Corresponds to a text input on the input method side. An input method context
/// is created on text input activation on the input method side. It allows
/// receiving information about the text input from the application via events.
/// Input method contexts do not keep state after deactivation and should be
/// destroyed after deactivation is handled.
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
class ZwpInputMethodContextV1 extends Proxy implements Dispatcher {
  final Context innerContext;
  final version = 1;

  ZwpInputMethodContextV1(this.innerContext)
      : super(innerContext.allocateClientId()) {
    innerContext.register(this);
  }

  @override
  toString() {
    return "ZwpInputMethodContextV1 {name: 'zwp_input_method_context_v1', id: '$objectId', version: '1',}";
  }

  ///
  ///
  void destroy() {
    logLn("ZwpInputMethodContextV1::destroy ");
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

  /// commit string
  ///
  /// Send the commit string text for insertion to the application.
  ///
  /// The text to commit could be either just a single character after a key
  /// press or the result of some composing (pre-edit). It could be also an
  /// empty text when some text should be removed (see
  /// delete_surrounding_text) or when the input cursor should be moved (see
  /// cursor_position).
  ///
  /// Any previously set composing text will be removed.
  ///
  /// [serial]: serial of the latest known text input state
  /// [text]:
  void commitString(int serial, String text) {
    logLn("ZwpInputMethodContextV1::commitString  serial: $serial text: $text");
    var arguments = [serial, text];
    var argTypes = <WaylandType>[WaylandType.uint, WaylandType.string];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 1])
            .buffer
            .asUint8List());
    bytesBuilder.add(Uint32List.fromList([serial]).buffer.asUint8List());
    final textBytes = utf8.encode(text);
    bytesBuilder
        .add(Uint32List.fromList([textBytes.length + 1]).buffer.asUint8List());
    bytesBuilder.add(textBytes);
    bytesBuilder.add([0]); // Null terminator
    while (bytesBuilder.length % 4 != 0) {
      bytesBuilder.add([0]);
    } // Padding
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// pre-edit string
  ///
  /// Send the pre-edit string text to the application text input.
  ///
  /// The commit text can be used to replace the pre-edit text on reset (for
  /// example on unfocus).
  ///
  /// Previously sent preedit_style and preedit_cursor requests are also
  /// processed by the text_input.
  ///
  /// [serial]: serial of the latest known text input state
  /// [text]:
  /// [commit]:
  void preeditString(int serial, String text, String commit) {
    logLn(
        "ZwpInputMethodContextV1::preeditString  serial: $serial text: $text commit: $commit");
    var arguments = [serial, text, commit];
    var argTypes = <WaylandType>[
      WaylandType.uint,
      WaylandType.string,
      WaylandType.string
    ];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 2])
            .buffer
            .asUint8List());
    bytesBuilder.add(Uint32List.fromList([serial]).buffer.asUint8List());
    final textBytes = utf8.encode(text);
    bytesBuilder
        .add(Uint32List.fromList([textBytes.length + 1]).buffer.asUint8List());
    bytesBuilder.add(textBytes);
    bytesBuilder.add([0]); // Null terminator
    while (bytesBuilder.length % 4 != 0) {
      bytesBuilder.add([0]);
    } // Padding
    final commitBytes = utf8.encode(commit);
    bytesBuilder.add(
        Uint32List.fromList([commitBytes.length + 1]).buffer.asUint8List());
    bytesBuilder.add(commitBytes);
    bytesBuilder.add([0]); // Null terminator
    while (bytesBuilder.length % 4 != 0) {
      bytesBuilder.add([0]);
    } // Padding
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// pre-edit styling
  ///
  /// Set the styling information on composing text. The style is applied for
  /// length in bytes from index relative to the beginning of
  /// the composing text (as byte offset). Multiple styles can
  /// be applied to a composing text.
  ///
  /// This request should be sent before sending a preedit_string request.
  ///
  /// [index]:
  /// [length]:
  /// [style]:
  void preeditStyling(int index, int length, int style) {
    logLn(
        "ZwpInputMethodContextV1::preeditStyling  index: $index length: $length style: $style");
    var arguments = [index, length, style];
    var argTypes = <WaylandType>[
      WaylandType.uint,
      WaylandType.uint,
      WaylandType.uint
    ];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 3])
            .buffer
            .asUint8List());
    bytesBuilder.add(Uint32List.fromList([index]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([length]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([style]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// pre-edit cursor
  ///
  /// Set the cursor position inside the composing text (as byte offset)
  /// relative to the start of the composing text.
  ///
  /// When index is negative no cursor should be displayed.
  ///
  /// This request should be sent before sending a preedit_string request.
  ///
  /// [index]:
  void preeditCursor(int index) {
    logLn("ZwpInputMethodContextV1::preeditCursor  index: $index");
    var arguments = [index];
    var argTypes = <WaylandType>[WaylandType.int];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 4])
            .buffer
            .asUint8List());
    bytesBuilder.add(Int32List.fromList([index]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// delete text
  ///
  /// Remove the surrounding text.
  ///
  /// This request will be handled on the text_input side directly following
  /// a commit_string request.
  ///
  /// [index]:
  /// [length]:
  void deleteSurroundingText(int index, int length) {
    logLn(
        "ZwpInputMethodContextV1::deleteSurroundingText  index: $index length: $length");
    var arguments = [index, length];
    var argTypes = <WaylandType>[WaylandType.int, WaylandType.uint];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 5])
            .buffer
            .asUint8List());
    bytesBuilder.add(Int32List.fromList([index]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([length]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// set cursor to a new position
  ///
  /// Set the cursor and anchor to a new position. Index is the new cursor
  /// position in bytes (when >= 0 this is relative to the end of the inserted text,
  /// otherwise it is relative to the beginning of the inserted text). Anchor is
  /// the new anchor position in bytes (when >= 0 this is relative to the end of the
  /// inserted text, otherwise it is relative to the beginning of the inserted
  /// text). When there should be no selected text, anchor should be the same
  /// as index.
  ///
  /// This request will be handled on the text_input side directly following
  /// a commit_string request.
  ///
  /// [index]:
  /// [anchor]:
  void cursorPosition(int index, int anchor) {
    logLn(
        "ZwpInputMethodContextV1::cursorPosition  index: $index anchor: $anchor");
    var arguments = [index, anchor];
    var argTypes = <WaylandType>[WaylandType.int, WaylandType.int];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 6])
            .buffer
            .asUint8List());
    bytesBuilder.add(Int32List.fromList([index]).buffer.asUint8List());
    bytesBuilder.add(Int32List.fromList([anchor]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  ///
  ///
  /// [map]:
  void modifiersMap(List<int> map) {
    logLn("ZwpInputMethodContextV1::modifiersMap  map: $map");
    var arguments = [map];
    var argTypes = <WaylandType>[WaylandType.array];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 7])
            .buffer
            .asUint8List());
    bytesBuilder.add(Uint32List.fromList([map.length]).buffer.asUint8List());
    bytesBuilder.add(map);
    while (bytesBuilder.length % 4 != 0) {
      bytesBuilder.add([0]);
    } // Padding
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// keysym
  ///
  /// Notify when a key event was sent. Key events should not be used for
  /// normal text input operations, which should be done with commit_string,
  /// delete_surrounding_text, etc. The key event follows the wl_keyboard key
  /// event convention. Sym is an XKB keysym, state is a wl_keyboard key_state.
  ///
  /// [serial]: serial of the latest known text input state
  /// [time]:
  /// [sym]:
  /// [state]:
  /// [modifiers]:
  void keysym(int serial, int time, int sym, int state, int modifiers) {
    logLn(
        "ZwpInputMethodContextV1::keysym  serial: $serial time: $time sym: $sym state: $state modifiers: $modifiers");
    var arguments = [serial, time, sym, state, modifiers];
    var argTypes = <WaylandType>[
      WaylandType.uint,
      WaylandType.uint,
      WaylandType.uint,
      WaylandType.uint,
      WaylandType.uint
    ];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 8])
            .buffer
            .asUint8List());
    bytesBuilder.add(Uint32List.fromList([serial]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([time]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([sym]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([state]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([modifiers]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// grab hardware keyboard
  ///
  /// Allow an input method to receive hardware keyboard input and process
  /// key events to generate text events (with pre-edit) over the wire. This
  /// allows input methods which compose multiple key events for inputting
  /// text like it is done for CJK languages.
  ///
  /// [keyboard]:
  Keyboard grabKeyboard() {
    var keyboard = Keyboard(innerContext);
    logLn("ZwpInputMethodContextV1::grabKeyboard  keyboard: $keyboard");
    var arguments = [keyboard];
    var argTypes = <WaylandType>[WaylandType.newId];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 9])
            .buffer
            .asUint8List());
    bytesBuilder
        .add(Uint32List.fromList([keyboard.objectId]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
    return keyboard;
  }

  /// forward key event
  ///
  /// Forward a wl_keyboard::key event to the client that was not processed
  /// by the input method itself. Should be used when filtering key events
  /// with grab_keyboard.  The arguments should be the ones from the
  /// wl_keyboard::key event.
  ///
  /// For generating custom key events use the keysym request instead.
  ///
  /// [serial]: serial from wl_keyboard::key
  /// [time]: time from wl_keyboard::key
  /// [key]: key from wl_keyboard::key
  /// [state]: state from wl_keyboard::key
  void key(int serial, int time, int key, int state) {
    logLn(
        "ZwpInputMethodContextV1::key  serial: $serial time: $time key: $key state: $state");
    var arguments = [serial, time, key, state];
    var argTypes = <WaylandType>[
      WaylandType.uint,
      WaylandType.uint,
      WaylandType.uint,
      WaylandType.uint
    ];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 10])
            .buffer
            .asUint8List());
    bytesBuilder.add(Uint32List.fromList([serial]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([time]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([key]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([state]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// forward modifiers event
  ///
  /// Forward a wl_keyboard::modifiers event to the client that was not
  /// processed by the input method itself.  Should be used when filtering
  /// key events with grab_keyboard. The arguments should be the ones
  /// from the wl_keyboard::modifiers event.
  ///
  /// [serial]: serial from wl_keyboard::modifiers
  /// [mods_depressed]: mods_depressed from wl_keyboard::modifiers
  /// [mods_latched]: mods_latched from wl_keyboard::modifiers
  /// [mods_locked]: mods_locked from wl_keyboard::modifiers
  /// [group]: group from wl_keyboard::modifiers
  void modifiers(int serial, int modsDepressed, int modsLatched, int modsLocked,
      int group) {
    logLn(
        "ZwpInputMethodContextV1::modifiers  serial: $serial modsDepressed: $modsDepressed modsLatched: $modsLatched modsLocked: $modsLocked group: $group");
    var arguments = [serial, modsDepressed, modsLatched, modsLocked, group];
    var argTypes = <WaylandType>[
      WaylandType.uint,
      WaylandType.uint,
      WaylandType.uint,
      WaylandType.uint,
      WaylandType.uint
    ];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 11])
            .buffer
            .asUint8List());
    bytesBuilder.add(Uint32List.fromList([serial]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([modsDepressed]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([modsLatched]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([modsLocked]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([group]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  ///
  ///
  /// [serial]: serial of the latest known text input state
  /// [language]:
  void language(int serial, String language) {
    logLn(
        "ZwpInputMethodContextV1::language  serial: $serial language: $language");
    var arguments = [serial, language];
    var argTypes = <WaylandType>[WaylandType.uint, WaylandType.string];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 12])
            .buffer
            .asUint8List());
    bytesBuilder.add(Uint32List.fromList([serial]).buffer.asUint8List());
    final languageBytes = utf8.encode(language);
    bytesBuilder.add(
        Uint32List.fromList([languageBytes.length + 1]).buffer.asUint8List());
    bytesBuilder.add(languageBytes);
    bytesBuilder.add([0]); // Null terminator
    while (bytesBuilder.length % 4 != 0) {
      bytesBuilder.add([0]);
    } // Padding
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  ///
  ///
  /// [serial]: serial of the latest known text input state
  /// [direction]:
  void textDirection(int serial, int direction) {
    logLn(
        "ZwpInputMethodContextV1::textDirection  serial: $serial direction: $direction");
    var arguments = [serial, direction];
    var argTypes = <WaylandType>[WaylandType.uint, WaylandType.uint];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 13])
            .buffer
            .asUint8List());
    bytesBuilder.add(Uint32List.fromList([serial]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([direction]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// surrounding text event
  ///
  /// The plain surrounding text around the input position. Cursor is the
  /// position in bytes within the surrounding text relative to the beginning
  /// of the text. Anchor is the position in bytes of the selection anchor
  /// within the surrounding text relative to the beginning of the text. If
  /// there is no selected text then anchor is the same as cursor.
  ///
  /// Event handler for SurroundingText
  /// - [text]:
  /// - [cursor]:
  /// - [anchor]:
  void onSurroundingText(
      ZwpInputMethodContextV1SurroundingTextEventHandler handler) {
    _surroundingTextHandler = handler;
  }

  ZwpInputMethodContextV1SurroundingTextEventHandler? _surroundingTextHandler;

  ///
  ///
  /// Event handler for Reset
  void onReset(ZwpInputMethodContextV1ResetEventHandler handler) {
    _resetHandler = handler;
  }

  ZwpInputMethodContextV1ResetEventHandler? _resetHandler;

  ///
  ///
  /// Event handler for ContentType
  /// - [hint]:
  /// - [purpose]:
  void onContentType(ZwpInputMethodContextV1ContentTypeEventHandler handler) {
    _contentTypeHandler = handler;
  }

  ZwpInputMethodContextV1ContentTypeEventHandler? _contentTypeHandler;

  ///
  ///
  /// Event handler for InvokeAction
  /// - [button]:
  /// - [index]:
  void onInvokeAction(ZwpInputMethodContextV1InvokeActionEventHandler handler) {
    _invokeActionHandler = handler;
  }

  ZwpInputMethodContextV1InvokeActionEventHandler? _invokeActionHandler;

  ///
  ///
  /// Event handler for CommitState
  /// - [serial]: serial of text input state
  void onCommitState(ZwpInputMethodContextV1CommitStateEventHandler handler) {
    _commitStateHandler = handler;
  }

  ZwpInputMethodContextV1CommitStateEventHandler? _commitStateHandler;

  ///
  ///
  /// Event handler for PreferredLanguage
  /// - [language]:
  void onPreferredLanguage(
      ZwpInputMethodContextV1PreferredLanguageEventHandler handler) {
    _preferredLanguageHandler = handler;
  }

  ZwpInputMethodContextV1PreferredLanguageEventHandler?
      _preferredLanguageHandler;

  @override
  void dispatch(int opcode, int fd, Uint8List data) {
    logLn("ZwpInputMethodContextV1.dispatch($opcode, $fd, $data)");
    switch (opcode) {
      case 0:
        if (_surroundingTextHandler != null) {
          var offset = 0;
          final textLength =
              ByteData.view(data.buffer).getUint32(offset, Endian.little);
          offset += 4;
          final text =
              utf8.decode(data.sublist(offset, offset + textLength - 1));
          offset += textLength; // Skip the string bytes and null terminator
          while (offset % 4 != 0) {
            offset++;
          } // Padding
          final cursor =
              ByteData.view(data.buffer).getUint32(offset, Endian.little);
          offset += 4;
          final anchor =
              ByteData.view(data.buffer).getUint32(offset, Endian.little);
          offset += 4;
          var event = ZwpInputMethodContextV1SurroundingTextEvent(
            text,
            cursor,
            anchor,
          );
          _surroundingTextHandler!(event);
        }
        break;
      case 1:
        if (_resetHandler != null) {
          _resetHandler!(ZwpInputMethodContextV1ResetEvent());
        }
        break;
      case 2:
        if (_contentTypeHandler != null) {
          var offset = 0;
          final hint =
              ByteData.view(data.buffer).getUint32(offset, Endian.little);
          offset += 4;
          final purpose =
              ByteData.view(data.buffer).getUint32(offset, Endian.little);
          offset += 4;
          var event = ZwpInputMethodContextV1ContentTypeEvent(
            hint,
            purpose,
          );
          _contentTypeHandler!(event);
        }
        break;
      case 3:
        if (_invokeActionHandler != null) {
          var offset = 0;
          final button =
              ByteData.view(data.buffer).getUint32(offset, Endian.little);
          offset += 4;
          final index =
              ByteData.view(data.buffer).getUint32(offset, Endian.little);
          offset += 4;
          var event = ZwpInputMethodContextV1InvokeActionEvent(
            button,
            index,
          );
          _invokeActionHandler!(event);
        }
        break;
      case 4:
        if (_commitStateHandler != null) {
          var offset = 0;
          final serial =
              ByteData.view(data.buffer).getUint32(offset, Endian.little);
          offset += 4;
          var event = ZwpInputMethodContextV1CommitStateEvent(
            serial,
          );
          _commitStateHandler!(event);
        }
        break;
      case 5:
        if (_preferredLanguageHandler != null) {
          var offset = 0;
          final languageLength =
              ByteData.view(data.buffer).getUint32(offset, Endian.little);
          offset += 4;
          final language =
              utf8.decode(data.sublist(offset, offset + languageLength - 1));
          offset += languageLength; // Skip the string bytes and null terminator
          while (offset % 4 != 0) {
            offset++;
          } // Padding
          var event = ZwpInputMethodContextV1PreferredLanguageEvent(
            language,
          );
          _preferredLanguageHandler!(event);
        }
        break;
    }
  }
}

/// activate event
///
/// A text input was activated. Creates an input method context object
/// which allows communication with the text input.
///
class ZwpInputMethodV1ActivateEvent {
  ///
  final int id;

  ZwpInputMethodV1ActivateEvent(
    this.id,
  );

  @override
  toString() {
    return "ZwpInputMethodV1ActivateEvent (id: $id)";
  }
}

typedef ZwpInputMethodV1ActivateEventHandler = void Function(
    ZwpInputMethodV1ActivateEvent);

/// deactivate event
///
/// The text input corresponding to the context argument was deactivated.
/// The input method context should be destroyed after deactivation is
/// handled.
///
class ZwpInputMethodV1DeactivateEvent {
  ///
  final int context;

  ZwpInputMethodV1DeactivateEvent(
    this.context,
  );

  @override
  toString() {
    return "ZwpInputMethodV1DeactivateEvent (context: $context)";
  }
}

typedef ZwpInputMethodV1DeactivateEventHandler = void Function(
    ZwpInputMethodV1DeactivateEvent);

/// input method
///
/// An input method object is responsible for composing text in response to
/// input from hardware or virtual keyboards. There is one input method
/// object per seat. On activate there is a new input method context object
/// created which allows the input method to communicate with the text input.
///
class ZwpInputMethodV1 extends Proxy implements Dispatcher {
  final Context innerContext;
  final version = 1;

  ZwpInputMethodV1(this.innerContext) : super(innerContext.allocateClientId()) {
    innerContext.register(this);
  }

  @override
  toString() {
    return "ZwpInputMethodV1 {name: 'zwp_input_method_v1', id: '$objectId', version: '1',}";
  }

  /// activate event
  ///
  /// A text input was activated. Creates an input method context object
  /// which allows communication with the text input.
  ///
  /// Event handler for Activate
  /// - [id]:
  void onActivate(ZwpInputMethodV1ActivateEventHandler handler) {
    _activateHandler = handler;
  }

  ZwpInputMethodV1ActivateEventHandler? _activateHandler;

  /// deactivate event
  ///
  /// The text input corresponding to the context argument was deactivated.
  /// The input method context should be destroyed after deactivation is
  /// handled.
  ///
  /// Event handler for Deactivate
  /// - [context]:
  void onDeactivate(ZwpInputMethodV1DeactivateEventHandler handler) {
    _deactivateHandler = handler;
  }

  ZwpInputMethodV1DeactivateEventHandler? _deactivateHandler;

  @override
  void dispatch(int opcode, int fd, Uint8List data) {
    logLn("ZwpInputMethodV1.dispatch($opcode, $fd, $data)");
    switch (opcode) {
      case 0:
        if (_activateHandler != null) {
          var offset = 0;
          final id = innerContext
              .getProxy(
                  ByteData.view(data.buffer).getUint32(offset, Endian.little))
              .objectId;
          offset += 4;
          var event = ZwpInputMethodV1ActivateEvent(
            id,
          );
          _activateHandler!(event);
        }
        break;
      case 1:
        if (_deactivateHandler != null) {
          var offset = 0;
          final context = innerContext
              .getProxy(
                  ByteData.view(data.buffer).getUint32(offset, Endian.little))
              .objectId;
          offset += 4;
          var event = ZwpInputMethodV1DeactivateEvent(
            context,
          );
          _deactivateHandler!(event);
        }
        break;
    }
  }
}

/// interface for implementing keyboards
///
/// Only one client can bind this interface at a time.
///
class ZwpInputPanelV1 extends Proxy {
  final Context innerContext;
  final version = 1;

  ZwpInputPanelV1(this.innerContext) : super(innerContext.allocateClientId()) {
    innerContext.register(this);
  }

  @override
  toString() {
    return "ZwpInputPanelV1 {name: 'zwp_input_panel_v1', id: '$objectId', version: '1',}";
  }

  ///
  ///
  /// [id]:
  /// [surface]:
  ZwpInputPanelSurfaceV1 getInputPanelSurface(Surface surface) {
    var id = ZwpInputPanelSurfaceV1(innerContext);
    logLn("ZwpInputPanelV1::getInputPanelSurface  id: $id surface: $surface");
    var arguments = [id, surface];
    var argTypes = <WaylandType>[WaylandType.newId, WaylandType.object];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 0])
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
class ZwpInputPanelSurfaceV1 extends Proxy {
  final Context innerContext;
  final version = 1;

  ZwpInputPanelSurfaceV1(this.innerContext)
      : super(innerContext.allocateClientId()) {
    innerContext.register(this);
  }

  @override
  toString() {
    return "ZwpInputPanelSurfaceV1 {name: 'zwp_input_panel_surface_v1', id: '$objectId', version: '1',}";
  }

  /// set the surface type as a keyboard
  ///
  /// Set the input_panel_surface type to keyboard.
  ///
  /// A keyboard surface is only shown when a text input is active.
  ///
  /// [output]:
  /// [position]:
  void setToplevel(Output output, int position) {
    logLn(
        "ZwpInputPanelSurfaceV1::setToplevel  output: $output position: $position");
    var arguments = [output, position];
    var argTypes = <WaylandType>[WaylandType.object, WaylandType.uint];
    var calclulatedSize = calculateSize(argTypes, arguments);
    final bytesBuilder = BytesBuilder();
    bytesBuilder.add(
        Uint32List.fromList([objectId, (calclulatedSize << 16) | 0])
            .buffer
            .asUint8List());
    bytesBuilder
        .add(Uint32List.fromList([output.objectId]).buffer.asUint8List());
    bytesBuilder.add(Uint32List.fromList([position]).buffer.asUint8List());
    innerContext.sendMessage(bytesBuilder.toBytes());
  }

  /// set the surface type as an overlay panel
  ///
  /// Set the input_panel_surface to be an overlay panel.
  ///
  /// This is shown near the input cursor above the application window when
  /// a text input is active.
  ///
  void setOverlayPanel() {
    logLn("ZwpInputPanelSurfaceV1::setOverlayPanel ");
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

enum ZwpInputPanelSurfaceV1Position {
  ///
  centerBottom("center_bottom", 0);

  const ZwpInputPanelSurfaceV1Position(this.enumName, this.enumValue);
  final int enumValue;
  final String enumName;
  @override
  toString() {
    return "ZwpInputPanelSurfaceV1Position {name: $enumName, value: $enumValue}";
  }
}
