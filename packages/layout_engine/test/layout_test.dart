import 'package:test/test.dart';
import 'package:layout_engine/layout_engine.dart';

/// A test text measure — monospace approximation.
class _TestTextMeasure extends TextMeasure {
  @override
  double textWidth(String text) => text.length * 8.0;
  @override
  double get lineHeight => 16.0;
}

/// A test render object with a fixed size (simulates a button/label).
class _FixedSizeBox extends RenderBox {
  final double fixedWidth;
  final double fixedHeight;
  _FixedSizeBox(this.fixedWidth, this.fixedHeight);

  @override
  void layout(BoxConstraints constraints) {
    size = constraints.constrain(Size(fixedWidth, fixedHeight));
  }
}

void main() {
  setUp(() {
    TextMeasureScope.set(_TestTextMeasure());
  });

  group('BoxConstraints', () {
    test('constrain clamps to bounds', () {
      final c = BoxConstraints(minWidth: 10, maxWidth: 100, minHeight: 10, maxHeight: 100);
      expect(c.constrain(Size(5, 5)), Size(10, 10));
      expect(c.constrain(Size(50, 50)), Size(50, 50));
      expect(c.constrain(Size(200, 200)), Size(100, 100));
    });

    test('loosen sets min to 0', () {
      final c = BoxConstraints(minWidth: 50, minHeight: 50, maxWidth: 100, maxHeight: 100);
      final loosened = c.loosen();
      expect(loosened.minWidth, 0);
      expect(loosened.minHeight, 0);
      expect(loosened.maxWidth, 100);
    });

    test('hasBoundedWidth', () {
      expect(BoxConstraints(maxWidth: 100).hasBoundedWidth, isTrue);
      expect(BoxConstraints().hasBoundedWidth, isFalse);
    });
  });

  group('RenderRow', () {
    test('lays out children horizontally', () {
      final row = RenderRow(gap: 4);
      final a = _FixedSizeBox(30, 20);
      final b = _FixedSizeBox(50, 20);
      row.attach(a);
      row.attach(b);
      row.layout(BoxConstraints(maxWidth: 200, maxHeight: 100));

      expect(row.size.width, 84); // 30 + 4 + 50
      expect(row.size.height, 20);
      expect(a.offset.dx, 0);
      expect(b.offset.dx, 34); // 30 + 4
    });

    test('stretches to max width when mainAxisSize=max', () {
      final row = RenderRow(gap: 0, mainAxisSize: MainAxisSize.max);
      final a = _FixedSizeBox(30, 20);
      row.attach(a);
      row.layout(BoxConstraints(maxWidth: 200, maxHeight: 100));

      expect(row.size.width, 200);
    });
  });

  group('RenderColumn', () {
    test('lays out children vertically', () {
      final col = RenderColumn(gap: 8);
      final a = _FixedSizeBox(100, 30);
      final b = _FixedSizeBox(100, 50);
      col.attach(a);
      col.attach(b);
      col.layout(BoxConstraints(maxWidth: 200, maxHeight: 200));

      expect(col.size.height, 88); // 30 + 8 + 50
      expect(a.offset.dy, 0);
      expect(b.offset.dy, 38); // 30 + 8
    });
  });

  group('RenderPadding', () {
    test('insets child by given amounts', () {
      final pad = RenderPadding(left: 10, top: 20, right: 10, bottom: 20);
      final child = _FixedSizeBox(50, 30);
      pad.attach(child);
      pad.layout(BoxConstraints(maxWidth: 200, maxHeight: 200));

      expect(child.offset.dx, 10);
      expect(child.offset.dy, 20);
      expect(pad.size.width, 70); // 50 + 10 + 10
      expect(pad.size.height, 70); // 30 + 20 + 20
    });

    test('zero padding passes through', () {
      final pad = RenderPadding();
      final child = _FixedSizeBox(50, 30);
      pad.attach(child);
      pad.layout(BoxConstraints(maxWidth: 200, maxHeight: 200));

      expect(child.offset.dx, 0);
      expect(child.offset.dy, 0);
      expect(pad.size.width, 50);
    });
  });

  group('HitTest', () {
    test('hitTest returns deep child', () {
      final row = RenderRow(gap: 4);
      final a = _FixedSizeBox(30, 20);
      final b = _FixedSizeBox(50, 20);
      row.attach(a);
      row.attach(b);
      row.layout(BoxConstraints(maxWidth: 200, maxHeight: 100));

      final result = HitTestResult();
      expect(row.hitTest(result, localX: 10, localY: 10), isTrue);
      expect(result.path.first.target, a);

      result.clear();
      expect(row.hitTest(result, localX: 35, localY: 10), isTrue);
      expect(result.path.first.target, b);

      result.clear();
      expect(row.hitTest(result, localX: 100, localY: 10), isFalse); // past end
    });
  });
}
