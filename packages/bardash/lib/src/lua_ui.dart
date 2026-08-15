/// Lua ⇄ window_toolkit drawing bridge.
///
/// This is **not** baked into `window_toolkit`. It's a thin, self-contained
/// "protocol" layer built in bardash on top of `window_toolkit`'s `Painter`:
///
///  1. Each Lua script calls a small set of `cv_*` globals registered by
///     [LuaUi]. Those calls are the *only* way Lua draws — it never
///     constructs Dart objects.
///  2. The calls are appended to [commands] as plain record objects
///     ([UiCmd]s). This decouples "what Lua wants drawn" from "how it is
///     rendered".
///  3. At a frame, [paint] replays [commands] into any window_toolkit
///     [Painter] (Skia for the real bar, RecordingPainter in tests). The
///     compositor/panel plumbing (a popup surface, the tray-menu pattern)
///     stays in Dart.
///
/// Why a "scripted" immediate API instead of exposing widget constructors?
/// It keeps window_toolkit completely out of Lua (a drawing *protocol, mask*
/// not a widget DSL) and so matches "expose the drawing surface, not the
/// whole class hierarchy." Interactivity is handled on the Dart side by
/// matching pointer hits back to Lua *callback* ids (see `runAction`).
library;

import 'package:lualike/lualike.dart';
import 'package:window_toolkit/window_toolkit.dart';

/// A replayable render command produced by a Lua script.
sealed class UiCmd {
  const UiCmd();
}

/// Filled rounded/plain rect (panel background, slider track, buttons).
class UiRect extends UiCmd {
  final double x, y, w, h, radius;
  final int argb;
  const UiRect(this.x, this.y, this.w, this.h, this.argb, [this.radius = 0]);
}

/// A line of text.
class UiText extends UiCmd {
  final double x, y;
  final String text;
  final double size;
  final int argb;
  const UiText(this.x, this.y, this.text, this.size, this.argb);
}

/// A filled circle (slider thumb).
class UiCircle extends UiCmd {
  final double cx, cy, radius;
  final int argb;
  const UiCircle(this.cx, this.cy, this.radius, this.argb);
}

/// Lua's window into the bar: a small, fixed set of drawing commands.
///
/// Every `cv_*` function registered here becomes a global the Lua script can
/// call. Arguments are unwrapped Dart primitives (ints/doubles/strings);
/// colors are ARGB ints such as `0xff202028`.
class LuaUi {
  final LuaLike lua;
  final List<UiCmd> commands = [];

  /// Completes when the optional [source] passed to the constructor has been
  /// evaluated (so [commands] is readable). Null when no source was given.
  Future<void>? done;

  LuaUi({String? source, String? sourceName}) : lua = LuaLike() {
    _register();
    if (source != null) done = _run(source, sourceName);
  }

  void _register() {
    // (x, y, w, h, argb)
    lua.vm.expose('cv_rect', (num x, num y, num w, num h, num argb) {
      commands.add(UiRect(
          x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble(), argb.toInt()));
    });
    // (x, y, w, h, argb, radius)
    lua.vm.expose(
        'cv_rrect', (num x, num y, num w, num h, num argb, num radius) {
      commands.add(UiRect(x.toDouble(), y.toDouble(), w.toDouble(),
          h.toDouble(), argb.toInt(), radius.toDouble()));
    });
    // (x, y, text, size, argb)
    lua.vm.expose('cv_text', (num x, num y, Object text, num size, num argb) {
      commands.add(UiText(x.toDouble(), y.toDouble(), text.toString(),
          size.toDouble(), argb.toInt()));
    });
    // (cx, cy, radius, argb)
    lua.vm.expose('cv_circle', (num cx, num cy, num radius, num argb) {
      commands.add(UiCircle(cx.toDouble(), cy.toDouble(), radius.toDouble(),
          argb.toInt()));
    });
    // Convenience slider:
    // (x, y, w, h, fraction, trackArgb, fillArgb, thumbArgb)
    lua.vm.expose('cv_slider',
        (num x, num y, num w, num h, num frac, num track, num fill, num thumb) {
      final xd = x.toDouble(), yd = y.toDouble(), wd = w.toDouble(), hd = h.toDouble();
      final f = frac.toDouble().clamp(0.0, 1.0);
      commands.add(UiRect(xd, yd, wd, hd, track.toInt()));
      commands.add(UiRect(xd, yd, wd * f, hd, fill.toInt()));
      commands.add(
          UiCircle(xd + wd * f, yd + hd / 2, hd / 2 + 2, thumb.toInt()));
    });
  }

  Future<void> _run(String source, String? name) async {
    await lua.execute(source, scriptPath: name);
  }

  /// Render the recorded commands into [painter].
  void paint(Painter painter, {int? width, int? height}) {
    if (width != null && height != null) {
      painter.clear(const Color(0, 0, 0, 0));
    }
    for (final c in commands) {
      if (c is UiRect) {
        final rect = Rect.fromLTWH(c.x, c.y, c.w, c.h);
        final p = Paint()..color = Color.fromArgb8888(c.argb);
        if (c.radius > 0) {
          painter.drawRRect(rect, c.radius, c.radius, p);
        } else {
          painter.drawRect(rect, p);
        }
      } else if (c is UiText) {
        painter.drawText(
          c.text,
          Offset(c.x, c.y),
          color: Color.fromArgb8888(c.argb),
          size: c.size,
        );
      } else if (c is UiCircle) {
        painter.drawCircle(Offset(c.cx, c.cy), c.radius,
            Paint()..color = Color.fromArgb8888(c.argb));
      }
    }
  }

  UiText? findText(String text) {
    for (final c in commands) {
      if (c is UiText && c.text == text) return c;
    }
    return null;
  }
}