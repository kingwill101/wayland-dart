mixin Size {
  int _width = 0;
  int _height = 0;

  int get height => _height;

  int get width => _width;

  set width(int width) {
    _width = width;
  }

  set height(int height) {
    _height = height;
  }

  setDimensions(int width, int height) {
    this.width = width;
    this.height = height;
  }
}
