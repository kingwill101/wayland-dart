# layout_engine

Framework-agnostic, **constraint-based** layout for Dart.

Geometry, render objects (flex, padding, wrap, stack, scroll, align, constrain),
and an optional Element/State tree — **no painting or windowing dependency**.
Host toolkits (e.g. [`window_toolkit`](../window_toolkit)) adapt paintables into
`RenderBox` nodes, call `layout`, then paint from `size` / `offset`.

## Install

```yaml
dependencies:
  layout_engine:
    path: ../layout_engine   # or your package source
```

```dart
import 'package:layout_engine/layout_engine.dart';
```

## Mental model

1. Parent offers **`BoxConstraints`** (min/max width & height).
2. Child picks a **`Size`** inside those bounds.
3. Parent places the child with an **`Offset`**.

Always re-layout when the parent size changes. Do **not** stick to a previous
frame’s width when the max constraint grows (window resize, larger viewport).

```
┌─ parent constraints ─────────────────────┐
│  minW ≤ child.width  ≤ maxW              │
│  minH ≤ child.height ≤ maxH              │
│         ┌─ child ─┐                      │
│         │ size    │ offset from parent   │
│         └─────────┘                      │
└──────────────────────────────────────────┘
```

## Quick examples

### Fixed leaf + row with flex

```dart
class FixedBox extends RenderBox {
  FixedBox(this.preferred);
  final Size preferred;

  @override
  void layout(BoxConstraints constraints) {
    this.constraints = constraints;
    size = constraints.constrain(preferred);
  }
}

final row = RenderRow(gap: 8, mainAxisSize: MainAxisSize.max);
final a = FixedBox(const Size(40, 24));
final flex = FixedBox(const Size(0, 24))
  ..parentData = const FlexParentData(flex: 1);
final b = FixedBox(const Size(40, 24));

row
  ..attach(a)
  ..attach(flex)
  ..attach(b);

row.layout(const BoxConstraints(maxWidth: 300, maxHeight: 48));
// a at x=0, flex takes leftover, b after flex + gap
```

### Padding + stretched column

```dart
final col = RenderColumn(
  gap: 6,
  crossAxisAlignment: CrossAxisAlignment.stretch,
);
col.attach(FixedBox(const Size(20, 16)));
col.attach(FixedBox(const Size(80, 16)));

final pad = RenderPadding(padding: const EdgeInsets.all(12));
pad.attach(col);
pad.layout(const BoxConstraints(maxWidth: 200));
// Both children laid out with tight width = content width inside padding
```

### Align / center

```dart
final child = FixedBox(const Size(40, 20));
final align = RenderPositionedBox(alignment: Alignment.center)
  ..attach(child);

align.layout(const BoxConstraints.tightFor(width: 200, height: 100));
// child.offset ≈ Offset(80, 40)
```

### Sized box / constraints

```dart
final box = RenderConstrainedBox(
  additionalConstraints: BoxConstraints.tightFor(width: 64, height: 32),
)..attach(FixedBox(const Size(10, 10)));

box.layout(const BoxConstraints(maxWidth: 400, maxHeight: 400));
// box.size == Size(64, 32)
```

### Vertical scroll

```dart
final content = FixedBox(const Size(200, 2000));
final ctrl = ViewportScrollController();
final vp = RenderViewport(
  controller: ctrl,
  scrollDirection: Axis.vertical,
)..attach(content);

vp.layout(const BoxConstraints(maxWidth: 200, maxHeight: 300));
// Child: tight width 200, unbounded height
// Viewport size: 200×300
ctrl.scrollBy(50);
```

### Wrap

```dart
final wrap = RenderWrap(spacing: 8, runSpacing: 8);
for (var i = 0; i < 6; i++) {
  wrap.attach(FixedBox(Size(40.0 + i * 10, 24)));
}
wrap.layout(const BoxConstraints(maxWidth: 120));
// Children flow into multiple runs when they exceed maxWidth
```

### Stack + positioned child

```dart
final stack = RenderStack(alignment: Alignment.center);
final bg = FixedBox(const Size(100, 100));
final badge = FixedBox(const Size(16, 16))
  ..parentData = const StackParentData(right: 4, top: 4);
stack
  ..attach(bg)
  ..attach(badge);
stack.layout(const BoxConstraints(maxWidth: 100, maxHeight: 100));
```

### Custom single-child layout

```dart
final custom = RenderCustomSingleChildLayout((child, constraints, setSize, setOffset) {
  child!.layout(const BoxConstraints.tightFor(width: 24, height: 24));
  setSize(const Size(100, 100));
  setOffset(const Offset(76, 76)); // bottom-right-ish badge
});
custom.attach(FixedBox(const Size(24, 24)));
custom.layout(const BoxConstraints(maxWidth: 200, maxHeight: 200));
```

### Element tree (stateful rebuilds)

```dart
class Counter extends StatefulWidget {
  @override
  State createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int n = 0;
  @override
  ElementWidget build(BuildContext context) {
    // Host toolkit turns this into a paintables widget.
    return /* Label('Count: $n') */ this as ElementWidget; // illustrative
  }
  void inc() => setState(() => n++);
}

final tree = ElementTree()
  ..onNeedsBuild = () { /* schedule repaint */ }
  ..mount(Counter());
tree.build();
```

## API map

### Geometry (`geometry.dart`)

| Type | Purpose |
|------|---------|
| `Offset`, `Size`, `Rect` | Positions and extents |
| `EdgeInsets` | Padding/margin; `deflateSize` / `inflateSize` |
| `BoxConstraints` | min/max ranges; `tighten`, `loosen`, `enforce`, `deflate` |
| `HitTestResult` / `HitTestEntry` | Hit-test path |

Useful factories:

- `BoxConstraints.tightFor(width:, height:)` — fixed size  
- `BoxConstraints.expand()` — fill  
- `BoxConstraints.loose` — unbounded  

### Render objects

| Object | Role |
|--------|------|
| `RenderObject` / `RenderBox` | Tree node: `layout`, `size`, `offset`, `parentData` |
| `RenderDelegateBox` | Callback-based leaf/host adapter |
| `RenderRow` / `RenderColumn` | Flex; flex factor via `FlexParentData` |
| `RenderPadding` | Insets via `EdgeInsets` |
| `RenderConstrainedBox` | SizedBox / ConstrainedBox |
| `RenderPositionedBox` | Align / Center |
| `RenderAspectRatio` | Fixed aspect |
| `RenderLimitedBox` | Soft max when parent unbounded |
| `RenderFractionallySizedBox` | Fraction of parent |
| `RenderRotatedBox` | Quarter-turn layout (axes swap) |
| `RenderCustomSingleChildLayout` | One-off geometry |
| `RenderStack` | Layered children; `StackParentData` |
| `RenderWrap` | Flow into runs |
| `RenderViewport` | Clip + scroll; tight cross-axis |
| `RenderList` | Vertical list content for scroll |

### Flex notes

- Set `child.parentData = FlexParentData(flex: n)` for expandable children.
- Space is split by **total flex factor**, not head-count.
- Flex does **not** expand on an **unbounded** main axis (intrinsic only).
- `CrossAxisAlignment.stretch` re-lays out children with a tight cross-axis.

### Viewport notes

Vertical scroll gives the child:

- **tight width** = viewport width  
- **unbounded height**  

Horizontal scroll swaps axes. Viewport size is the constraint box, not the
content size.

### Text measurement

Some hosts may set a global measure for future text-aware layout:

```dart
TextMeasureScope.set(MySkiaTextMeasure());
// TextMeasureScope.current.textWidth('Hello')
```

### Widget framework

- `ElementWidget`, `StatelessWidget`, `StatefulWidget`, `State`, `InheritedWidget`
- `ElementTree`, `BuildOwner`, `BuildContext`
- Keys: `WidgetKey`, `ValueWidgetKey`, `UniqueWidgetKey`

Used for lifecycle (`initState` / `setState` / `dispose`) independent of paint.

## Integrating with window_toolkit

`window_toolkit` adapters implement `RenderBox.layout` by calling
`Widget.performLayout` and reporting size. Containers such as `VBox`, `Padding`,
`ScrollArea`, and `Card` host these layout objects so sizing math stays in this
package.

Rules of thumb for adapters:

1. Always honor **parent constraints** (never sticky previous width).  
2. Wire **`FlexParentData`** for flex children.  
3. Leaf controls keep **intrinsic** size under loose max; containers fill max.  
4. After layout, copy `offset` / `size` back onto paintables.

## Examples

Runnable samples live under [`example/`](example/):

```bash
cd packages/layout_engine
dart run example/layout_engine_example.dart
```

## Tree dumps

Debug helpers live in this package (not the host toolkit):

```dart
// RenderObject
row.dumpTree();                    // stderr
print(row.formatTree());

// Element
elementTree.root?.dumpTree();

// Generic (any host tree)
TreeDump.write(
  label: 'root',
  children: kids,
  labelOf: (n) => n.toString(),
  childrenOf: (n) => ...,
);
```

`window_toolkit` [Widget.dumpTree] / [Widget.formatTree] delegate to [TreeDump].

## Tests

```bash
dart test
```

## Documentation

Generate API docs:

```bash
dart doc .
# open doc/api/index.html
```

## License

Same as the monorepo workspace.
