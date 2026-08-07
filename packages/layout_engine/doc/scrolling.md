# Scrolling

`RenderViewport` clips a single child and applies a scroll offset via
`ScrollController` / `ViewportScrollController`.

Vertical scroll: **tight width**, **unbounded height**.  
Horizontal scroll: **unbounded width**, **tight height**.

`RenderList` lays children out as a tall column suitable as viewport content.
`ScrollbarMetrics` computes thumb geometry without depending on a paint backend.
