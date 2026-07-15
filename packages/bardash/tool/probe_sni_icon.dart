import 'package:dbus/dbus.dart';

Future<void> main() async {
  final bus = DBusClient.session();
  final watcher = DBusRemoteObject(bus,
      name: 'org.kde.StatusNotifierWatcher',
      path: DBusObjectPath('/StatusNotifierWatcher'));
  final items = await watcher.getProperty(
      'org.kde.StatusNotifierWatcher', 'RegisteredStatusNotifierItems');
  print('items $items');
  if (items is! DBusArray) { await bus.close(); return; }
  for (final it in items.children) {
    if (it is! DBusString) continue;
    final s = it.value;
    final slash = s.indexOf('/');
    final name = slash > 0 ? s.substring(0, slash) : s;
    final path = slash > 0 ? s.substring(slash) : '/StatusNotifierItem';
    print('service $s');
    final obj = DBusRemoteObject(bus, name: name, path: DBusObjectPath(path));
    for (final p in ['Id', 'Title', 'IconName', 'Status']) {
      try {
        final v = await obj.getProperty('org.kde.StatusNotifierItem', p);
        print('  $p = $v');
      } catch (e) {
        print('  $p ERR $e');
      }
    }
    try {
      final pm = await obj.getProperty('org.kde.StatusNotifierItem', 'IconPixmap');
      print('  IconPixmap type=${pm.runtimeType} sig=${pm.signature}');
      if (pm is DBusArray) {
        print('  entries=${pm.children.length}');
        for (final e in pm.children) {
          if (e is DBusStruct) {
            final w = e.children[0];
            final h = e.children[1];
            final data = e.children[2];
            print('    w=$w h=$h data=${data.runtimeType} sig=${data.signature}');
            if (data is DBusArray) {
              print('    array children=${data.children.length}');
              try {
                final bytes = data.asByteArray().toList();
                print('    asByteArray ${bytes.length} first=${bytes.take(16).toList()}');
              } catch (err) {
                print('    asByteArray $err');
              }
            }
          }
        }
      }
    } catch (e) {
      print('  IconPixmap ERR $e');
    }
  }
  await bus.close();
}
