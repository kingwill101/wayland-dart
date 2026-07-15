/// Font stack — Qt-inspired fonts, metrics, and text positioning.
///
/// | Qt | window_toolkit |
/// |----|----------------|
/// | `QFont` | [Font] |
/// | `QFontDatabase` | [FontDatabase] |
/// | `QFontMetricsF` | [FontMetrics] |
/// | `QFontInfo` | [FontInfo] |
/// | `QPlatformFontDatabase` | [FontEngine] → [SkiaFontEngine] / [BitmapFontEngine] |
/// | `Qt::Alignment` | [TextAlign] / [TextHAlign] / [TextVAlign] |
/// | `QTextOption` | [TextOption] |
/// | `QPainter::drawText(QRect, …)` | [TextLayout.drawInRect] / [PainterFont.drawTextInRect] |
/// | `QFontMetrics::elidedText` | [TextLayout.elide] / [FontMetrics.elidedText] |
library;

export 'bitmap_font_engine.dart';
export 'font.dart';
export 'font_database.dart';
export 'font_engine.dart';
export 'font_info.dart';
export 'font_metrics.dart';
export 'painter_font.dart';
export 'skia_font_engine.dart';
export 'text_align.dart';
export 'text_layout.dart';
export 'text_option.dart';
