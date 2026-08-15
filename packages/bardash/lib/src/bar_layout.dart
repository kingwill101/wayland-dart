import 'package:window_toolkit/window_toolkit.dart';

/// Bardash's three-region composition, built from toolkit primitives.
///
/// The region policy belongs to Bardash, but every child remains an ordinary
/// toolkit widget. This keeps mounting, CSS ancestry, hover, hit-testing, and
/// repaint ownership on the shared widget path.
class BarLayout extends Stack {
  final HBox left;
  final HBox center;
  final HBox right;

  BarLayout({int spacing = 0})
    : left = HBox(spacing: spacing),
      center = HBox(spacing: spacing),
      right = HBox(spacing: spacing),
      super(children: [], fitExpand: true) {
    children.addAll([
      Positioned(left: 0, top: 0, child: left),
      Positioned(left: 0, right: 0, top: 0, child: Center(child: center)),
      Positioned(right: 0, top: 0, child: right),
    ]);
  }
}
