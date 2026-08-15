import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  test('parses supported renderer backend names', () {
    expect(RendererBackend.parse('auto'), RendererBackend.auto);
    expect(RendererBackend.parse('GLES'), RendererBackend.gl);
    expect(RendererBackend.parse('raster'), RendererBackend.skia);
    expect(RendererBackend.parse('webgpu'), RendererBackend.dawn);
  });

  test('unknown or missing backend defaults to auto', () {
    expect(RendererBackend.parse(null), RendererBackend.auto);
    expect(RendererBackend.parse('unknown'), RendererBackend.auto);
  });
}
