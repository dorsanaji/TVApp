import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as sb show User;

import '../../core/error/error_mapper.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/repositories/auth_repository.dart';

/// Accounts held by Supabase Auth, so one account works on every device.
///
/// **On the address.** Registration is username-and-password; the brief has no
/// email anywhere. Supabase Auth needs an identifier of some shape, so each
/// account is registered as `<username>@hamsekans.local`. That address is
/// synthetic: it is never shown, never typed, and never receives mail, which
/// is why the project must have email confirmation turned off — a
/// confirmation link sent to a domain that does not exist would lock every
/// account out on creation.
///
/// **Why not a table of our own.** Storing password hashes in a `public`
/// table would put them behind the anon key, and that key ships inside the
/// APK. Letting Supabase hold the credentials also gives `auth.uid()`, which
/// is what the row-level policies in `0001_cloud_accounts.sql` compare
/// against — without it no policy could tell two accounts apart.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({
    required SupabaseClient client,
    required FlutterSecureStorage storage,
    LocalAuthentication? localAuth,
  })  : _client = client,
        _storage = storage,
        _localAuth = localAuth ?? LocalAuthentication() {
    _authSubscription = _client.auth.onAuthStateChange.listen((state) {
      unawaited(_publish(state.session?.user));
    });
    unawaited(_publish(_client.auth.currentUser));
  }

  final SupabaseClient _client;
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  static const _biometricKey = 'auth_biometric_enabled';

  /// The domain the synthetic addresses live in. Reserved by RFC 6761 for
  /// exactly this — it can never resolve, so nothing can be sent to it.
  static const _addressDomain = 'hamsekans.local';

  final _userController = StreamController<AppUser?>.broadcast();
  StreamSubscription<AuthState>? _authSubscription;
  AppUser? _current;
  bool _biometricEnabled = false;

  @override
  Stream<AppUser?> get currentUser async* {
    yield _current;
    yield* _userController.stream;
  }

  @override
  AppUser? get currentUserOrNull => _current;

  @override
  bool get isBiometricEnabled => _biometricEnabled;

  /// Reads back the persisted session and the biometric preference.
  ///
  /// `supabase_flutter` restores the session from its own storage, so this
  /// only has to wait for that and publish the result before the first frame.
  Future<void> restoreSession() async {
    _biometricEnabled = await _storage.read(key: _biometricKey) == 'true';
    await _publish(_client.auth.currentUser);
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _userController.close();
  }

  String _addressFor(String username) =>
      '${username.trim().toLowerCase()}@$_addressDomain';

  /// The address to sign [username] in with.
  ///
  /// Reads the address recorded at signup, so a user who has since renamed
  /// themselves still signs in under the name they type now. Accounts created
  /// before that column existed have no record, and fall back to the old
  /// derivation — right for them, since they predate renaming working at all.
  Future<String> _loginAddressFor(String username) async {
    final trimmed = username.trim();
    try {
      final row = await _client
          .from('public_profiles')
          .select('login_email')
          .ilike('username', trimmed)
          .maybeSingle();
      final stored = row?['login_email'] as String?;
      if (stored != null && stored.isNotEmpty) return stored;
    } catch (_) {
      // Offline, or the column is not there yet: fall through.
    }
    return _addressFor(trimmed);
  }

  /// Upserts a profile row, tolerating a database that predates
  /// `login_email` (migration 0002).
  ///
  /// Writing a column the schema does not have fails the whole request, which
  /// is what turned "sign up" into a bare fetch error. Signing up survives
  /// without it — the address can still be derived from a name that has never
  /// changed — so the column is dropped and the write retried.
  ///
  /// A rename is the one case that cannot degrade: with no address on record,
  /// the next sign-in would look for one derived from the *new* name and find
  /// nothing. That is refused outright rather than locking the account.
  Future<void> _upsertProfile(
    Map<String, dynamic> row, {
    bool renaming = false,
  }) async {
    try {
      await _client.from('public_profiles').upsert(row);
    } on PostgrestException catch (e) {
      final missingColumn = e.code == 'PGRST204' || e.code == '42703';
      if (!missingColumn || !row.containsKey('login_email')) rethrow;

      if (renaming) {
        throw const ValidationFailure(
          'تغییر شناسه در حال حاضر ممکن نیست. لطفاً به‌روزرسانی پایگاه داده '
          'را اجرا کنید.',
          field: 'username',
        );
      }

      debugPrint(
        '[SupabaseAuthRepository] public_profiles has no login_email column; '
        'run supabase/migrations/0002_login_email.sql. Renaming stays '
        'disabled until then.',
      );
      await _client.from('public_profiles').upsert(
        Map<String, dynamic>.from(row)..remove('login_email'),
      );
    }
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } catch (e, stack) {
      debugPrint('[SupabaseAuthRepository] $e\n$stack');
      return Err(ErrorMapper.fromUnknown(e, stack));
    }
  }

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
      _validate(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        username: normalisedUsername,
        password: password,
      );

      // Checked up front so the message names the field. Supabase would
      // otherwise reject the duplicate address with a generic error that says
      // nothing about which box to fix.
      final taken = await _client
          .from('public_profiles')
          .select('user_id')
          .ilike('username', normalisedUsername)
          .maybeSingle();
      if (taken != null) {
        throw const ValidationFailure(
          'این شناسه قبلاً ثبت شده است',
          field: 'username',
        );
      }

      final AuthResponse response;
      try {
        response = await _client.auth.signUp(
          email: _addressFor(normalisedUsername),
          password: password,
          data: {
            'username': normalisedUsername,
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
          },
        );
      } on AuthException catch (e) {
        if (e.message.toLowerCase().contains('already')) {
          throw const ValidationFailure(
            'این شناسه قبلاً ثبت شده است',
            field: 'username',
          );
        }
        rethrow;
      }

      final created = response.user;
      if (created == null) {
        // Signing up without a session means the project still has email
        // confirmation switched on, and nothing can confirm a .local address.
        throw const ServiceUnavailableFailure();
      }

      await _upsertProfile({
        'user_id': created.id,
        'username': normalisedUsername,
        // The address is fixed here for the life of the account. Renaming
        // changes the username only, so sign-in has to look this up rather
        // than derive it from whatever the user is called today.
        'login_email': _addressFor(normalisedUsername),
        'bio': bio?.trim() ?? '$firstName $lastName'.trim(),
        'avatar_url': avatarPath,
        'total_watched': 0,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      final user = await _publish(created);
      if (user == null) throw const UnauthorizedFailure();
      return user;
    });
  }

  void _validate({
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
    // The address is built from the username, so it has to survive being put
    // in front of an @.
    if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(username)) {
      throw const ValidationFailure(
        'شناسه فقط می‌تواند شامل حروف انگلیسی، عدد، نقطه، خط تیره و زیرخط باشد',
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

  @override
  Future<Result<AppUser>> login({
    required String username,
    required String password,
  }) {
    return _guard(() async {
      // One message whether the account is unknown or the password is wrong,
      // so the form cannot be used to discover who is registered.
      const rejected = ValidationFailure('شناسه یا رمز عبور نادرست است');

      final AuthResponse response;
      try {
        response = await _client.auth.signInWithPassword(
          email: await _loginAddressFor(username),
          password: password,
        );
      } on AuthException {
        throw rejected;
      }

      final signedIn = response.user;
      if (signedIn == null) throw rejected;

      final user = await _publish(signedIn);
      if (user == null) throw rejected;
      return user;
    });
  }

  @override
  Future<Result<void>> logout() {
    return _guard(() async {
      await _client.auth.signOut();
      await _publish(null);
    });
  }

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
      final account = _client.auth.currentUser;
      if (account == null) throw const UnauthorizedFailure();

      final metadata = Map<String, dynamic>.from(account.userMetadata ?? {});
      final newUsername = username?.trim();
      // The edit form always sends the username, changed or not, so "was a
      // username supplied" is not the same question as "is this a rename".
      // Only the latter needs the login address on record.
      final isRename =
          newUsername != null && newUsername != metadata['username'];

      if (isRename) {
        _validate(
          firstName: (firstName ?? metadata['first_name'] as String? ?? 'x')
              .trim(),
          lastName:
              (lastName ?? metadata['last_name'] as String? ?? 'x').trim(),
          username: newUsername,
          // Not being changed here; the length rule must not reject the edit.
          password: '________',
        );

        final taken = await _client
            .from('public_profiles')
            .select('user_id')
            .ilike('username', newUsername)
            .maybeSingle();
        if (taken != null && taken['user_id'] != account.id) {
          throw const ValidationFailure(
            'این شناسه قبلاً ثبت شده است',
            field: 'username',
          );
        }
        metadata['username'] = newUsername;
      }

      if (firstName != null) metadata['first_name'] = firstName.trim();
      if (lastName != null) metadata['last_name'] = lastName.trim();

      // Deliberately no `email:` here. The login address is fixed at signup
      // and recorded in `public_profiles.login_email`; Supabase rejects an
      // email *change* to the unroutable `.local` domain even though it
      // accepts the same address at signup, so moving it is both unnecessary
      // and impossible.
      await _client.auth.updateUser(UserAttributes(data: metadata));

      await _upsertProfile(renaming: isRename, {
        'user_id': account.id,
        'username': metadata['username'],
        // Written on every save, which backfills accounts created before the
        // column existed. It must succeed for a rename to be safe: if the
        // address were not recorded, the next sign-in would derive it from
        // the *new* name and never find the account.
        'login_email': account.email,
        if (bio != null) 'bio': bio.trim(),
        if (clearAvatar) 'avatar_url': null,
        if (!clearAvatar && avatarPath != null) 'avatar_url': avatarPath,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      final user = await _publish(_client.auth.currentUser);
      if (user == null) throw const UnauthorizedFailure();
      return user;
    });
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _guard(() async {
      final account = _client.auth.currentUser;
      final address = account?.email;
      if (account == null || address == null) {
        throw const UnauthorizedFailure();
      }

      if (newPassword.length < 8) {
        throw const ValidationFailure(
          'رمز عبور باید حداقل ۸ نویسه باشد',
          field: 'password',
        );
      }

      // Supabase will change the password of whoever holds the session
      // without re-checking the old one, so prove it here first.
      try {
        await _client.auth.signInWithPassword(
          email: address,
          password: currentPassword,
        );
      } on AuthException {
        throw const ValidationFailure(
          'رمز عبور فعلی نادرست است',
          field: 'currentPassword',
        );
      }

      await _client.auth.updateUser(UserAttributes(password: newPassword));
    });
  }

  @override
  Future<Result<void>> setBiometricEnabled({required bool enabled}) {
    return _guard(() async {
      _biometricEnabled = enabled;
      await _storage.write(key: _biometricKey, value: '$enabled');
    });
  }

  @override
  Future<Result<bool>> authenticateBiometric() {
    return _guard(() async {
      if (!await _localAuth.canCheckBiometrics) return false;
      // local_auth 3.x flattened the old AuthenticationOptions into named
      // parameters. `persistAcrossBackgrounding` keeps the prompt alive if
      // the system briefly backgrounds the app while the sensor is active.
      return _localAuth.authenticate(
        localizedReason: 'برای ورود به حساب خود احراز هویت کنید',
        persistAcrossBackgrounding: true,
      );
    });
  }

  /// Turns a Supabase account into an [AppUser] and announces it.
  Future<AppUser?> _publish(sb.User? account) async {
    if (account == null) {
      _current = null;
      _userController.add(null);
      return null;
    }

    final metadata = account.userMetadata ?? const {};
    var username = metadata['username'] as String? ?? '';
    var bio = metadata['bio'] as String?;
    String? avatar;

    // The profile row is the source of truth for anything another user can
    // see, so prefer it over the copy in the account metadata.
    try {
      final profile = await _client
          .from('public_profiles')
          .select('username,bio,avatar_url')
          .eq('user_id', account.id)
          .maybeSingle();
      if (profile != null) {
        username = profile['username'] as String? ?? username;
        bio = profile['bio'] as String? ?? bio;
        avatar = profile['avatar_url'] as String?;
      }
    } catch (_) {
      // Offline: the metadata copy is enough to keep the session usable.
    }

    if (username.isEmpty) {
      username = account.email?.split('@').first ?? account.id;
    }

    final user = AppUser(
      id: account.id,
      firstName: metadata['first_name'] as String? ?? '',
      lastName: metadata['last_name'] as String? ?? '',
      username: username,
      bio: bio,
      avatarPath: avatar,
      createdAt: DateTime.tryParse(account.createdAt),
    );

    _current = user;
    _userController.add(user);
    return user;
  }
}
