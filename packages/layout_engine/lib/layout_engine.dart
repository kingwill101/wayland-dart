/// Framework-agnostic layout engine.
///
/// Provides geometry primitives, a render-object tree, and flex/padding
/// layout algorithms. No dependencies on any rendering backend.
library layout_engine;

export 'src/element_tree.dart'
    show
        BuildContext,
        BuildOwner,
        Element,
        ElementTree,
        InheritedElement,
        NeedsBuildCallback,
        StatefulElement,
        StatelessElement,
        WidgetElement,
        createElement;
// framework.dart defines ElementWidget, StatefulWidget, StatelessWidget, State,
// InheritedWidget — but window_toolkit re-exports its own versions that extend
// Widget. Export only for internal use; users get them from window_toolkit.
export 'src/framework.dart'
    show ElementWidget, InheritedWidget, State, StatefulWidget, StatelessWidget;
export 'src/geometry.dart';
export 'src/render_object.dart';
export 'src/render_flex.dart';
export 'src/render_padding.dart';
export 'src/render_scroll.dart';
export 'src/render_stack.dart';
export 'src/render_wrap.dart';
export 'src/text_measure.dart';
