import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../lib/src/audio_popup.dart';
import '../lib/src/modules/audio.dart';
import '../lib/src/modules/registry.dart';
import '../lib/src/native/mpris_client.dart';

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

  group('AudioPanelWidget', () {
    tearDown(StyleContext.reset);

    AudioPanelWidget buildPanel() => AudioPanelWidget(
      onMute: () {},
      onMicMute: () {},
      onMixer: () {},
      onPrevious: () {},
      onPlayPause: () {},
      onNext: () {},
      onOutputChanged: (_) {},
      onMicChanged: (_) {},
    );

    test('is composed from toolkit controls with stable CSS hooks', () {
      final panel = buildPanel();

      expect(panel.styleId, 'audio-popup');
      expect(panel.hasClass('popup'), isTrue);
      expect(panel.children, contains(panel.outputSlider));
      expect(panel.children, contains(panel.playPauseButton));
      expect(panel.children, contains(panel.mixerButton));
      expect(panel.outputSlider, isA<Slider>());
      expect(panel.outputSlider.min, 0);
      expect(panel.outputSlider.max, 1);
      expect(panel.muteButton, isA<Button>());
      expect(panel.previousButton, isA<TransportButton>());
    });

    test('lays out controls inside the popup bounds', () {
      final panel = buildPanel();
      panel.performLayout(300);

      for (final child in panel.children) {
        expect(child.x, greaterThanOrEqualTo(0));
        expect(child.y, greaterThanOrEqualTo(0));
        expect(child.x + child.width, lessThanOrEqualTo(panel.width));
        expect(child.y + child.height, lessThanOrEqualTo(panel.height));
      }
      expect(panel.outputSlider.width, greaterThan(panel.muteButton.width));
      expect(panel.mixerButton.x, greaterThan(panel.micMuteButton.x));
    });

    test('descendant CSS reaches audio controls and hover states', () {
      final css = CssProvider()
        ..loadFromString('''
          #audio-popup { background-color: #101820; border-radius: 16px; padding: 20px; }
          #audio-popup .audio-action { background-color: #263849; padding: 10px 14px; }
          #audio-popup .audio-action:hover { background-color: #405a72; }
          #audio-popup .audio-slider { background-color: #202b35; color: #8bd5ca; border-color: #f5e0c0; }
        ''');
      StyleContext.addProvider(css, priority: StyleProviderPriority.user);

      final panel = buildPanel();
      panel.performLayout(300);

      expect(panel.resolvedStyle().borderRadius, 16);
      expect(panel.styledPaddingLeft(), 20);
      expect(panel.muteButton.resolvedStyle().backgroundColor, isNotNull);
      expect(panel.muteButton.resolvedStyle().backgroundColor!.r, 0x26);
      expect(
        panel.muteButton.resolvedStyleOn(const ['hover']).backgroundColor!.r,
        0x40,
      );
      expect(panel.outputSlider.resolvedStyle().backgroundColor!.r, 0x20);
      expect(panel.outputSlider.resolvedStyle().color.r, 0x8b);
      expect(panel.outputSlider.resolvedStyle().borderColor.r, 0xf5);

      panel.updateAudio(
        output: 1,
        muted: false,
        mic: 0.5,
        micMuted: false,
        media: MprisSnapshot.empty,
      );
      expect(panel.outputSlider.value, 1);
      expect(panel.outputValue.text, '100%');
    });
  });
}
