import 'package:cinetrack/domain/repositories/review_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// FR-13 §5.13 — "the percentage of the number of stars for each qualitative
/// level must be shown from 0 to 100".
///
/// The requirement describes a *distribution across the five levels*, not one
/// average rescaled to a percentage. These tests pin that reading down, since
/// misreading it is the common way to lose the mark.
void main() {
  group('FR-13 · star distribution', () {
    test('each level is a share of the total, and the shares sum to 100', () {
      const summary = RatingSummary(counts: {1: 1, 2: 1, 3: 2, 4: 3, 5: 3});

      expect(summary.total, 10);
      expect(summary.percentFor(1), 10);
      expect(summary.percentFor(2), 10);
      expect(summary.percentFor(3), 20);
      expect(summary.percentFor(4), 30);
      expect(summary.percentFor(5), 30);

      final sum = [
        1,
        2,
        3,
        4,
        5,
      ].map(summary.percentFor).reduce((a, b) => a + b);
      expect(sum, closeTo(100, 0.001));
    });

    test('a level with no ratings is 0 percent, not absent', () {
      const summary = RatingSummary(counts: {5: 4});

      expect(summary.percentFor(1), 0);
      expect(summary.percentFor(3), 0);
      expect(summary.percentFor(5), 100);
    });

    test('no ratings at all yields zero everywhere and a null average', () {
      const summary = RatingSummary.empty();

      expect(summary.total, 0);
      expect(summary.percentFor(3), 0);
      expect(summary.average, isNull);
    });
  });

  group('FR-06 field 12 · application users\' rating', () {
    test('the average is weighted by how many ratings each level has', () {
      const summary = RatingSummary(counts: {4: 1, 5: 3});

      // (4×1 + 5×3) / 4 = 4.75
      expect(summary.average, closeTo(4.75, 0.0001));
    });

    test('a single rating averages to itself', () {
      const summary = RatingSummary(counts: {3: 1});

      expect(summary.average, 3);
    });
  });
}
