import 'dart:io';

import 'package:wayland/wayland.dart';

import 'connection.dart';
import 'wayland_surface.dart';

enum LayerEdge { top, right, bottom, left }

enum LayerKeyboardMode { none, onDemand, exclusive }

/// Protocol-neutral placement values translated by [WaylandLayerSurface].
class LayerSurfacePlacement {
  final Set<LayerEdge> anchors;
  final int width;
  final int height;
  final int marginTop;
  final int marginRight;
  final int marginBottom;
  final int marginLeft;
  final int exclusiveZone;
  final LayerKeyboardMode keyboardMode;

  const LayerSurfacePlacement({
    required this.anchors,
    required this.width,
    required this.height,
    this.marginTop = 0,
    this.marginRight = 0,
    this.marginBottom = 0,
    this.marginLeft = 0,
    this.exclusiveZone = 0,
    this.keyboardMode = LayerKeyboardMode.none,
  });
}

/// Shared placement for popups opened from a layer-shell bar.
///
/// The bar's layer surface already owns its [exclusiveZone], so popup margins
/// are measured from the reserved edge. Callers must not add the bar height a
/// second time; doing so leaves an unnecessary bar-sized gap above the popup.
class BarPopupPlacement {
  const BarPopupPlacement._();

  static LayerSurfacePlacement forBar({
    required int anchorX,
    required int parentWidth,
    required int width,
    required int height,
    required bool openUpward,
    int gap = 4,
    LayerKeyboardMode keyboardMode = LayerKeyboardMode.none,
    int exclusiveZone = 0,
  }) {
    final safeWidth = parentWidth.clamp(1, 7680);
    final safePopupWidth = width.clamp(1, safeWidth);
    final maxLeft = (safeWidth - safePopupWidth - 4).clamp(0, safeWidth);
    final minLeft = maxLeft >= 4 ? 4 : 0;
    final left = (anchorX - 8).clamp(minLeft, maxLeft);
    final right = (safeWidth - left - safePopupWidth).clamp(0, safeWidth);
    final preferRight = left + safePopupWidth / 2 > safeWidth / 2;

    if (openUpward) {
      return preferRight
          ? LayerSurfacePlacement(
              anchors: {LayerEdge.bottom, LayerEdge.right},
              width: safePopupWidth,
              height: height,
              marginRight: right,
              marginBottom: gap,
              exclusiveZone: exclusiveZone,
              keyboardMode: keyboardMode,
            )
          : LayerSurfacePlacement(
              anchors: {LayerEdge.bottom, LayerEdge.left},
              width: safePopupWidth,
              height: height,
              marginLeft: left,
              marginBottom: gap,
              exclusiveZone: exclusiveZone,
              keyboardMode: keyboardMode,
            );
    }

    return preferRight
        ? LayerSurfacePlacement(
            anchors: {LayerEdge.top, LayerEdge.right},
            width: safePopupWidth,
            height: height,
            marginRight: right,
            marginTop: gap,
            exclusiveZone: exclusiveZone,
            keyboardMode: keyboardMode,
          )
        : LayerSurfacePlacement(
            anchors: {LayerEdge.top, LayerEdge.left},
            width: safePopupWidth,
            height: height,
            marginLeft: left,
            marginTop: gap,
            exclusiveZone: exclusiveZone,
            keyboardMode: keyboardMode,
          );
  }
}

/// Owns a layer-shell surface and translates toolkit placement values into
/// Wayland protocol requests.
class WaylandLayerSurface {
  final WaylandConnection connection;
  final String namespace;
  final WaylandSurface surface;
  final LayerSurfaceV1 layer;

  WaylandLayerSurface._({
    required this.connection,
    required this.namespace,
    required this.surface,
    required this.layer,
  });

  int get surfaceId => surface.objectId;

  static WaylandLayerSurface? create({
    required WaylandConnection connection,
    required String namespace,
  }) {
    final shell = connection.layerShell;
    if (shell == null) {
      stderr.writeln('[wt:layer] layer shell unavailable for $namespace');
      return null;
    }

    try {
      final nativeSurface = connection.compositor.createSurface().getOrElse(
        (e) => throw StateError('createSurface failed: $e'),
      );
      final surface = WaylandSurface(connection, nativeSurface);
      final layer = shell
          .getLayerSurface(
            nativeSurface,
            connection.output,
            LayerShellV1Layer.overlay.enumValue,
            namespace,
          )
          .getOrElse((e) => throw StateError('getLayerSurface failed: $e'));
      return WaylandLayerSurface._(
        connection: connection,
        namespace: namespace,
        surface: surface,
        layer: layer,
      );
    } catch (e) {
      stderr.writeln('[wt:layer] unable to create $namespace: $e');
      return null;
    }
  }

  void configure(LayerSurfacePlacement placement) {
    var anchor = 0;
    if (placement.anchors.contains(LayerEdge.top)) {
      anchor |= LayerSurfaceV1Anchor.top.enumValue;
    }
    if (placement.anchors.contains(LayerEdge.right)) {
      anchor |= LayerSurfaceV1Anchor.right.enumValue;
    }
    if (placement.anchors.contains(LayerEdge.bottom)) {
      anchor |= LayerSurfaceV1Anchor.bottom.enumValue;
    }
    if (placement.anchors.contains(LayerEdge.left)) {
      anchor |= LayerSurfaceV1Anchor.left.enumValue;
    }
    layer.setAnchor(anchor);
    layer.setMargin(
      placement.marginTop,
      placement.marginRight,
      placement.marginBottom,
      placement.marginLeft,
    );
    layer.setSize(placement.width, placement.height);
    layer.setExclusiveZone(placement.exclusiveZone);
    layer.setKeyboardInteractivity(switch (placement.keyboardMode) {
      LayerKeyboardMode.none =>
        LayerSurfaceV1KeyboardInteractivity.none.enumValue,
      LayerKeyboardMode.onDemand =>
        LayerSurfaceV1KeyboardInteractivity.onDemand.enumValue,
      LayerKeyboardMode.exclusive =>
        LayerSurfaceV1KeyboardInteractivity.exclusive.enumValue,
    });
  }

  void onConfigure(void Function(int width, int height) callback) {
    layer.onConfigure((event) {
      layer.ackConfigure(event.serial);
      callback(event.width, event.height);
    });
  }

  void onClosed(void Function() callback) {
    layer.onClosed((_) => callback());
  }

  void commit() {
    surface.commit();
  }

  void destroy() {
    layer.destroy();
    surface.destroy();
  }
}
