import 'dart:async' as async;
import 'dart:io';

import '../app.dart';
import '../backend/wayland_layer_surface.dart';
import '../backend/wayland_shm_presenter.dart';
import '../backend/connection.dart';
import '../drawing/color.dart';
import '../mixins/event.dart';
import '../widget.dart';
import '../widget_host.dart';

enum LayerPopupRegion { content, outside }

class LayerPopupEvent {
  final Event event;
  final LayerPopupRegion region;

  const LayerPopupEvent(this.event, this.region);

  bool get isOutside => region == LayerPopupRegion.outside;

  /// A press outside content should dismiss the popup and may continue to the
  /// underlying bar, allowing one click to switch to another popup.
  bool get isOutsideClick =>
      isOutside &&
      event is MouseButtonEvent &&
      (event as MouseButtonEvent).isPressed;
}

typedef LayerPopupEventHandler = bool Function(LayerPopupEvent event);

/// Creates toolkit-owned layer-shell popups for layer-backed windows.
class LayerPopupHost {
  final WaylandConnection _connection;
  int _serial = 0;
  LayerPopup? _active;

  LayerPopupHost(this._connection);

  /// Whether this host currently owns a visible or configuring popup.
  bool get hasActivePopup => _active != null && !_active!._closed;

  /// Close the host's active popup without requiring callers to know its
  /// concrete popup type. Bar/window shells use this before handling a click
  /// on their own surface, which makes popup switching deterministic even if
  /// the compositor does not send a fresh pointer-enter event.
  void closeActivePopup() => _active?.close();

  /// The platform connection used by toolkit-owned legacy adapters.
  ///
  /// New popup content should use [create] and remain independent of this
  /// backend detail. The getter is intentionally limited to the host so
  /// existing toolkit integrations can migrate incrementally.
  WaylandConnection get connection => _connection;

  LayerPopup create({
    required Widget content,
    required LayerSurfacePlacement placement,
    required LayerSurfacePlacement dismissPlacement,
    Color background = const Color(0, 0, 0, 0),
    bool routeWidgetEvents = true,
    LayerPopupEventHandler? onEvent,
    void Function()? onClosed,
  }) {
    return LayerPopup._(
      host: this,
      connection: _connection,
      namespace: 'window-toolkit-popup-${++_serial}',
      content: content,
      placement: placement,
      dismissPlacement: dismissPlacement,
      background: background,
      routeWidgetEvents: routeWidgetEvents,
      onEvent: onEvent,
      onClosed: onClosed,
    );
  }

  void _activate(LayerPopup popup) {
    final previous = _active;
    if (previous != null && !identical(previous, popup)) {
      previous.close();
    }
    _active = popup;
  }

  void _deactivate(LayerPopup popup) {
    if (identical(_active, popup)) _active = null;
  }
}

/// A widget-backed layer popup with a transparent outside-click surface.
///
/// Wayland layer-shell objects, SHM buffers, event registration, and frame
/// presentation are deliberately private to this class. Callers provide a
/// widget tree, placement, and optional event policy only.
class LayerPopup with EventReceiver {
  final LayerPopupHost _host;
  final WaylandConnection _connection;
  final String namespace;
  final Widget content;
  final LayerSurfacePlacement placement;
  final LayerSurfacePlacement dismissPlacement;
  final Color background;
  final bool routeWidgetEvents;
  final LayerPopupEventHandler? _eventHandler;
  final void Function()? onClosed;
  late final WidgetHostController _widgetHost;

  WaylandLayerSurface? _surface;
  WaylandLayerSurface? _dismissSurface;
  WaylandShmPresenter? _presenter;
  WaylandShmPresenter? _dismissPresenter;
  bool _open = false;
  bool _paintScheduled = false;
  bool _needsPaint = false;
  bool _closed = false;
  int _openedAtMs = 0;

  LayerPopup._({
    required LayerPopupHost host,
    required WaylandConnection connection,
    required this.namespace,
    required this.content,
    required this.placement,
    required this.dismissPlacement,
    required this.background,
    required this.routeWidgetEvents,
    required LayerPopupEventHandler? onEvent,
    required this.onClosed,
  }) : _host = host,
       _connection = connection,
       _eventHandler = onEvent {
    _widgetHost = WidgetHostController(content, onRepaint: requestRepaint);
  }

  bool get isOpen => _open;

  int get width => placement.width;

  int get height => placement.height;

  Future<bool> show() async {
    if (_open) return true;
    _host._activate(this);
    _closed = false;
    try {
      // Create the dismiss surface first. Both surfaces live on the overlay
      // layer; committing the content second keeps the popup above its full
      // output click catcher.
      final dismissSurface = WaylandLayerSurface.create(
        connection: _connection,
        namespace: '$namespace-dismiss',
      );
      final contentSurface = WaylandLayerSurface.create(
        connection: _connection,
        namespace: namespace,
      );
      _dismissSurface = dismissSurface;
      _surface = contentSurface;
      if (contentSurface == null || dismissSurface == null) {
        close();
        return false;
      }

      contentSurface.configure(placement);
      dismissSurface.configure(dismissPlacement);

      var contentReady = false;
      var dismissReady = false;
      final configured = async.Completer<void>();
      void completeIfReady() {
        if (contentReady && dismissReady && !configured.isCompleted) {
          configured.complete();
        }
      }

      contentSurface.onConfigure((_, __) {
        contentReady = true;
        completeIfReady();
      });
      dismissSurface.onConfigure((width, height) {
        _configuredDismissWidth = width > 0 ? width : 1;
        _configuredDismissHeight = height > 0 ? height : 1;
        dismissReady = true;
        completeIfReady();
      });
      contentSurface.onClosed(close);
      dismissSurface.onClosed(() {});
      dismissSurface.commit();
      contentSurface.commit();

      await configured.future.timeout(const Duration(milliseconds: 500));
    } on async.TimeoutException {
      stderr.writeln('[wt:popup] configure timeout');
      close();
      return false;
    } catch (e) {
      stderr.writeln('[wt:popup] show failed: $e');
      close();
      return false;
    }

    // A compositor close can arrive while waiting for configure.  Do not
    // dereference the handles after that asynchronous teardown.
    final contentSurface = _surface;
    final dismissSurface = _dismissSurface;
    if (_closed || contentSurface == null || dismissSurface == null) {
      close();
      return false;
    }

    try {
      _presenter = WaylandShmPresenter(
        connection: _connection,
        surface: contentSurface.surface,
        width: width,
        height: height,
        logTag: '[wt:popup]',
        onBufferAvailable: requestRepaint,
      );
      _dismissPresenter = WaylandShmPresenter(
        connection: _connection,
        surface: dismissSurface.surface,
        width: _configuredDismissWidth,
        height: _configuredDismissHeight,
        bufferCount: 1,
        logTag: '[wt:popup:dismiss]',
      );
      if (!_presenter!.initialize()) {
        close();
        return false;
      }
      _dismissPresenter!.present((_) {});
      _open = true;
      _openedAtMs = DateTime.now().millisecondsSinceEpoch;
      Application.instance.prependEventReceiver(this);
      requestRepaint();
      return true;
    } catch (e) {
      stderr.writeln('[wt:popup] presenter setup failed: $e');
      close();
      return false;
    }
  }

  int _configuredDismissWidth = 1;
  int _configuredDismissHeight = 1;

  void requestRepaint() {
    if (!_open || _closed) return;
    _needsPaint = true;
    if (_paintScheduled) return;
    _paintScheduled = true;
    async.scheduleMicrotask(() {
      _paintScheduled = false;
      if (_open && _needsPaint) _paint();
    });
  }

  void _paint() {
    final presenter = _presenter;
    if (presenter == null) return;
    if (presenter.present((painter) {
      content
        ..x = 0
        ..y = 0
        ..width = width
        ..height = height;
      if (routeWidgetEvents) {
        _widgetHost.draw(painter, width: width, height: height);
      } else {
        content.measure(painter);
        content.performLayout(width);
        content.draw(painter);
      }
    }, clearColor: background)) {
      _needsPaint = false;
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    final wasOpen = _open;
    final hadResources = wasOpen || _surface != null || _dismissSurface != null;
    _open = false;
    _host._deactivate(this);
    Application.instance.removeEventReceiver(this);
    _presenter?.dispose();
    _presenter = null;
    _dismissPresenter?.dispose();
    _dismissPresenter = null;
    _surface?.destroy();
    _surface = null;
    _dismissSurface?.destroy();
    _dismissSurface = null;
    if (hadResources) onClosed?.call();
  }

  void destroy() => close();

  @override
  void onEvent(Event event) {
    if (!_open) return;

    final surfaceId = _connection.pointerSurfaceId;
    final contentId = _surface?.surfaceId;
    final outsideId = _dismissSurface?.surfaceId;
    // The dismiss surface is normally full-output, but a click may still be
    // delivered by the bar or another surface when layer-shell input regions
    // overlap. Every non-content pointer surface is outside this popup.
    final region = event is MouseEvent
        ? surfaceId == contentId
              ? LayerPopupRegion.content
              : LayerPopupRegion.outside
        : LayerPopupRegion.content;

    if (Platform.environment['BARDASH_DEBUG_POPUPS'] == '1' &&
        event is MouseButtonEvent) {
      stderr.writeln(
        '[wt:popup] button=${event.button} pressed=${event.isPressed} '
        'surface=$surfaceId content=$contentId dismiss=$outsideId '
        'region=$region',
      );
    }

    final age = DateTime.now().millisecondsSinceEpoch - _openedAtMs;
    if (age < 200) {
      event.accept();
      return;
    }

    if (event is KeyEvent &&
        event.isPressed &&
        (event.key == 1 || event.character == '\x1b')) {
      close();
      event.accept();
      return;
    }

    var widgetHandled = false;
    if (routeWidgetEvents && region == LayerPopupRegion.content) {
      widgetHandled = _routeWidgetEvent(event);
    }
    final handled =
        widgetHandled ||
        (_eventHandler?.call(LayerPopupEvent(event, region)) ?? false);
    if (region == LayerPopupRegion.outside &&
        event is MouseButtonEvent &&
        event.isPressed) {
      if (!handled && !_closed) {
        close();
        stderr.writeln('[wt:popup] dismissed by outside click');
      }
      // An outside click is intentionally left unaccepted so the bar or
      // another popup can process the same click after this one closes.
      return;
    }
    if (handled) event.accept();
  }

  bool _routeWidgetEvent(Event event) {
    if (event is MouseMotionEvent) {
      return _widgetHost.dispatchMouseMotion(event.x.round(), event.y.round());
    }
    if (event is MouseEnterEvent) {
      return _widgetHost.dispatchMouseMotion(event.x.round(), event.y.round());
    }
    if (event is MouseLeaveEvent) {
      _widgetHost.clearHover();
      return true;
    }
    if (event is MouseWheelEvent) {
      return _widgetHost.dispatchMouseWheel(
        event.x.round(),
        event.y.round(),
        event.dx.round(),
        event.dy.round(),
      );
    }
    if (event is MouseButtonEvent) {
      // WidgetHostController owns the Linux input-button contract. A popup
      // still consumes secondary presses, but only the primary button can
      // activate a widget.
      if (event.button != 0x110) return true;
      return event.isPressed
          ? _widgetHost.dispatchMouseDown(
              event.x.round(),
              event.y.round(),
              event.button,
            )
          : _widgetHost.dispatchMouseUp(
              event.x.round(),
              event.y.round(),
              event.button,
            );
    }
    if (event is KeyEvent) {
      return event.isPressed
          ? _widgetHost.dispatchKeyPressed(event)
          : _widgetHost.dispatchKeyReleased(event);
    }
    return false;
  }
}
