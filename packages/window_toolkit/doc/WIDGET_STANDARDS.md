# Widget standards (window_toolkit)

Standards derived from layout_engine integration work. All new and touched
widgets should meet these.

## 1. Layout

| Rule | Detail |
|------|--------|
| Prefer `layout_engine` | Containers use `RenderRow` / `RenderColumn` / `RenderPadding` / `RenderWrap` / `RenderStack` / `RenderViewport` / `RenderConstrainedBox` / `RenderPositionedBox` via `RenderWidgetBox`. |
| No sticky sizes | Never treat previous `width`/`height` as intrinsic after a clamp. Leaves recompute preferred size from content each `performLayout`. |
| Constraints flow down | Parent max width always available to children; growing the parent must re-expand. |
| Cross-axis stretch | Vertical stacks that fill width use `CrossAxisAlignment.stretch`. |
| Adapter | Use shared `lib/src/layout/render_widget_box.dart` — do not reintroduce `widget.width > 0 ? widget.width : max`. |

## 2. Text

| Rule | Detail |
|------|--------|
| Rect-aligned draw | Use `Painter.drawTextInRect` / `drawTextBlockInRect` (or `TextLayout.drawInRect`), not raw `drawText` + hand-tuned `y + 4`. |
| Alignment | Prefer `TextOption.center` (buttons/chips), `TextOption.leftCenter` (rows, labels), or explicit `TextAlign`. |
| Elide | When space can be tight: `TextElideMode.right` (or only when width was clamped). |
| Clip | Clip to the control bounds when text might overflow. |
| Metrics | Prefer `measureTextFont` / `FontMetrics.horizontalAdvance` for layout width. |

## 3. Structure

| Rule | Detail |
|------|--------|
| `performLayout` | Containers implement it; leaves either implement (intrinsic + clamp) or use base. |
| `children` / `dumpChildren` | Composite widgets expose children for hit-test and `TreeDump`. |
| Dump | Use `dumpTree` / `formatTree` from layout_engine `TreeDump` (via `Widget`). |
| Paint | Draw chrome first, then children; avoid layout-only work in `draw` when possible (or call `performLayout` once if needed). |

## 4. Checklist for PR review

- [ ] Layout math in layout_engine or justified exception (e.g. pure paint chrome)
- [ ] No sticky width after clamp
- [ ] Text uses `drawTextInRect` + `TextOption` when label is in a box
- [ ] Overflow: elide and/or clip
- [ ] `dart test` for the widget still green

## Status snapshot (text + layout)

### Layout: on layout_engine (OK)

Align, Center, Padding, SizedBox, ConstrainedBox, VBox, HBox, Flex/Row/Column,
VBoxLayout, Wrap, Stack, ScrollArea, Frame, DecoratedBox, Card, GroupBox,
ListView, Dialog (button strip), ElementHost.

### Text: uses `drawTextInRect` (OK)

Button, Label, Chip, Badge, ToggleButton, SegmentedControl, MenuItem, TabBar,
RadioButton, Dropdown, ListBox, ProgressBar, Dialog (+ DialogButton), Card
title, GroupBox title, Slider value, Tooltip.

### Text: resolved

| Widget | Notes |
|--------|--------|
| TextField | `drawTextInRect` + metric-based caret; no elide while editing |
| Checkbox / Switch | Optional `label` with `TextOption.leftCenter` |
| Context menu | Delegates to `Menu` / `MenuItem` (rect text) |

### Non-text / N/A

Checkbox/Switch track chrome, Separator, Spinner, IconButton, ImageIcon,
RangeSlider track, Scrollbar, animations, Theme, controllers, popups.

### childrenOf

Prefers `Widget.children` when non-empty; type fallbacks for legacy fields.
Composites should override `children` (VBox, HBox, Flex, Card, … do).
