/// Framework-agnostic layout engine.
///
/// Provides geometry primitives, a render-object tree, and flex/padding
/// layout algorithms. No dependencies on any rendering backend.
library layout_engine;

export 'src/geometry.dart';
export 'src/render_object.dart';
export 'src/render_flex.dart';
export 'src/render_padding.dart';
export 'src/render_stack.dart';
export 'src/render_wrap.dart';
export 'src/text_measure.dart';
