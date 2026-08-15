# window_toolkit Style System (GTK CSS catalog)

`window_toolkit` has a **general, typed style system**. CSS is *just one addon*
that injects into it — every provider (theme/palette defaults, programmatic
presets, CSS) contributes typed values to the same model, and `StyleContext`
merges them by priority so the most specific source wins.

This document catalogs the properties we support. It mirrors GTK's CSS
property reference (GTK3 `css-properties.html` + `css-overview.html`), which we
follow so a `Gtk.CssProvider`-style stylesheet behaves as expected.

## Architecture

- `StylePatch` — the **internal** nullable style contribution (a plain object
  of typed fields, one
  per supported property). Widgets read typed values and fall back to the
  palette defaults when a field is unset.
- `Style` — the public concrete style widgets render after the cascade is
  resolved.
- `StyleProvider` — the general injection interface: `StylePatch styleFor(widget, chain)`.
- `StyleContext` — merges every registered `StyleProvider` by priority
  (`apply`, highest priority wins per-property), then fills non-loop gaps.
- `CssProvider implements StyleProvider` — the **CSS addon**. It parses CSS/SCSS
  and maps declarations onto `StylePatch`. Nothing else knows about CSS.
- `Palette` — the theme default provider of color groups; it's the fallback when
  CSS leaves a property unset.

### Cascading / specificity

As in GTK/CSS, matched rules merge with specificity, then source order
(both descending), so `#id` (100) > `.class`/`:pseudo` (10) > `element` (1).
`@define-color` symbolic colors and `inherit/initial/unset` are supported for
color values.

### Colors

`@define-color name value;` defines a symbolic color referenced as `@name`.
`currentColor` resolves to the foreground at use site.

`color` accepts:
- `transparent`, CSS color names (SVG subset),
- `#rgb`, `#rrggbb`, `#rrggbbaa`,
- `rgb()` / `rgba()` with numbers *or* percentages,
- `@name` symbolic references.

## Property catalog

### Color

| Property   | Type      | Notes                              |
|------------|-----------|------------------------------------|
| `color`    | `Color`   | foreground text/icon color         |
| `opacity`  | `double`  | widget opacity (0..1)              |

### Font

| Property           | StylePatch field   | Notes |
|--------------------|--------------------|-------|
| `font-family`      | `fontFamily`       | quoted or bare family name |
| `font-size`        | `fontSize`         | `px` / `pt` lengths; keyword sizes (`small`, `large`, …) |
| `font-style`       | `fontStyle`        | `normal` / `italic` / `oblique` |
| `font-weight`      | `fontWeight`       | `100`–`900`, `normal`(400), `bold`(700), `bolder`, `lighter` |
| `font-variant`     | `fontSmallCaps`    | `small-caps` |
| `letter-spacing`   | `letterSpacing`    | length |
| `font`             | (shorthand)        | `style [weight] size family` |

### Text decoration

| Property                   | Field              | Notes |
|----------------------------|--------------------|-------|
| `text-decoration`          | `textDecoration` / `textDecorationColor` | shorthand |
| `text-decoration-line`     | `textDecoration`   | `none` / `underline` / `line-through` |
| `text-decoration-color`    | `textDecorationColor` | color |

### Box

| Property          | Field(s)                              |
|-------------------|---------------------------------------|
| `padding`         | `padding*` (four-sides shorthand)     |
| `padding-top/right/bottom/left` | per side                  |
| `margin`          | `margin*` (four-sides shorthand)      |
| `margin-top/right/bottom/left` | per side                  |
| `min-width`       | `minWidth`  (`length`)                |
| `min-height`      | `minHeight` (`length`)                |

Shorthand `top right bottom left` semantics (1–4 values) follow CSS/GTK.

### Border

| Property                             | Field(s)                     |
|--------------------------------------|------------------------------|
| `border-width`                       | `border*Width` (4-sides)     |
| `border-style`                       | `border*Style` (4-sides)     |
| `border-color`                       | `border*Color` (4-sides)     |
| `border` / `border-top/right/bottom/left` | width+style+color per side |
| `border-top/right/bottom/left-width/style/color` | per-side      |
| `border-radius`                      | per-corner radius (4-values) |
| `border-top-left/right-radius`, `border-bottom-right/left-radius` | per corner |

`border-style` values: `none`, `solid`, `dotted`, `dashed`, `hidden`,
`groove`, `ridge`, `inset`, `outset`.

### Outline (focus rectangle)

| Property            | Field         |
|---------------------|---------------|
| `outline`           | shortcut      |
| `outline-color`     | `outlineColor` |
| `outline-width`     | `outlineWidth` |
| `outline-style`     | `outlineStyle` |

### Background images / effects

| Property          | Field(s)                                  |
|-------------------|------------------------------------------|
| `background` (shorthand) | `backgroundColor` (when all other layers absent) |
| `background-color` | `backgroundColor`                        |
| `box-shadow`       | `shadowOffsetX/Y`, `shadowBlur`, `shadowColor` (single soft drop shadow) |

## Not yet modeled (GTK parity)

`window_toolkit` renders with Skia; images are planned but not yet in the
model. These GTK properties are intentionally deferred:

- **Image / gradient backgrounds**: `background-image`, `linear-gradient`,
  `radial-gradient`, `-gtk-gradient`, `cross-fade`, `image()`, background size
  / position / repeat / clip / origin, `border-image`.
- **Icon properties**: `-gtk-icon-source`, `-gtk-icon-*`, themed icons.
- **Transitions / animations**: `transition-*`, `animation-*` (see
  `implicit_animation.dart` for the in-tree animation widget).
- **Key bindings**: `@binding-set`, `-gtk-key-bindings`.
- `font-feature-settings`, `font-stretch`, `caret-*`, `-gtk-secondary-caret-color`, `-gtk-dpi`.

Add a property by (1) adding a typed field to `StylePatch` + wiring it into
`apply` / `fillFrom`, (2) adding its declaration mapping in `CssProvider
_styleFromDecls`, and (3) consuming it in the widget's draw. CSS stays an
addon — the widget reads only typed values.

## Using it

```dart
final css = CssProvider();
css.loadFromPath('/path/to/style.css', isScss: false);
StyleContext.addProviderForScreen(css, priority: StyleProviderPriority.user);

// Widgets read ONE concrete entry point — the cascade is centralized in
// `StyleContext.resolveStyle`, nothing CSS-specific lives in widgets:
final st = myWidget.resolvedStyle(); // Style (non-null fields)
st.color;           // CSS `color`  → widget local → role palette
st.backgroundColor; // null = draw no background
```

### How a widget's style resolves (single place)

Every basic widget applies the same three-stage pipeline, all folded in
`Widget.resolvedStyle()` / `Widget.resolvedStyleOn(['hover'])`:

1. **Role defaults** — `styleRole()` returns the widget's inherited
   global-palette colors (e.g. `Button` → button/buttonText, `Label` → text,
   tooltip shell → tooltipBase/tooltipText).
2. **Providers / CSS addon** — registered `StyleProvider`s (CSS is just one)
   merge by priority; more specific selectors win.
3. **Widget-local override** — `localOverrides()` registers the widget's own
   constructor fields (its own colors, radius, …) so *inherit the global
   palette* and *inherit-and-override* are the same code path.

Widget `draw()` implementations contain no CSS code and no re-merging — they
only read concrete `resolvedStyle()` values (`color`, `backgroundColor`,
`borderColor`, `borderWidth`, `borderRadius`). CSS classes/ids are wired on
widgets via `addClass(...)` / `styleId` so selectors like
`.tooltip .calendar .today { color: … }` match through an explicit ancestry
chain.
