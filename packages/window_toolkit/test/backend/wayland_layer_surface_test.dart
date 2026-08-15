import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  test('bar popup placement measures gap from the reserved bar edge', () {
    final placement = BarPopupPlacement.forBar(
      anchorX: 100,
      parentWidth: 1920,
      width: 300,
      height: 292,
      openUpward: true,
      gap: 4,
    );

    expect(placement.anchors, {LayerEdge.bottom, LayerEdge.left});
    expect(placement.marginLeft, 92);
    expect(placement.marginBottom, 4);
    expect(placement.marginTop, 0);
  });

  test(
    'bar popup placement mirrors horizontal anchoring at the right edge',
    () {
      final placement = BarPopupPlacement.forBar(
        anchorX: 1850,
        parentWidth: 1920,
        width: 260,
        height: 190,
        openUpward: false,
      );

      expect(placement.anchors, {LayerEdge.top, LayerEdge.right});
      expect(placement.marginRight, 4);
      expect(placement.marginTop, 4);
      expect(placement.marginBottom, 0);
    },
  );
}
