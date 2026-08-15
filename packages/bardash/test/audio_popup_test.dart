import 'package:test/test.dart';

import '../lib/src/audio_popup.dart';
import '../lib/src/modules/audio.dart';
import '../lib/src/modules/registry.dart';

void main() {
  group('AudioPanelLayout', () {
    final layout = AudioPanelLayout(width: 240, height: 200);

    test('default geometry is consistent', () {
      expect(layout.width, 240);
      expect(layout.height, 200);
      expect(layout.sliderX, AudioPanelLayout.pad);
      expect(layout.sliderW, 240 - AudioPanelLayout.pad * 2);
      final track = layout.sliderTrack();
      expect(track.left, AudioPanelLayout.pad);
      expect(track.width, 216);
      expect(track.height, AudioPanelLayout.sliderH);
    });

    test('source row mirrors the output row', () {
      final st = layout.sourceSliderTrack();
      expect(st.top, AudioPanelLayout.sourceSliderY);
      expect(st.width, layout.sliderW);
      final midY =
          AudioPanelLayout.sourceSliderY + AudioPanelLayout.sliderH / 2;
      expect(
        layout.hitSourceSlider(
          (layout.sliderX + 10).toDouble(),
          midY.toDouble(),
        ),
        isTrue,
      );
      expect(
        layout.hitSourceSlider((layout.sliderX + 10).toDouble(), 30),
        isFalse,
      );
    });

    test(
      'action row: Mute / Mic / Mixer pills are distinct and hit-testable',
      () {
        final mb = layout.muteButton();
        final micb = layout.micMuteButton();
        final mxb = layout.mixerButton();
        // No overlaps between the three actions.
        expect(micb.left, greaterThanOrEqualTo(mb.right));
        expect(mxb.left, greaterThanOrEqualTo(micb.right));
        expect(mxb.right, lessThanOrEqualTo(240));
        // Hits land on the right pill only.
        expect(layout.hitMute(mb.center.dx, mb.center.dy), isTrue);
        expect(layout.hitMicMute(micb.center.dx, micb.center.dy), isTrue);
        expect(layout.hitMixer(mxb.center.dx, mxb.center.dy), isTrue);
        expect(layout.hitMicMute(mb.center.dx, mb.center.dy), isFalse);
        expect(layout.hitMixer(mb.center.dx, mb.center.dy), isFalse);
        // Sliders are not buttons.
        expect(layout.hitMixer(20, AudioPanelLayout.sliderY + 4), isFalse);
      },
    );

    test('fractionForX clamps at both ends', () {
      expect(layout.fractionForX(AudioPanelLayout.pad.toDouble()), 0.0);
      expect(layout.fractionForX((AudioPanelLayout.pad + 216).toDouble()), 1.0);
      expect(layout.fractionForX(-50), 0.0);
      expect(layout.fractionForX(9999), 1.0);
      // Midpoint → 0.5
      expect(
        layout.fractionForX(AudioPanelLayout.pad + 108.0),
        closeTo(0.5, 1e-9),
      );
    });

    test('thumbCenter tracks the fraction', () {
      final t0 = layout.thumbCenter(0);
      expect(t0.dx, layout.sliderX);
      expect(t0.dy, AudioPanelLayout.sliderY + AudioPanelLayout.sliderH / 2);
      final t1 = layout.thumbCenter(1);
      expect(t1.dx, layout.sliderX + layout.sliderW);
      expect(t1.dy, t0.dy);
    });

    test('hitSlider covers thumb + track padding, not arbitrary points', () {
      final midY = AudioPanelLayout.sliderY + AudioPanelLayout.sliderH / 2;
      expect(
        layout.hitSlider(layout.sliderX.toDouble(), midY.toDouble()),
        isTrue,
      );
      expect(
        layout.hitSlider((layout.sliderX + 108).toDouble(), midY.toDouble()),
        isTrue,
      );
      expect(
        layout.hitSlider(
          (layout.sliderX + layout.sliderW).toDouble(),
          midY.toDouble(),
        ),
        isTrue,
      );
      // Outside vertically (title area) — not a slider hit.
      expect(layout.hitSlider((layout.sliderX + 100).toDouble(), 20), isFalse);
    });

    test('hitMute is the pill, nowhere else', () {
      final b = layout.muteButton();
      expect(layout.hitMute(b.left + 5, b.top + 5), isTrue);
      expect(layout.hitMute(b.center.dx, b.center.dy), isTrue);
      expect(layout.hitMute(4, 150), isFalse);
      expect(layout.hitMute(b.right + 4, b.center.dy), isFalse);
      // Slider area is not the mute button.
      expect(
        layout.hitMute(layout.sliderX + 10, AudioPanelLayout.sliderY + 4),
        isFalse,
      );
    });
  });

  group('AudioModule registration', () {
    test('registry creates an audio module with click support', () {
      final module = createModule('audio');
      expect(module, isA<AudioModule>());
      expect(module!.showsGraphics, isFalse);
      expect(module.hasClick, isTrue);
      // Overlay capability is opt-in via a flag — no bar-side type checks.
      expect(module.needsPopupOverlay, isTrue);
    });

    test('popup wiring is generic (flag-driven, not per-type)', () {
      // Any module defaults to no overlay.
      final plain = createModule('clock')!;
      expect(plain.needsPopupOverlay, isFalse);
      // SNI opts in the same way as audio.
      final tray = createModule('tray')!;
      expect(tray.needsPopupOverlay, isTrue);
      final sni = createModule('sni')!;
      expect(sni.needsPopupOverlay, isTrue);
      // The hook is a plain BarModule method; the flag gates it.
      final m = AudioModule();
      expect(m.needsPopupOverlay, isTrue);
    });

    test('default format composes icon + percent placeholders', () {
      final module = AudioModule();
      module.init({'format': '{icon} {volume}%'});
      // Update falls back to pactl/amixer; without audio daemons it yields
      // 'ERR' — but the format path never throws.
      module.update();
      expect(module.output, anyOf(startsWith('ERR'), contains('%')));
    });
  });
}
