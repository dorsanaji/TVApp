import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/core/error/failure.dart';
import 'package:cinetrack/core/error/result.dart';
import 'package:cinetrack/core/widgets/empty_state.dart';
import 'package:cinetrack/core/widgets/error_view.dart';
import 'package:cinetrack/domain/repositories/tracking_repository.dart';
import 'package:cinetrack/features/stats/presentation/statistics_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// FR-19 — what the statistics screen says about an account.
///
/// Driven through a fake repository rather than a real database: the figures
/// now come from Supabase, and what is being checked here is how the screen
/// reads them, not how they are stored.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required Result<UserStatistics> stats,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trackingRepositoryProvider
              .overrideWithValue(_FakeTracking(stats)),
        ],
        child: const MaterialApp(
          locale: Locale('fa'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: StatisticsScreen(),
          ),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('a brand-new account is told there is nothing yet',
      (tester) async {
    await pump(tester, stats: const Ok(UserStatistics()));

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('a watched film produces statistics rather than an empty state',
      (tester) async {
    await pump(
      tester,
      stats: const Ok(
        UserStatistics(
          moviesWatched: 1,
          totalMinutesWatched: 104,
          favouriteGenre: 'اکشن',
          genreBreakdown: {'اکشن': 1},
        ),
      ),
    );

    expect(find.byType(EmptyState), findsNothing);
    expect(find.text('فیلم‌های دیده‌شده'), findsOneWidget);
  });

  testWidgets('activity that is not finished still counts as activity',
      (tester) async {
    // Nothing marked *watched* — so every one of the six FR-19 figures is
    // zero — but the account is plainly in use, and the profile says so.
    await pump(
      tester,
      stats: const Ok(UserStatistics(episodesWatched: 3)),
    );

    expect(
      find.byType(EmptyState),
      findsNothing,
      reason: 'the profile shows counters for this account; so must this screen',
    );
  });

  testWidgets('a failed read is shown as an error, not as an empty account',
      (tester) async {
    await pump(tester, stats: const Err(FetchFailure()));

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(EmptyState), findsNothing);
  });
}

/// Answers `statistics()` and nothing else; the screen asks for nothing else.
class _FakeTracking implements TrackingRepository {
  _FakeTracking(this._stats);

  final Result<UserStatistics> _stats;

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<Result<UserStatistics>> statistics() async => _stats;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
