import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/data/local/app_database.dart';
import 'package:cinetrack/data/repositories/supabase_social_repository.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/media_summary.dart';
import 'package:cinetrack/domain/repositories/auth_repository.dart';
import 'package:cinetrack/domain/repositories/review_repository.dart';
import 'package:cinetrack/domain/repositories/tracking_repository.dart';
import 'package:cinetrack/features/auth/presentation/auth_providers.dart';
import 'package:cinetrack/features/reviews/presentation/widgets/diary_entry_modal.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockReviewRepository extends Mock implements ReviewRepository {}
class MockTrackingRepository extends Mock implements TrackingRepository {}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  const testMedia = MediaSummary(
    id: 550,
    type: MediaType.movie,
    title: 'باشگاه مبارزه (Fight Club)',
    releaseDate: '1999-10-15',
  );

  const testUser = AppUser(
    id: 'user_1',
    firstName: 'علی',
    lastName: 'اکبری',
    username: 'ali',
    email: 'ali@example.com',
  );

  Widget createSubject({required Widget child}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        currentUserProvider.overrideWith((ref) => Stream.value(testUser)),
        socialRepositoryProvider
            .overrideWithValue(SupabaseSocialRepository(client: null)),
      ],
      child: MaterialApp(
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [Locale('fa', 'IR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('Task 2 · DiaryEntryModal UI Tests', () {
    testWidgets('renders all required inputs for Letterboxd diary', (tester) async {
      await tester.pumpWidget(
        createSubject(child: const DiaryEntryModal(item: testMedia)),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('ثبت در دفترچه تماشا (Diary)'), findsOneWidget);
      expect(find.text('باشگاه مبارزه (Fight Club)'), findsWidgets);

      // 1. Star Rating
      expect(find.text('امتیاز شما'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsWidgets);

      // 2. Jalali Date Picker
      expect(find.text('تاریخ تماشا (تقویم شمسی)'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);

      // 3. Rewatch toggle
      expect(find.text('تماشای مجدد (Rewatch)'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);

      // 4. Written review textfield
      expect(find.text('یادداشت یا نقد (اختیاری)'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // 5. Spoiler toggle
      expect(find.text('این یادداشت حاوی اسپویل داستان است'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsOneWidget);

      // 6. Submit button
      expect(find.text('ثبت در دفترچه تماشا'), findsOneWidget);
    });

    testWidgets('toggling rewatch updates switch state', (tester) async {
      await tester.pumpWidget(
        createSubject(child: const DiaryEntryModal(item: testMedia)),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);

      // Toggle rewatch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.value, isTrue);
    });
  });
}
