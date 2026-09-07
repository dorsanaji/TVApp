import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/core/error/result.dart';
import 'package:cinetrack/data/local/app_database.dart';
import 'package:cinetrack/data/repositories/local_auth_repository.dart';
import 'package:cinetrack/data/repositories/local_tracking_repository.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/episode.dart';
import 'package:cinetrack/domain/entities/media_summary.dart';
import 'package:cinetrack/domain/entities/series.dart';
import 'package:cinetrack/domain/repositories/catalog_repository.dart';
import 'package:cinetrack/features/tracking/presentation/tracking_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// The watch statuses a user may set, and what "watched" means for a series.
void main() {
  group('FR-09 · which statuses exist', () {
    test('paused, dropped and favourite are no longer statuses', () {
      expect(WatchStatus.values, hasLength(3));
      expect(
        WatchStatus.values.map((s) => s.name),
        containsAll(<String>['planToWatch', 'watching', 'watched']),
      );
    });

    test('a film is either seen or planned — never "in progress"', () {
      expect(
        WatchStatus.availableFor(MediaType.movie),
        <WatchStatus>[WatchStatus.watched, WatchStatus.planToWatch],
      );
    });

    test('a series adds "in progress"', () {
      expect(
        WatchStatus.availableFor(MediaType.series),
        <WatchStatus>[
          WatchStatus.watched,
          WatchStatus.watching,
          WatchStatus.planToWatch,
        ],
      );
    });
  });

  group('marking a series watched', () {
    late AppDatabase db;
    late LocalAuthRepository auth;
    late LocalTrackingRepository repository;
    late ProviderContainer container;

    const breakingBad = MediaSummary(
      id: 1396,
      type: MediaType.series,
      title: 'بریکینگ بد',
      releaseDate: '2008-01-20',
    );

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      db = AppDatabase(NativeDatabase.memory());
      auth = LocalAuthRepository(
        db: db,
        storage: const FlutterSecureStorage(),
      );
      repository = LocalTrackingRepository(db, auth);

      final registered = await auth.register(
        firstName: 'آریا',
        lastName: 'تست',
        username: 'tester',
        password: 'correct-horse',
      );
      expect(registered.isOk, isTrue, reason: '${registered.failureOrNull}');

      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        trackingRepositoryProvider.overrideWithValue(repository),
        catalogRepositoryProvider.overrideWithValue(_FakeCatalog()),
      ]);

      // Two aired episodes in season 1, three in season 2; the third episode
      // of season 2 has not aired yet, and season 0 is specials.
      await repository.rememberSeriesProgress(
        seriesId: 1396,
        airedEpisodeCount: 4,
        hasFinishedAiring: false,
      );
    });

    tearDown(() async {
      container.dispose();
      repository.dispose();
      auth.dispose();
      await db.close();
    });

    test('ticks every aired episode and fills the bar', () async {
      await container
          .read(trackingActionsProvider)
          .setStatus(breakingBad, WatchStatus.watched);

      final watched = (await repository.watchedEpisodeIds(1396)).valueOrNull!;
      // s1e1, s1e2, s2e1, s2e2 — not the unaired s2e3, not the special.
      expect(watched, <int>{101, 102, 201, 202});

      final progress = (await repository.progressOf(1396)).valueOrNull!;
      expect(progress.percent, 100);
      expect(progress.isComplete, isTrue);
    });

    test('a film records no episode marks', () async {
      const dune = MediaSummary(
        id: 438631,
        type: MediaType.movie,
        title: 'تل‌ماسه',
      );

      await container
          .read(trackingActionsProvider)
          .setStatus(dune, WatchStatus.watched);

      final watched = (await repository.watchedEpisodeIds(438631)).valueOrNull!;
      expect(watched, isEmpty);
    });
  });
}

Episode _ep(int id, int season, int number, {required bool aired}) => Episode(
  id: id,
  seasonNumber: season,
  episodeNumber: number,
  name: 'E$number',
  airDate: aired ? '2010-01-01' : '2999-01-01',
  runtime: 45,
);

/// Only the two methods the "mark everything watched" path calls are real.
class _FakeCatalog implements CatalogRepository {
  @override
  Future<Result<Series>> seriesDetails(int id) async => Ok(
    Series(
      id: id,
      name: 'بریکینگ بد',
      seasons: const [
        SeasonSummary(id: 0, seasonNumber: 0, name: 'ویژه'),
        SeasonSummary(id: 1, seasonNumber: 1, name: 'فصل ۱'),
        SeasonSummary(id: 2, seasonNumber: 2, name: 'فصل ۲'),
      ],
    ),
  );

  @override
  Future<Result<Season>> season(int seriesId, int seasonNumber) async => Ok(
    Season(
      id: seasonNumber,
      seasonNumber: seasonNumber,
      name: 'فصل $seasonNumber',
      episodes: switch (seasonNumber) {
        0 => [_ep(1, 0, 1, aired: true)],
        1 => [_ep(101, 1, 1, aired: true), _ep(102, 1, 2, aired: true)],
        _ => [
          _ep(201, 2, 1, aired: true),
          _ep(202, 2, 2, aired: true),
          _ep(203, 2, 3, aired: false),
        ],
      },
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
