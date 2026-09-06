import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/error/error_mapper.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/review_repository.dart';
import '../local/app_database.dart';

/// [ReviewRepository] backed by the local database — FR-13, FR-14, FR-15.
class LocalReviewRepository implements ReviewRepository {
  LocalReviewRepository({required AppDatabase db, required AuthRepository auth})
    : _db = db,
      _auth = auth {
    // See `LocalTrackingRepository`: an account change invalidates what the
    // rating and review screens show, so it travels on the same stream.
    _authSubscription = _auth.currentUser.listen((_) => _notify());
  }

  StreamSubscription<AppUser?>? _authSubscription;

  final AppDatabase _db;
  final AuthRepository _auth;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  Stream<void> get changes => _changes.stream;

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } catch (e, stack) {
      return Err(ErrorMapper.fromUnknown(e, stack));
    }
  }

  /// Reviews and ratings are personal actions, so §4.1 requires a signed-in
  /// user: "registration and login are mandatory for recording activity,
  /// rating, review, and personal lists".
  AppUser _requireUser() {
    final user = _auth.currentUserOrNull;
    if (user == null) throw const UnauthorizedFailure();
    return user;
  }

  // ── FR-13 · Rating ────────────────────────────────────────────────────

  @override
  Future<Result<int?>> myRating(int id, MediaType type) {
    return _guard(() async {
      final user = _auth.currentUserOrNull;
      if (user == null) return null;

      final row =
          await (_db.select(_db.ratings)..where(
                (t) =>
                    t.userId.equals(user.id) &
                    t.mediaId.equals(id) &
                    t.mediaType.equalsValue(type),
              ))
              .getSingleOrNull();
      return row?.stars;
    });
  }

  @override
  Future<Result<void>> rate(int id, MediaType type, int stars) {
    return _guard(() async {
      final user = _requireUser();

      // FR-13 — "rating is qualitative, from 1 to 5 stars". Enforced here so
      // a caller cannot store 0 or 7 and corrupt the distribution.
      if (stars < 1 || stars > 5) {
        throw const ValidationFailure('امتیاز باید بین ۱ تا ۵ ستاره باشد');
      }

      // Upsert on the composite key: re-rating edits the previous rating
      // rather than adding a second, which is what FR-13 requires and what
      // keeps NFR-22 true.
      await _db
          .into(_db.ratings)
          .insertOnConflictUpdate(
            RatingsCompanion.insert(
              userId: Value(user.id),
              mediaId: id,
              mediaType: type,
              stars: stars,
              updatedAt: Value(DateTime.now()),
            ),
          );
      _notify();
    });
  }

  @override
  Future<Result<void>> clearRating(int id, MediaType type) {
    return _guard(() async {
      final user = _requireUser();
      await (_db.delete(_db.ratings)..where(
            (t) =>
                t.userId.equals(user.id) &
                t.mediaId.equals(id) &
                t.mediaType.equalsValue(type),
          ))
          .go();
      _notify();
    });
  }

  @override
  Future<Result<RatingSummary>> ratingSummary(int id, MediaType type) {
    return _guard(() async {
      final rows =
          await (_db.select(_db.ratings)..where(
                (t) => t.mediaId.equals(id) & t.mediaType.equalsValue(type),
              ))
              .get();

      final counts = <int, int>{};
      for (final row in rows) {
        counts[row.stars] = (counts[row.stars] ?? 0) + 1;
      }
      return RatingSummary(counts: counts);
    });
  }

  // ── FR-14 · Reviews ───────────────────────────────────────────────────

  @override
  Future<Result<List<Review>>> reviews(int id, MediaType type) {
    return _guard(() async {
      final query =
          _db.select(_db.reviews).join([
              leftOuterJoin(
                _db.users,
                _db.users.id.equalsExp(_db.reviews.userId),
              ),
            ])
            ..where(
              _db.reviews.mediaId.equals(id) &
                  _db.reviews.mediaType.equalsValue(type),
            )
            // Newest first, as the acceptance criteria specify.
            //
            // The id is a secondary key, not decoration: Drift stores DateTime at
            // second resolution, so two reviews written in the same second would
            // otherwise come back in arbitrary order. Ids are microsecond-based
            // and monotonic, which makes the ordering deterministic.
            ..orderBy([
              OrderingTerm.desc(_db.reviews.createdAt),
              OrderingTerm.desc(_db.reviews.id),
            ]);

      final rows = await query.get();
      final ratings =
          await (_db.select(_db.ratings)..where(
                (t) => t.mediaId.equals(id) & t.mediaType.equalsValue(type),
              ))
              .get();
      final starsByUser = {for (final r in ratings) r.userId: r.stars};

      return rows.map((row) {
        final review = row.readTable(_db.reviews);
        final author = row.readTableOrNull(_db.users);

        return Review(
          id: review.id,
          mediaId: review.mediaId,
          mediaType: review.mediaType,
          authorId: review.userId,
          // 2 · نام کاربر  ·  3 · تصویر کاربر
          authorName: author == null
              ? 'کاربر حذف‌شده'
              : '${author.firstName} ${author.lastName}'.trim(),
          authorAvatar: author?.avatarPath,
          body: review.body, // 1 · متن نظر
          createdAt: review.createdAt, // 4 · تاریخ ثبت
          updatedAt: review.updatedAt,
          hasSpoiler: review.hasSpoiler, // 5 · وضعیت اسپویل
          stars: starsByUser[review.userId],
        );
      }).toList();
    });
  }

  @override
  Future<Result<Review>> submitReview({
    required int id,
    required MediaType type,
    required String body,
    required bool hasSpoiler,
  }) {
    return _guard(() async {
      final user = _requireUser();
      final trimmed = body.trim();

      // NFR-10 / FR-14 acceptance — empty review text is rejected before it
      // reaches storage.
      if (trimmed.isEmpty) {
        throw const ValidationFailure(
          'متن نظر نمی‌تواند خالی باشد',
          field: 'body',
        );
      }

      final reviewId = 'review_${DateTime.now().microsecondsSinceEpoch}';
      final now = DateTime.now();

      await _db
          .into(_db.reviews)
          .insert(
            ReviewsCompanion.insert(
              id: reviewId,
              userId: Value(user.id),
              mediaId: id,
              mediaType: type,
              body: trimmed,
              hasSpoiler: Value(hasSpoiler),
              createdAt: Value(now),
            ),
          );
      _notify();

      return Review(
        id: reviewId,
        mediaId: id,
        mediaType: type,
        authorId: user.id,
        authorName: user.displayName,
        authorAvatar: user.avatarPath,
        body: trimmed,
        createdAt: now,
        hasSpoiler: hasSpoiler,
      );
    });
  }

  @override
  Future<Result<Review>> editReview({
    required String reviewId,
    required String body,
    required bool hasSpoiler,
  }) {
    return _guard(() async {
      final user = _requireUser();
      final trimmed = body.trim();

      if (trimmed.isEmpty) {
        throw const ValidationFailure(
          'متن نظر نمی‌تواند خالی باشد',
          field: 'body',
        );
      }

      final existing = await (_db.select(
        _db.reviews,
      )..where((t) => t.id.equals(reviewId))).getSingleOrNull();
      if (existing == null) throw const NotFoundFailure();

      // NFR-16 — "users must only have access to their own permitted
      // information". Editing someone else's review is refused.
      if (existing.userId != user.id) throw const UnauthorizedFailure();

      final now = DateTime.now();
      await (_db.update(
        _db.reviews,
      )..where((t) => t.id.equals(reviewId))).write(
        ReviewsCompanion(
          body: Value(trimmed),
          hasSpoiler: Value(hasSpoiler),
          updatedAt: Value(now),
        ),
      );
      _notify();

      return Review(
        id: reviewId,
        mediaId: existing.mediaId,
        mediaType: existing.mediaType,
        authorId: user.id,
        authorName: user.displayName,
        authorAvatar: user.avatarPath,
        body: trimmed,
        createdAt: existing.createdAt,
        updatedAt: now,
        hasSpoiler: hasSpoiler,
      );
    });
  }

  @override
  Future<Result<void>> deleteReview(String reviewId) {
    return _guard(() async {
      final user = _requireUser();

      final existing = await (_db.select(
        _db.reviews,
      )..where((t) => t.id.equals(reviewId))).getSingleOrNull();
      if (existing == null) return;
      if (existing.userId != user.id) throw const UnauthorizedFailure();

      await (_db.delete(_db.reviews)..where((t) => t.id.equals(reviewId))).go();
      _notify();
    });
  }

  /// FR-19 statistic 6 — the mean of the ratings this user has submitted.
  Future<double?> averageRatingOfCurrentUser() async {
    final user = _auth.currentUserOrNull;
    if (user == null) return null;

    final rows = await (_db.select(
      _db.ratings,
    )..where((t) => t.userId.equals(user.id))).get();
    if (rows.isEmpty) return null;

    final total = rows.fold(0, (sum, r) => sum + r.stars);
    return total / rows.length;
  }

  void dispose() {
    _authSubscription?.cancel();
    _changes.close();
  }
}
