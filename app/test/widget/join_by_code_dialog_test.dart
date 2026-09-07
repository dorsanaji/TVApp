import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/data/local/app_database.dart';
import 'package:cinetrack/domain/entities/social/custom_list.dart';
import 'package:cinetrack/domain/repositories/list_repository.dart';
import 'package:cinetrack/features/lists/presentation/list_providers.dart';
import 'package:cinetrack/features/lists/presentation/lists_screen.dart';
import 'package:cinetrack/features/social/presentation/social_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';

/// Regression: backing out of the invitation-code dialog turned the screen red.
///
/// The dialog's `TextEditingController` was disposed as soon as `showDialog`
/// returned, while the `TextField` was still on screen for the dismiss
/// animation — "A TextEditingController was used after being disposed".
void main() {
  Future<List<String>> openAndDismiss(
    WidgetTester tester,
    Future<void> Function(WidgetTester) dismiss,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exceptionAsString());
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...authOverrides(),
          databaseProvider.overrideWithValue(db),
          personalListsProvider
              .overrideWith((ref) => Future.value(const <PersonalList>[])),
          myCollaborativeListsProvider
              .overrideWith((ref) => Future.value(const <CustomList>[])),
        ],
        child: const MaterialApp(
          locale: Locale('fa', 'IR'),
          supportedLocales: [Locale('fa', 'IR')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ListsScreen(),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    await tester.tap(find.byIcon(Icons.vpn_key_outlined));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('پیوستن با کد دعوت'), findsWidgets);

    await dismiss(tester);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    return errors;
  }

  testWidgets('cancelling the code dialog throws nothing', (tester) async {
    final errors = await openAndDismiss(tester, (t) async {
      await t.tap(find.text('انصراف'));
    });

    expect(errors, isEmpty);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('typing then cancelling throws nothing', (tester) async {
    final errors = await openAndDismiss(tester, (t) async {
      await t.enterText(find.byType(TextField), 'ABCD-EFGH');
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(find.text('انصراف'));
    });

    expect(errors, isEmpty);
  });
}
