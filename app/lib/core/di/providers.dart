import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/app_database.dart';
import '../../data/remote/tmdb/tmdb_api.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../data/repositories/supabase_list_repository.dart';
import '../../data/repositories/supabase_review_repository.dart';
import '../../data/repositories/supabase_social_repository.dart';
import '../../data/repositories/supabase_tracking_repository.dart';
import '../../data/repositories/tmdb_catalog_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/list_repository.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/repositories/social_repository.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../config/env.dart';
import '../network/dio_client.dart';
import '../network/interceptors/dedup_interceptor.dart';
import '../network/interceptors/response_cache_interceptor.dart';

/// Composition root.
///
/// Every repository is exposed here as its abstract type; nothing in
/// `features/` ever names a concrete implementation. That is what satisfies
/// NFR-32 (interface logic, data retrieval, and storage separated from one
/// another) and NFR-33 (the project structure must allow changing the API or
/// the information service) — swapping TMDB for another provider means adding
/// one class and changing one line here.
///
/// Riverpod is used without code generation: `riverpod_generator` pins
/// `freezed_annotation ^2`, which conflicts with the `^3` that `drift`
/// requires. Hand-written providers avoid the conflict and cost a few lines.
//
// ── Infrastructure ────────────────────────────────────────────────────────

/// Shared so the suppressed-request counter reflects the whole app
/// (NM-08, NFR-05).
final dedupInterceptorProvider = Provider<DedupInterceptor>((ref) {
  return DedupInterceptor();
});

/// The other half of NM-08: a repeat of a request already answered minutes ago
/// is served from memory rather than sent again. Shared for the same reason —
/// the saving only counts if every screen draws on the same store.
final responseCacheProvider = Provider<ResponseCacheInterceptor>((ref) {
  return ResponseCacheInterceptor();
});

/// NFR-17 — the session token is kept in encrypted platform storage, backed by
/// the Android keystore, rather than in plain shared preferences.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(aOptions: AndroidOptions.defaultOptions);
});

/// HTTP client for the information service (NM-02: information is received
/// directly from the service).
final tmdbDioProvider = Provider<Dio>((ref) {
  return DioClient.tmdb(
    dedup: ref.watch(dedupInterceptorProvider),
    responseCache: ref.watch(responseCacheProvider),
  );
});

// ── Repositories ──────────────────────────────────────────────────────────
//
// Bound to their implementations in the phase named below. Until then these
// throw a message that names the phase rather than failing obscurely.
//
// Tests bind fakes by overriding these providers, which is how the layering
// is verified with no network and no database at all.

final tmdbApiProvider = Provider<TmdbApi>((ref) {
  return TmdbApi(ref.watch(tmdbDioProvider));
});

/// The seam in practice: the presentation layer asks for the abstract type and
/// receives whichever implementation is bound here. Tests override this with a
/// fake — see `test/core/architecture_seam_test.dart`.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return TmdbCatalogRepository(ref.watch(tmdbApiProvider));
});

/// Bumped whenever a social activity is written or removed.
///
/// The activity providers read it, so favouriting a title or marking one
/// watched refreshes the profile and the diary immediately. It lives here,
/// in the DI root, because both the tracking and social layers bump it and
/// neither should have to import the other.
final socialActivityRevisionProvider = StateProvider<int>((ref) => 0);

/// NM-07 — the local store for the user's personal information.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  final repository = SupabaseTrackingRepository(
    ref.watch(requiredSupabaseClientProvider),
    ref.watch(authRepositoryProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

/// Accounts live in Supabase Auth, so the app cannot run without a client.
/// Failing loudly here beats a screen of empty states with no explanation.
final requiredSupabaseClientProvider = Provider<SupabaseClient>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError(
      'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY in '
      'dart_defines.json — accounts and user data both live there now.',
    );
  }
  return client;
});

final localAuthRepositoryProvider = Provider<SupabaseAuthRepository>((ref) {
  final repository = SupabaseAuthRepository(
    client: ref.watch(requiredSupabaseClientProvider),
    storage: ref.watch(secureStorageProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ref.watch(localAuthRepositoryProvider);
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return SupabaseReviewRepository(
    ref.watch(requiredSupabaseClientProvider),
    ref.watch(authRepositoryProvider),
  );
});

final listRepositoryProvider = Provider<ListRepository>((ref) {
  return SupabaseListRepository(
    ref.watch(requiredSupabaseClientProvider),
    ref.watch(authRepositoryProvider),
  );
});

// ── Social & Realtime Collaboration (Task 1) ───────────────────────────

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (Env.hasSupabase) {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
  return null;
});

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SupabaseSocialRepository(
    client: ref.watch(supabaseClientProvider),
  );
});
