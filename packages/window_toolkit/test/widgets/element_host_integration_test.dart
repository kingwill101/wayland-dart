import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  group('ElementHost integration', () {
    test('hitTest reaches widget inside element tree', () {
      final host = ElementHost(child: _TestButton());
      host.x = 0;
      host.y = 0;
      host.width = 200;
      host.height = 50;

      // Simulate what WidgetWindow.draw does
      host.performLayout(200);

      // The ElementHost should delegate hit-test to the built widget
      expect(host.hitTest(10, 10), isTrue, reason: 'inside button bounds');
      expect(host.hitTest(200, 200), isFalse, reason: 'outside bounds');
    });

    test('children exposes built widget for event traversal', () {
      final host = ElementHost(child: _TestButton());
      host.performLayout(200);

      expect(
        host.children,
        hasLength(1),
        reason: 'ElementHost should expose built widget',
      );
      expect(
        host.children.first,
        isA<_TestButtonRender>(),
        reason: 'built widget should be the render output',
      );
    });

    test('onClick fires through element tree', () {
      bool clicked = false;
      final btn = _TestButton(onClick: () => clicked = true);
      final host = ElementHost(child: btn);
      host.x = 0;
      host.y = 0;
      host.width = 200;
      host.height = 50;
      host.performLayout(200);

      // The button's onClick fires through the render widget
      // when it's hit-tested via ElementHost
      expect(host.children.first.onClick, isNotNull);
      host.children.first.onClick!();
      expect(clicked, isTrue);
    });
  });

  test('performs layout with correct size propagation', () {
    final host = ElementHost(child: _SizedBox(size: 100));
    host.x = 5;
    host.y = 10;
    host.width = 200;
    host.height = 100;
    host.performLayout(200);

    // ElementHost should reflect the renderable widget's size
    expect(
      host.width,
      greaterThan(0),
      reason: 'width should be set from renderable widget',
    );
    expect(
      host.height,
      greaterThan(0),
      reason: 'height should be set from renderable widget',
    );

    // The renderable widget should have received the position
    final render = host.children.first;
    expect(render.x, 5, reason: 'x should propagate to renderable');
    expect(render.y, 10, reason: 'y should propagate to renderable');
  });

  test('renders ScrollArea with correct height', () {
    final host = ElementHost(child: _ScrollContainer());
    host.x = 0;
    host.y = 0;
    host.width = 400;
    host.height = 300;
    host.performLayout(400);

    // The ScrollArea should have non-zero height from the host
    expect(host.height, 300, reason: 'height should match the host height');

    // The renderable should be a ScrollArea
    final render = host.children.first;
    expect(
      render,
      isA<ScrollArea>(),
      reason: 'renderable should be ScrollArea',
    );
  });
}

class _SizedBox extends StatelessWidget {
  final double size;
  _SizedBox({this.size = 50});

  @override
  ElementWidget build(BuildContext context) {
    return SizedBox(width: size.round(), height: size.round());
  }
}

class _ScrollContainer extends StatelessWidget {
  @override
  ElementWidget build(BuildContext context) {
    return ScrollArea(
      child: SizedBox(width: 200, height: 1000),
      showVertical: true,
    );
  }
}

class _TestButton extends StatefulWidget {
  final VoidCallback? onClick;
  _TestButton({this.onClick});

  @override
  State createState() => _TestButtonState();
}

class _TestButtonState extends State<_TestButton> {
  @override
  ElementWidget build(BuildContext context) {
    return _TestButtonRender(onClick: widget.onClick);
  }
}

class _TestButtonRender extends Widget {
  final VoidCallback? onTap;
  _TestButtonRender({VoidCallback? onClick}) : onTap = onClick {
    this.onClick = () {
      onTap?.call();
      return true;
    };
  }

  @override
  void draw(Painter canvas) {
    canvas.drawRect(
      Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        width.toDouble(),
        height.toDouble(),
      ),
      Paint()..color = const Color(100, 100, 100),
    );
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    height = 30;
  }
}
