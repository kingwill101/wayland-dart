import '../widget.dart';
import 'style_patch.dart';

/// A source of typed widget styles.
///
/// The toolkit's style system is **general**: anything that can answer "what
/// style applies to this widget and its ancestry" is a [StyleProvider].
/// `StyleContext` merges all registered providers by [priority], so the
/// highest-priority provider wins a property it sets and lower providers fill
/// gaps.
///
/// CSS is one such addon — `CssProvider` implements this interface by mapping
/// parsed CSS rules onto [StylePatch]. Apps can register their own providers
/// (themes, programmatic presets) through [StyleContext.addProvider].
abstract class StyleProvider {
  /// Merge priority; higher wins when multiple providers set the same
  /// property. Callers register a provider with its desired priority — see
  /// [StyleContext.addProvider].
  int priority;

  StyleProvider({this.priority = 1});

  /// The style this provider contributes for [widget], given its [chain] from
  /// root to [widget] (for ancestor / descendant selectors).
  StylePatch styleFor(Widget widget, List<Widget> chain);
}

/// GTK-style provider priorities. Higher value wins.
class StyleProviderPriority {
  static const int fallback = 1;
  static const int theme = 200;
  static const int settings = 400;
  static const int application = 600;
  static const int user = 800;
}
