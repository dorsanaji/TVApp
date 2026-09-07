import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/data/local/app_database.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/media_summary.dart';
import 'package:cinetrack/domain/repositories/tracking_repository.dart';
import 'package:cinetrack/features/tracking/presentation/tracking_providers.dart';
import 'package:cinetrack/features/tracking/presentation/watchlist_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';

/// Tab order, and the film/series filter on the watched section.
void main() {
  const movie = MediaSummary(
    id: 1,
    type: MediaType.movie,
    title: 'یک فیلم',
  );
  const series = MediaSummary(
    id: 2,
    type: MediaType.series,
    title: 'یک سریال',
  );

  Future<void> pumpScreen(WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...authOverrides(),
          databaseProvider.overrideWithValue(db),
          watchlistProvider(WatchlistSection.watched)
              .overrideWith((ref) => Future.value([movie, series])),
          watchlistProvider(WatchlistSection.watching)
              .overrideWith((ref) => Future.value(const <MediaSummary>[])),
          watchlistProvider(WatchlistSection.watchLater)
              .overrideWith((ref) => Future.value(const <MediaSummary>[])),
          watchlistProvider(WatchlistSection.favourites)
              .overrideWith((ref) => Future.value(const <MediaSummary>[])),
          progressForAllProvider(const [2])
              .overrideWith((ref) => Future.value(const {})),
        ],
        child: const MaterialApp(
          locale: Locale('fa', 'IR'),
          supportedLocales: [Locale('fa', 'IR')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: WatchlistScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  /// The screen always has a shimmer somewhere, so `pumpAndSettle` never
  /// returns; advance past the tab animation by hand instead.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('sections read: plan to watch, favourites, watched, watching',
      (tester) async {
    await pumpScreen(tester);

    final tabs = tester
        .widgetList<Tab>(find.byType(Tab))
        .map((t) => (t.child as Text?)?.data ?? t.text)
        .toList();

    expect(tabs, <String>[
      'بعداً تماشا می‌کنم',
      'موردعلاقه‌ها',
      'مشاهده شده',
      'در حال تماشا',
    ]);
  });

  testWidgets('the watched section can show films and series separately',
      (tester) async {
    await pumpScreen(tester);

    // Third tab is "watched".
    await tester.tap(find.text('مشاهده شده'));
    await settle(tester);

    // Mixed by default.
    expect(find.text('یک فیلم'), findsWidgets);
    expect(find.text('یک سریال'), findsWidgets);

    await tester.tap(find.widgetWithText(ChoiceChip, 'فیلم‌ها'));
    await settle(tester);
    expect(find.text('یک فیلم'), findsWidgets);
    expect(find.text('یک سریال'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'سریال‌ها'));
    await settle(tester);
    expect(find.text('یک فیلم'), findsNothing);
    expect(find.text('یک سریال'), findsWidgets);

    await tester.tap(find.widgetWithText(ChoiceChip, 'همه'));
    await settle(tester);
    expect(find.text('یک فیلم'), findsWidgets);
    expect(find.text('یک سریال'), findsWidgets);
  });
}
