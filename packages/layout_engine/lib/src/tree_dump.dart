/// ASCII tree dumping for layout and element trees.
///
/// Host toolkits (e.g. window_toolkit) call [TreeDump.write] with their own
/// label/children extractors. Render objects and elements get first-class
/// helpers: [dumpRenderTree], [RenderObjectDump.dumpTree],
/// [dumpElementTree], [ElementDump.dumpTree].
///
/// {@category Render objects}
library;

import 'dart:io';

import 'element_tree.dart';
import 'render_flex.dart' show FlexParentData;
import 'render_object.dart';
import 'render_stack.dart' show StackParentData;

/// Formats hierarchical trees as box-drawing ASCII (for stderr / logs).
///
/// ```dart
/// TreeDump.write(
///   label: 'root',
///   children: [a, b],
///   labelOf: (n) => n.toString(),
///   childrenOf: (n) => n.children,
/// );
/// // └── root
/// //     ├── a
/// //     └── b
/// ```
class TreeDump {
  TreeDump._();

  /// Default sink: [stderr.writeln].
  static void Function(String line) get defaultWriteln => stderr.writeln;

  /// Writes one node and its descendants.
  ///
  /// [label] is this node's text. [children] are child objects; each is
  /// labeled with [labelOf] and expanded with [childrenOf].
  ///
  /// When [isRoot] is true (default for top-level calls), the first line has
  /// no branch connector so multi-root dumps stay readable.
  static void write({
    required String label,
    required List<Object?> children,
    required String Function(Object node) labelOf,
    required List<Object?> Function(Object node) childrenOf,
    void Function(String line)? writeln,
    String indent = '',
    bool isLast = true,
    bool isRoot = true,
  }) {
    final out = writeln ?? defaultWriteln;
    if (isRoot) {
      out(label);
    } else {
      final conn = isLast ? '└── ' : '├── ';
      out('$indent$conn$label');
    }
    final childIndent = isRoot
        ? indent
        : indent + (isLast ? '    ' : '│   ');
    final list = children.whereType<Object>().toList();
    for (var i = 0; i < list.length; i++) {
      final child = list[i];
      write(
        label: labelOf(child),
        children: childrenOf(child),
        labelOf: labelOf,
        childrenOf: childrenOf,
        writeln: out,
        indent: childIndent,
        isLast: i == list.length - 1,
        isRoot: false,
      );
    }
  }

  /// Same as [write] but returns the full dump as a single string.
  static String format({
    required String label,
    required List<Object?> children,
    required String Function(Object node) labelOf,
    required List<Object?> Function(Object node) childrenOf,
    bool isRoot = true,
  }) {
    final buf = StringBuffer();
    write(
      label: label,
      children: children,
      labelOf: labelOf,
      childrenOf: childrenOf,
      writeln: buf.writeln,
      isRoot: isRoot,
    );
    return buf.toString();
  }

  /// Formats a bounds suffix: `(x,y) w×h` using rounded doubles.
  static String bounds({
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    String n(double v) =>
        v.isFinite ? (v == v.roundToDouble() ? '${v.round()}' : v.toString()) : v.toString();
    return '(${n(x)},${n(y)}) ${n(width)}×${n(height)}';
  }

  /// Formats integer bounds: `(x,y) w×h`.
  static String boundsInt({
    required int x,
    required int y,
    required int width,
    required int height,
  }) =>
      '($x,$y) ${width}×${height}';
}

// ---------------------------------------------------------------------------
// RenderObject
// ---------------------------------------------------------------------------

/// Human-readable label for a [RenderObject] dump line.
String describeRenderObject(RenderObject node) {
  final o = node.offset;
  final s = node.size;
  final extras = <String>[];
  final pd = node.parentData;
  if (pd is FlexParentData && pd.flex > 0) {
    extras.add('flex=${pd.flex}');
  }
  if (pd is StackParentData && pd.isPositioned) {
    extras.add('positioned');
  }
  final suffix = extras.isEmpty ? '' : ' ${extras.join(' ')}';
  return '${node.runtimeType} '
      '${TreeDump.bounds(x: o.dx, y: o.dy, width: s.width, height: s.height)}'
      '$suffix';
}

/// Prints the [RenderObject] tree under [root] (default: stderr).
void dumpRenderTree(
  RenderObject root, {
  void Function(String line)? writeln,
}) {
  TreeDump.write(
    label: describeRenderObject(root),
    children: root.children,
    labelOf: (n) => describeRenderObject(n as RenderObject),
    childrenOf: (n) => (n as RenderObject).children,
    writeln: writeln,
  );
}

/// Returns the dump of [root] as a string.
String formatRenderTree(RenderObject root) {
  return TreeDump.format(
    label: describeRenderObject(root),
    children: root.children,
    labelOf: (n) => describeRenderObject(n as RenderObject),
    childrenOf: (n) => (n as RenderObject).children,
  );
}

/// Dump helpers on [RenderObject].
extension RenderObjectDump on RenderObject {
  /// Prints this subtree using [TreeDump] (default sink: stderr).
  void dumpTree({void Function(String line)? writeln}) =>
      dumpRenderTree(this, writeln: writeln);

  /// Formats this subtree as a multi-line string.
  String formatTree() => formatRenderTree(this);
}

// ---------------------------------------------------------------------------
// Element tree
// ---------------------------------------------------------------------------

/// Human-readable label for an [Element] dump line.
String describeElement(Element node) {
  final w = node.widget;
  final rw = node.renderWidget;
  final focus = node.focusable ? ' focusable' : '';
  if (!identical(w, rw)) {
    return '${w.runtimeType} → ${rw.runtimeType}$focus';
  }
  return '${w.runtimeType}$focus';
}

/// Children used when dumping an element (element children list).
List<Element> elementDumpChildren(Element node) => node.children;

/// Prints the [Element] tree under [root] (default: stderr).
void dumpElementTree(
  Element root, {
  void Function(String line)? writeln,
}) {
  TreeDump.write(
    label: describeElement(root),
    children: elementDumpChildren(root),
    labelOf: (n) => describeElement(n as Element),
    childrenOf: (n) => elementDumpChildren(n as Element),
    writeln: writeln,
  );
}

/// Returns the dump of [root] as a string.
String formatElementTree(Element root) {
  return TreeDump.format(
    label: describeElement(root),
    children: elementDumpChildren(root),
    labelOf: (n) => describeElement(n as Element),
    childrenOf: (n) => elementDumpChildren(n as Element),
  );
}

/// Dump helpers on [Element].
extension ElementDump on Element {
  /// Prints this element subtree (default sink: stderr).
  void dumpTree({void Function(String line)? writeln}) =>
      dumpElementTree(this, writeln: writeln);

  /// Formats this element subtree as a multi-line string.
  String formatTree() => formatElementTree(this);
}

