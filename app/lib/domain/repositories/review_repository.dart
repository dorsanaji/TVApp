import '../../core/error/result.dart';
import '../entities/enums.dart';

/// Ratings and reviews — FR-13, FR-14, FR-15.
abstract interface class ReviewRepository {
  // ── FR-13 · Rating ────────────────────────────────────────────────────

  /// This user's rating, or `null` if they have not rated it.
  Future<Result<int?>> myRating(int id, MediaType type);

  /// [stars] is 1–5, the qualitative scale the brief specifies. Re-rating
  /// overwrites rather than appends, so a user has exactly one rating per
  /// title (FR-13: "every user must be able to edit their previous rating").
  Future<Result<void>> rate(int id, MediaType type, int stars);

  Future<Result<void>> clearRating(int id, MediaType type);

  /// The distribution the brief asks for: "the percentage of the number of
  /// stars for each qualitative level must be shown from 0 to 100".
  Future<Result<RatingSummary>> ratingSummary(int id, MediaType type);

  // ── FR-14 · Reviews ───────────────────────────────────────────────────

  Future<Result<List<Review>>> reviews(int id, MediaType type);

  Future<Result<Review>> submitReview({
    required int id,
    required MediaType type,
    required String body,
    required bool hasSpoiler,
  });

  Future<Result<Review>> editReview({
    required String reviewId,
    required String body,
    required bool hasSpoiler,
  });

  Future<Result<void>> deleteReview(String reviewId);
}

/// A review, carrying the five fields FR-14 §5.14 requires.
///
/// | # | Brief field     | Property        |
/// |---|-----------------|-----------------|
/// | 1 | متن نظر         | [body]          |
/// | 2 | نام کاربر       | [authorName]    |
/// | 3 | تصویر کاربر     | [authorAvatar]  |
/// | 4 | تاریخ ثبت       | [createdAt]     |
/// | 5 | وضعیت اسپویل    | [hasSpoiler]    |
class Review {
  const Review({
    required this.id,
    required this.mediaId,
    required this.mediaType,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    this.authorAvatar,
    this.hasSpoiler = false,
    this.stars,
    this.updatedAt,
  });

  final String id;
  final int mediaId;
  final MediaType mediaType;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String body;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// FR-15 — spoiler reviews are hidden until the user chooses to reveal them.
  final bool hasSpoiler;

  /// The author's rating, shown alongside the review when they left one.
  final int? stars;

  bool get isEdited => updatedAt != null && updatedAt != createdAt;
}

/// Aggregate ratings for one title (FR-13, and field 12 of FR-06).
class RatingSummary {
  const RatingSummary({required this.counts});

  const RatingSummary.empty() : counts = const {};

  /// Star level (1–5) → number of ratings at that level.
  final Map<int, int> counts;

  int get total => counts.values.fold(0, (sum, c) => sum + c);

  /// Mean on the 1–5 scale — this is the "امتیاز کاربران اپلیکیشن" of FR-06.
  double? get average {
    if (total == 0) return null;
    final weighted = counts.entries.fold(0, (sum, e) => sum + e.key * e.value);
    return weighted / total;
  }

  /// Percentage of ratings at [stars], from 0 to 100.
  ///
  /// This is what the brief means by "the percentage of the number of stars
  /// for each qualitative level must be from 0 to 100" — a distribution across
  /// the five levels, which sums to 100, not one score rescaled.
  double percentFor(int stars) {
    if (total == 0) return 0;
    return (counts[stars] ?? 0) / total * 100;
  }
}
