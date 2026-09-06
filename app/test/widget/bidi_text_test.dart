import 'package:cinetrack/core/l10n/bidi_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reported from the device: an English synopsis on a Persian screen was laid
/// out against the right margin, with the closing full stop pushed to the left
/// of the last line.
void main() {
  const english =
      'A young billionaire Bruce Wayne fights crime and evil as the '
      'mysterious vigilante, The Batman.';
  const persian = 'بروس وین جوان به‌عنوان بتمن با جنایت مبارزه می‌کند.';

  group('directionOf', () {
    test('English prose reads left to right', () {
      expect(directionOf(english), TextDirection.ltr);
    });

    test('Persian prose reads right to left', () {
      expect(directionOf(persian), TextDirection.rtl);
    });

    test('a Latin name inside a Persian sentence does not flip it', () {
      expect(
        directionOf('بروس وین جوان به‌عنوان The Batman با جنایت مبارزه می‌کند'),
        TextDirection.rtl,
      );
    });

    test('digits and punctuation alone defer to the ambient direction', () {
      expect(directionOf('۲۰۰۴ — ۱۲۳'), isNull);
      expect(directionOf('2004 (12)'), isNull);
    });

    test('CJK is not treated as evidence for either direction', () {
      // Korean and Chinese titles should follow the surrounding layout rather
      // than force it one way.
      expect(directionOf('오징어 게임'), isNull);
    });
  });

  group('BidiText inside an RTL app', () {
    Future<Text> render(WidgetTester tester, String data) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: MediaQueryData(),
            child: BidiText('placeholder'),
          ),
        ),
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: BidiText(data),
          ),
        ),
      );
      return tester.widget<Text>(find.byType(Text));
    }

    testWidgets('an English synopsis is laid out left to right', (
      tester,
    ) async {
      final text = await render(tester, english);

      expect(text.textDirection, TextDirection.ltr);
      // `start` against an LTR direction is the left margin — which is the
      // whole point. Hard-coding TextAlign.left would break the Persian case.
      expect(text.textAlign, TextAlign.start);
    });

    testWidgets('a Persian synopsis stays right to left', (tester) async {
      final text = await render(tester, persian);

      expect(text.textDirection, TextDirection.rtl);
    });

    testWidgets('undecidable text inherits the ambient direction', (
      tester,
    ) async {
      final text = await render(tester, '۱۳۹۹');

      expect(
        text.textDirection,
        isNull,
        reason: 'a null direction lets Directionality decide',
      );
    });
  });
}
