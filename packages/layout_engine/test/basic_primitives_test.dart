import 'package:test/test.dart';
import 'package:layout_engine/layout_engine.dart';

class _Fixed extends RenderBox {
  final double w;
  final double h;
  _Fixed(this.w, this.h);

  @override
  void layout(BoxConstraints constraints) {
    this.constraints = constraints;
    size = constraints.constrain(Size(w, h));
  }
}

void main() {
  group('EdgeInsets', () {
    test('all / symmetric / deflateSize', () {
      const e = EdgeInsets.all(8);
      expect(e.horizontal, 16);
      expect(e.vertical, 16);
      expect(e.deflateSize(const Size(100, 50)), const Size(84, 34));

      const s = EdgeInsets.symmetric(horizontal: 10, vertical: 4);
      expect(s.left, 10);
      expect(s.top, 4);
    });
  });

  group('BoxConstraints helpers', () {
    test('tightFor and enforce', () {
      final c = BoxConstraints.tightFor(width: 100, height: 40);
      expect(c.isTight, isTrue);
      expect(c.constrain(const Size(10, 10)), const Size(100, 40));

      final loose = const BoxConstraints(maxWidth: 200, maxHeight: 200);
      final enforced = loose.enforce(const BoxConstraints(
        minWidth: 50,
        maxWidth: 80,
        minHeight: 10,
        maxHeight: 90,
      ));
      expect(enforced.minWidth, 50);
      expect(enforced.maxWidth, 80);
    });

    test('deflate by EdgeInsets', () {
      final c = const BoxConstraints(maxWidth: 100, maxHeight: 50)
          .deflate(const EdgeInsets.all(10));
      expect(c.maxWidth, 80);
      expect(c.maxHeight, 30);
    });

    test('constrainWidth / Height', () {
      final c = const BoxConstraints(minWidth: 10, maxWidth: 100);
      expect(c.constrainWidth(5), 10);
      expect(c.constrainWidth(50), 50);
      expect(c.constrainWidth(200), 100);
    });
  });

  group('RenderConstrainedBox', () {
    test('forces minimum size', () {
      final box = RenderConstrainedBox(
        additionalConstraints: const BoxConstraints(minWidth: 120, minHeight: 40),
      );
      box.attach(_Fixed(20, 10));
      box.layout(const BoxConstraints(maxWidth: 200, maxHeight: 200));
      expect(box.size.width, 120);
      expect(box.size.height, 40);
      expect(box.child!.size.width, 120);
    });

    test('SizedBox-style tight size', () {
      final box = RenderConstrainedBox(
        additionalConstraints: BoxConstraints.tightFor(width: 64, height: 32),
      );
      box.attach(_Fixed(10, 10));
      box.layout(const BoxConstraints(maxWidth: 400, maxHeight: 400));
      expect(box.size, const Size(64, 32));
      expect(box.child!.size, const Size(64, 32));
    });
  });

  group('RenderPositionedBox', () {
    test('centers child in expanded bounds', () {
      final align = RenderPositionedBox(alignment: Alignment.center);
      final child = _Fixed(40, 20);
      align.attach(child);
      align.layout(const BoxConstraints.tightFor(width: 200, height: 100));

      expect(align.size, const Size(200, 100));
      expect(child.offset.dx, 80); // (200-40)/2
      expect(child.offset.dy, 40); // (100-20)/2
    });

    test('bottomRight alignment', () {
      final align = RenderPositionedBox(alignment: Alignment.bottomRight);
      final child = _Fixed(30, 10);
      align.attach(child);
      align.layout(const BoxConstraints.tightFor(width: 100, height: 50));
      expect(child.offset.dx, 70);
      expect(child.offset.dy, 40);
    });

    test('heightFactor sizes to child when unbounded height', () {
      final align = RenderPositionedBox(
        alignment: Alignment.center,
        heightFactor: 1,
      );
      align.attach(_Fixed(50, 24));
      align.layout(const BoxConstraints(maxWidth: 200));
      expect(align.size.width, 200);
      expect(align.size.height, 24);
    });
  });

  group('RenderAspectRatio', () {
    test('16:9 within max bounds', () {
      final box = RenderAspectRatio(aspectRatio: 16 / 9);
      box.attach(_Fixed(1, 1));
      box.layout(const BoxConstraints(maxWidth: 320, maxHeight: 400));
      expect(box.size.width, 320);
      expect(box.size.height, closeTo(180, 0.5));
    });
  });

  group('RenderLimitedBox', () {
    test('caps unbounded max', () {
      final box = RenderLimitedBox(maxWidth: 100, maxHeight: 50);
      box.attach(_Fixed(1000, 1000));
      box.layout(const BoxConstraints()); // unbounded
      expect(box.child!.size.width, 100);
      expect(box.child!.size.height, 50);
    });

    test('does not shrink bounded parent', () {
      final box = RenderLimitedBox(maxWidth: 100, maxHeight: 50);
      box.attach(_Fixed(80, 40));
      box.layout(const BoxConstraints(maxWidth: 400, maxHeight: 300));
      expect(box.child!.size.width, 80);
    });
  });

  group('RenderFractionallySizedBox', () {
    test('half width child', () {
      final box = RenderFractionallySizedBox(widthFactor: 0.5, heightFactor: 1);
      final child = _Fixed(10, 10);
      box.attach(child);
      box.layout(const BoxConstraints.tightFor(width: 200, height: 80));
      expect(child.size.width, 100);
      expect(child.size.height, 80);
      expect(box.size, const Size(200, 80));
    });
  });

  group('RenderPadding + EdgeInsets', () {
    test('deflates child constraints via EdgeInsets', () {
      final pad = RenderPadding(padding: const EdgeInsets.all(12));
      final child = _Fixed(50, 30);
      pad.attach(child);
      pad.layout(const BoxConstraints(maxWidth: 200, maxHeight: 200));
      expect(child.offset, const Offset(12, 12));
      expect(pad.size.width, 74);
      expect(pad.size.height, 54);
    });
  });

  group('RenderFlex cross-axis stretch', () {
    test('column stretch gives children full width', () {
      final col = RenderColumn(crossAxisAlignment: CrossAxisAlignment.stretch);
      final a = _Fixed(20, 10);
      final b = _Fixed(40, 10);
      col.attach(a);
      col.attach(b);
      col.layout(const BoxConstraints(maxWidth: 200, maxHeight: 100));

      expect(col.size.width, 200);
      expect(a.size.width, 200);
      expect(b.size.width, 200);
    });

    test('row stretch gives children full height', () {
      final row = RenderRow(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
      );
      final a = _Fixed(30, 10);
      row.attach(a);
      row.layout(const BoxConstraints(maxWidth: 200, maxHeight: 60));
      expect(row.size.height, 60);
      expect(a.size.height, 60);
    });
  });

  group('RenderCustomSingleChildLayout', () {
    test('delegate positions child', () {
      final custom = RenderCustomSingleChildLayout((child, constraints, setSize, setOffset) {
        child!.layout(const BoxConstraints.tightFor(width: 20, height: 20));
        setSize(const Size(100, 100));
        setOffset(const Offset(40, 40));
      });
      final child = _Fixed(20, 20);
      custom.attach(child);
      custom.layout(const BoxConstraints(maxWidth: 200, maxHeight: 200));
      expect(custom.size, const Size(100, 100));
      expect(child.offset, const Offset(40, 40));
    });
  });

  group('RenderProxyBox', () {
    test('sizes to child', () {
      final proxy = RenderProxyBox();
      proxy.attach(_Fixed(33, 44));
      proxy.layout(const BoxConstraints(maxWidth: 100, maxHeight: 100));
      expect(proxy.size, const Size(33, 44));
    });
  });
}
