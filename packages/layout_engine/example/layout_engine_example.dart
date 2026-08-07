/// Demonstrates core layout_engine primitives without a paint backend.
///
/// Run from the package root:
///
/// ```bash
/// dart run example/layout_engine_example.dart
/// ```
library;

import 'package:layout_engine/layout_engine.dart';

/// Leaf that wants [preferred] but always respects constraints.
class FixedBox extends RenderBox {
  FixedBox(this.preferred, {this.name = '?'});
  final Size preferred;
  final String name;

  @override
  void layout(BoxConstraints constraints) {
    this.constraints = constraints;
    size = constraints.constrain(preferred);
  }

  @override
  String toString() =>
      'FixedBox($name ${size.width.toStringAsFixed(0)}×${size.height.toStringAsFixed(0)}'
      ' @ ${offset.dx.toStringAsFixed(0)},${offset.dy.toStringAsFixed(0)})';
}

void dump(String title, RenderObject root) {
  print('--- $title ---');
  // layout_engine TreeDump (same helper used by window_toolkit).
  root.dumpTree(writeln: print);
  print('');
}

void demoFlexRow() {
  final row = RenderRow(gap: 8, mainAxisSize: MainAxisSize.max);
  final a = FixedBox(const Size(40, 24), name: 'A');
  final flex = FixedBox(const Size(0, 24), name: 'flex')
    ..parentData = const FlexParentData(flex: 1);
  final b = FixedBox(const Size(40, 24), name: 'B');
  row
    ..attach(a)
    ..attach(flex)
    ..attach(b);
  row.layout(const BoxConstraints(maxWidth: 300, maxHeight: 48));
  dump('Flex row (Expanded in the middle)', row);
}

void demoColumnStretch() {
  final col = RenderColumn(
    gap: 6,
    crossAxisAlignment: CrossAxisAlignment.stretch,
  );
  col.attach(FixedBox(const Size(20, 16), name: 'short'));
  col.attach(FixedBox(const Size(80, 16), name: 'wide'));
  final pad = RenderPadding(padding: const EdgeInsets.all(12))..attach(col);
  pad.layout(const BoxConstraints(maxWidth: 200));
  dump('Padding + column stretch', pad);
}

void demoAlign() {
  final child = FixedBox(const Size(40, 20), name: 'chip');
  final align = RenderPositionedBox(alignment: Alignment.center)..attach(child);
  align.layout(const BoxConstraints.tightFor(width: 200, height: 100));
  dump('Centered chip in 200×100', align);
}

void demoConstrained() {
  final box = RenderConstrainedBox(
    additionalConstraints: BoxConstraints.tightFor(width: 64, height: 32),
  )..attach(FixedBox(const Size(10, 10), name: 'tiny'));
  box.layout(const BoxConstraints(maxWidth: 400, maxHeight: 400));
  dump('SizedBox-style 64×32', box);
}

void demoViewport() {
  final content = FixedBox(const Size(200, 2000), name: 'content');
  final ctrl = ViewportScrollController();
  final vp = RenderViewport(
    controller: ctrl,
    scrollDirection: Axis.vertical,
  )..attach(content);
  vp.layout(const BoxConstraints(maxWidth: 200, maxHeight: 300));
  ctrl.scrollBy(80);
  // Re-layout applies the new controller offset to the child's position.
  vp.layout(const BoxConstraints(maxWidth: 200, maxHeight: 300));
  print('--- Vertical viewport ---');
  print('  viewport: ${vp.size.width}×${vp.size.height}');
  print('  content:  ${content.size.width}×${content.size.height}');
  print('  content.offset.dy: ${content.offset.dy} (scrolled)');
  print('  scroll offset: ${ctrl.offset} / max ${ctrl.maxOffset}');
  print('');
}

void demoWrap() {
  final wrap = RenderWrap(spacing: 8, runSpacing: 8);
  for (var i = 0; i < 5; i++) {
    wrap.attach(FixedBox(Size(36.0 + i * 12, 24), name: 'w$i'));
  }
  wrap.layout(const BoxConstraints(maxWidth: 120));
  dump('Wrap at maxWidth 120', wrap);
}

void demoStack() {
  final stack = RenderStack(alignment: Alignment.center);
  final bg = FixedBox(const Size(100, 80), name: 'bg');
  final badge = FixedBox(const Size(16, 16), name: 'badge')
    ..parentData = const StackParentData(right: 4, top: 4);
  stack
    ..attach(bg)
    ..attach(badge);
  stack.layout(const BoxConstraints(maxWidth: 100, maxHeight: 80));
  dump('Stack with corner badge', stack);
}

void demoCustom() {
  final custom = RenderCustomSingleChildLayout(
    (child, constraints, setSize, setOffset) {
      child!.layout(const BoxConstraints.tightFor(width: 20, height: 20));
      setSize(const Size(100, 100));
      setOffset(const Offset(70, 70));
    },
  )..attach(FixedBox(const Size(20, 20), name: 'dot'));
  custom.layout(const BoxConstraints(maxWidth: 200, maxHeight: 200));
  dump('Custom single-child (badge corner)', custom);
}

void demoFlexFactors() {
  final row = RenderRow(gap: 0, mainAxisSize: MainAxisSize.max);
  final f1 = FixedBox(const Size(0, 20), name: 'flex1')
    ..parentData = const FlexParentData(flex: 1);
  final f3 = FixedBox(const Size(0, 20), name: 'flex3')
    ..parentData = const FlexParentData(flex: 3);
  row
    ..attach(f1)
    ..attach(f3);
  row.layout(const BoxConstraints(maxWidth: 400, maxHeight: 20));
  dump('Flex factors 1:3', row);
}

void main() {
  print('layout_engine examples\n');
  demoFlexRow();
  demoFlexFactors();
  demoColumnStretch();
  demoAlign();
  demoConstrained();
  demoViewport();
  demoWrap();
  demoStack();
  demoCustom();
  print('Done. See README.md and dart doc for full API.');
}
