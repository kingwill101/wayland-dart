/// D-Bus menu transport and toolkit popup controller for tray items.
library;

import 'dart:async' show unawaited;
import 'dart:io' show stderr;

import 'package:dbus/dbus.dart';
import 'package:window_toolkit/window_toolkit.dart';

import 'tray_menu_widget.dart';

class DbusMenuEntry {
  final int id;
  final String label;
  final bool separator;
  final bool enabled;
  final bool visible;

  const DbusMenuEntry({
    required this.id,
    required this.label,
    this.separator = false,
    this.enabled = true,
    this.visible = true,
  });
}

Future<List<DbusMenuEntry>> fetchDbusMenu(
  DBusClient bus,
  String service,
  String menuPath,
) async {
  final obj = DBusRemoteObject(
    bus,
    name: service,
    path: DBusObjectPath(menuPath),
  );

  try {
    await obj.callMethod('com.canonical.dbusmenu', 'AboutToShow', [
      DBusInt32(0),
    ]);
  } catch (e) {
    stderr.writeln('[dbusmenu] AboutToShow: $e');
  }

  final result = await obj.callMethod('com.canonical.dbusmenu', 'GetLayout', [
    DBusInt32(0),
    DBusInt32(3),
    DBusArray.string(const []),
  ]);
  if (result.returnValues.length < 2) return const [];

  final entries = <DbusMenuEntry>[];

  void walk(DBusValue node, {int depth = 0}) {
    var current = node;
    if (current is DBusVariant) current = current.value;
    if (current is! DBusStruct || current.children.length < 3) return;

    final idValue = current.children[0];
    final propsValue = current.children[1];
    final childrenValue = current.children[2];

    int? id;
    if (idValue is DBusInt32) id = idValue.value;
    if (idValue is DBusUint32) id = idValue.value;
    if (id == null) return;

    final props = <String, DBusValue>{};
    if (propsValue is DBusDict) {
      for (final entry in propsValue.children.entries) {
        final key = entry.key;
        var value = entry.value;
        if (value is DBusVariant) value = value.value;
        if (key is DBusString) props[key.value] = value;
      }
    }

    final type = props['type'] is DBusString
        ? (props['type'] as DBusString).value
        : 'standard';
    final label = props['label'] is DBusString
        ? (props['label'] as DBusString).value.replaceAll('_', '')
        : '';
    final enabled = props['enabled'] is DBusBoolean
        ? (props['enabled'] as DBusBoolean).value
        : true;
    final visible = props['visible'] is DBusBoolean
        ? (props['visible'] as DBusBoolean).value
        : true;

    if (depth == 1 && visible) {
      entries.add(
        DbusMenuEntry(
          id: id,
          label: label,
          separator: type == 'separator',
          enabled: enabled,
          visible: visible,
        ),
      );
    }

    if (depth == 0 && childrenValue is DBusArray) {
      for (final child in childrenValue.children) {
        walk(child, depth: 1);
      }
    }
  }

  walk(result.returnValues[1]);
  return entries;
}

Future<void> dbusMenuClick(
  DBusClient bus,
  String service,
  String menuPath,
  int itemId,
) async {
  final obj = DBusRemoteObject(
    bus,
    name: service,
    path: DBusObjectPath(menuPath),
  );
  final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  try {
    await obj.callMethod('com.canonical.dbusmenu', 'Event', [
      DBusInt32(itemId),
      DBusString('clicked'),
      DBusVariant(DBusInt32(0)),
      DBusUint32(timestamp),
    ]);
  } catch (e) {
    stderr.writeln('[dbusmenu] Event failed: $e');
  }
}

class TrayMenuController {
  static LayerPopup? _active;
  static int _generation = 0;

  static bool get isOpen => _active?.isOpen ?? false;

  static void close() {
    _generation++;
    _active?.close();
    _active = null;
  }

  static Future<void> open({
    required LayerPopupHost popupHost,
    required DBusClient bus,
    required String service,
    required String menuPath,
    required int anchorX,
    required int parentWidth,
    required int parentHeight,
    required bool openUpward,
  }) async {
    final generation = ++_generation;
    _active?.close();
    _active = null;

    List<DbusMenuEntry> items;
    try {
      items = await fetchDbusMenu(bus, service, menuPath);
    } catch (e, st) {
      stderr.writeln('[dbusmenu] fetch failed: $e\n$st');
      return;
    }
    if (generation != _generation) return;

    items = items.where((entry) => entry.visible).toList();
    if (items.isEmpty) {
      stderr.writeln('[dbusmenu] empty menu');
      return;
    }

    final widget = TrayMenuWidget(
      entries: [
        for (final item in items)
          TrayMenuItemData(
            id: item.id,
            label: item.label,
            separator: item.separator,
            enabled: item.enabled,
          ),
      ],
      onTriggered: (id) {
        stderr.writeln('[dbusmenu] activate id=$id');
        unawaited(dbusMenuClick(bus, service, menuPath, id));
        close();
      },
    );
    final placement = BarPopupPlacement.forBar(
      anchorX: anchorX,
      parentWidth: parentWidth,
      width: widget.preferredWidth,
      height: widget.preferredHeight,
      openUpward: openUpward,
      keyboardMode: LayerKeyboardMode.exclusive,
    );
    final dismissPlacement = LayerSurfacePlacement(
      anchors: {
        LayerEdge.top,
        LayerEdge.right,
        LayerEdge.bottom,
        LayerEdge.left,
      },
      width: 0,
      height: 0,
      marginTop: openUpward ? 0 : parentHeight,
      marginBottom: openUpward ? parentHeight : 0,
      exclusiveZone: -1,
      keyboardMode: LayerKeyboardMode.none,
    );
    late final LayerPopup popup;
    popup = popupHost.create(
      content: widget,
      placement: placement,
      dismissPlacement: dismissPlacement,
      background: const Color(0, 0, 0, 0),
      onEvent: (popupEvent) {
        if (popupEvent.isOutsideClick) {
          popup.close();
          return false;
        }
        return false;
      },
      onClosed: () {
        if (identical(_active, popup)) _active = null;
      },
    );
    _active = popup;
    if (!await popup.show()) {
      if (identical(_active, popup)) _active = null;
      return;
    }
    stderr.writeln(
      '[dbusmenu] open toolkit popup ${widget.width}x${widget.height} '
      'items=${items.length} anchorX=$anchorX',
    );
  }
}
