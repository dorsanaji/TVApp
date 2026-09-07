import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/core/theme/app_theme.dart';
import 'package:cinetrack/data/repositories/supabase_social_repository.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/social/collaboration_request.dart';
import 'package:cinetrack/domain/entities/social/custom_list.dart';
import 'package:cinetrack/domain/entities/social/custom_list_item.dart';
import 'package:cinetrack/domain/entities/social/list_collaborator.dart';
import 'package:cinetrack/domain/repositories/auth_repository.dart';
import 'package:cinetrack/features/social/presentation/collaborative_list_screen.dart';
import 'package:cinetrack/features/social/presentation/social_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_auth.dart';

/// Regression: a pending access request must not break the owner's view.
///
/// The app theme gives every `FilledButton` `minimumSize: Size.fromHeight(48)`,
/// whose *width* is `double.infinity`. Inside a Column that merely stretches
/// the button, but a Row lays non-flexible children out with an unbounded main
/// axis. The «تأیید دسترسی» button in the pending-request card lives in a Row,
/// so it was asked to lay out at an infinite width; layout threw, the whole
/// card subtree was left un-laid-out, and the owner saw an empty screen — but
/// only once somebody had actually requested access.
void main() {
  const listId = 'list_x';
  const ownerId = 'owner_b';

  final list = CustomList(
    listId: listId,
    ownerId: ownerId,
    title: 'فهرست تست',
    isPublic: true,
    itemCount: 1,
    createdAt: DateTime(2026, 9, 5),
    updatedAt: DateTime(2026, 9, 5),
  );

  final item = CustomListItem(
    id: 'i1',
    listId: listId,
    mediaId: 550,
    mediaType: MediaType.movie,
    title: 'Fight Club',
    addedBy: ownerId,
    addedAt: DateTime(2026, 9, 5),
  );

  final request = CollaborationRequest(
    requestId: 'collab_req_${listId}_acc_a',
    listId: listId,
    userId: 'acc_a',
    username: 'account_a',
    createdAt: DateTime(2026, 9, 5),
  );

  Future<List<String>> pumpOwnerView(
    WidgetTester tester, {
    required List<CollaborationRequest> requests,
    required Size size,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exceptionAsString());
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...authOverrides(
            const AppUser(
              id: ownerId,
              username: 'owner',
              firstName: 'User',
              lastName: 'B',
            ),
          ),
          socialRepositoryProvider
              .overrideWithValue(SupabaseSocialRepository(client: null)),
          collaborativeListStreamProvider(listId)
              .overrideWith((ref) => Stream.value(list)),
          collaborativeListDetailsProvider(listId)
              .overrideWith((ref) => Future.value(list)),
          collaborativeListItemsStreamProvider(listId)
              .overrideWith((ref) => Stream.value([item])),
          collaborativeListItemsProvider(listId)
              .overrideWith((ref) => Future.value([item])),
          listCollaboratorsStreamProvider(listId)
              .overrideWith((ref) => Stream.value(const <ListCollaborator>[])),
          listCollaboratorsProvider(listId)
              .overrideWith((ref) => Future.value(const <ListCollaborator>[])),
          isCollaboratorProvider(listId)
              .overrideWith((ref) => Future.value(true)),
          collaborationRequestsStreamProvider(listId)
              .overrideWith((ref) => Stream.value(requests)),
          collaborationRequestsProvider(listId)
              .overrideWith((ref) => Future.value(requests)),
        ],
        child: MaterialApp(
          // NFR-11a: the real app runs Persian / RTL, and the failure only
          // reproduces under the RTL layout the app actually ships.
          locale: const Locale('fa', 'IR'),
          supportedLocales: const [Locale('fa', 'IR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const CollaborativeListScreen(listId: listId),
        ),
      ),
    );

    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    return errors;
  }

  const phone = Size(411, 915);
  const smallPhone = Size(360, 640);

  testWidgets('owner view lays out cleanly with no pending request',
      (tester) async {
    final errors = await pumpOwnerView(
      tester,
      requests: const [],
      size: phone,
    );

    expect(errors, isEmpty);
    expect(find.text('فهرست تست'), findsWidgets);
  });

  for (final (label, size, scale) in <(String, Size, double)>[
    ('phone', phone, 1.0),
    ('small phone', smallPhone, 1.0),
    ('phone, large font', phone, 1.3),
    ('small phone, large font', smallPhone, 1.3),
  ]) {
    testWidgets('owner still sees the list with a pending request ($label)',
        (tester) async {
      final errors = await pumpOwnerView(
        tester,
        requests: [request],
        size: size,
        textScale: scale,
      );

      // Previously: "BoxConstraints forces an infinite width", followed by a
      // cascade of "RenderBox was not laid out" — a blank page.
      expect(errors, isEmpty);

      // The list itself must still be there alongside the request card.
      expect(find.text('فهرست تست'), findsWidgets);
      expect(find.text('تأیید دسترسی'), findsOneWidget);
      expect(find.text('رد'), findsOneWidget);
    });
  }

  testWidgets('owner view survives several pending requests', (tester) async {
    final errors = await pumpOwnerView(
      tester,
      requests: [
        request,
        request.copyWith(requestId: 'r2', userId: 'u2', username: 'یاسی'),
        request.copyWith(
          requestId: 'r3',
          userId: 'u3',
          username: 'mohammad_hosseini_1997',
        ),
      ],
      size: smallPhone,
    );

    expect(errors, isEmpty);
    expect(find.text('تأیید دسترسی'), findsNWidgets(3));
  });
}
