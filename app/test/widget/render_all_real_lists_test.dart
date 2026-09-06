import 'package:cinetrack/core/di/providers.dart';
import 'package:cinetrack/data/repositories/supabase_social_repository.dart';
import 'package:cinetrack/domain/repositories/auth_repository.dart';
import 'package:cinetrack/features/auth/presentation/auth_providers.dart';
import 'package:cinetrack/features/social/presentation/collaborative_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final client = SupabaseClient(
    'https://okrcsawzkaaroxcgwgap.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9rcmNzYXd6a2Fhcm94Y2d3Z2FwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg2MTI0NTAsImV4cCI6MjEwNDE4ODQ1MH0.h80ACKkqxFu57qkvm-DFlx_GFvsbNt0lfM_CdTQt06U',
  );

  const realListIds = [
    'list_1788620699241105',
    'list_1788621972531538',
    'list_1788627402529799',
    'list_1788622557874015',
  ];

  const testUser = AppUser(
    id: 'user_different_phone',
    email: 'other@phone.com',
    username: 'گوشی_دیگر',
    firstName: 'کاربر',
    lastName: 'دیگر',
  );

  for (final listId in realListIds) {
    testWidgets('renders CollaborativeListScreen with real Supabase data for $listId', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            socialRepositoryProvider.overrideWithValue(
              SupabaseSocialRepository(client: client),
            ),
            currentUserProvider.overrideWith((ref) => Stream.value(testUser)),
          ],
          child: MaterialApp(
            home: CollaborativeListScreen(listId: listId),
          ),
        ),
      );

      // Pump through loading states
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(CollaborativeListScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
