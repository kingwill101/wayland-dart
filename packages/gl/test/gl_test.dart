import 'package:gl/gl.dart';
import 'package:test/test.dart';

void main() {
  group('GL bindings', () {
    test('exports EGL', () {
      expect(EGL, isNotNull);
    });
  });
}
