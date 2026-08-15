import 'package:layout_engine/layout_engine.dart' as le;

import 'drawing/color.dart';
import 'mixins/event.dart';
import 'interaction.dart';
import 'painter/painter.dart';
import 'metrics.dart';
import 'palette.dart';
import 'style.dart';
import 'style/style_context.dart';
import 'style/style_patch.dart';

// Re-export so widget implementations can type-check KeyEvent.
export 'mixins/event.dart' show KeyEvent;

// Re-export layout_engine Element types.
export 'package:layout_engine/layout_engine.dart'
    show
        BuildContext,
        BuildOwner,
        Element,
        ElementTree,
        WidgetKey,
        ElementWidget,
        InheritedElement,
        InheritedWidget,
        NeedsBuildCallback,
        State,
        StatefulElement,
        StatefulWidget,
        StatelessElement,
        StatelessWidget,
        WidgetElement;

typedef VoidCallback = void Function();

abstract class Widget extends le.ElementWidget {
  /// Legacy fallback for widgets not attached to a host.
  ///
  /// Widget windows bind [repaintCallback] per tree. This remains for small
  /// standalone widget tests and older integrations.
  static VoidCallback? onNeedsRepaint;

  /// Repaint callback owned by the widget host containing this widget.
  VoidCallback? repaintCallback;

  /// Parent pointer — set by containers when they lay out children.
  Widget? parent;

  /// Optional CSS id — mirrors `widget.set_name()` / `get_style_context()->add_class(id)` in GTK.
  /// Waybar uses e.g. `window#waybar`, `#pulseaudio`, `#workspaces`.
  String? styleId;

  /// CSS classes — mirrors `get_style_context()->add_class()`. Waybar adds
  /// `"module"` to every module, plus `"modules-left"` etc.
  final Set<String> styleClasses = {};

  /// Pseudo-classes — mirrors `add_class("hidden")`, `:hover`, etc.
  final Set<String> pseudoClasses = {};

  /// Canonical interaction state for this widget.
  final InteractionState interaction = InteractionState();

  bool _enabled = true;

  /// Whether this widget accepts interaction events.
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    setInteractionState(WidgetState.disabled, !value);
  }

  bool get isHovered => hasInteractionState(WidgetState.hovered);
  bool get isFocused => hasInteractionState(WidgetState.focused);
  bool get isPressed => hasInteractionState(WidgetState.pressed);
  bool get isDisabled => !enabled;

  bool hasInteractionState(WidgetState state) => interaction.contains(state);

  /// Updates a state and mirrors it into the CSS pseudo-class set.
  ///
  /// The state is deliberately owned by [Widget], so all controls and
  /// composites use the same state-to-style path.
  bool setInteractionState(WidgetState state, bool active) {
    final changed = interaction.update(state, active);
    if (!changed) return false;
    if (active) {
      addPseudoClass(state.pseudoClass);
    } else {
      removePseudoClass(state.pseudoClass);
    }
    requestRepaint();
    return true;
  }

  /// Clears transient interaction state when a widget is unmounted.
  void clearInteractionState() {
    for (final state in interaction.values.toList()) {
      setInteractionState(state, false);
    }
  }

  bool hasClass(String name) => styleClasses.contains(name);
  bool hasPseudoClass(String name) =>
      pseudoClasses.contains(name) || styleClasses.contains(name);
  void addClass(String name) => styleClasses.add(name);
  void removeClass(String name) {
    styleClasses.remove(name);
    pseudoClasses.remove(name);
  }

  void addPseudoClass(String name) => pseudoClasses.add(name);
  void removePseudoClass(String name) => pseudoClasses.remove(name);

  /// Creates a widget with an optional [key] for reconciliation.
  Widget({super.key, this.styleId});

  /// Whether this widget is mounted in a widget tree.
  bool mounted = false;

  /// Called once when the widget is first mounted into a widget tree.
  void initState() {}

  /// Called when the widget is removed from the widget tree.
  void dispose() {}

  /// Notify the framework that internal data changed.
  /// Triggers a repaint on the next frame.
  void setState(void Function() fn) {
    fn();
    requestRepaint();
  }

  /// Requests a repaint from the owning widget host.
  void requestRepaint() {
    final callback = repaintCallback ?? onNeedsRepaint;
    callback?.call();
  }

  int x = 0, y = 0, width = 0, height = 0;

  /// Click handler. Return true to consume the event and stop propagation.
  /// The click bubbles up the widget tree: deepest widget is called first,
  /// then its parent, grandparent, etc., until a handler returns true.
  bool Function()? onClick;
  VoidCallback? onMouseEnter;
  VoidCallback? onMouseLeave;

  /// Convenience accessor for the active palette colors.
  ColorGroup get palette => Palette.current.forState(true, true);

  // ── General style system resolvers ────────────────────────────────────
  //
  // A widget's typed [StylePatch] is the merge of every registered
  // [StyleProvider] (theme defaults, programmatic presets, CSS…). CSS is just
  // one addon that injects via `StyleContext.addProviderForScreen`. These
  // helpers make that resolver uniform on every widget: a widget asks
  // `widgetStyle` / `widgetStyleOn(...)`, then falls back to palette/explicit
  // values when a property is unset.

  /// Resolved typed style for this widget from all registered providers.
  /// Unset properties stay null → the widget falls back to palette defaults.
  StylePatch get widgetStyle => StyleContext.forWidget(this).style;

  /// [widgetStyle] resolved as if [pseudos] were active (e.g. `['hover']`).
  /// The pseudo-classes are applied for the lookup only and restored after.
  StylePatch widgetStyleOn(Iterable<String> pseudos) {
    final prev = <String, bool>{};
    for (final p in pseudos) {
      prev[p] = hasPseudoClass(p);
      addPseudoClass(p);
    }
    final s = StyleContext.forWidget(this).style;
    for (final p in pseudos) {
      removePseudoClass(p);
      if (prev[p]!) addPseudoClass(p);
    }
    return s;
  }

  /// CSS `color` (foreground) else [fallback] (explicit/constructor or palette).
  Color colorFromStyle(Color fallback) => widgetStyle.color ?? fallback;

  /// CSS `background-color` else [fallback].
  Color backgroundFromStyle(Color fallback) =>
      widgetStyle.backgroundColor ?? fallback;

  /// CSS `font-size` else [fallback].
  double fontSizeFromStyle(double fallback) => widgetStyle.fontSize ?? fallback;

  /// The inherited global-palette defaults, folded into a concrete
  /// [Style]. Override per widget so [resolvedStyle] knows its
  /// baseline. CSS/providers and local overrides apply on top of this.
  Style styleRole() => Style(
    color: palette.text,
    backgroundColor: palette.base,
    borderColor: palette.mid,
    borderRadius: ThemeMetrics.current.borderRadiusSm.toDouble(),
    fontSize: ThemeMetrics.current.fontSize,
  );

  /// The fully-resolved style this widget actually draws with. Single point
  /// of the cascade: role palette → CSS/providers → [local] override.
  /// Widgets read only concrete values (`resolvedStyle.color` ...); they never
  /// re-implement the merge.
  Style resolvedStyle({StylePatch? local}) {
    var overrides = localOverrides();
    if (local != null) overrides = overrides.apply(local);
    return StyleContext.resolveStyle(this, role: styleRole(), local: overrides);
  }

  /// [resolvedStyle] with [pseudos] (e.g. `['hover']`) active, applying the
  /// widget-local [local] overrides for that state.
  Style resolvedStyleOn(Iterable<String> pseudos, {StylePatch? local}) {
    var overrides = localOverrides();
    if (local != null) overrides = overrides.apply(local);
    return StyleContext.resolveStyle(
      this,
      role: styleRole(),
      local: overrides,
      pseudos: pseudos.toList(),
    );
  }

  /// The widget's own explicit style values (constructor fields), registered
  /// in one place. Folds into [`resolvedStyle`]/[`resolvedStyleOn`] so every
  /// basic widget's own look flows through the same single cascade.
  StylePatch localOverrides() => const StylePatch();

  /// Positioned mouse callbacks. Override in interactive widgets.
  /// Called by WidgetWindow when events reach this widget via hit-test.
  void onMouseDown(int x, int y, int button) {}
  void onMouseUp(int x, int y, int button) {}
  void onMouseDrag(int x, int y) {}
  void onMouseMove(int x, int y) {}

  /// Called when the pointer is captured by this widget and moves outside it.
  void onPointerCancel() {}

  /// Keyboard input. Override in widgets that need text input.
  /// Called by WidgetWindow when this widget has keyboard focus.
  void onKeyPressed(KeyEvent event) {}
  void onKeyReleased(KeyEvent event) {}

  /// Activates the widget from keyboard input. Return true when consumed.
  bool activate() {
    if (!enabled || onClick == null) return false;
    return onClick!();
  }

  /// The child widgets of this widget, for hit-test traversal and layout.
  /// Override in composite widgets that contain children.
  List<Widget> get children => const [];

  /// Called when this widget gains or loses keyboard focus.
  void onFocusChanged(bool focused) {}

  /// Called after the canonical hover state changes.
  void onHoverChanged(bool hovering) {}

  /// Whether this widget accepts keyboard focus (e.g. Button, TextField).
  bool get acceptsFocus => false;

  /// Focus order for Tab key navigation. Widgets with the same
  /// [tabIndex] are focused in hit-test order. Default 0 (no focus).
  int tabIndex = 0;

  /// Whether this widget can be reached via Tab key.
  bool get isFocusable => tabIndex > 0 && acceptsFocus;

  /// Scroll / wheel input. Override in widgets that respond to scroll.
  /// Called by WidgetWindow when this widget is under the cursor.
  /// Return true to consume the event and stop propagation.
  bool onMouseWheel(MouseWheelEvent event) => false;

  void measure(Painter painter) {}

  void draw(Painter canvas);

  /// Lays out this widget within [containerWidth], setting [height] to
  /// the widget's intrinsic height after measuring its children.
  void performLayout(int containerWidth) {
    width = containerWidth;
  }

  bool hitTest(int px, int py) {
    assert(
      width >= 0 && height >= 0,
      'Widget $runtimeType hit-tested before layout (width=$width height=$height). '
      'Call performLayout() or pump() before hit-testing.',
    );
    return px >= x && px < x + width && py >= y && py < y + height;
  }

  String _widgetLabel() => '$runtimeType ($x,$y) $width×$height';

  String formatTree() {
    final buf = StringBuffer();
    buf.writeln(_widgetLabel());
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final isLast = i == children.length - 1;
      _writeTree(child, buf, '', isLast);
    }
    return buf.toString();
  }

  void _writeTree(Widget node, StringBuffer buf, String indent, bool isLast) {
    final conn = isLast ? '└── ' : '├── ';
    buf.writeln('$indent$conn${node._widgetLabel()}');
    final childIndent = indent + (isLast ? '    ' : '│   ');
    for (var i = 0; i < node.children.length; i++) {
      _writeTree(
        node.children[i],
        buf,
        childIndent,
        i == node.children.length - 1,
      );
    }
  }

  void dumpTree({void Function(String line)? writeln}) {
    final text = formatTree();
    final out = writeln ?? (String s) => print(s);
    for (final line in text.split('\n')) {
      if (line.isNotEmpty) out(line);
    }
  }
}

class Container extends Widget {
  @override
  final List<Widget> children;

  /// Transparent generic child host.
  ///
  /// Region-specific placement belongs to a domain widget (for example,
  /// Bardash's bar layout), while [Container] only owns composition and
  /// child traversal. Use [HBox], [VBox], [Flex], or [Stack] when a specific
  /// layout policy is required.
  Container({List<Widget>? children, super.key}) : children = children ?? [];

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    var contentHeight = 0;
    for (final child in children) {
      child.parent = this;
      child.performLayout(child.width > 0 ? child.width : containerWidth);
      final bottom = child.y - y + child.height;
      if (bottom > contentHeight) contentHeight = bottom;
    }
    if (height <= 0) height = contentHeight;
  }

  @override
  void draw(Painter canvas) {
    if (width > 0) performLayout(width);
    for (final child in children) {
      child.draw(canvas);
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    for (final child in children.reversed) {
      if (child.hitTest(px, py)) return true;
    }
    return true;
  }
}

// Label lives in widgets/label.dart (measured text + ellipsis).

class Spacer extends Widget {
  @override
  void draw(Painter canvas) {
    // Spacer draws nothing
  }

  @override
  bool hitTest(int px, int py) => false;
}
