# Geometry

Pure value types used by every layout pass: positions (`Offset`), extents
(`Size`), rectangles (`Rect`), insets (`EdgeInsets`), and constraint ranges
(`BoxConstraints`).

Constraints flow **down** the tree; sizes flow **up**. Prefer
`BoxConstraints.tighten`, `loosen`, `enforce`, and `deflate` over ad-hoc
min/max arithmetic.
