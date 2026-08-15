import '../painter/painter.dart';
import '../widget.dart';

/// A fixed-size widget whose pixels are produced by a toolkit [Painter].
///
/// This is useful for widgets that contain charts or other genuinely custom
/// graphics while keeping measurement, clipping, presentation, and input
/// ownership in the normal widget/popup pipeline.
class PainterWidget extends Widget {
  final int preferredWidth;
  final int preferredHeight;
  final void Function(Painter painter) onPaint;

  PainterWidget({
    required this.preferredWidth,
    required this.preferredHeight,
    required this.onPaint,
  }) : assert(preferredWidth > 0),
       assert(preferredHeight > 0);

  @override
  void measure(Painter painter) {
    width = preferredWidth;
    height = preferredHeight;
  }

  @override
  void performLayout(int containerWidth) {
    width = preferredWidth;
    height = preferredHeight;
  }

  @override
  void draw(Painter painter) {
    drawStyledBox(painter);
    onPaint(painter);
  }

  @override
  bool hitTest(int px, int py) =>
      px >= 0 && py >= 0 && px < width && py < height;
}
