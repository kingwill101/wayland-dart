import 'package:window_toolkit/window_toolkit.dart';
import 'package:test/test.dart';

import '../lib/src/lua_ui.dart';

const _audioLua = r'''
-- An audio panel drawn entirely from Lua via the cv_* protocol.
local W,H = 220, 148
cv_rrect(0, 0, W, H, 0xff202028, 10)        -- panel background
cv_text(18, 14, 'Audio', 16, 0xffececf4)     -- title
cv_text(18, 38, 'Default speakers', 12, 0xff9a9aaa)
cv_slider(18, 58, W-36, 8, 0.55,            -- sink volume at 55%
        0xff3a4a50, 0xff7fb3d5, 0xfff2f2f7)
cv_text(18, 72, '55%', 12, 0xffb8b8c8)
cv_rect(18, 102, W-36, 1, 0xff2f3438)       -- divider
cv_rrect(18, 110, 46, 22, 0xff2e5d3b, 6)    -- mute pill
cv_text(32, 116, 'Mute', 12, 0xfff2f2f7)
''';

void main() {
  test('Lua draws a volume panel through the window toolkit Painter',
      () async {
    final ui = LuaUi(source: _audioLua, sourceName: 'audio.lua');
    await ui.done;

    // The record is a replayable, shape-correct command list.
    expect(ui.commands, isNotEmpty);
    final panel = ui.commands.first as UiRect;
    expect(panel.w, greaterThanOrEqualTo(200), reason: 'panel width');
    expect(panel.h, greaterThanOrEqualTo(140), reason: 'panel height');

    // Slider → track + fill + a thumb circle.
    expect(ui.commands.whereType<UiCircle>(), isNotEmpty,
        reason: 'slider thumb');

    // Exact labels the script asked for.
    final labels = ui.commands.whereType<UiText>().map((t) => t.text);
    expect(labels, containsAll(['Audio', '55%', 'Mute']));

    // Replays into any window_toolkit Painter (RecordingPainter here).
    final rec = RecordingPainter();
    ui.paint(rec, width: 220, height: 148);
    expect(rec.commands.whereType<DrawCircleCommand>(), isNotEmpty);
    expect(
      rec.commands.whereType<DrawTextCommand>().map((c) => c.text),
      contains('Audio'),
    );
  });
}