/// A click-to-open audio panel (Windows-tray style) for bardash.
///
/// Clicking an audio module pops an overlay-layer panel with a master
/// volume slider + a mute toggle. Pointer drag on the slider drives
/// [PulseClient] (in-process), and the panel reflects live sink state.
///
/// Surface plumbing mirrors `tray_menu.dart` (the pattern proven there): a
/// dedicated `zwlr_layer_shell` overlay surface + a transparent full-output
/// dismiss catcher that closes on outside click. Geometry and hit-testing
/// are a pure, unit-testable [AudioPanelLayout].
library;

import 'dart:async' show unawaited;
import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import 'native/pulse_client.dart';
import 'native/mpris_client.dart';

/// Pure layout + hit-testing for the audio panel. No Wayland, so it's
/// unit-testable headless.
class AudioPanelLayout {
  final int width;
  final int height;

  AudioPanelLayout({int? width, int? height})
    : width = width ?? 240,
      height = height ?? 200;

  static const pad = 12;
  static const sliderH = 8;
  static const thumbR = 7;

  // Sink (output) row.
  static const sliderY = 58;
  // Source (mic) row.
  static const sourceSliderY = 106;
  // Bottom action row.
  static const actionH = 24;

  int get mediaY => height - 106;
  int get actionsY => height - 42;

  Rect mediaPrevious() =>
      Rect.fromLTWH((width / 2 - 76).toDouble(), mediaY.toDouble(), 44, 30);
  Rect mediaPlayPause() =>
      Rect.fromLTWH((width / 2 - 22).toDouble(), mediaY.toDouble(), 44, 30);
  Rect mediaNext() =>
      Rect.fromLTWH((width / 2 + 32).toDouble(), mediaY.toDouble(), 44, 30);

  int get sliderX => pad;
  int get sliderW => width - pad * 2;

  bool _inTrackBand(double y, int trackTop) =>
      y >= trackTop - 6 && y <= trackTop + sliderH + 8;

  Rect sliderTrack() => Rect.fromLTWH(
    sliderX.toDouble(),
    sliderY.toDouble(),
    sliderW.toDouble(),
    sliderH.toDouble(),
  );

  Rect sourceSliderTrack() => Rect.fromLTWH(
    sliderX.toDouble(),
    sourceSliderY.toDouble(),
    sliderW.toDouble(),
    sliderH.toDouble(),
  );

  Offset thumbCenter(double fraction) => Offset(
    sliderX + sliderW * fraction.clamp(0.0, 1.0),
    sliderY + sliderH / 2,
  );

  Offset sourceThumbCenter(double fraction) => Offset(
    sliderX + sliderW * fraction.clamp(0.0, 1.0),
    sourceSliderY + sliderH / 2,
  );

  Rect muteButton() => Rect.fromLTWH(
    pad.toDouble(),
    actionsY.toDouble(),
    52.0,
    actionH.toDouble(),
  );

  Rect micMuteButton() => Rect.fromLTWH(
    (pad + 60).toDouble(),
    actionsY.toDouble(),
    52.0,
    actionH.toDouble(),
  );

  Rect mixerButton() => Rect.fromLTWH(
    (pad + 120).toDouble(),
    actionsY.toDouble(),
    (width - pad - (pad + 120)).toDouble(),
    actionH.toDouble(),
  );

  bool hitSlider(double x, double y) =>
      _inTrackBand(y, sliderY) &&
      x >= sliderX - thumbR &&
      x <= sliderX + sliderW + thumbR;

  bool hitSourceSlider(double x, double y) =>
      _inTrackBand(y, sourceSliderY) &&
      x >= sliderX - thumbR &&
      x <= sliderX + sliderW + thumbR;

  bool _inRect(Rect b, double x, double y) =>
      x >= b.left && x <= b.right && y >= b.top && y <= b.bottom;

  bool hitMute(double x, double y) => _inRect(muteButton(), x, y);

  bool hitMicMute(double x, double y) => _inRect(micMuteButton(), x, y);

  bool hitMixer(double x, double y) => _inRect(mixerButton(), x, y);
  bool hitMediaPrevious(double x, double y) => _inRect(mediaPrevious(), x, y);
  bool hitMediaPlayPause(double x, double y) => _inRect(mediaPlayPause(), x, y);
  bool hitMediaNext(double x, double y) => _inRect(mediaNext(), x, y);

  /// Fraction (0..1) for an x inside the track.
  double fractionForX(double x) => ((x - sliderX) / sliderW).clamp(0.0, 1.0);
}

/// Toolkit-owned audio popup content.
///
/// The layer surface is still owned by the overlay adapter, but every visible
/// control is a normal toolkit widget. This keeps CSS ancestry, measurement,
/// hover animation, hit testing, and text rendering identical to the rest of
/// the toolkit.
class AudioPanelWidget extends Widget {
  final int panelWidth;
  final int panelHeight;
  final VoidCallback onMute;
  final VoidCallback onMicMute;
  final VoidCallback onMixer;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final void Function(double value) onOutputChanged;
  final void Function(double value) onMicChanged;

  late final Label title;
  late final Label outputLabel;
  late final Label outputValue;
  late final Slider outputSlider;
  late final Label micLabel;
  late final Label micValue;
  late final Slider micSlider;
  late final Separator divider;
  late final Label mediaTitle;
  late final Label mediaArtist;
  late final TransportButton previousButton;
  late final TransportButton playPauseButton;
  late final TransportButton nextButton;
  late final Button muteButton;
  late final Button micMuteButton;
  late final Button mixerButton;

  @override
  late final List<Widget> children;

  AudioPanelWidget({
    this.panelWidth = 300,
    this.panelHeight = 292,
    required this.onMute,
    required this.onMicMute,
    required this.onMixer,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    required this.onOutputChanged,
    required this.onMicChanged,
  }) {
    styleId = 'audio-popup';
    addClass('popup');
    addClass('audio-popup');

    title = Label('Audio', fontSize: 15)
      ..styleId = 'audio-title'
      ..addClass('popup-title');
    outputLabel = Label('Output', fontSize: 12)
      ..styleId = 'audio-output-label'
      ..addClass('audio-label');
    outputValue = Label('0%', fontSize: 12)
      ..styleId = 'audio-output-value'
      ..addClass('audio-value');
    outputSlider = Slider(min: 0, max: 1, showValue: false, onChanged: () {})
      ..styleId = 'audio-output-slider'
      ..addClass('audio-slider')
      ..addClass('output-slider');
    outputSlider.onChanged = () => onOutputChanged(outputSlider.value);

    micLabel = Label('Mic', fontSize: 12)
      ..styleId = 'audio-mic-label'
      ..addClass('audio-label');
    micValue = Label('0%', fontSize: 12)
      ..styleId = 'audio-mic-value'
      ..addClass('audio-value');
    micSlider = Slider(min: 0, max: 1, showValue: false, onChanged: () {})
      ..styleId = 'audio-mic-slider'
      ..addClass('audio-slider')
      ..addClass('mic-slider');
    micSlider.onChanged = () => onMicChanged(micSlider.value);

    divider = Separator(lineWidth: 1, margin: 0)
      ..styleId = 'audio-divider'
      ..addClass('audio-divider');
    mediaTitle = Label('No media player', fontSize: 13, maxWidth: 272)
      ..styleId = 'audio-media-title'
      ..addClass('media-title');
    mediaArtist = Label('MPRIS', fontSize: 11, maxWidth: 272)
      ..styleId = 'audio-media-artist'
      ..addClass('media-artist');

    previousButton =
        TransportButton(TransportAction.previous, onPressed: onPrevious)
          ..styleId = 'audio-previous'
          ..addClass('transport-button');
    playPauseButton =
        TransportButton(TransportAction.play, onPressed: onPlayPause)
          ..styleId = 'audio-play-pause'
          ..addClass('transport-button');
    nextButton = TransportButton(TransportAction.next, onPressed: onNext)
      ..styleId = 'audio-next'
      ..addClass('transport-button');

    muteButton = Button('Mute', onPressed: onMute, padding: 8)
      ..styleId = 'audio-mute'
      ..addClass('audio-action');
    micMuteButton = Button('Mic', onPressed: onMicMute, padding: 8)
      ..styleId = 'audio-mic-mute'
      ..addClass('audio-action');
    mixerButton = Button('Mixer', onPressed: onMixer, padding: 8)
      ..styleId = 'audio-mixer'
      ..addClass('audio-action')
      ..addClass('mixer-action');

    children = [
      title,
      outputLabel,
      outputValue,
      outputSlider,
      micLabel,
      micValue,
      micSlider,
      divider,
      mediaTitle,
      mediaArtist,
      previousButton,
      playPauseButton,
      nextButton,
      muteButton,
      micMuteButton,
      mixerButton,
    ];
  }

  @override
  Style styleRole() => Style(
    color: const Color(240, 240, 245),
    backgroundColor: const Color(32, 32, 36),
    borderColor: const Color(90, 90, 100),
    borderWidth: 1,
    borderRadius: 10,
  );

  void updateAudio({
    required double output,
    required bool muted,
    required double mic,
    required bool micMuted,
    required MprisSnapshot media,
  }) {
    outputSlider.value = output.clamp(0.0, 1.0);
    micSlider.value = mic.clamp(0.0, 1.0);
    outputValue.text = '${(outputSlider.value * 100).round()}%';
    micValue.text = '${(micSlider.value * 100).round()}%';
    mediaTitle.text = media.hasTrack ? media.title : 'No media player';
    mediaArtist.text = media.hasTrack
        ? (media.artist.isEmpty ? media.identity : media.artist)
        : 'MPRIS';
    playPauseButton.action = media.isPlaying
        ? TransportAction.pause
        : TransportAction.play;
    if (muted) {
      muteButton.text = 'Unmute';
      muteButton.addPseudoClass('muted');
    } else {
      muteButton.text = 'Mute';
      muteButton.removePseudoClass('muted');
    }
    if (micMuted) {
      micMuteButton.text = 'Mic on';
      micMuteButton.addPseudoClass('muted');
    } else {
      micMuteButton.text = 'Mic';
      micMuteButton.removePseudoClass('muted');
    }
    requestRepaint();
  }

  @override
  void performLayout(int containerWidth) {
    final left = styledPaddingLeft(14);
    final right = styledPaddingRight(14);
    final top = styledPaddingTop(12);
    width = panelWidth;
    height = panelHeight;
    final innerWidth = (width - left - right).clamp(1, width);

    for (final child in children) {
      child.parent = this;
      child.performLayout(innerWidth);
    }

    void place(Widget child, int px, int py, int pw, int ph) {
      child
        ..x = x + px
        ..y = y + py
        ..width = pw
        ..height = ph;
    }

    place(title, left, top, innerWidth, 22);
    place(outputLabel, left, 39, innerWidth - 48, 16);
    place(outputValue, width - right - 46, 39, 46, 16);
    place(outputSlider, left, 56, innerWidth, 22);
    place(micLabel, left, 87, innerWidth - 48, 16);
    place(micValue, width - right - 46, 87, 46, 16);
    place(micSlider, left, 104, innerWidth, 22);
    place(divider, left, 132, innerWidth, 1);
    place(mediaTitle, left, 145, innerWidth, 18);
    place(mediaArtist, left, 164, innerWidth, 16);

    final transportY = 184;
    place(previousButton, width ~/ 2 - 76, transportY, 44, 30);
    place(playPauseButton, width ~/ 2 - 22, transportY, 44, 30);
    place(nextButton, width ~/ 2 + 32, transportY, 44, 30);

    final actionY = height - 42;
    place(muteButton, left, actionY, 54, 28);
    place(micMuteButton, left + 62, actionY, 54, 28);
    place(
      mixerButton,
      left + 124,
      actionY,
      (width - right - left - 124).clamp(54, width),
      28,
    );
  }

  @override
  void draw(Painter painter) {
    drawStyledBox(painter);
    for (final child in children) {
      child.draw(painter);
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    for (final child in children.reversed) {
      if (child.hitTest(px, py)) return true;
    }
    return true;
  }
}

class AudioPopupController {
  static LayerPopup? _active;
  static AudioPanelWidget? _view;
  static void Function(PulseSnapshot)? _pulseListener;
  static void Function(MprisSnapshot)? _mediaListener;
  static int _generation = 0;

  static bool get isOpen => _active?.isOpen ?? false;

  static void close() {
    _generation++;
    _active?.close();
    _active = null;
    _removeListeners();
  }

  static Future<void> open({
    required LayerPopupHost popupHost,
    required int anchorX,
    required int parentWidth,
    required int parentHeight,
    required bool openUpward,
    String? mixerCommand,
  }) async {
    final gen = ++_generation;
    _active?.close();
    _active = null;

    final pulse = PulseClient.instance.last;
    final media = MprisClient.instance.last;
    final value = (pulse.sinkPercent / 100).clamp(0.0, 1.0);
    final micValue = (pulse.sourcePercent / 100).clamp(0.0, 1.0);
    late final AudioPanelWidget view;
    view =
        AudioPanelWidget(
          onMute: PulseClient.instance.toggleMute,
          onMicMute: PulseClient.instance.toggleSourceMute,
          onMixer: () => _openMixer(mixerCommand),
          onPrevious: MprisClient.instance.previous,
          onPlayPause: MprisClient.instance.playPause,
          onNext: MprisClient.instance.next,
          onOutputChanged: (next) {
            final target = (next * 100).round();
            final delta = target - PulseClient.instance.last.sinkPercent;
            if (delta != 0) PulseClient.instance.stepVolume(delta);
          },
          onMicChanged: (next) {
            final target = (next * 100).round();
            final delta = target - PulseClient.instance.last.sourcePercent;
            if (delta != 0) PulseClient.instance.stepSourceVolume(delta);
          },
        )..updateAudio(
          output: value,
          muted: pulse.sinkMuted,
          mic: micValue,
          micMuted: pulse.sourceMuted,
          media: media,
        );
    _view = view;

    final placement = BarPopupPlacement.forBar(
      anchorX: anchorX,
      parentWidth: parentWidth,
      width: view.panelWidth,
      height: view.panelHeight,
      openUpward: openUpward,
      keyboardMode: LayerKeyboardMode.exclusive,
    );
    final dismissPlacement = LayerSurfacePlacement(
      anchors: {
        LayerEdge.top,
        LayerEdge.right,
        LayerEdge.bottom,
        LayerEdge.left,
      },
      width: 0,
      height: 0,
      marginTop: openUpward ? 0 : parentHeight,
      marginBottom: openUpward ? parentHeight : 0,
      exclusiveZone: -1,
      keyboardMode: LayerKeyboardMode.none,
    );
    late final LayerPopup popup;
    popup = popupHost.create(
      content: view,
      placement: placement,
      dismissPlacement: dismissPlacement,
      background: const Color(0, 0, 0, 0),
      onEvent: (event) {
        if (event.isOutsideClick) {
          popup.close();
          return false;
        }
        return false;
      },
      onClosed: () {
        _removeListeners();
        view.dispose();
        if (identical(_active, popup)) {
          _active = null;
          _view = null;
        }
      },
    );
    _active = popup;
    try {
      if (!await popup.show()) {
        if (identical(_active, popup)) _active = null;
        return;
      }
    } catch (e) {
      stderr.writeln('[audio] popup failed: $e');
      popup.close();
      return;
    }
    if (gen != _generation) return;

    _pulseListener = (state) {
      final current = _view;
      if (current == null || !_active!.isOpen) return;
      current.updateAudio(
        output: state.sinkPercent / 100,
        muted: state.sinkMuted,
        mic: state.sourcePercent / 100,
        micMuted: state.sourceMuted,
        media: MprisClient.instance.last,
      );
    };
    PulseClient.instance.addListener(_pulseListener!);
    _mediaListener = (state) {
      final current = _view;
      if (current == null || !_active!.isOpen) return;
      final pulseState = PulseClient.instance.last;
      current.updateAudio(
        output: pulseState.sinkPercent / 100,
        muted: pulseState.sinkMuted,
        mic: pulseState.sourcePercent / 100,
        micMuted: pulseState.sourceMuted,
        media: state,
      );
    };
    MprisClient.instance.addListener(_mediaListener!);
    stderr.writeln(
      '[audio] open toolkit popup ${view.panelWidth}x${view.panelHeight} '
      'anchorX=$anchorX',
    );
  }

  static void _removeListeners() {
    if (_pulseListener != null) {
      PulseClient.instance.removeListener(_pulseListener!);
      _pulseListener = null;
    }
    if (_mediaListener != null) {
      MprisClient.instance.removeListener(_mediaListener!);
      _mediaListener = null;
    }
  }

  static void _openMixer(String? configured) {
    final requested = configured?.trim() ?? '';
    final candidates = requested.isNotEmpty
        ? [requested]
        : ['pavucontrol', 'pwvucontrol', 'helvum', 'qpwgraph'];
    for (final command in candidates) {
      final result = Process.runSync('which', [command]);
      if (result.exitCode == 0 || requested.isNotEmpty) {
        stderr.writeln('[audio] opening mixer: $command');
        unawaited(Process.run(command, const [], runInShell: false));
        return;
      }
    }
    stderr.writeln('[audio] no mixer found');
  }
}
