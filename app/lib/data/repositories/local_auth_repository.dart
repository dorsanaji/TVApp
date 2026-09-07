import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/error_mapper.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../core/security/password_hasher.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/auth_repository.dart';
import '../local/app_database.dart';

/// [AuthRepository] backed by the local database — FR-01 to FR-04.
///
/// With no server in scope (§3.3), accounts live on the device. The password
/// is never stored: only a PBKDF2 hash and its salt (NFR-13a), and the session
/// token is held in the Android keystore rather than shared preferences
/// (NFR-17).
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    required AppDatabase db,
    required FlutterSecureStorage storage,
    LocalAuthentication? localAuth,
    SupabaseClient? supabaseClient,
  }) :        _localAuth = localAuth ?? LocalAuthentication(),
       _db = db,
       _storage = storage,
       _supabase = supabaseClient;

  final AppDatabase _db;
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;
  final SupabaseClient? _supabase;

  static const _tokenKey = 'auth_token';
  static const _expiryKey = 'auth_expires_at';
  static const _biometricKey = 'auth_biometric_enabled';

  /// FR-02 — "if the user logs in once, there is no need to log in again for
  /// one month".
  static const sessionDuration = Duration(days: 30);

  final StreamController<AppUser?> _userController =
      StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;
  bool _biometricEnabled = false;

  @override
  Stream<AppUser?> get currentUser => _userController.stream;

  @override
  AppUser? get currentUserOrNull => _currentUser;

  @override
  bool get isBiometricEnabled => _biometricEnabled;

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } catch (e, stack) {
      return Err(ErrorMapper.fromUnknown(e, stack));
    }
  }

  /// Restores a session on launch, if one is still valid.
  ///
  /// An expired session is cleared rather than merely rejected, so a stale
  /// token cannot linger in storage indefinitely.
  /// Never throws. Reading a stale session must not be able to stop the app
  /// from starting.
  ///
  /// The Android keystore can genuinely fail here — a cipher-algorithm change
  /// between plugin versions, a key invalidated by a lock-screen change, or a
  /// vendor keystore quirk. A first device run showed the plugin logging
  /// "Stored key cannot be decrypted with current algorithm" and migrating
  /// itself; had it thrown instead, an unguarded call would have propagated out
  /// of `main()` before `runApp()` and left a black screen with no message.
  ///
  /// Failing closed is the right behaviour: the user starts as a guest and
  /// signs in again. Nothing of theirs is lost, because everything they track
  /// lives in the database, not in the token (NFR-20).
  Future<void> restoreSession() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      final expiryRaw = await _storage.read(key: _expiryKey);
      _biometricEnabled = (await _storage.read(key: _biometricKey)) == 'true';

      if (token == null || expiryRaw == null) return;

      final expiry = DateTime.tryParse(expiryRaw);
      if (expiry == null || expiry.isBefore(DateTime.now())) {
        await _clearSession();
        return;
      }

      final row = await (_db.select(
        _db.users,
      )..where((t) => t.id.equals(token))).getSingleOrNull();
      if (row == null) {
        await _clearSession();
        return;
      }

      _currentUser = await _toUser(row);
      _userController.add(_currentUser);
    } catch (e, stack) {
      debugPrint('restoreSession failed, continuing as guest: $e\n$stack');
      _currentUser = null;
      // Best-effort cleanup: if the stored session is unreadable it is also
      // unusable, so drop it rather than retrying the same failure each launch.
      try {
        await _clearSession();
      } catch (_) {
        // Storage is unavailable entirely; the guest state above still holds.
      }
    } finally {
      if (_supabase != null) {
        unawaited(_syncAllProfilesToCloud());
      }
    }
  }

  // ── FR-01 · Registration ──────────────────────────────────────────────

  @override
  Future<Result<AppUser>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String password,
    String? bio,
    String? avatarPath,
  }) {
    return _guard(() async {
      final normalisedUsername = username.trim();

      _validateRegistration(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        username: normalisedUsername,
        password: password,
      );

      // FR-01 — "the system must prevent registration of a duplicate
      // username". Checked explicitly so the error names the field, rather
      // than surfacing a raw unique-constraint violation.
      final existing =
          await (_db.select(_db.users)
                ..where((t) => t.username.equals(normalisedUsername)))
              .get();

      if (existing.isNotEmpty) {
        throw const ValidationFailure(
          'این شناسه قبلاً ثبت شده است',
          field: 'username',
        );
      }

      final salt = PasswordHasher.generateSalt();
      final id = 'user_${DateTime.now().microsecondsSinceEpoch}';

      await _db
          .into(_db.users)
          .insert(
            UsersCompanion.insert(
              id: id,
              firstName: firstName.trim(),
              lastName: lastName.trim(),
              username: normalisedUsername,
              passwordHash: PasswordHasher.hash(password, salt),
              passwordSalt: salt,
              bio: Value(bio?.trim()),
              avatarPath: Value(avatarPath),
            ),
          );

      final row = await (_db.select(
        _db.users,
      )..where((t) => t.id.equals(id))).getSingle();
      final user = await _toUser(row);

      await _startSession(user);

      final client = _supabase;
      if (client != null) {
        try {
          final cloudAvatar = await _toCloudAvatar(user.avatarPath);
          await client.from('public_profiles').upsert({
            'user_id': user.id,
            'username': user.username,
            'bio': user.bio ?? '${user.firstName} ${user.lastName}'.trim(),
            'avatar_url': cloudAvatar,
            'total_watched': 0,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (e) {
          debugPrint('[LocalAuthRepository] Cloud profile sync error: $e');
        }
      }

      return user;
    });
  }

  void _validateRegistration({
    required String firstName,
    required String lastName,
    required String username,
    required String password,
  }) {
    if (firstName.isEmpty || lastName.isEmpty) {
      throw const ValidationFailure(
        'نام و نام خانوادگی الزامی است',
        field: 'name',
      );
    }
    if (username.length < 3) {
      throw const ValidationFailure(
        'شناسه باید حداقل ۳ نویسه باشد',
        field: 'username',
      );
    }
    if (password.length < 8) {
      throw const ValidationFailure(
        'رمز عبور باید حداقل ۸ نویسه باشد',
        field: 'password',
      );
    }
  }

  // ── FR-02 · Login and logout ──────────────────────────────────────────

  @override
  Future<Result<AppUser>> login({
    required String username,
    required String password,
  }) {
    return _guard(() async {
      final row =
          await (_db.select(_db.users)
                ..where((t) => t.username.equals(username.trim())))
              .getSingleOrNull();

      // The same message whether the username is unknown or the password is
      // wrong, so the form cannot be used to enumerate registered accounts.
      const rejected = ValidationFailure('شناسه یا رمز عبور نادرست است');

      if (row == null) throw rejected;
      if (!PasswordHasher.verify(
        password,
        row.passwordSalt,
        row.passwordHash,
      )) {
        throw rejected;
      }

      final user = await _toUser(row);
      await _startSession(user);
      if (_supabase != null) {
        unawaited(_syncAllProfilesToCloud());
      }
      return user;
    });
  }

  @override
  Future<Result<void>> logout() => _guard(_clearSession);

  Future<void> _startSession(AppUser user) async {
    _currentUser = user;
    await _storage.write(key: _tokenKey, value: user.id);
    await _storage.write(
      key: _expiryKey,
      value: DateTime.now().add(sessionDuration).toIso8601String(),
    );
    _userController.add(user);
  }

  Future<void> _clearSession() async {
    _currentUser = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _expiryKey);
    _userController.add(null);
  }

  // ── FR-04 · Profile ───────────────────────────────────────────────────

  @override
  Future<Result<AppUser>> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    String? avatarPath,
    bool clearAvatar = false,
  }) {
    return _guard(() async {
      final current = _currentUser;
      if (current == null) throw const UnauthorizedFailure();

      final newUsername = username?.trim();
      if (newUsername != null && newUsername != current.username) {
        if (newUsername.length < 3) {
          throw const ValidationFailure(
            'نام کاربری باید حداقل ۳ نویسه باشد',
            field: 'username',
          );
        }
        // Uniqueness is re-checked on change, exactly as at registration.
        final clash =
            await (_db.select(_db.users)..where(
                  (t) =>
                      t.username.equals(newUsername) &
                      t.id.equals(current.id).not(),
                ))
                .getSingleOrNull();
        if (clash != null) {
          throw const ValidationFailure(
            'این نام کاربری قبلاً ثبت شده است',
            field: 'username',
          );
        }
      }

      await (_db.update(
        _db.users,
      )..where((t) => t.id.equals(current.id))).write(
        UsersCompanion(
          firstName: firstName == null
              ? const Value.absent()
              : Value(firstName.trim()),
          lastName: lastName == null
              ? const Value.absent()
              : Value(lastName.trim()),
          username: newUsername == null
              ? const Value.absent()
              : Value(newUsername),
          bio: bio == null ? const Value.absent() : Value(bio.trim()),
          avatarPath: clearAvatar
              ? const Value(null)
              : (avatarPath == null ? const Value.absent() : Value(avatarPath)),
        ),
      );

      final row = await (_db.select(
        _db.users,
      )..where((t) => t.id.equals(current.id))).getSingle();
      _currentUser = await _toUser(row);
      _userController.add(_currentUser);

      final client = _supabase;
      if (client != null && _currentUser != null) {
        try {
          final cloudAvatar = await _toCloudAvatar(_currentUser!.avatarPath);
          await client.from('public_profiles').upsert({
            'user_id': _currentUser!.id,
            'username': _currentUser!.username,
            'bio': _currentUser!.bio ??
                '${_currentUser!.firstName} ${_currentUser!.lastName}'.trim(),
            'avatar_url': cloudAvatar,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (e) {
          debugPrint('[LocalAuthRepository] Update profile cloud sync error: $e');
        }
      }

      return _currentUser!;
    });
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _guard(() async {
      final current = _currentUser;
      if (current == null) throw const UnauthorizedFailure();

      final row = await (_db.select(
        _db.users,
      )..where((t) => t.id.equals(current.id))).getSingle();

      if (!PasswordHasher.verify(
        currentPassword,
        row.passwordSalt,
        row.passwordHash,
      )) {
        throw const ValidationFailure(
          'رمز عبور فعلی نادرست است',
          field: 'currentPassword',
        );
      }
      if (newPassword.length < 8) {
        throw const ValidationFailure(
          'رمز عبور باید حداقل ۸ نویسه باشد',
          field: 'password',
        );
      }

      final salt = PasswordHasher.generateSalt();
      await (_db.update(
        _db.users,
      )..where((t) => t.id.equals(current.id))).write(
        UsersCompanion(
          passwordHash: Value(PasswordHasher.hash(newPassword, salt)),
          passwordSalt: Value(salt),
        ),
      );
    });
  }

  // ── FR-02 · Biometric re-authentication ───────────────────────────────

  @override
  Future<Result<void>> setBiometricEnabled({required bool enabled}) {
    return _guard(() async {
      if (enabled) {
        final supported = await _localAuth.isDeviceSupported();
        final canCheck = await _localAuth.canCheckBiometrics;
        if (!supported || !canCheck) {
          throw const ValidationFailure(
            'این دستگاه از ورود بیومتریک پشتیبانی نمی‌کند',
          );
        }
      }
      _biometricEnabled = enabled;
      await _storage.write(key: _biometricKey, value: '$enabled');
    });
  }

  @override
  Future<Result<bool>> authenticateBiometric() {
    return _guard(() async {
      // local_auth 3.x flattened the old AuthenticationOptions into named
      // parameters. `persistAcrossBackgrounding` keeps the prompt alive if the
      // system briefly backgrounds the app while the sensor is active.
      return _localAuth.authenticate(
        localizedReason: 'برای ورود به حساب خود احراز هویت کنید',
        persistAcrossBackgrounding: true,
      );
    });
  }

  // ── Mapping ───────────────────────────────────────────────────────────

  /// Builds the domain user, including the three counters FR-01 says every
  /// profile must automatically carry.
  Future<AppUser> _toUser(UserRow row) async {
    final moviesWatched = await _countStatuses(row.id, 'movie', 'watched');
    final seriesFollowed = await _countFollowedSeries(row.id);
    final favourites = await _countFavourites(row.id);

    return AppUser(
      id: row.id,
      firstName: row.firstName,
      lastName: row.lastName,
      username: row.username,
      bio: row.bio,
      avatarPath: row.avatarPath,
      role: row.role == 'admin' ? UserRole.admin : UserRole.user,
      moviesWatchedCount: moviesWatched,
      seriesFollowedCount: seriesFollowed,
      favouritesCount: favourites,
      createdAt: row.createdAt,
    );
  }

  // The three counters below are the derived values FR-01 says every profile
  // must carry. Each takes a `userId` and **must** filter on it: they were
  // originally written without the `WHERE user_id = ?` clause, so every
  // account's profile reported totals aggregated across all accounts on the
  // device. Fixed, and covered by the isolation tests.

  Future<int> _countStatuses(String userId, String type, String status) async {
    final rows = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM watch_statuses '
          'WHERE user_id = ?1 AND media_type = ?2 AND status = ?3',
          variables: [
            Variable<String>(userId),
            Variable<String>(type),
            Variable<String>(status),
          ],
          readsFrom: {_db.watchStatuses},
        )
        .getSingle();
    return rows.read<int>('c');
  }

  /// "Followed" covers anything the user is actively tracking, not only
  /// finished series — which is what the brief's "سریال‌های دنبال شده" means.
  Future<int> _countFollowedSeries(String userId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM watch_statuses '
          "WHERE user_id = ?1 AND media_type = 'series' "
          "AND status IN ('watching', 'planToWatch', 'watched')",
          variables: [Variable<String>(userId)],
          readsFrom: {_db.watchStatuses},
        )
        .getSingle();
    return row.read<int>('c');
  }

  Future<int> _countFavourites(String userId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM favourites WHERE user_id = ?1',
          variables: [Variable<String>(userId)],
          readsFrom: {_db.favourites},
        )
        .getSingle();
    return row.read<int>('c');
  }

  Future<String?> _toCloudAvatar(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http') || path.startsWith('data:')) return path;
    final file = File(path);
    if (file.existsSync()) {
      try {
        final bytes = await file.readAsBytes();
        if (bytes.length <= 500 * 1024) {
          return 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
      } catch (e) {
        debugPrint('[LocalAuthRepository] Avatar base64 error: $e');
      }
    }
    return null;
  }

  Future<void> _syncAllProfilesToCloud() async {
    final client = _supabase;
    if (client == null) return;
    try {
      final allUsers = await _db.select(_db.users).get();
      for (final u in allUsers) {
        final cloudAvatar = await _toCloudAvatar(u.avatarPath);

        // Count watched titles
        final watchedRows = await (_db.select(_db.watchStatuses)..where(
          (t) =>
              t.userId.equals(u.id) &
              t.status.equalsValue(WatchStatus.watched),
        )).get();

        await client.from('public_profiles').upsert({
          'user_id': u.id,
          'username': u.username,
          'bio': u.bio ?? '${u.firstName} ${u.lastName}'.trim(),
          'avatar_url': cloudAvatar,
          'total_watched': watchedRows.length,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });

        // Sync watched titles to social_activities so other users can see them
        for (final w in watchedRows) {
          final cached = await (_db.select(_db.cachedMedia)..where(
            (t) =>
                t.mediaId.equals(w.mediaId) &
                t.mediaType.equalsValue(w.mediaType),
          )).getSingleOrNull();

          if (cached != null) {
            await client.from('social_activities').upsert({
              'activity_id': 'watch_${u.id}_${w.mediaId}',
              'user_id': u.id,
              'action_type': 'watched',
              'movie_id': w.mediaId,
              'movie_title': cached.title,
              'movie_poster': cached.posterPath,
              'username': u.username,
              'user_avatar': cloudAvatar,
              'created_at': w.updatedAt.toUtc().toIso8601String(),
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[LocalAuthRepository] syncAllProfilesToCloud error: $e');
    }
  }

  void dispose() => _userController.close();
}
