import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/app_database.dart';
import '../../data/remote/tmdb/tmdb_api.dart';
import '../../data/repositories/local_auth_repository.dart';
import '../../data/repositories/local_list_repository.dart';
import '../../data/repositories/local_review_repository.dart';
import '../../data/repositories/local_tracking_repository.dart';
import '../../data/repositories/supabase_social_repository.dart';
import '../../data/repositories/tmdb_catalog_repository.dart';
import '../../data/services/email_sender.dart';
import '../../data/services/emailjs_sender.dart';
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

/// NM-07 — the local store for the user's personal information.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  final repository = LocalTrackingRepository(
    ref.watch(databaseProvider),
    ref.watch(authRepositoryProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

/// FR-03's delivery transport.
///
/// EmailJS when credentials are present, otherwise the development sender that
/// surfaces the code on screen. The fallback keeps the flow demonstrable on a
/// clone with no credentials.
final debugEmailSenderProvider = Provider<DebugEmailSender>(
  (ref) => DebugEmailSender(),
);

final emailSenderProvider = Provider<EmailSender>((ref) {
  return EmailSenderWithFallback(
    primary: EmailJsSender(),
    fallback: ref.watch(debugEmailSenderProvider),
  );
});

final localAuthRepositoryProvider = Provider<LocalAuthRepository>((ref) {
  final repository = LocalAuthRepository(
    db: ref.watch(databaseProvider),
    storage: ref.watch(secureStorageProvider),
    emailSender: ref.watch(emailSenderProvider),
    supabaseClient: ref.watch(supabaseClientProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ref.watch(localAuthRepositoryProvider);
});

final localReviewRepositoryProvider = Provider<LocalReviewRepository>((ref) {
  final repository = LocalReviewRepository(
    db: ref.watch(databaseProvider),
    auth: ref.watch(authRepositoryProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ref.watch(localReviewRepositoryProvider);
});

final listRepositoryProvider = Provider<ListRepository>((ref) {
  return LocalListRepository(
    ref.watch(databaseProvider),
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
  final client = ref.watch(supabaseClientProvider);
  final db = ref.watch(databaseProvider);
  return SupabaseSocialRepository(client: client, db: db);
});
