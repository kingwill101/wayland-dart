# Widget catalog and interaction contract

This is the audit map for the public widgets in `window_toolkit`. Every
widget should have one deliberate answer for each of these concerns:

1. **Theme** — visual values come from `resolvedStyle()` and
   `resolvedStyleOn(...)`, with constructor values treated as explicit local
   overrides and palette values as the fallback.
2. **Animation** — interactive visual changes use `HoverAnimated` or an
   explicit animation widget. Static layout and data widgets do not need an
   animation controller.
3. **Events** — controls use the `Widget` event API and canonical
   `WidgetState` values. A widget that is not interactive should say so by
   having no handlers, rather than implementing a second event system.

The status markers below describe the current audit state:

| Marker | Meaning |
| --- | --- |
| `yes` | Uses the shared contract for this concern. |
| `partial` | Has a fallback or a local implementation, but still needs migration to the common contract. |
| `no` | Not applicable to this widget, or not implemented where it is required. |

## Layout and composition

These widgets are structural. They should not own hover animations or pointer
activation unless explicitly extended with an interactive child.

| Widget | Theme | Animation | Events | Notes |
| --- | --- | --- | --- | --- |
| `Widget`, `Container`, `Spacer` | no | no | no | Base/structural hosts; visual behavior belongs to descendants or decoration widgets. |
| `Align`, `Center` | no | no | no | Positioning only. |
| `Container` | partial | no | no | Generic child host; background/border should be style-driven when painted. |
| `DecoratedBox` | yes | no | no | Shared style resolver for decoration. |
| `SizedBox`, `ConstrainedBox` | no | no | no | Constraints only. |
| `Padding` | no | no | no | Layout spacing only. |
| `Flex`, `Row`, `Column`, `Flexible`, `Expanded` | no | no | no | Flex layout only. |
| `HBox`, `VBox`, `VBoxLayout` | no | no | no | Bar-oriented layout helpers. |
| `Stack`, `Positioned` | no | no | no | Layered layout only. |
| `WrapLayout` | no | no | no | Flow layout only. |
| `ListView` | partial | no | partial | Scrolling and child hit testing need shared host routing. |
| `ScrollArea` | partial | partial | yes | Scroll animation exists; scrollbar and surface colors need style migration. |
| `Scrollbar` | yes | yes | yes | Hover/drag contract and theme-resolved track/thumb. |

## Content and indicators

| Widget | Theme | Animation | Events | Notes |
| --- | --- | --- | --- | --- |
| `Label` | yes | no | no | Text color/font resolve through the style cascade. |
| `TextRuns` | yes | no | no | Text-run rendering; no interaction by design. |
| `ImageIcon` | partial | no | no | Asset rendering; tint/style integration remains limited. |
| `Badge` | yes | no | no | Static semantic indicator. |
| `Card` | yes | no | no | Static surface and border roles. |
| `Frame` | yes | no | no | Static surface and border roles. |
| `GroupBox` | partial | no | no | Needs full surface and title role mapping. |
| `Chip` | yes | yes | yes | Shared style, hover transition, and activation. |
| `Separator` | yes | no | no | Static visual with a theme-resolved line color. |
| `ProgressBar` | yes | no | no | Fill/background/text use the shared style role. |
| `Spinner` | yes | yes | no | Animation is intentional; color uses the shared role. |
| `Sparkline` | partial | no | no | Data visualization; colors need style migration. |
| `Speedometer` | partial | no | no | Data visualization; colors need style migration. |
| `Tooltip` | partial | no | yes | Hover visibility works; panel/text colors need style migration. |

## Controls and input

All controls in this group must expose hover, pressed, focus, disabled, and
selected/checked states where those states are meaningful. Their drawing code
must consume the resolved style instead of bypassing it with direct color
constants.

| Widget | Theme | Animation | Events | State coverage |
| --- | --- | --- | --- | --- |
| `Button` | yes | yes | yes | hover, pressed, focus, disabled |
| `DialogButton` | yes | yes | yes | hover, pressed |
| `IconButton` | yes | yes | yes | hover, pressed |
| `TransportButton` | yes | yes | yes | hover, pressed |
| `Checkbox` | yes | yes | yes | hover, pressed, checked |
| `StatefulCheckbox` | partial | yes | yes | Stateful wrapper around checkbox rendering. |
| `RadioButton` | yes | yes | yes | hover, pressed, checked |
| `Switch` | yes | yes | yes | hover, pressed, checked |
| `StatefulSwitch` | partial | yes | yes | Stateful wrapper around switch rendering. |
| `ToggleButton` | partial | yes | yes | hover, pressed, selected |
| `SegmentedControl` | partial | yes | yes | hover, pressed, selected |
| `Slider` | partial | yes | yes | hover, pressed, dragging, focus |
| `RangeSlider` | partial | yes | yes | hover, pressed, dragging, focus |
| `Dropdown` | yes | yes | yes | hover, pressed, expanded, focus |
| `TextField` | partial | yes | yes | hover, focus, disabled, keyboard input; placeholder/cursor roles remain to split out. |
| `ListBox` | yes | partial | yes | selection and hover use shared pseudo-state styles. |
| `TabBar` | partial | yes | yes | hover, pressed, selected |
| `TabView` | partial | no | no | Content host; interaction belongs to `TabBar`. |
| `MenuItem`, `Menu` | yes | yes | yes | hover, pressed, expanded |
| `ContextMenu` | partial | no | yes | Surface/controller for menu items. |
| `MouseRegion` | no | no | yes | Event adapter; visual styling is intentionally absent. |
| `Dialog` | yes | no | yes | Surface layout; buttons own control states. |

## Animation, lifecycle, and surface support

| Widget/API | Theme | Animation | Events | Notes |
| --- | --- | --- | --- | --- |
| `AnimatedBuilder` | no | yes | no | Animation listener/build bridge. |
| `StatefulAnimatedBuilder` | no | yes | no | Stateful animation bridge. |
| `AnimatedOpacity` | no | yes | no | Implicit animation primitive. |
| `AnimatedSlide` | no | yes | no | Implicit animation primitive. |
| `AnimatedContainer` | partial | yes | no | Animated decoration should consume resolved styles. |
| `AnimatedCrossFade` | no | yes | no | Child transition primitive. |
| `ElementHost` | partial | no | no | Lifecycle bridge; child owns visual contract. |
| `Theme` | yes | no | no | Inherited theme scope; style providers remain the renderer source of truth. |
| `PopupHost`, `PopupWindow` | partial | no | yes | Surface plumbing; popup content owns widget states. |
| `WidgetWindow`, `WidgetLayerWindow` | n/a | n/a | yes | Surface adapters; both now use the same `WidgetHostController` event routing. |
| `TextEditingController` | n/a | n/a | n/a | Text model/controller, not a visual widget. |

## Migration rules

The `partial` entries are the work queue. New widgets should not add another
custom color cascade or a bespoke pointer-state flag. Instead:

- define a semantic `styleRole()`;
- expose constructor colors through `localOverrides()`;
- read `resolvedStyle()` in `draw()`;
- use `resolvedStyleOn(['hover'])` (or another pseudo state) for transitions;
- update `WidgetState` through `setInteractionState()`;
- let `WidgetHostController` route pointer, keyboard, focus, and wheel events.

The catalog is intentionally explicit about noninteractive widgets so the
toolkit does not accumulate animation controllers and event handlers where
they cannot provide user value.
