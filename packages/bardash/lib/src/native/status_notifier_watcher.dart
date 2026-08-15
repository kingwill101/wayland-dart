import 'dart:io';

import 'package:dbus/dbus.dart';

/// Minimal StatusNotifierWatcher, matching the service Waybar starts when no
/// watcher is already present. This lets tray applications register before a
/// panel such as Waybar is launched.
class StatusNotifierWatcherService extends DBusObject {
  static const serviceName = 'org.kde.StatusNotifierWatcher';
  static const interfaceName = 'org.kde.StatusNotifierWatcher';

  final Set<String> _hosts = {};
  final Set<String> _items = {};

  StatusNotifierWatcherService()
    : super(DBusObjectPath('/StatusNotifierWatcher'));

  bool get isHostRegistered => _hosts.isNotEmpty;

  @override
  Map<String, Map<String, DBusValue>> get interfacesAndProperties => {
    interfaceName: {
      'IsStatusNotifierHostRegistered': DBusBoolean(isHostRegistered),
      'RegisteredStatusNotifierItems': DBusArray(
        DBusSignature('s'),
        _items.map(DBusString.new),
      ),
      'ProtocolVersion': const DBusInt32(0),
    },
  };

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    if (interface != interfaceName) {
      return DBusMethodErrorResponse.unknownInterface();
    }
    return DBusGetAllPropertiesResponse(
      interfacesAndProperties[interfaceName]!,
    );
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    final properties = interfacesAndProperties[interface];
    final value = properties?[name];
    if (value == null) return DBusMethodErrorResponse.unknownProperty();
    return DBusGetPropertyResponse(value);
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall call) async {
    if (call.interface != interfaceName) {
      return DBusMethodErrorResponse.unknownInterface();
    }
    if (call.values.length != 1 || call.values.first is! DBusString) {
      return DBusMethodErrorResponse.invalidArgs();
    }

    final requested = (call.values.first as DBusString).value;
    final sender = call.sender ?? '';
    final path = requested.startsWith('/')
        ? requested
        : '/${call.name == 'RegisterStatusNotifierHost' ? 'StatusNotifierHost' : 'StatusNotifierItem'}';
    final busName = requested.startsWith('/') ? sender : requested;
    final registration = '$busName$path';

    stderr.writeln(
      '[sni-watcher] ${call.name} requested=$requested '
      'sender=$sender registration=$registration',
    );

    switch (call.name) {
      case 'RegisterStatusNotifierHost':
        if (_hosts.add(registration)) {
          await emitSignal(
            'org.kde.StatusNotifierWatcher',
            'StatusNotifierHostRegistered',
          );
          await emitPropertiesChanged(
            interfaceName,
            changedProperties: {
              'IsStatusNotifierHostRegistered': DBusBoolean(true),
            },
          );
        }
        return DBusMethodSuccessResponse();
      case 'RegisterStatusNotifierItem':
        if (_items.add(registration)) {
          await emitSignal(
            'org.kde.StatusNotifierWatcher',
            'StatusNotifierItemRegistered',
            [DBusString(registration)],
          );
          await emitPropertiesChanged(
            interfaceName,
            changedProperties: {
              'RegisteredStatusNotifierItems': DBusArray(
                DBusSignature('s'),
                _items.map(DBusString.new),
              ),
            },
          );
        }
        return DBusMethodSuccessResponse();
      default:
        return DBusMethodErrorResponse.unknownMethod();
    }
  }

  @override
  List<DBusIntrospectInterface> introspect() => [
    DBusIntrospectInterface(
      interfaceName,
      methods: [
        DBusIntrospectMethod(
          'RegisterStatusNotifierItem',
          args: [
            DBusIntrospectArgument(
              DBusSignature('s'),
              DBusArgumentDirection.in_,
              name: 'service',
            ),
          ],
        ),
        DBusIntrospectMethod(
          'RegisterStatusNotifierHost',
          args: [
            DBusIntrospectArgument(
              DBusSignature('s'),
              DBusArgumentDirection.in_,
              name: 'service',
            ),
          ],
        ),
      ],
      properties: [
        DBusIntrospectProperty(
          'RegisteredStatusNotifierItems',
          DBusSignature('as'),
          access: DBusPropertyAccess.read,
        ),
        DBusIntrospectProperty(
          'IsStatusNotifierHostRegistered',
          DBusSignature('b'),
          access: DBusPropertyAccess.read,
        ),
        DBusIntrospectProperty(
          'ProtocolVersion',
          DBusSignature('i'),
          access: DBusPropertyAccess.read,
        ),
      ],
      signals: [
        DBusIntrospectSignal(
          'StatusNotifierItemRegistered',
          args: [
            DBusIntrospectArgument(
              DBusSignature('s'),
              DBusArgumentDirection.out,
              name: 'service',
            ),
          ],
        ),
        DBusIntrospectSignal(
          'StatusNotifierItemUnregistered',
          args: [
            DBusIntrospectArgument(
              DBusSignature('s'),
              DBusArgumentDirection.out,
              name: 'service',
            ),
          ],
        ),
        DBusIntrospectSignal('StatusNotifierHostRegistered'),
        DBusIntrospectSignal('StatusNotifierHostUnregistered'),
      ],
    ),
  ];
}

class StatusNotifierWatcherHost {
  final DBusClient bus;
  final StatusNotifierWatcherService? service;

  StatusNotifierWatcherHost._(this.bus, this.service);

  bool get ownsWatcher => service != null;

  static Future<StatusNotifierWatcherHost> ensure(DBusClient bus) async {
    final reply = await bus.requestName(
      StatusNotifierWatcherService.serviceName,
      flags: {
        DBusRequestNameFlag.allowReplacement,
        DBusRequestNameFlag.doNotQueue,
      },
    );
    if (reply != DBusRequestNameReply.primaryOwner &&
        reply != DBusRequestNameReply.alreadyOwner) {
      return StatusNotifierWatcherHost._(bus, null);
    }

    final service = StatusNotifierWatcherService();
    await bus.registerObject(service);
    return StatusNotifierWatcherHost._(bus, service);
  }

  Future<void> close() async {
    if (service != null) {
      await bus.unregisterObject(service!);
      await bus.releaseName(StatusNotifierWatcherService.serviceName);
    }
  }
}
