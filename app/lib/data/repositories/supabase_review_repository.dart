import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/error_mapper.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/review_repository.dart';

/// Ratings and reviews, held in Supabase.
///
/// Two different kinds of thing share this repository because FR-13 and FR-14
/// are two halves of one act: a review usually carries the stars the same
/// person gave. Ratings are private to their owner; reviews are published
/// under the title, which is why the policies in `0001_cloud_accounts.sql`
/// let anyone read a review but only its author write one.
class SupabaseReviewRepository implements ReviewRepository {
  SupabaseReviewRepository(this._client, this._auth);

  final SupabaseClient _client;
  final AuthRepository _auth;

  String get _userId {
    final id = _auth.currentUserOrNull?.id;
    if (id == null) throw const UnauthorizedFailure();
    return id;
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } catch (e, stack) {
      debugPrint('[SupabaseReviewRepository] $e\n$stack');
      return Err(ErrorMapper.fromUnknown(e, stack));
    }
  }

  // ── FR-13 · Ratings ─────────────────────────────────────────────────────

  @override
  Future<Result<int?>> myRating(int id, MediaType type) {
    return _guard(() async {
      final row = await _client
          .from('ratings')
          .select('stars')
          .match({
            'user_id': _userId,
            'media_id': id,
            'media_type': type.name,
          })
          .maybeSingle();
      return (row?['stars'] as num?)?.toInt();
    });
  }

  @override
  Future<Result<void>> rate(int id, MediaType type, int stars) {
    return _guard(() async {
      if (stars < 1 || stars > 5) {
        throw const ValidationFailure('امتیاز باید بین ۱ تا ۵ باشد');
      }
      // Upsert on the composite key, so rating the same title twice replaces
      // the score rather than adding a second one (NFR-22).
      await _client.from('ratings').upsert({
        'user_id': _userId,
        'media_id': id,
        'media_type': type.name,
        'stars': stars,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    });
  }

  @override
  Future<Result<void>> clearRating(int id, MediaType type) {
    return _guard(() async {
      await _client.from('ratings').delete().match({
        'user_id': _userId,
        'media_id': id,
        'media_type': type.name,
      });
    });
  }

  @override
  Future<Result<RatingSummary>> ratingSummary(int id, MediaType type) {
    return _guard(() async {
      // Everyone's scores, not just this user's — this is the app's own
      // average of FR-06, so it has to read across accounts.
      final rows = await _client
          .from('ratings')
          .select('stars')
          .match({'media_id': id, 'media_type': type.name});

      final counts = <int, int>{};
      for (final row in (rows as List).cast<Map<String, dynamic>>()) {
        final stars = (row['stars'] as num).toInt();
        counts[stars] = (counts[stars] ?? 0) + 1;
      }
      return RatingSummary(counts: counts);
    });
  }

  // ── FR-14 · Reviews ─────────────────────────────────────────────────────

  @override
  Future<Result<List<Review>>> reviews(int id, MediaType type) {
    return _guard(() async {
      final rows = await _client
          .from('reviews')
          .select()
          .match({'media_id': id, 'media_type': type.name})
          .order('created_at', ascending: false);

      final reviews = (rows as List).cast<Map<String, dynamic>>();
      if (reviews.isEmpty) return <Review>[];

      final authorIds =
          reviews.map((r) => r['user_id'] as String).toSet().toList();

      // One lookup for every author on the page rather than one per review.
      final profileRows = await _client
          .from('public_profiles')
          .select('user_id,username,avatar_url')
          .inFilter('user_id', authorIds);

      final profiles = {
        for (final row in (profileRows as List).cast<Map<String, dynamic>>())
          row['user_id'] as String: row,
      };

      final ratingRows = await _client
          .from('ratings')
          .select('user_id,stars')
          .match({'media_id': id, 'media_type': type.name})
          .inFilter('user_id', authorIds);

      final stars = {
        for (final row in (ratingRows as List).cast<Map<String, dynamic>>())
          row['user_id'] as String: (row['stars'] as num).toInt(),
      };

      return [
        for (final row in reviews)
          _toReview(row, profiles[row['user_id']], stars[row['user_id']]),
      ];
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
      final text = body.trim();
      if (text.isEmpty) {
        throw const ValidationFailure('متن نقد نمی‌تواند خالی باشد');
      }

      // Keyed to the author and the title, so re-posting edits the existing
      // review instead of stacking a second one under the same film.
      final reviewId = 'review_${_userId}_${type.name}_$id';

      await _client.from('reviews').upsert({
        'id': reviewId,
        'user_id': _userId,
        'media_id': id,
        'media_type': type.name,
        'body': text,
        'has_spoiler': hasSpoiler,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      return _readOne(reviewId);
    });
  }

  @override
  Future<Result<Review>> editReview({
    required String reviewId,
    required String body,
    required bool hasSpoiler,
  }) {
    return _guard(() async {
      final text = body.trim();
      if (text.isEmpty) {
        throw const ValidationFailure('متن نقد نمی‌تواند خالی باشد');
      }

      // The row policy restricts this to the author, but checking here turns
      // a silent no-op into a message the user can act on.
      final existing = await _client
          .from('reviews')
          .select('user_id')
          .eq('id', reviewId)
          .maybeSingle();
      if (existing == null) throw const NotFoundFailure();
      if (existing['user_id'] != _userId) {
        throw const ValidationFailure('تنها نویسنده می‌تواند نقد را ویرایش کند');
      }

      await _client.from('reviews').update({
        'body': text,
        'has_spoiler': hasSpoiler,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', reviewId);

      return _readOne(reviewId);
    });
  }

  @override
  Future<Result<void>> deleteReview(String reviewId) {
    return _guard(() async {
      await _client
          .from('reviews')
          .delete()
          .match({'id': reviewId, 'user_id': _userId});
    });
  }

  Future<Review> _readOne(String reviewId) async {
    final row = await _client
        .from('reviews')
        .select()
        .eq('id', reviewId)
        .maybeSingle();
    if (row == null) throw const NotFoundFailure();

    final profile = await _client
        .from('public_profiles')
        .select('user_id,username,avatar_url')
        .eq('user_id', row['user_id'] as String)
        .maybeSingle();

    final rating = await _client
        .from('ratings')
        .select('stars')
        .match({
          'user_id': row['user_id'] as String,
          'media_id': row['media_id'] as int,
          'media_type': row['media_type'] as String,
        })
        .maybeSingle();

    return _toReview(row, profile, (rating?['stars'] as num?)?.toInt());
  }

  Review _toReview(
    Map<String, dynamic> row,
    Map<String, dynamic>? profile,
    int? stars,
  ) {
    return Review(
      id: row['id'] as String,
      mediaId: (row['media_id'] as num).toInt(),
      mediaType: row['media_type'] == MediaType.series.name
          ? MediaType.series
          : MediaType.movie,
      authorId: row['user_id'] as String,
      authorName: profile?['username'] as String? ?? 'کاربر',
      authorAvatar: profile?['avatar_url'] as String?,
      body: row['body'] as String? ?? '',
      hasSpoiler: row['has_spoiler'] as bool? ?? false,
      stars: stars,
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
              DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
    );
  }
}
