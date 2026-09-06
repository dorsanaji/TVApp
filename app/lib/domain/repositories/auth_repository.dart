import '../../core/error/result.dart';

/// Account lifecycle — FR-01 to FR-04.
abstract interface class AuthRepository {
  /// The signed-in user, or `null` for a guest (§4.1).
  Stream<AppUser?> get currentUser;

  AppUser? get currentUserOrNull;

  /// FR-01. Duplicate email or username must fail with a [ValidationFailure]
  /// naming the offending field, not a generic error.
  Future<Result<AppUser>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    String? bio,
    String? avatarPath,
  });

  /// FR-02. The session must remain valid for 30 days.
  Future<Result<AppUser>> login({
    required String email,
    required String password,
  });

  /// FR-02 — secure logout: clears the token from secure storage.
  Future<Result<void>> logout();

  /// FR-03 — dispatches a recovery code to the address.
  Future<Result<void>> requestPasswordReset(String email);

  /// FR-03 — completes the reset. The code is single-use and time-limited.
  Future<Result<void>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// FR-04.
  ///
  /// A `null` argument means "leave this field alone". Clearing the picture is
  /// therefore a separate flag — otherwise there would be no way to express
  /// "remove it", since `null` already means "no change".
  Future<Result<AppUser>> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    String? avatarPath,
    bool clearAvatar = false,
  });

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// FR-02 biometric clause: "unless the user requests that biometric login
  /// be enabled for them".
  Future<Result<void>> setBiometricEnabled({required bool enabled});

  bool get isBiometricEnabled;

  /// Prompts for fingerprint/face confirmation. Returns `true` on success.
  Future<Result<bool>> authenticateBiometric();
}

/// An account (FR-01 §5.1).
///
/// The three counters are the "derived values every profile must
/// automatically carry" that the brief lists after the registration fields.
class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.bio,
    this.avatarPath,
    this.role = UserRole.user,
    this.moviesWatchedCount = 0,
    this.seriesFollowedCount = 0,
    this.favouritesCount = 0,
    this.createdAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? bio;
  final String? avatarPath;

  /// §4.3 / AM-07 — two access levels.
  final UserRole role;

  /// Derived: تعداد فیلم‌های مشاهده شده
  final int moviesWatchedCount;

  /// Derived: تعداد سریال‌های دنبال شده
  final int seriesFollowedCount;

  /// Derived: فهرست آثار موردعلاقه
  final int favouritesCount;

  final DateTime? createdAt;

  String get displayName => '$firstName $lastName'.trim();

  bool get isAdmin => role == UserRole.admin;
}

/// AM-07 — "the backend must have at least two access levels".
enum UserRole { user, admin }
