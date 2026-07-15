import 'app.dart';
import 'backend/layer.dart';
import 'window_behavior.dart';

class LayerWindow extends LayerBackend with EventReceiver, WindowBehavior {
  LayerWindow({
    Anchor anchor = Anchor.top,
    int barHeight = 30,
    int exclusiveZone = 30,
    String namespace = 'wayland-toolkit',
  }) : super(
          anchor: anchor,
          barHeight: barHeight,
          exclusiveZone: exclusiveZone,
          namespace: namespace,
        ) {
    initWindow();
  }
}
