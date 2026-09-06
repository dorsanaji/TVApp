import 'enums.dart';

/// The lightweight projection used in every list: search results (FR-05),
/// home carousels (FR-18), watchlist sections (FR-12), and personal lists
/// (FR-17).
///
/// Kept separate from the full [Movie]/[Series] entities so that a grid of
/// twenty posters does not require twenty detail requests — which is what
/// NM-08 and NFR-05 are asking for.
class MediaSummary {
  const MediaSummary({
    required this.id,
    required this.type,
    required this.title,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.releaseDate,
    this.voteAverage,
    this.genreIds = const [],
  });

  /// TMDB id. Unique per [type], not globally — always pair the two.
  final int id;
  final MediaType type;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;

  /// ISO date: `release_date` for films, `first_air_date` for series.
  final String? releaseDate;
  final double? voteAverage;
  final List<int> genreIds;

  /// Stable composite key for local storage and de-duplication.
  String get key => '${type.name}:$id';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaSummary && other.id == id && other.type == type);

  @override
  int get hashCode => Object.hash(id, type);
}

/// One page of results from a paginated endpoint.
///
/// NFR-04 requires long lists to be paginated or lazily loaded, so pagination
/// is part of the repository contract rather than something each screen
/// reinvents.
class Paged<T> {
  const Paged({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalResults,
  });

  const Paged.empty()
    : items = const [],
      page = 1,
      totalPages = 1,
      totalResults = 0;

  final List<T> items;
  final int page;
  final int totalPages;
  final int totalResults;

  bool get hasMore => page < totalPages;
  int get nextPage => page + 1;
  bool get isEmpty => items.isEmpty;
}
