import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/di/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (Env.hasSupabase) {
    try {
      await Supabase.initialize(
        url: Env.cleanSupabaseUrl,
        // ignore: deprecated_member_use
        anonKey: Env.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('⚠️ Supabase initialization error: $e');
    }
  }

  assert(() {
    if (!Env.hasTmdbToken) {
      debugPrint(
        '⚠️  TMDB_READ_TOKEN is empty. Run with:\n'
        '    flutter run --dart-define-from-file=dart_defines.json\n'
        '    (copy dart_defines.example.json first)',
      );
    }
    return true;
  }());

  // The container is built here rather than by `ProviderScope` so the session
  // can be restored *before* the first frame. FR-02 promises a 30-day session;
  // restoring it after the tree is built would flash the signed-out state on
  // every launch.
  final container = ProviderContainer();
  await container.read(localAuthRepositoryProvider).restoreSession();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CineTrackApp(),
    ),
  );
}
