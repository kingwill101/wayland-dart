/// Shared interaction state for toolkit widgets.
enum WidgetState {
  hovered('hover'),
  focused('focus'),
  pressed('active'),
  disabled('disabled'),
  selected('selected'),
  checked('checked'),
  expanded('expanded'),
  dragging('dragging');

  const WidgetState(this.pseudoClass);

  final String pseudoClass;
}

/// Mutable state container used by every [Widget].
class InteractionState {
  final Set<WidgetState> _active = {};

  bool contains(WidgetState state) => _active.contains(state);

  Iterable<WidgetState> get values => _active;

  bool update(WidgetState state, bool value) {
    if (value) return _active.add(state);
    return _active.remove(state);
  }

  void clear() => _active.clear();
}
