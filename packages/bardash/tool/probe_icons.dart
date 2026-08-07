import 'package:window_toolkit/window_toolkit.dart';
import 'package:skia_dart/skia_dart.dart';

void main() {
  FontDatabase.instance.useSkiaEngine();
  FontDatabase.instance.setRoleFamily(FontRole.icon, 'Hack Nerd Font');
  FontDatabase.instance.setRoleFamily(FontRole.ui, 'sans');
  
  final glyphs = {
    'gear': '\uf013',
    'firefox': '\uf269',
    'folder': '\uf07b',
    'power': '\uf011',
    'wifi': '\u{f05a9}',
    'vol': '\uf028',
  };
  
  for (final e in glyphs.entries) {
    final f = Font.icon(pixelSize: 14);
    final resolved = FontDatabase.instance.resolveRequest(f);
    final m = FontDatabase.instance.metrics(f);
    final info = FontDatabase.instance.fontInfo(f);
    final adv = m.horizontalAdvance(e.value);
    final bounds = m.boundingRect(e.value);
    print('${e.key} family=${resolved.family} exact=${info.exactMatch} face=${info.family} adv=$adv bounds=$bounds codes=${e.value.runes.map((r)=>r.toRadixString(16)).join(",")}');
  }
  
  final emoji = Font(family: 'Noto Color Emoji', pixelSize: 14);
  for (final ch in ['🔊','🔋','⚡']) {
    final m = FontDatabase.instance.metrics(emoji);
    final info = FontDatabase.instance.fontInfo(emoji);
    print('emoji $ch exact=${info.exactMatch} face=${info.family} adv=${m.horizontalAdvance(ch)} bounds=${m.boundingRect(ch)}');
  }
  
  final mgr = SkFontMgr.createPlatformDefault()!;
  for (final fam in ['Hack Nerd Font', 'Noto Color Emoji', 'Font Awesome 7 Free', 'Font Awesome 7 Free Solid', 'sans']) {
    final face = mgr.matchFamilyStyle(fam, SkFontStyle.normal());
    print('match $fam -> ${face?.familyName} glyphs=${face?.glyphCount}');
  }

  final face = mgr.matchFamilyStyle('Hack Nerd Font', SkFontStyle.normal())!;
  final font = SkFont(typeface: face, size: 14);
  for (final e in glyphs.entries) {
    final m = font.measureText(SkEncodedText.string(e.value), includeBounds: true);
    print('measure ${e.key} adv=${m.advance} bounds=${m.bounds}');
  }
  final eface = mgr.matchFamilyStyle('Noto Color Emoji', SkFontStyle.normal())!;
  final efont = SkFont(typeface: eface, size: 14);
  for (final ch in ['🔊','🔋','⚡']) {
    final m = efont.measureText(SkEncodedText.string(ch), includeBounds: true);
    print('emoji measure $ch adv=${m.advance} bounds=${m.bounds}');
  }
  
  // sans measure of gear - what happens without nerd font
  final sface = mgr.matchFamilyStyle('sans', SkFontStyle.normal())!;
  final sfont = SkFont(typeface: sface, size: 14);
  for (final e in glyphs.entries) {
    final m = sfont.measureText(SkEncodedText.string(e.value), includeBounds: true);
    print('sans ${e.key} face=${sface.familyName} adv=${m.advance} bounds=${m.bounds}');
  }
}
