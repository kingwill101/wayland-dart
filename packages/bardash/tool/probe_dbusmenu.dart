import 'package:dbus/dbus.dart';
import 'package:bardash/src/tray_menu.dart';

Future<void> main() async {
  final bus = DBusClient.session();
  final watcher = DBusRemoteObject(
    bus,
    name: 'org.kde.StatusNotifierWatcher',
    path: DBusObjectPath('/StatusNotifierWatcher'),
  );
  try {
    final result = await watcher.getProperty(
      'org.kde.StatusNotifierWatcher',
      'RegisteredStatusNotifierItems',
    );
    print('items: $result');
    if (result is! DBusArray) return;
    for (final item in result.children) {
      if (item is! DBusString) continue;
      final svc = item.value;
      final slash = svc.indexOf('/');
      final busName = slash > 0 ? svc.substring(0, slash) : svc;
      final objectPath =
          slash > 0 ? svc.substring(slash) : '/StatusNotifierItem';
      print('SNI $busName $objectPath');
      final sni = DBusRemoteObject(
        bus,
        name: busName,
        path: DBusObjectPath(objectPath),
      );
      try {
        final menu =
            await sni.getProperty('org.kde.StatusNotifierItem', 'Menu');
        print('  Menu=$menu (${menu.runtimeType})');
        var menuPath = '';
        if (menu is DBusObjectPath) menuPath = menu.value;
        if (menu is DBusString) menuPath = menu.value;
        if (menuPath.isEmpty) continue;
        final entries = await fetchDbusMenu(bus, busName, menuPath);
        print('  entries=${entries.length}');
        for (final e in entries) {
          print('    [${e.id}] sep=${e.separator} "${e.label}"');
        }
      } catch (e, st) {
        print('  err $e\n$st');
      }
    }
  } catch (e, st) {
    print('fail $e\n$st');
  }
  await bus.close();
}
