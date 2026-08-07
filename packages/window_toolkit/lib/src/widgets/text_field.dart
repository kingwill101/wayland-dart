import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';
import 'text_editing_controller.dart';

class TextField extends Widget {
  TextEditingController controller;
  final Color? _textColor;
  final Color? _bgColor;
  final Color? _cursorColor;
  final Color? _borderColor;
  final Color? _placeholderColor;
  String? placeholder;
  bool obscured;
  bool _focused = false;

  TextField({
    TextEditingController? controller,
    Color? textColor,
    Color? backgroundColor,
    Color? cursorColor,
    Color? borderColor,
    Color? placeholderColor,
    this.placeholder,
    this.obscured = false,
  })  : controller = controller ?? TextEditingController(),
        _textColor = textColor,
        _bgColor = backgroundColor,
        _cursorColor = cursorColor,
        _borderColor = borderColor,
        _placeholderColor = placeholderColor {
    height = 24;
    tabIndex = 1;
    onClick = () { _focused = true; return true; };
  }

  @override
  bool get acceptsFocus => true;

  @override
  void onFocusChanged(bool focused) {
    _focused = focused;
  }

  Color get textColor => _textColor ?? const Color(0xff, 0xff, 0xff);
  Color get bgColor => _bgColor ?? const Color(0x1e, 0x1e, 0x1e);
  Color get cursorColor => _cursorColor ?? const Color(0xc8, 0xc8, 0xc8);
  Color get borderColor => _borderColor ?? const Color(0x50, 0x50, 0x50);
  Color get placeholderColor => _placeholderColor ?? const Color(0x64, 0x64, 0x64);

  String get text => controller.text;

  String get _displayText => obscured ? '•' * text.length : text;

  @override
  void onKeyPressed(KeyEvent event) {
    controller.handleKey(event);
  }

  @override
  void draw(Painter canvas) {
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
      Paint()..color = bgColor,
    );

    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), 1),
      Paint()..color = _focused ? const Color(100, 160, 255) : borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), (y + height - 1).toDouble(), width.toDouble(), 1),
      Paint()..color = _focused ? const Color(100, 160, 255) : borderColor,
    );

    final display = _displayText;
    final isEmpty = display.isEmpty;
    final label = isEmpty ? (placeholder ?? '') : display;
    final labelColor = isEmpty ? placeholderColor : textColor;

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
    );

    const margin = 4;
    canvas.drawText(
      label,
      Offset((x + margin).toDouble(), (y + 4).toDouble()),
      color: labelColor,
      size: 16,
    );

    if (!isEmpty && _focused) {
      final cursorX = x + margin + controller.cursor * 8;
      canvas.drawLine(
        Offset(cursorX.toDouble(), (y + 4).toDouble()),
        Offset(cursorX.toDouble(), (y + height - 4).toDouble()),
        Paint()
          ..color = cursorColor
          ..strokeWidth = 1.5,
      );
    }

    canvas.restore();
  }
}
