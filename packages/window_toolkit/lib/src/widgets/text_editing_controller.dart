import '../widget.dart';

class TextEditingController {
  String _text = '';
  int _cursor = 0;
  int _selectionStart = -1;
  int _selectionEnd = -1;
  VoidCallback? onChanged;

  TextEditingController({String text = ''}) : _text = text, _cursor = text.length;

  String get text => _text;
  set text(String value) {
    _text = value;
    _cursor = _text.length;
    _selectionStart = -1;
    _selectionEnd = -1;
    onChanged?.call();
  }

  int get cursor => _cursor;
  set cursor(int pos) {
    _cursor = pos.clamp(0, _text.length);
    _selectionStart = -1;
    _selectionEnd = -1;
  }

  bool get hasSelection => _selectionStart >= 0;
  String get selectedText => hasSelection
      ? _text.substring(_selectionStart, _selectionEnd)
      : '';

  void insert(String char) {
    if (hasSelection) _deleteSelection();
    _text = _text.substring(0, _cursor) + char + _text.substring(_cursor);
    _cursor += char.length;
    onChanged?.call();
  }

  void deleteLeft() {
    if (hasSelection) { _deleteSelection(); return; }
    if (_cursor <= 0) return;
    _text = _text.substring(0, _cursor - 1) + _text.substring(_cursor);
    _cursor--;
    onChanged?.call();
  }

  void deleteRight() {
    if (hasSelection) { _deleteSelection(); return; }
    if (_cursor >= _text.length) return;
    _text = _text.substring(0, _cursor) + _text.substring(_cursor + 1);
    onChanged?.call();
  }

  void _deleteSelection() {
    if (!hasSelection) return;
    final start = _selectionStart < _selectionEnd ? _selectionStart : _selectionEnd;
    final end = _selectionStart < _selectionEnd ? _selectionEnd : _selectionStart;
    _text = _text.substring(0, start) + _text.substring(end);
    _cursor = start;
    _selectionStart = -1;
    _selectionEnd = -1;
    onChanged?.call();
  }

  void moveCursorLeft() { if (_cursor > 0) _cursor--; _selectionStart = -1; _selectionEnd = -1; }
  void moveCursorRight() { if (_cursor < _text.length) _cursor++; _selectionStart = -1; _selectionEnd = -1; }
  void moveCursorHome() { _cursor = 0; _selectionStart = -1; _selectionEnd = -1; }
  void moveCursorEnd() { _cursor = _text.length; _selectionStart = -1; _selectionEnd = -1; }

  bool handleKey(KeyEvent event) {
    if (!event.isPressed) return false;
    if (event.character != null && event.character!.isNotEmpty) {
      insert(event.character!);
      return true;
    }
    switch (event.key) {
      case 42: // backspace
        deleteLeft();
        return true;
      case 14: // backspace (non-linux)
        deleteLeft();
        return true;
      case 105: // left
        moveCursorLeft();
        return true;
      case 106: // right
        moveCursorRight();
        return true;
      case 102: // home
        moveCursorHome();
        return true;
      case 107: // end
        moveCursorEnd();
        return true;
      default:
        return false;
    }
  }
}
