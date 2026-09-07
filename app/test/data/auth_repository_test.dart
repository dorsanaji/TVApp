import 'package:cinetrack/core/error/failure.dart';
import 'package:cinetrack/core/security/password_hasher.dart';
import 'package:cinetrack/data/local/app_database.dart';
import 'package:cinetrack/data/repositories/local_auth_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// FR-01 to FR-04, plus the NFR-13a guarantee that a password is never stored
/// in plain text.
void main() {
  late AppDatabase db;
  late LocalAuthRepository repository;

  setUp(() {
    // The plugin cannot run in a unit test, so an in-memory implementation
    // stands in. What is being tested here is the repository's logic, not the
    // platform keystore.
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    repository = LocalAuthRepository(
      db: db,
      storage: const FlutterSecureStorage(),
    );
  });

  tearDown(() async {
    repository.dispose();
    await db.close();
  });

  Future<void> registerAlice() async {
    final result = await repository.register(
      firstName: 'آریا',
      lastName: 'تمکین',
      username: 'arya',
      password: 'correct-horse',
    );
    expect(result.isOk, isTrue, reason: '${result.failureOrNull}');
  }

  group('NFR-13a · passwords are never stored in plain text', () {
    test(
      'the stored row contains neither the password nor a bare hash of it',
      () async {
        await registerAlice();

        final row = await db.select(db.users).getSingle();
        expect(row.passwordHash, isNot(contains('correct-horse')));
        expect(row.passwordSalt, isNotEmpty);
        // A bare SHA-256 would be reversible with a rainbow table; PBKDF2 with a
        // per-user salt is not, so the two must differ.
        expect(row.passwordHash, isNot(equals('correct-horse')));
      },
    );

    test('two users with the same password get different hashes', () async {
      final salt1 = PasswordHasher.generateSalt();
      final salt2 = PasswordHasher.generateSalt();

      expect(salt1, isNot(salt2));
      expect(
        PasswordHasher.hash('same-password', salt1),
        isNot(PasswordHasher.hash('same-password', salt2)),
      );
    });

    test('verification accepts the right password and rejects a wrong one', () {
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hash('correct-horse', salt);

      expect(PasswordHasher.verify('correct-horse', salt, hash), isTrue);
      expect(PasswordHasher.verify('wrong-horse', salt, hash), isFalse);
    });
  });

  group('FR-01 · registration', () {
    test('a new account is created and signed in', () async {
      await registerAlice();

      expect(repository.currentUserOrNull?.username, 'arya');
      expect(repository.currentUserOrNull?.displayName, 'آریا تمکین');
    });

    test('an account stores no address at all', () async {
      await registerAlice();

      // The users table has no email column: the username is the whole
      // identity, so nothing about an account can leak by address.
      final columns =
          db.users.$columns.map((c) => c.name).toSet();
      expect(columns, isNot(contains('email')));
    });

    test('a duplicate username is rejected, naming the field', () async {
      await registerAlice();

      final result = await repository.register(
        firstName: 'کسی',
        lastName: 'دیگر',
        username: 'arya',
        password: 'another-password',
      );

      expect((result.failureOrNull! as ValidationFailure).field, 'username');
    });

    test('a short username and a short password are rejected', () async {
      final shortUsername = await repository.register(
        firstName: 'ا',
        lastName: 'ب',
        username: 'ab',
        password: 'long-enough-password',
      );
      expect(
        (shortUsername.failureOrNull! as ValidationFailure).field,
        'username',
      );

      final shortPassword = await repository.register(
        firstName: 'ا',
        lastName: 'ب',
        username: 'user2',
        password: 'short',
      );
      expect(
        (shortPassword.failureOrNull! as ValidationFailure).field,
        'password',
      );
    });

    test('the three derived counters start at zero', () async {
      await registerAlice();
      final user = repository.currentUserOrNull!;

      expect(user.moviesWatchedCount, 0);
      expect(user.seriesFollowedCount, 0);
      expect(user.favouritesCount, 0);
    });
  });

  group('FR-02 · login and logout', () {
    test('correct credentials sign the user in', () async {
      await registerAlice();
      await repository.logout();

      final result = await repository.login(
        username: 'arya',
        password: 'correct-horse',
      );

      expect(result.isOk, isTrue);
      expect(repository.currentUserOrNull?.username, 'arya');
    });

    test('a wrong password is rejected', () async {
      await registerAlice();
      await repository.logout();

      final result = await repository.login(
        username: 'arya',
        password: 'wrong',
      );

      expect(result.isErr, isTrue);
      expect(repository.currentUserOrNull, isNull);
    });

    test('an unknown user and a wrong password look identical', () async {
      await registerAlice();
      await repository.logout();

      final unknown = await repository.login(
        username: 'nobody',
        password: 'whatever',
      );
      final wrong = await repository.login(
        username: 'arya',
        password: 'whatever',
      );

      // Otherwise the login form becomes a username-enumeration oracle.
      expect(unknown.failureOrNull!.message, wrong.failureOrNull!.message);
    });

    test('logout clears the session', () async {
      await registerAlice();
      await repository.logout();

      expect(repository.currentUserOrNull, isNull);
    });

    test('a session is restored after a restart within 30 days', () async {
      await registerAlice();

      // A fresh repository over the same database and storage: what happens on
      // the next cold start.
      final restarted = LocalAuthRepository(
        db: db,
        storage: const FlutterSecureStorage(),
      );
      addTearDown(restarted.dispose);
      await restarted.restoreSession();

      expect(restarted.currentUserOrNull?.username, 'arya');
    });
  });

  group('FR-04 · profile', () {
    test('profile fields can be edited', () async {
      await registerAlice();

      final result = await repository.updateProfile(
        firstName: 'آریا',
        lastName: 'تمکین‌شا',
        bio: 'دانشجوی مهندسی کامپیوتر',
      );

      expect(result.valueOrNull?.lastName, 'تمکین‌شا');
      expect(result.valueOrNull?.bio, 'دانشجوی مهندسی کامپیوتر');
    });

    test('changing to a taken username is rejected', () async {
      await registerAlice();
      await repository.logout();
      await repository.register(
        firstName: 'ب',
        lastName: 'ج',
        username: 'taken',
        password: 'another-password',
      );

      final result = await repository.updateProfile(username: 'arya');

      expect((result.failureOrNull! as ValidationFailure).field, 'username');
    });

    test('changing the password requires the current one', () async {
      await registerAlice();

      final wrong = await repository.changePassword(
        currentPassword: 'not-it',
        newPassword: 'brand-new-password',
      );
      expect(wrong.isErr, isTrue);

      final right = await repository.changePassword(
        currentPassword: 'correct-horse',
        newPassword: 'brand-new-password',
      );
      expect(right.isOk, isTrue);
    });

    test('editing a profile while signed out is refused', () async {
      final result = await repository.updateProfile(firstName: 'کسی');
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });
  });
}
