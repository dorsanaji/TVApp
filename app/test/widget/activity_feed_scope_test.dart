import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/data/local/app_database.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/social/social_activity.dart';
import 'package:cinetrack/features/social/presentation/activity_feed_screen.dart';
import 'package:cinetrack/features/social/presentation/social_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';

/// The feed shows other people, and a follow is not about a film.
void main() {
  SocialActivity follow() => SocialActivity(
    activityId: 'follow_u1_u2',
    userId: 'u2',
    actionType: SocialActionType.followed,
    movieId: 0,
    movieTitle: 'دورسا',
    username: 'آریا',
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
  );

  SocialActivity watched() => SocialActivity(
    activityId: 'watch_u2_movie_550',
    userId: 'u2',
    actionType: SocialActionType.watched,
    movieId: 550,
    mediaType: MediaType.movie,
    movieTitle: 'باشگاه مبارزه',
    moviePoster: '/p.jpg',
    username: 'آریا',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
  );

  Future<void> pumpFeed(
    WidgetTester tester,
    List<SocialActivity> activities,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...authOverrides(),
          databaseProvider.overrideWithValue(db),
          activityFeedStreamProvider
              .overrideWith((ref) => Stream.value(activities)),
        ],
        child: const MaterialApp(
          locale: Locale('fa', 'IR'),
          supportedLocales: [Locale('fa', 'IR')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: ActivityFeedView()),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('a follow carries no poster card', (tester) async {
    await pumpFeed(tester, [follow()]);

    expect(find.text('آریا «دورسا» را دنبال کرد'), findsOneWidget);

    // The media card renders a poster placeholder and the title again; a
    // follow has neither, and tapping the placeholder said "film not found".
    expect(find.byIcon(Icons.movie), findsNothing);
    expect(find.text('دورسا'), findsNothing);
  });

  testWidgets('a watch still shows its poster card', (tester) async {
    await pumpFeed(tester, [watched()]);

    expect(find.text('باشگاه مبارزه'), findsOneWidget);
  });
}
