import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

class _FakeConnection implements PlatformConnection {
  @override
  bool isConnected = true;

  var dispatchCount = 0;

  @override
  void dispatch() {
    dispatchCount++;
  }

  @override
  void reset() {}
}

class _FakeSurface implements PlatformSurface {
  SurfaceInputMode? inputMode;
  var commitCount = 0;
  var destroyCount = 0;

  @override
  void setInputMode(SurfaceInputMode mode) {
    inputMode = mode;
  }

  @override
  void commit() {
    commitCount++;
  }

  @override
  void destroy() {
    destroyCount++;
  }
}

void main() {
  test('platform contracts carry connection and surface policy only', () {
    final connection = _FakeConnection();
    final surface = _FakeSurface();

    connection.dispatch();
    surface.setInputMode(SurfaceInputMode.passthrough);
    surface.commit();
    surface.destroy();

    expect(connection.isConnected, isTrue);
    expect(connection.dispatchCount, 1);
    expect(surface.inputMode, SurfaceInputMode.passthrough);
    expect(surface.commitCount, 1);
    expect(surface.destroyCount, 1);
  });
}
