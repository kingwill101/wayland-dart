import 'dart:async' as async;
import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import '../native/hyprland_ipc.dart' as ipc;
import 'module.dart';

/// Hyprland workspace switcher using [Button] + [HBox].
///
/// Listens on Hyprland's event socket (socket2.sock) for instant workspace
/// switches instead of polling `hyprctl` every second.  A dedicated 50ms
/// Timer drains the event socket, so the bar updates as fast as the paint
/// loop allows — comparable to waybar's event-driven response time.
class HyprlandWorkspacesModule extends BarModule {
  @override
  String get name => 'hyprland/workspaces';

  List<Map<String, dynamic>> _workspaces = [];
  int _activeId = -1;
  bool _available = true;
  final Set<int> _urgentIds = <int>{};
  async.Timer? _drainTimer;
  bool _dirty = false;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{name}', '');
    // Keep a longer poll interval as a safety net; event socket drives updates.
    interval = 5;

    // Register event socket listener — called from drain loop below.
    ipc.onEvent(_onHyprEvent);

    // Initial fetch so workspaces appear immediately on startup.
    if (ipc.isAvailable) {
      _refresh();
      if (_dirty) {
        _dirty = false;
        requestRepaint?.call();
      }
    }

    // High-frequency drain so events are picked up within ~50ms.
    _drainTimer = async.Timer.periodic(const Duration(milliseconds: 50), (_) {
      ipc.pollEvents();
      if (_dirty) {
        _dirty = false;
        requestRepaint?.call();
      }
    });
  }

  void _onHyprEvent(String event, String data) {
    // Workspace switch, creation, destruction, or rename → refresh the list.
    switch (event) {
      case 'workspace':
      case 'focusedmon':
      case 'createworkspace':
      case 'destroyworkspace':
      case 'moveworkspace':
      case 'renameworkspace':
        _refresh();
        _dirty = true;
      case 'urgent':
        final id = int.tryParse(data.trim());
        if (id != null) {
          _urgentIds.add(id);
          _dirty = true;
          _refresh();
        }
    }
  }

  void _refresh() {
    final list = ipc.hyprctl('workspaces');
    if (list is! List) {
      _available = false;
      widget = null;
      return;
    }

    _workspaces = list.cast<Map<String, dynamic>>();
    _urgentIds..removeWhere((id) => !_workspaces.any((ws) => ws['id'] == id));
    final clients = ipc.hyprctl('clients');
    if (clients is List) {
      for (final client in clients.whereType<Map>()) {
        if (client['urgent'] == true && client['workspace'] is Map) {
          final id = (client['workspace'] as Map)['id'];
          if (id is int) _urgentIds.add(id);
        }
      }
    }
    final active = ipc.hyprctl('activeworkspace');
    _activeId = (active is Map) ? (active['id'] as int? ?? -1) : -1;
    _workspaces.sort((a, b) => (a['id'] as int).compareTo(b['id'] as int));

    final buttons = <Widget>[];
    const gap = 2;
    for (var i = 0; i < _workspaces.length; i++) {
      final ws = _workspaces[i];
      final id = ws['id'] as int;
      final label = ws['name']?.toString() ?? '$id';
      final isActive = id == _activeId;
      final isUrgent = _urgentIds.contains(id) || ws['urgent'] == true;

      final btn =
          Button(
              label,
              // Let CSS override via .module / #workspaces button.active; keep fallback for no-CSS
              textColor: isActive
                  ? const Color(0xff, 0xff, 0xff)
                  : isUrgent
                  ? const Color(0xff, 0xb0, 0x70)
                  : const Color(0xa0, 0xa0, 0xa0),
              backgroundColor: isActive
                  ? const Color(0x50, 0x60, 0x80)
                  : isUrgent
                  ? const Color(0x70, 0x40, 0x28)
                  : const Color(0x30, 0x30, 0x38),
              hoverColor: const Color(0x60, 0x70, 0x90),
              padding: 3,
              charWidth: 7,
              charHeight: 14,
            )
            ..styleId = 'workspace-$id'
            ..addClass('workspace')
            ..addClass('button');
      if (isActive) {
        btn.addClass('active');
        btn.addClass('focused');
        btn.addPseudoClass('active');
      }
      if (isUrgent) btn.addClass('urgent');

      final capturedId = id;
      btn.onClick = () {
        stderr.writeln('[bardash:workspaces] click workspace $capturedId');
        ipc.hyprctl(
          'dispatch hl.dsp.focus({ workspace = "$capturedId" })',
          useJson: false,
        );
        _urgentIds.remove(capturedId);
        _refresh();
        return true;
      };
      buttons.add(btn);
      if (i < _workspaces.length - 1) {
        buttons.add(Spacer()..width = gap);
      }
    }

    widget = HBox(spacing: 0, children: buttons);
    output = _workspaces.map((w) => w['name'] ?? '').join(' ');
  }

  @override
  void update() {
    if (!_available) {
      widget = null;
      return;
    }
    if (!ipc.isAvailable) {
      _available = false;
      widget = null;
      return;
    }

    // Safety net: periodic poll still fires events if the drain missed one.
    ipc.pollEvents();
    if (_dirty) {
      _dirty = false;
      requestRepaint?.call();
    }
  }

  @override
  double draw(Painter painter, double x, double y) => 0;

  @override
  void onScroll(double delta) {
    if (delta == 0 || _workspaces.isEmpty) return;
    final current = _workspaces.indexWhere((ws) => ws['id'] == _activeId);
    if (current < 0) return;
    final next = (current + (delta < 0 ? 1 : -1)).clamp(
      0,
      _workspaces.length - 1,
    );
    if (next == current) return;
    final id = _workspaces[next]['id'];
    ipc.hyprctl('dispatch hl.dsp.focus({ workspace = "$id" })', useJson: false);
    _refresh();
  }
}
