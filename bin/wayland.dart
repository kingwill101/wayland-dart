import 'package:wayland/generated/stable/xdg-shell/xdg_shell.dart';
import 'package:wayland/generated/wayland.dart';
import 'package:wayland/wayland.dart';

Compositor? compositor;
Shm? shm;
Seat? seat;
XdgWmBase? xdgWmBase;

void main() async {
  Context context = Context(WaylandConnection());
  await context.connect();

  var display = Display(context);
  display.onError((a) {
    print("display.onerror: $a");
  });

  display.onDeleteId((a) {
    print("display.ondeleteId: $a");
  });

  var reg = await display.getRegistry();

  reg.onGlobal((global) async {
    print(
        "discovered an interface: $global");

    switch (global.interface) {
      case "wl_compositor":
        compositor = Compositor(context);
        try {
          await reg.bind(
              global.name, global.version, global.interface,  compositor!.objectId);
        } catch (err) {
          print("unable to bind wl_compositor interface: $err");
        }
        break;
      case "wl_shm":
        shm = Shm(context);
        try {
          await reg.bind(global.name, global.version, global.interface, shm!.objectId);
        } catch (err) {
          print("unable to bind wl_compositor interface: $err");
        }
        break;

      default:
        print("Unknown interface: ${global.interface}");
        break;
    }
  });

  var callback = await display.sync();

  callback.onDone((val) {
    print("callback.ondone: $val");
  });

  context.dispatch();
}
