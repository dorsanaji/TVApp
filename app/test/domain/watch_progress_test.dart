import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/watch_progress.dart';
import 'package:flutter_test/flutter_test.dart';

/// FR-11 §5.11 — the progress percentage and its five colour states.
///
/// The brief names each colour and its condition explicitly, so there is one
/// test per named state plus the worked example it gives. These are the
/// cheapest three points in the project to defend.
void main() {
  group('FR-11 · percentage', () {
    test('the brief\'s worked example: 10 of 20 episodes is 50 percent', () {
      const progress = WatchProgress(
        watchedEpisodes: 10,
        totalEpisodes: 20,
        hasFinishedAiring: false,
      );

      expect(progress.percent, 50);
      expect(progress.fraction, 0.5);
    });

    test('reports remaining episodes as well as watched (FR-10)', () {
      const progress = WatchProgress(
        watchedEpisodes: 3,
        totalEpisodes: 8,
        hasFinishedAiring: false,
      );

      expect(progress.remainingEpisodes, 5);
    });

    test('a series with no aired episodes does not divide by zero', () {
      const progress = WatchProgress.empty();

      expect(progress.percent, 0);
      expect(progress.fraction, 0);
      expect(progress.remainingEpisodes, 0);
    });

    test('watching more than the aired count is clamped to 100 percent', () {
      const progress = WatchProgress(
        watchedEpisodes: 12,
        totalEpisodes: 10,
        hasFinishedAiring: true,
      );

      expect(progress.percent, 100);
      expect(progress.isComplete, isTrue);
    });
  });

  group('FR-11 · colour states', () {
    test('بی‌رنگ/مشکی — nothing watched', () {
      const progress = WatchProgress(
        watchedEpisodes: 0,
        totalEpisodes: 20,
        hasFinishedAiring: false,
      );

      expect(progress.state, ProgressState.none);
    });

    test('سبز — all watched, but more episodes are coming', () {
      const progress = WatchProgress(
        watchedEpisodes: 20,
        totalEpisodes: 20,
        hasFinishedAiring: false,
      );

      expect(progress.state, ProgressState.ongoingComplete);
    });

    test('بنفش — all watched and nothing further will be released', () {
      const progress = WatchProgress(
        watchedEpisodes: 20,
        totalEpisodes: 20,
        hasFinishedAiring: true,
      );

      expect(progress.state, ProgressState.finishedComplete);
    });

    test('قرمز — the user stopped without watching everything', () {
      const dropped = WatchProgress(
        watchedEpisodes: 4,
        totalEpisodes: 20,
        hasFinishedAiring: true,
        userStatus: WatchStatus.dropped,
      );
      const paused = WatchProgress(
        watchedEpisodes: 4,
        totalEpisodes: 20,
        hasFinishedAiring: true,
        userStatus: WatchStatus.paused,
      );

      expect(dropped.state, ProgressState.stopped);
      expect(paused.state, ProgressState.stopped);
    });

    test('زرد — unwatched episodes remain', () {
      const progress = WatchProgress(
        watchedEpisodes: 7,
        totalEpisodes: 20,
        hasFinishedAiring: false,
        userStatus: WatchStatus.watching,
      );

      expect(progress.state, ProgressState.partial);
    });
  });

  group('FR-11 · precedence between conditions', () {
    test('nothing watched reads as black even when marked dropped', () {
      const progress = WatchProgress(
        watchedEpisodes: 0,
        totalEpisodes: 20,
        hasFinishedAiring: true,
        userStatus: WatchStatus.dropped,
      );

      // Red means "stopped part-way". A series never started is simply
      // untouched, so black is the honest signal.
      expect(progress.state, ProgressState.none);
    });

    test(
      'watched in full then paused still counts as complete, not stopped',
      () {
        const progress = WatchProgress(
          watchedEpisodes: 20,
          totalEpisodes: 20,
          hasFinishedAiring: true,
          userStatus: WatchStatus.paused,
        );

        expect(progress.state, ProgressState.finishedComplete);
      },
    );
  });
}
