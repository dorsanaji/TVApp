import 'package:cinetrack/data/local/app_database.dart';
import 'package:cinetrack/data/repositories/local_auth_repository.dart';
import 'package:cinetrack/data/repositories/local_tracking_repository.dart';
import 'package:cinetrack/data/services/email_sender.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/media_summary.dart';
import 'package:cinetrack/domain/entities/watch_progress.dart';
import 'package:cinetrack/domain/repositories/tracking_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 3 requirements exercised against a real (in-memory) database, so the
/// SQL is verified rather than assumed: FR-09, FR-10, FR-11, FR-12, FR-16 and
/// FR-19, plus the idempotency NFR-22 demands.
void main() {
  late AppDatabase db;
  late LocalAuthRepository auth;
  late LocalTrackingRepository repository;

  const dune = MediaSummary(
    id: 438631,
    type: MediaType.movie,
    title: 'تل‌ماسه',
    releaseDate: '2021-10-22',
  );

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
      emailSender: DebugEmailSender(),
    );
    repository = LocalTrackingRepository(db, auth);

    // §4.1 makes signing in a precondition for recording activity, so these
    // tests run as a real account. Guest behaviour is covered separately in
    // `user_isolation_test.dart`.
    final registered = await auth.register(
      firstName: 'آریا',
      lastName: 'تست',
      username: 'tester',
      email: 'tester@example.com',
      password: 'correct-horse',
    );
    expect(registered.isOk, isTrue, reason: '${registered.failureOrNull}');
  });

  tearDown(() async {
    repository.dispose();
    auth.dispose();
    await db.close();
  });

  group('FR-09 · watch status', () {
    test('a status is stored and read back', () async {
      await repository.addToWatchlist(dune, WatchStatus.watching);

      final result = await repository.statusOf(dune.id, dune.type);
      expect(result.valueOrNull, WatchStatus.watching);
    });

    test('setting a new status replaces the old one', () async {
      await repository.addToWatchlist(dune, WatchStatus.planToWatch);
      await repository.addToWatchlist(dune, WatchStatus.watched);

      expect(
        (await repository.statusOf(dune.id, dune.type)).valueOrNull,
        WatchStatus.watched,
      );
      // One row, not two — the composite key is what enforces this.
      final rows = await db.select(db.watchStatuses).get();
      expect(rows, hasLength(1));
    });

    test('a null status clears the entry', () async {
      await repository.addToWatchlist(dune, WatchStatus.watching);
      await repository.setStatus(dune.id, dune.type, null);

      expect(
        (await repository.statusOf(dune.id, dune.type)).valueOrNull,
        isNull,
      );
    });

    test('a film and a series sharing an id are tracked separately', () async {
      // Ids are only unique per type upstream, so a collision is possible and
      // must not conflate two different titles.
      const film = MediaSummary(id: 1396, type: MediaType.movie, title: 'X');

      await repository.addToWatchlist(film, WatchStatus.watched);
      await repository.addToWatchlist(breakingBad, WatchStatus.watching);

      expect(
        (await repository.statusOf(1396, MediaType.movie)).valueOrNull,
        WatchStatus.watched,
      );
      expect(
        (await repository.statusOf(1396, MediaType.series)).valueOrNull,
        WatchStatus.watching,
      );
    });
  });

  group('NFR-22 · writes are idempotent', () {
    test('marking the same episode twice does not double-count', () async {
      for (var i = 0; i < 3; i++) {
        await repository.setEpisodeWatched(
          1396,
          101,
          watched: true,
          seasonNumber: 1,
          episodeNumber: 1,
          runtimeMinutes: 58,
        );
      }

      final watched = await repository.watchedEpisodeIds(1396);
      expect(watched.valueOrNull, {101});

      final stats = await repository.statistics();
      expect(stats.valueOrNull?.episodesWatched, 1);
      expect(stats.valueOrNull?.totalMinutesWatched, 58);
    });
  });

  group('FR-10 · episode marks', () {
    test('an episode can be marked and unmarked', () async {
      await repository.setEpisodeWatched(1396, 101, watched: true);
      expect((await repository.watchedEpisodeIds(1396)).valueOrNull, {101});

      await repository.setEpisodeWatched(1396, 101, watched: false);
      expect((await repository.watchedEpisodeIds(1396)).valueOrNull, isEmpty);
    });

    test('a whole season is marked in one action', () async {
      await repository.setSeasonWatched(
        1396,
        1,
        [101, 102, 103],
        watched: true,
        runtimes: {101: 58, 102: 48, 103: 48},
        episodeNumbers: {101: 1, 102: 2, 103: 3},
      );

      expect((await repository.watchedEpisodeIds(1396)).valueOrNull, {
        101,
        102,
        103,
      });
      expect(
        (await repository.statistics()).valueOrNull?.totalMinutesWatched,
        58 + 48 + 48,
      );
    });

    test('unmarking a season clears only that season', () async {
      await repository.setSeasonWatched(1396, 1, [101, 102], watched: true);
      await repository.setSeasonWatched(1396, 2, [201, 202], watched: true);

      await repository.setSeasonWatched(1396, 1, [101, 102], watched: false);

      expect((await repository.watchedEpisodeIds(1396)).valueOrNull, {
        201,
        202,
      });
    });
  });

  group('FR-11 · progress', () {
    setUp(() async {
      await repository.rememberSeriesProgress(
        seriesId: 1396,
        airedEpisodeCount: 20,
        hasFinishedAiring: false,
      );
    });

    test("the brief's worked example: 10 of 20 is 50 percent", () async {
      await repository.setSeasonWatched(
        1396,
        1,
        List.generate(10, (i) => 100 + i),
        watched: true,
      );

      final progress = (await repository.progressOf(1396)).valueOrNull!;
      expect(progress.watchedEpisodes, 10);
      expect(progress.totalEpisodes, 20);
      expect(progress.percent, 50);
      expect(progress.remainingEpisodes, 10);
      expect(progress.state, ProgressState.partial); // زرد
    });

    test('all watched while still airing is green, not purple', () async {
      await repository.setSeasonWatched(
        1396,
        1,
        List.generate(20, (i) => 100 + i),
        watched: true,
      );

      final progress = (await repository.progressOf(1396)).valueOrNull!;
      expect(progress.state, ProgressState.ongoingComplete);
    });

    test('all watched once the series has ended is purple', () async {
      await repository.rememberSeriesProgress(
        seriesId: 1396,
        airedEpisodeCount: 20,
        hasFinishedAiring: true,
      );
      await repository.setSeasonWatched(
        1396,
        1,
        List.generate(20, (i) => 100 + i),
        watched: true,
      );

      final progress = (await repository.progressOf(1396)).valueOrNull!;
      expect(progress.state, ProgressState.finishedComplete);
    });

    test('a dropped series part-way through is red', () async {
      await repository.addToWatchlist(breakingBad, WatchStatus.dropped);
      await repository.setSeasonWatched(1396, 1, [101, 102], watched: true);

      final progress = (await repository.progressOf(1396)).valueOrNull!;
      expect(progress.state, ProgressState.stopped);
    });

    test('progress for many series comes back in one call', () async {
      await repository.rememberSeriesProgress(
        seriesId: 999,
        airedEpisodeCount: 10,
        hasFinishedAiring: true,
      );
      await repository.setSeasonWatched(1396, 1, [101, 102], watched: true);
      await repository.setSeasonWatched(999, 1, [901], watched: true);

      final all = (await repository.progressForAll([1396, 999])).valueOrNull!;
      expect(all[1396]!.watchedEpisodes, 2);
      expect(all[999]!.watchedEpisodes, 1);
    });

    test('an untracked series reports empty progress, not an error', () async {
      final progress = (await repository.progressOf(4242)).valueOrNull!;
      expect(progress.totalEpisodes, 0);
      expect(progress.percent, 0);
      expect(progress.state, ProgressState.none);
    });
  });

  group('FR-12 · watchlist sections', () {
    test('a title appears in the section matching its status', () async {
      await repository.addToWatchlist(dune, WatchStatus.watching);
      await repository.addToWatchlist(breakingBad, WatchStatus.planToWatch);

      final watching = (await repository.watchlist(
        WatchlistSection.watching,
      )).valueOrNull!;
      final later = (await repository.watchlist(
        WatchlistSection.watchLater,
      )).valueOrNull!;

      expect(watching.map((i) => i.id), [dune.id]);
      expect(later.map((i) => i.id), [breakingBad.id]);
    });

    test('the cached title renders without a network call', () async {
      await repository.addToWatchlist(dune, WatchStatus.watching);

      final items = (await repository.watchlist(
        WatchlistSection.watching,
      )).valueOrNull!;
      // Enough was cached at add time to draw the card offline (NFR-20).
      expect(items.single.title, 'تل‌ماسه');
      expect(items.single.releaseDate, '2021-10-22');
    });
  });

  group('FR-16 · favourites', () {
    test('favourite is independent of watch status', () async {
      await repository.addToWatchlist(dune, WatchStatus.watching);
      await repository.setFavourite(dune, favourite: true);

      expect(
        (await repository.isFavourite(dune.id, dune.type)).valueOrNull,
        isTrue,
      );
      // Both hold at once, which is why the brief lists them separately.
      expect(
        (await repository.statusOf(dune.id, dune.type)).valueOrNull,
        WatchStatus.watching,
      );
    });

    test('unfavouriting removes it from the favourites section', () async {
      await repository.setFavourite(dune, favourite: true);
      await repository.setFavourite(dune, favourite: false);

      expect((await repository.favourites()).valueOrNull, isEmpty);
    });
  });

  group('FR-19 · statistics', () {
    test('counts films, series, and episodes separately', () async {
      await repository.addToWatchlist(dune, WatchStatus.watched);
      await repository.addToWatchlist(breakingBad, WatchStatus.watched);
      await repository.setSeasonWatched(1396, 1, [101, 102], watched: true);

      final stats = (await repository.statistics()).valueOrNull!;
      expect(stats.moviesWatched, 1);
      expect(stats.seriesWatched, 1);
      expect(stats.episodesWatched, 2);
    });

    test(
      'the favourite genre is the most frequent across watched titles',
      () async {
        await repository.remember(dune, genres: ['علمی-تخیلی', 'ماجراجویی']);
        await repository.addToWatchlist(dune, WatchStatus.watched);
        await repository.remember(breakingBad, genres: ['علمی-تخیلی', 'درام']);
        await repository.addToWatchlist(breakingBad, WatchStatus.watched);

        final stats = (await repository.statistics()).valueOrNull!;
        expect(stats.favouriteGenre, 'علمی-تخیلی');
        expect(stats.genreBreakdown['علمی-تخیلی'], 2);
      },
    );

    test('a user who has watched nothing gets zeroes, not nulls', () async {
      final stats = (await repository.statistics()).valueOrNull!;
      expect(stats.moviesWatched, 0);
      expect(stats.episodesWatched, 0);
      expect(stats.totalMinutesWatched, 0);
      expect(stats.favouriteGenre, isNull);
    });
  });

  test('changes are emitted so dependent screens refresh', () async {
    // Drain first. This stream carries account changes as well as data
    // changes, and the sign-in performed in setUp arrives on a microtask that
    // can land either side of the subscription below — which made this
    // assertion count two emissions or three depending on the run.
    await Future<void>.delayed(Duration.zero);

    final emissions = <void>[];
    final subscription = repository.changes.listen(emissions.add);
    addTearDown(subscription.cancel);

    await repository.addToWatchlist(dune, WatchStatus.watching);
    await repository.setFavourite(dune, favourite: true);
    await Future<void>.delayed(Duration.zero);

    expect(emissions, hasLength(2));
  });
}
