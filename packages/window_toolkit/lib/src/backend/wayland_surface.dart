import 'package:wayland/wayland.dart';

import '../platform/platform.dart';
import 'connection.dart';

/// Wayland implementation of the toolkit's platform surface contract.
///
/// This is the only layer that translates the toolkit input policy into a
/// Wayland input region. Callers should receive a [PlatformSurface] from a
/// backend rather than constructing this adapter themselves.
class WaylandSurface implements PlatformSurface {
  final WaylandConnection connection;
  final WlSurface nativeSurface;

  WaylandSurface(this.connection, this.nativeSurface);

  int get objectId => nativeSurface.objectId;

  void attach(WlBuffer buffer) {
    nativeSurface.attach(buffer, 0, 0);
  }

  void damage(int width, int height) {
    nativeSurface.damage(0, 0, width, height);
  }

  @override
  void setInputMode(SurfaceInputMode mode) {
    switch (mode) {
      case SurfaceInputMode.normal:
        // Wayland's default input region is the surface's full geometry. The
        // generated bindings currently expose only a non-null WlRegion setter,
        // so restoring a cleared region will be added when that API supports
        // nullable regions.
        return;
      case SurfaceInputMode.passthrough:
        final region = connection.compositor.createRegion().getOrElse((e) {
          throw StateError('Unable to create passthrough input region: $e');
        });
        nativeSurface.setInputRegion(region);
        region.destroy();
    }
  }

  @override
  void commit() {
    nativeSurface.commit();
  }

  @override
  void destroy() {
    nativeSurface.destroy();
  }
}
