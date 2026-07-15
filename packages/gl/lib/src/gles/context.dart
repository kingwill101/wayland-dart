/// EGL context configuration.
class EglConfig {
  final int redBits;
  final int greenBits;
  final int blueBits;
  final int alphaBits;
  final int depthBits;
  final int stencilBits;
  final int samples;

  const EglConfig({
    this.redBits = 8,
    this.greenBits = 8,
    this.blueBits = 8,
    this.alphaBits = 8,
    this.depthBits = 0,
    this.stencilBits = 0,
    this.samples = 0,
  });
}
