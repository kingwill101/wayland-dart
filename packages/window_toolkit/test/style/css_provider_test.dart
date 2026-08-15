import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';
import 'package:window_toolkit/src/style/style_patch.dart';

/// Compares a [Color] by its channels (Color has no `==`).
void expectColor(Color? c, int r, int g, int b, [int a = 255]) {
  expect(c, isNotNull);
  expect(c!.r, r, reason: 'r');
  expect(c.g, g, reason: 'g');
  expect(c.b, b, reason: 'b');
  expect(c.a, a, reason: 'a');
}

/// Minimal [Widget] that can carry style id / classes for CSS matching.
class _Styled extends Widget {
  _Styled({String? id, List<String>? classes}) {
    if (id != null) styleId = id;
    for (final c in classes ?? const []) {
      addClass(c);
    }
  }

  @override
  void performLayout(int containerWidth) {}

  @override
  void draw(Painter canvas) {}
}

StylePatch _styleFor(CssProvider css, {String? id, List<String>? classes}) {
  StyleContext.reset();
  StyleContext.addProvider(css, priority: StyleProviderPriority.user);
  final w = _Styled(id: id, classes: classes);
  return StyleContext.forWidget(w).style;
}

void main() {
  group('CssProvider → StylePatch (GTK property catalog)', () {
    tearDown(StyleContext.reset);

    test('colors: hex, rgb, rgba, named, @define-color', () {
      final css = CssProvider()
        ..loadFromString('''
          @define-color accent #89b4fa;
          .a { color: #ff0000; background-color: rgba(0,0,0,0.5); }
          .b { color: rgb(10%,20%,30%); border-color: blue; }
          .c { color: @accent; }
        ''');
      final a = _styleFor(css, classes: ['a']);
      expectColor(a.color, 255, 0, 0);
      expect(a.backgroundColor?.a, 128);
      final b = _styleFor(css, classes: ['b']);
      expectColor(b.color, 26, 51, 77); // 10%,20%,30% → rounded
      expectColor(b.borderColor, 0, 0, 255);
      final c = _styleFor(css, classes: ['c']);
      expectColor(c.color, 0x89, 0xb4, 0xfa);
    });

    test('font properties + font shorthand', () {
      final css = CssProvider()
        ..loadFromString('''
          .a { font-family: "Comic Sans"; font-size: 14px; font-weight: bold; font-style: italic; font-variant: small-caps; }
          .b { font: italic bold 12px "Sans"; }
        ''');
      final a = _styleFor(css, classes: ['a']);
      expect(a.fontFamily, 'Comic Sans');
      expect(a.fontSize, 14);
      expect(a.fontWeight, 700);
      expect(a.fontStyle, TextStyle.italic);
      expect(a.fontSmallCaps, isTrue);
      final b = _styleFor(css, classes: ['b']);
      expect(b.fontWeight, 700);
      expect(b.fontSize, 12);
      expect(b.fontFamily, 'Sans');
    });

    test('box: padding / margin shorthands + per side, min sizes', () {
      final css = CssProvider()
        ..loadFromString('''
          .a { padding: 4px; margin: 2px 6px; min-width: 30px; min-height: 20px; }
          .b { padding-left: 8px; }
        ''');
      final a = _styleFor(css, classes: ['a']);
      expect(a.paddingLeft, 4);
      expect(a.paddingRight, 4);
      expect(a.paddingTop, 4);
      expect(a.paddingBottom, 4);
      expect(a.marginTop, 2);
      expect(a.marginBottom, 2);
      expect(a.marginLeft, 6);
      expect(a.marginRight, 6);
      expect(a.minWidth, 30);
      expect(a.minHeight, 20);
      final b = _styleFor(css, classes: ['b']);
      expect(b.paddingLeft, 8);
    });

    test('borders: shorthand width/style/color', () {
      final css = CssProvider()
        ..loadFromString(
          '.x { border-width: 2px; border-style: solid; border-color: #89b4fa; }',
        );
      final st = _styleFor(css, classes: ['x']);
      expect(st.borderTopWidth, 2);
      expect(st.borderRightWidth, 2);
      expect(st.borderTopStyle, BorderStyle.solid);
      expectColor(st.borderTopColor, 0x89, 0xb4, 0xfa);
      expectColor(st.borderColor, 0x89, 0xb4, 0xfa);
      expect(st.borderWidth, 2);
    });

    test('borders: per-side + border-radius shorthands', () {
      final css = CssProvider()
        ..loadFromString('''
          .x { border-radius: 8px; }
          .y { border-top-width: 3px; border-bottom-color: green; border-bottom-right-radius: 4px; }
        ''');
      final x = _styleFor(css, classes: ['x']);
      expect(x.borderTopLeftRadius, 8);
      expect(x.borderBottomRightRadius, 8);
      final y = _styleFor(css, classes: ['y']);
      expect(y.borderTopWidth, 3);
      expectColor(y.borderBottomColor, 0, 128, 0);
      expect(y.borderBottomRightRadius, 4);
      expect(y.borderTopLeftRadius, isNull);
    });

    test('background shorthand, box-shadow, opacity', () {
      final css = CssProvider()
        ..loadFromString('''
          .x {
            background: #112233;
            box-shadow: 2px 4px 6px rgba(0,0,0,0.4);
            opacity: 0.6;
          }
        ''');
      final st = _styleFor(css, classes: ['x']);
      expectColor(st.backgroundColor, 0x11, 0x22, 0x33);
      expect(st.shadowOffsetX, 2);
      expect(st.shadowOffsetY, 4);
      expect(st.shadowBlur, 6);
      expect(st.shadowColor?.a, (0.4 * 255).round());
      expect(st.opacity, 0.6);
    });

    test('specificity: more specific selector wins', () {
      final css = CssProvider()
        ..loadFromString('''
          button { color: red; }
          button.fancy { color: blue; }
          #main { color: green; }
        ''');
      final st = _styleFor(css, id: 'main', classes: ['fancy']);
      expectColor(st.color, 0, 128, 0); // id (100) > class (10)
    });

    test('descendant selector via explicit chain', () {
      final css = CssProvider()
        ..loadFromString('.calendar .today { color: #fab387; }');
      final root = _Styled(classes: ['calendar']);
      final today = _Styled(classes: ['today']);
      StyleContext.reset();
      StyleContext.addProvider(css, priority: StyleProviderPriority.user);
      final st = StyleContext.forWidget(today, ancestry: [root, today]).style;
      expectColor(st.color, 0xfa, 0xb3, 0x87);
    });

    test(
      'Widget resolvers apply CSS uniformly to Label / Button / DecoratedBox',
      () {
        final css = CssProvider()
          ..loadFromString('''
          .lbl { color: #fab387; }
          .btn { background-color: #111122; }
          .btn:hover { background-color: #334455; }
          .dec { background-color: #081020; border-color: #fab387; border-width: 3px; border-radius: 12px; }
        ''');
        StyleContext.reset();
        StyleContext.addProvider(css, priority: StyleProviderPriority.user);

        // Label.colorFromStyle → CSS wins, else palette/explicit.
        final lbl = Label('x')..addClass('lbl');
        expectColor(lbl.colorFromStyle(const Color(1, 2, 3)), 0xfa, 0xb3, 0x87);
        final plain = Label('x');
        expectColor(plain.colorFromStyle(const Color(9, 9, 9)), 9, 9, 9);

        // Button.widgetStyle + widgetStyleOn(['hover']) → :hover wins over :base.
        final btn = Button('ok')..addClass('btn');
        expectColor(btn.widgetStyle.backgroundColor, 0x11, 0x11, 0x22);
        expectColor(
          btn.widgetStyleOn(const ['hover']).backgroundColor,
          0x33,
          0x44,
          0x55,
        );

        // DecoratedBox reads CSS bg + radius the same way.
        final dec = DecoratedBox()..addClass('dec');
        expectColor(dec.widgetStyle.backgroundColor, 0x08, 0x10, 0x20);
        expect(dec.widgetStyle.borderRadius, 12);
        expect(dec.widgetStyle.borderWidth, 3);

        // Central resolver: resolvedStyle() is concrete and already cascaded
        // (role palette → providers/CSS → widget-local override) in ONE place.
        final lbl2 = Label('x')..addClass('lbl');
        final stLbl = lbl2.resolvedStyle();
        expect(stLbl, isA<Style>());
        expectColor(stLbl.color, 0xfa, 0xb3, 0x87); // CSS over role palette

        final btn2 = Button('ok')..addClass('btn');
        expectColor(btn2.resolvedStyle().backgroundColor, 0x11, 0x11, 0x22);
        expectColor(
          btn2.resolvedStyleOn(const ['hover']).backgroundColor,
          0x33,
          0x44,
          0x55,
        );

        // Local override feeds the same cascade: CSS still wins, else local
        // beats the role defaults.
        final dec2 = DecoratedBox(color: const Color(10, 20, 30))
          ..addClass('dec');
        expectColor(dec2.resolvedStyle().backgroundColor, 0x08, 0x10, 0x20);
        final dec3 = DecoratedBox(color: const Color(10, 20, 30));
        expectColor(dec3.resolvedStyle().backgroundColor, 10, 20, 30);
        // Role default: a plain DecoratedBox has no background (transparent).
        final dec4 = DecoratedBox();
        expectColor(dec4.resolvedStyle().backgroundColor!, 0, 0, 0, 0);
        // Role default for Label: palette text (concrete, never null).
        final plainLbl = Label('x');
        expect(plainLbl.resolvedStyle().color, isNotNull);
      },
    );

    test('control and indicator roles consume the shared style cascade', () {
      final css = CssProvider()
        ..loadFromString('''
          .control { color: #f5e0c0; background-color: #302838; border-color: #89b4fa; }
          .control:hover { background-color: #45405a; }
        ''');
      StyleContext.reset();
      StyleContext.addProvider(css, priority: StyleProviderPriority.user);

      final widgets = <Widget>[
        Checkbox()..addClass('control'),
        Switch()..addClass('control'),
        RadioButton('radio')..addClass('control'),
        IconButton(IconShape.circle)..addClass('control'),
        ProgressBar(barWidth: 100)..addClass('control'),
        Card()..addClass('control'),
        Spinner()..addClass('control'),
        Separator()..addClass('control'),
      ];

      for (final widget in widgets) {
        final style = widget.resolvedStyle();
        expectColor(style.color, 0xf5, 0xe0, 0xc0);
        expectColor(style.backgroundColor, 0x30, 0x28, 0x38);
        expectColor(style.borderColor, 0x89, 0xb4, 0xfa);
        expectColor(
          widget.resolvedStyleOn(const ['hover']).backgroundColor,
          0x45,
          0x40,
          0x5a,
        );
      }
    });
  });
}
