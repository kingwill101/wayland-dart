import 'app.dart';
import 'backend/layer.dart';
import 'window_behavior.dart';

class LayerWindow extends LayerBackend with EventReceiver, WindowBehavior {
  LayerWindow({
    super.anchor,
    super.barHeight,
    super.exclusiveZone,
    super.namespace,
  }) {
    initWindow();
  }
}
