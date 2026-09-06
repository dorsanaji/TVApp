import 'package:cinetrack/core/l10n/persian_numbers.dart';
import 'package:cinetrack/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

/// NFR-11a — a Persian interface that shows Western digits is half-translated.
void main() {
  group('Persian digits', () {
    test('converts Western digits', () {
      expect('2024'.toPersianDigits, '۲۰۲۴');
      expect('0123456789'.toPersianDigits, '۰۱۲۳۴۵۶۷۸۹');
    });

    test('round-trips back to Western for parsing user input', () {
      expect('۱۳۸۶'.toWesternDigits, '1386');
      expect('۴۲'.toWesternDigits.toPersianDigits, '۴۲');
    });

    test('leaves non-digit characters untouched', () {
      expect('S01E05'.toPersianDigits, 'S۰۱E۰۵');
    });

    test('groups thousands with the Persian separator', () {
      expect(12345.toPersian, '۱۲٬۳۴۵');
      expect(999.toPersian, '۹۹۹');
      expect(1000000.toPersian, '۱٬۰۰۰٬۰۰۰');
    });

    test('formats a fraction as a Persian percentage', () {
      expect(0.5.toPersianPercent(), '۵۰٪');
      expect(1.0.toPersianPercent(), '۱۰۰٪');
      expect(0.0.toPersianPercent(), '۰٪');
    });
  });

  group('runtime formatting (FR-06 field 6)', () {
    test('splits minutes into hours and minutes', () {
      expect(Formatters.runtime(137), '۲ ساعت و ۱۷ دقیقه');
    });

    test('omits the hour part below one hour', () {
      expect(Formatters.runtime(45), '۴۵ دقیقه');
    });

    test('omits the minute part on an exact hour', () {
      expect(Formatters.runtime(120), '۲ ساعت');
    });

    test('renders a dash when the service has no runtime', () {
      expect(Formatters.runtime(null), '—');
      expect(Formatters.runtime(0), '—');
    });
  });

  group('total watch time (FR-19 statistic 4)', () {
    test('rolls large totals up into days', () {
      // 3 days and 4 hours
      expect(Formatters.totalWatchTime(3 * 1440 + 4 * 60), '۳ روز و ۴ ساعت');
    });

    test('shows minutes only when under an hour', () {
      expect(Formatters.totalWatchTime(45), '۴۵ دقیقه');
    });

    test('handles a user who has watched nothing', () {
      expect(Formatters.totalWatchTime(0), '۰ دقیقه');
    });
  });

  group('dates and ratings', () {
    test('converts a Gregorian air date to Jalali', () {
      // 2008-01-20 falls in Dey 1386.
      expect(Formatters.jalaliDate('2008-01-20'), contains('دی'));
      expect(Formatters.jalaliDate('2008-01-20'), contains('۱۳۸۶'));
    });

    test('a year is never thousand-separated', () {
      // A year is an identifier, not a quantity: `۱۳۸۶`, not `۱٬۳۸۶`.
      expect(Formatters.jalaliDate('2008-01-20'), isNot(contains('٬')));
      expect(Formatters.year('2008-01-20'), isNot(contains('٬')));
    });

    test('falls back gracefully on a missing or unparseable date', () {
      expect(Formatters.jalaliDate(null), '—');
      expect(Formatters.jalaliDate(''), '—');
      expect(Formatters.jalaliDate('not-a-date'), 'not-a-date');
    });

    test('extracts the release year in Persian digits', () {
      expect(Formatters.year('2008-01-20'), '۲۰۰۸');
      expect(Formatters.year(null), '—');
    });

    test('formats a rating with a Persian decimal separator', () {
      expect(Formatters.rating(8.5), '۸٫۵');
      expect(Formatters.rating(null), '—');
      expect(Formatters.rating(0), '—');
    });
  });
}
