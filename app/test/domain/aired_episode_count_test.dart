import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/series.dart';
import 'package:flutter_test/flutter_test.dart';

/// FR-11 — the progress denominator counts released episodes only.
void main() {
  Series ongoing({
    required int numberOfEpisodes,
    required List<SeasonSummary> seasons,
    AiredEpisodeMarker? lastAired,
  }) => Series(
    id: 1,
    name: 'یک سریال',
    status: SeriesStatus.returning,
    numberOfEpisodes: numberOfEpisodes,
    seasons: seasons,
    lastEpisodeToAir: lastAired,
  );

  const s1 = SeasonSummary(
    id: 1,
    seasonNumber: 1,
    name: 'فصل ۱',
    episodeCount: 10,
  );
  const s2 = SeasonSummary(
    id: 2,
    seasonNumber: 2,
    name: 'فصل ۲',
    episodeCount: 10,
  );
  const specials = SeasonSummary(
    id: 0,
    seasonNumber: 0,
    name: 'ویژه',
    episodeCount: 5,
  );

  test('a part-aired season counts only what has been shown', () {
    // 20 ordered episodes, but season 2 has only reached episode 3.
    final series = ongoing(
      numberOfEpisodes: 20,
      seasons: const [s1, s2],
      lastAired: const AiredEpisodeMarker(seasonNumber: 2, episodeNumber: 3),
    );

    expect(series.airedEpisodeCount, 13);
  });

  test('specials never count toward the denominator', () {
    final series = ongoing(
      numberOfEpisodes: 25,
      seasons: const [specials, s1, s2],
      lastAired: const AiredEpisodeMarker(seasonNumber: 2, episodeNumber: 10),
    );

    expect(series.airedEpisodeCount, 20);
  });

  test('a finished series has its whole run out', () {
    const series = Series(
      id: 1,
      name: 'تمام‌شده',
      status: SeriesStatus.ended,
      numberOfEpisodes: 62,
      seasons: [s1, s2],
    );

    expect(series.airedEpisodeCount, 62);
  });

  test('an announced series with nothing aired counts zero', () {
    final series = ongoing(numberOfEpisodes: 8, seasons: const [s1]);

    expect(series.airedEpisodeCount, 0);
  });

  test('without a season breakdown it falls back to the current episode', () {
    final series = ongoing(
      numberOfEpisodes: 20,
      seasons: const [],
      lastAired: const AiredEpisodeMarker(seasonNumber: 1, episodeNumber: 4),
    );

    expect(series.airedEpisodeCount, 4);
  });

  test('being caught up on an ongoing series reaches 100%', () {
    final series = ongoing(
      numberOfEpisodes: 20,
      seasons: const [s1, s2],
      lastAired: const AiredEpisodeMarker(seasonNumber: 2, episodeNumber: 3),
    );

    // Watching all 13 released episodes fills the bar, rather than stalling
    // at 13/20 because seven episodes have not been made yet.
    expect(series.airedEpisodeCount, 13);
  });
}
