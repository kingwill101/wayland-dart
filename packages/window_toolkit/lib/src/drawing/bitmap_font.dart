import 'dart:typed_data';

import 'canvas.dart';
import 'color.dart';

class BitmapFont {
  final int charWidth;
  final int charHeight;
  final Map<int, Uint8List> _glyphs = {};

  BitmapFont({this.charWidth = 8, this.charHeight = 16});

  void loadGlyph(int codePoint, Uint8List pixels) {
    _glyphs[codePoint] = pixels;
  }

  void drawText(Canvas canvas, int x, int y, String text, Color color) {
    int cursorX = x;
    for (var i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      final glyph = _glyphs[code];
      if (glyph != null) {
        _drawGlyph(canvas, cursorX, y, glyph, color);
      }
      cursorX += charWidth;
    }
  }

  void _drawGlyph(Canvas canvas, int x, int y, Uint8List glyph, Color color) {
    for (var gy = 0; gy < charHeight; gy++) {
      for (var gx = 0; gx < charWidth; gx++) {
        final idx = gy * charWidth + gx;
        if (idx < glyph.length && glyph[idx] != 0) {
          canvas.setPixel(x + gx, y + gy, color);
        }
      }
    }
  }

  int textWidth(String text) => text.length * charWidth;

  int get height => charHeight;

  static BitmapFont createDefault() {
    final font = BitmapFont(charWidth: 8, charHeight: 16);
    _loadDefaultGlyphs(font);
    return font;
  }

  static void _loadDefaultGlyphs(BitmapFont font) {
    final chars = ' ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        'abcdefghijklmnopqrstuvwxyz'
        '0123456789'
        '!@#\$%^&*()-_=+[]{}|;:\'",.<>?/\\~`';

    for (var i = 0; i < chars.length; i++) {
      font.loadGlyph(chars.codeUnitAt(i), _defaultGlyph(chars[i], font.charWidth, font.charHeight));
    }
  }

  static Uint8List _defaultGlyph(String char, int w, int h) {
    final pixels = Uint8List(w * h);
    final pattern = _glyphPatterns[char];
    if (pattern == null) return pixels;

    final lines = pattern.split('\n');
    for (var y = 0; y < lines.length && y < h; y++) {
      final line = lines[y];
      for (var x = 0; x < line.length && x < w; x++) {
        if (line[x] == '#') {
          pixels[y * w + x] = 1;
        }
      }
    }
    return pixels;
  }

  static const Map<String, String> _glyphPatterns = {
    'A': '####\n#  #\n#  #\n####\n#  #\n#  #\n#  #\n    ',
    'B': '#### \n#  # \n#  # \n#### \n#  # \n#  # \n#### \n     ',
    'C': ' ####\n#    \n#    \n#    \n#    \n#    \n ####\n     ',
    'D': '#### \n#  # \n#  # \n#  # \n#  # \n#  # \n#### \n     ',
    'E': '#####\n#    \n#    \n#### \n#    \n#    \n#####\n     ',
    'F': '#####\n#    \n#    \n#### \n#    \n#    \n#    \n     ',
    'G': ' ####\n#    \n#    \n# ###\n#  # \n#  # \n ####\n     ',
    'H': '#  #\n#  #\n#  #\n####\n#  #\n#  #\n#  #\n    ',
    'I': '####\n #  \n #  \n #  \n #  \n #  \n####\n    ',
    'J': '  ##\n   #\n   #\n   #\n   #\n#  #\n ## \n    ',
    'K': '#  #\n# # \n##  \n#   \n##  \n# # \n#  #\n    ',
    'L': '#    \n#    \n#    \n#    \n#    \n#    \n#####\n     ',
    'M': '#   #\n## ##\n# # #\n#   #\n#   #\n#   #\n#   #\n     ',
    'N': '#   #\n##  #\n# # #\n#  ##\n#   #\n#   #\n#   #\n     ',
    'O': ' ## \n#  #\n#  #\n#  #\n#  #\n#  #\n ## \n    ',
    'P': '#### \n#  # \n#  # \n#### \n#    \n#    \n#    \n     ',
    'Q': ' ## \n#  #\n#  #\n#  #\n# # #\n#  #\n ## #\n     ',
    'R': '#### \n#  # \n#  # \n#### \n# #  \n#  # \n#   #\n     ',
    'S': ' ####\n#    \n#    \n ##  \n   # \n   #\n#### \n     ',
    'T': '#####\n  #  \n  #  \n  #  \n  #  \n  #  \n  #  \n     ',
    'U': '#  #\n#  #\n#  #\n#  #\n#  #\n#  #\n ## \n    ',
    'V': '#   #\n#   #\n#   #\n#   #\n # # \n # # \n  #  \n     ',
    'W': '#   #\n#   #\n#   #\n# # #\n# # #\n## ##\n#   #\n     ',
    'X': '#   #\n # # \n  #  \n  #  \n  #  \n # # \n#   #\n     ',
    'Y': '#   #\n # # \n  #  \n  #  \n  #  \n  #  \n  #  \n     ',
    'Z': '#####\n    #\n   # \n  #  \n #   \n#    \n#####\n     ',
    'a': '    \n    \n ###\n#  #\n####\n#  #\n####\n    ',
    'b': '#   \n#   \n####\n#  #\n#  #\n#  #\n####\n    ',
    'c': '    \n    \n ###\n#   \n#   \n#   \n ###\n    ',
    'd': '   #\n   #\n####\n#  #\n#  #\n#  #\n####\n    ',
    'e': '    \n    \n ###\n#  #\n####\n#   \n ###\n    ',
    'f': ' ##\n#  \n#  \n###\n#  \n#  \n#  \n   ',
    'g': '    \n    \n####\n#  #\n#  #\n####\n   #\n ## ',
    'h': '#   \n#   \n### \n#  #\n#  #\n#  #\n#  #\n    ',
    'i': ' #\n   \n # \n # \n # \n # \n # \n   ',
    'j': '  #\n    \n  #\n  #\n  #\n  #\n# #\n # ',
    'k': '#   \n#   \n# # \n##  \n# # \n#  #\n#  #\n    ',
    'l': ' #\n # \n # \n # \n # \n # \n # \n   ',
    'm': '      \n      \n##.## \n# # # \n# # # \n#   # \n#   # \n      ',
    'n': '    \n    \n### \n#  #\n#  #\n#  #\n#  #\n    ',
    'o': '    \n    \n ## \n#  #\n#  #\n#  #\n ## \n    ',
    'p': '    \n    \n####\n#  #\n#  #\n####\n#   \n#   ',
    'q': '    \n    \n####\n#  #\n#  #\n####\n   #\n   #',
    'r': '    \n    \n# ##\n##  \n#   \n#   \n#   \n    ',
    's': '    \n    \n ####\n#    \n ##  \n   # \n#### \n     ',
    't': ' #  \n #  \n### \n #  \n #  \n #  \n ## \n    ',
    'u': '    \n    \n#  #\n#  #\n#  #\n#  #\n ## \n    ',
    'v': '      \n      \n#   # \n#   # \n # #  \n # #  \n  #   \n      ',
    'w': '      \n      \n#   # \n#   # \n# # # \n## ## \n # #  \n      ',
    'x': '    \n    \n#  #\n # #\n  # \n # #\n#  #\n    ',
    'y': '    \n    \n#  #\n#  #\n#  #\n ## \n #  \n#   ',
    'z': '    \n    \n#####\n   # \n  #  \n #   \n#####\n     ',
    '0': ' ## \n#  #\n# ##\n## #\n#  #\n#  #\n ## \n    ',
    '1': '  # \n ## \n  # \n  # \n  # \n  # \n####\n    ',
    '2': ' ## \n#  #\n   #\n  # \n #  \n#   \n#####\n     ',
    '3': ' ## \n#  #\n   #\n  # \n   #\n#  #\n ## \n    ',
    '4': '#  #\n#  #\n#  #\n####\n   #\n   #\n   #\n     ',
    '5': '#####\n#    \n#### \n    #\n    #\n#  # \n ##  \n     ',
    '6': ' ## \n#  #\n#   \n### \n#  #\n#  #\n ## \n    ',
    '7': '#####\n#  # \n   # \n  #  \n  #  \n  #  \n  #  \n     ',
    '8': ' ## \n#  #\n#  #\n ## \n#  #\n#  #\n ## \n    ',
    '9': ' ## \n#  #\n#  #\n ###\n   #\n#  #\n ## \n    ',
    ' ': '    \n    \n    \n    \n    \n    \n    \n    ',
    '!': ' # \n # \n # \n # \n # \n   \n # \n   ',
    ':': '   \n # \n   \n   \n   \n # \n   \n   ',
    '.': '   \n   \n   \n   \n   \n   \n # \n   ',
    '-': '    \n    \n    \n####\n    \n    \n    \n    ',
    '/': '   #\n   #\n  # \n  # \n #  \n #  \n#   \n    ',
    '@': ' ## \n#  #\n# ##\n# # \n# # \n#   \n ## \n    ',
    '#': ' # # \n # # \n#####\n # # \n#####\n # # \n # # \n     ',
    '\$': '  #  \n ####\n# #  \n ### \n  # #\n#### \n  #  \n     ',
    '%': '##   \n##  #\n   # \n  #  \n #   \n#  ##\n   ##\n     ',
    '^': '  #  \n # # \n#   #\n     \n     \n     \n     \n     ',
    '&': ' ##  \n#  # \n#  # \n ##  \n# # #\n#  # \n ## #\n     ',
    '*': '     \n# # #\n ### \n#####\n ### \n# # #\n     \n     ',
    '(': '  # \n #  \n #  \n #  \n #  \n #  \n  # \n    ',
    ')': ' #  \n  # \n  # \n  # \n  # \n  # \n #  \n    ',
    '_': '     \n     \n     \n     \n     \n     \n#####\n     ',
    '=': '     \n     \n#####\n     \n#####\n     \n     \n     ',
    '+': '     \n  #  \n  #  \n#####\n  #  \n  #  \n     \n     ',
    '[': ' ##\n # \n # \n # \n # \n # \n ##\n   ',
    ']': '## \n # \n # \n # \n # \n # \n## \n   ',
    '{': '  #\n #  \n #  \n#   \n #  \n #  \n  #\n   ',
    '}': '#   \n  # \n  # \n   #\n  # \n  # \n#   \n    ',
    '|': ' # \n # \n # \n # \n # \n # \n # \n # ',
    ';': '   \n # \n   \n   \n # \n # \n   \n   ',
    "'": ' #\n #\n   \n   \n   \n   \n   \n   ',
    '"': ' # # \n # # \n     \n     \n     \n     \n     \n     ',
    ',': '   \n   \n   \n   \n   \n # \n#  \n   ',
    '<': '   #\n  # \n #  \n#   \n #  \n  # \n   #\n     ',
    '>': '#   \n #  \n  # \n   #\n  # \n #  \n#   \n     ',
    '?': ' ## \n#  #\n   #\n  # \n  # \n    \n  # \n    ',
    '\\': '#    \n #   \n  #  \n  #  \n  #  \n   # \n    #\n     ',
    '~': '     \n     \n #  #\n# ## \n    \n     \n     \n     ',
    '`': ' #\n#  \n   \n   \n   \n   \n   \n   ',
  };
}
