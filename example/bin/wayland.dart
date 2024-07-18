import 'dart:io';

import 'package:wayland/protocols/stable/xdg-shell/xdg_shell.dart';
import 'package:wayland/protocols/wayland.dart';
import 'package:wayland/wayland.dart';

Compositor? compositor;
Subcompositor? subCompositor;
Shm? shm;
Seat? seat;
XdgWmBase? xdgWmBase;

void main() async {
  Context context = Context();
  await context.connect();

  var display = Display(context);
  display.onError((a) {
    logLn("display.onerror: $a");
  });

  display.onDeleteId((a) {
    logLn("display.ondeleteId: $a");
  });

  var reg = display.getRegistry();
  reg
    ..onGlobal((global) async {
      logLn("discovered an interface: $global");
      try {
        switch (global.interface) {
          case "wl_compositor":
            compositor = Compositor(context);
            reg.bind(global.name, global.interface, global.version,
                compositor!.objectId);
            break;
          case "wl_subcompositor":
            subCompositor = Subcompositor(context);
            reg.bind(global.name, global.interface, global.version,
                subCompositor!.objectId);
            break;
          case "wl_shm":
            shm = Shm(context);
            shm?.onFormat((format) {
              logLn("shm format: $format");
            });
            reg.bind(
                global.name, global.interface, global.version, shm!.objectId);
            break;
          case "wl_seat":
            seat = Seat(context);
            seat?.onCapabilities((capa) {
              logLn("seat capabilities: $capa");
            });
            seat?.onName((name) {
              logLn("seat name: $name");
            });
            reg.bind(
                global.name, global.interface, global.version, seat!.objectId);
            break;
          case "xdg_wm_base":
            xdgWmBase = XdgWmBase(context);
            xdgWmBase?.onPing((ping) {
              logLn("xdg_wm_base ping: $ping");
              xdgWmBase?.pong(ping.serial);
            });
            reg.bind(global.name, global.interface, global.version,
                xdgWmBase!.objectId);
            break;
          case "wl_output":
          case "wl_drm":
          case "zxdg_output_manager_v1":
          case "wl_data_device_manager":
          case "zwp_primary_selection_device_manager_v1":
          case "gtk_shell1":
          case "wp_viewporter":
          case "wp_fractional_scale_manager_v1":
          case "zwp_pointer_gestures_v1":
          case "zwp_tablet_manager_v2":
          case "zwp_relative_pointer_manager_v1":
          case "zwp_pointer_constraints_v1":
          case "zxdg_exporter_v2":
          case "zxdg_importer_v2":
          case "zxdg_exporter_v1":
          case "zxdg_importer_v1":
          case "zwp_linux_dmabuf_v1":
          case "wp_single_pixel_buffer_manager_v1":
          case "zwp_keyboard_shortcuts_inhibit_manager_v1":
          case "zwp_text_input_manager_v3":
          case "wp_presentation":
          case "xdg_activation_v1":
          case "zwp_idle_inhibit_manager_v1":
          case "wp_linux_drm_syncobj_manager_v1":
            logLn(
                "Interface ${global.interface} is recognized but not yet handled.");
            break;
          default:
            logLn("Unknown interface: ${global.interface}");
            break;
        }
      } catch (err) {
        logLn("unable to bind ${global.interface} interface: $err");
      }
    })
    ..onGlobalRemove((global) {
      logLn("global RRRRRRRRRRRR: $global");
    });

  var callback = display.sync();
  var done = false;
  callback.onDone((val) {
    logLn("callback.ondone: $val\n");
    done = true;
  });

  while (!done) {
    await Future.delayed(Duration(milliseconds: 1000));
  }

  exit(0);
}
