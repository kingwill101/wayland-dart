import 'package:bardash/src/native/bluez.dart';
import 'package:bardash/src/native/mpris_client.dart';
import 'package:bardash/src/native/network_manager.dart';

void main() async {
  final bt = await BluezClient.instance.refresh();
  print('BT powered=${bt.powered} adapter=${bt.adapterName} connected=${bt.connectedCount}');
  for (final d in bt.connected) {
    print('  + ${d.name} (${d.address})');
  }
  for (final d in bt.devices.take(3)) {
    print('  · ${d.name} paired=${d.paired} conn=${d.connected}');
  }

  final nm = await NetworkManagerClient.instance.refresh();
  print('NM connected=${nm.connected} type=${nm.type} if=${nm.ifname} ip=${nm.ip4} ssid=${nm.ssid} sig=${nm.signal} id=${nm.connectionId}');

  final mp = await MprisClient.instance.refresh();
  print('MPRIS status=${mp.status} artist=${mp.artist} title=${mp.title} player=${mp.identity}');

  await BluezClient.instance.dispose();
  await NetworkManagerClient.instance.dispose();
  await MprisClient.instance.dispose();
}
