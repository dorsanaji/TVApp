import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/data/local/app_database.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/media_summary.dart';
import 'package:cinetrack/features/tracking/presentation/widgets/tracking_bar.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';

/// The status sheet must offer only what FR-09 allows for that kind of title.
void main() {
  const movie = MediaSummary(
    id: 438631,
    type: MediaType.movie,
    title: 'تل‌ماسه',
  );

  const series = MediaSummary(
    id: 1396,
    type: MediaType.series,
    title: 'بریکینگ بد',
  );

  Future<void> openSheet(WidgetTester tester, MediaSummary item) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...cloudOverrides(),
          databaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(home: Scaffold(body: TrackingBar(item: item))),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byType(FilledButton).first);
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('a film offers only watched and plan to watch', (tester) async {
    await openSheet(tester, movie);

    expect(find.text('مشاهده شده'), findsOneWidget);
    expect(find.text('قصد دارم تماشا کنم'), findsOneWidget);

    // No in-progress state for a film, and none of the retired statuses.
    expect(find.text('در حال تماشا'), findsNothing);
    expect(find.text('متوقف شده'), findsNothing);
    expect(find.text('رهاشده'), findsNothing);
    expect(find.text('موردعلاقه'), findsNothing);
  });

  testWidgets('a series adds in-progress, and nothing else', (tester) async {
    await openSheet(tester, series);

    expect(find.text('مشاهده شده'), findsOneWidget);
    expect(find.text('در حال تماشا'), findsOneWidget);
    expect(find.text('قصد دارم تماشا کنم'), findsOneWidget);

    expect(find.text('متوقف شده'), findsNothing);
    expect(find.text('رهاشده'), findsNothing);
    expect(find.text('موردعلاقه'), findsNothing);
  });
}
