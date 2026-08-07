# Render objects

The layout tree is made of `RenderObject` / `RenderBox` nodes.

- Call `attach` to add children.
- Call `layout` with parent `BoxConstraints`.
- Read `size` and `offset` after layout.
- Store per-parent metadata on `parentData`
  (`FlexParentData`, `StackParentData`, …).

Single-child helpers live in `render_basic.dart` and `render_padding.dart`.
Multi-child flex, wrap, and stack live in their own libraries.
