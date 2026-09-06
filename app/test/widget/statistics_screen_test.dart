import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/core/widgets/empty_state.dart';
import 'package:cinetrack/core/widgets/error_view.dart';
import 'package:cinetrack/data/local/app_database.dart';
import 'package:cinetrack/data/repositories/local_auth_repository.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/media_summary.dart';
import 'package:cinetrack/domain/repositories/tracking_repository.dart';
import 'package:cinetrack/features/stats/presentation/statistics_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reported from the device: the profile showed ۱ فیلم دیده‌شده, ۲ سریال
/// دنبال‌شده and ۱ موردعلاقه, and the activity screen one tap later said
/// «هنوز فعالیتی ثبت نشده است».
///
/// Two things made that possible, and both are covered here: the screen judged
/// emptiness on three counters alone, and a failed read was folded into an
/// empty [UserStatistics] so it was indistinguishable from a quiet account.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late LocalAuthRepository auth;

  const movie = MediaSummary(id: 1, type: MediaType.movie, title: 'Batman');
  const series = MediaSummary(id: 2, type: MediaType.series, title: 'Fringe');

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    auth = container.read(localAuthRepositoryProvider);
    final result = await auth.register(
      firstName: 'درسا',
      lastName: 'ناجی',
      username: 'dorsa',
      email: 'dorsa@example.com',
      password: 'correct-horse',
    );
    expect(result.isOk, isTrue, reason: '${result.failureOrNull}');
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('fa'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: StatisticsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a brand-new account is told there is nothing yet', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('a watched film produces statistics rather than an empty state', (
    tester,
  ) async {
    final tracking = container.read(trackingRepositoryProvider);
    await tracking.remember(movie, runtimeMinutes: 104, genres: ['اکشن']);
    await tracking.addToWatchlist(movie, WatchStatus.watched);

    await pump(tester);

    expect(find.byType(EmptyState), findsNothing);
    expect(find.text('فیلم‌های دیده‌شده'), findsOneWidget);
  });

  testWidgets('activity that is not finished still counts as activity', (
    tester,
  ) async {
    // Nothing marked *watched* — so every one of the six FR-19 figures is zero
    // — but the account is plainly in use, and the profile says so.
    final tracking = container.read(trackingRepositoryProvider);
    await tracking.addToWatchlist(series, WatchStatus.watching);
    await tracking.setFavourite(series, favourite: true);

    await pump(tester);

    expect(
      find.byType(EmptyState),
      findsNothing,
      reason:
          'the profile shows counters for this account; so must this screen',
    );
  });

  testWidgets('a failed read is shown as an error, not as an empty account', (
    tester,
  ) async {
    // Closing the database is the cheapest faithful stand-in for storage
    // giving way underneath the query.
    await db.close();

    await pump(tester);

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(EmptyState), findsNothing);
  });
}
