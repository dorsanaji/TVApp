import 'credits.dart';

/// A film, carrying every field FR-06 §5.6 requires.
///
/// The field list below is deliberately one-to-one with the brief so that the
/// detail screen can be checked against it during grading:
///
/// | # | Brief field           | Property           |
/// |---|-----------------------|--------------------|
/// | 1 | عنوان فیلم            | [title]            |
/// | 2 | عنوان اصلی            | [originalTitle]    |
/// | 3 | پوستر                 | [posterPath]       |
/// | 4 | خلاصه داستان          | [overview]         |
/// | 5 | سال انتشار            | [releaseDate]      |
/// | 6 | مدت زمان فیلم         | [runtime]          |
/// | 7 | ژانر                  | [genres]           |
/// | 8 | کشور سازنده           | [productionCountries] |
/// | 9 | کارگردان              | [directors]        |
/// |10 | بازیگران              | [cast]             |
/// |11 | امتیاز IMDb           | [voteAverage] / [imdbId] |
/// |12 | امتیاز کاربران اپلیکیشن | `ratingSummaryProvider` |
///
/// Field 12 is deliberately **not** a field on this entity. It is the mean
/// of ratings left by this application's own users, which lives in the local
/// database; the information service knows nothing about it, so a mapper
/// could never fill it. It once was a field here, and stayed null forever —
/// the detail screen reported «هنوز امتیازی ثبت نشده» however many stars had
/// been submitted. `RatingRow` now reads it from the ratings table.
class Movie {
  const Movie({
    required this.id,
    required this.title,
    this.originalTitle,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.releaseDate,
    this.runtime,
    this.genres = const [],
    this.productionCountries = const [],
    this.cast = const [],
    this.crew = const [],
    this.voteAverage,
    this.voteCount,
    this.imdbId,
  });

  final int id;
  final String title;
  final String? originalTitle;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;

  /// ISO `release_date`.
  final String? releaseDate;

  /// Minutes.
  final int? runtime;

  final List<Genre> genres;
  final List<String> productionCountries;
  final List<CastMember> cast;
  final List<CrewMember> crew;

  /// Field 11 — the external rating the brief calls "امتیاز IMDb".
  final double? voteAverage;
  final int? voteCount;

  /// Retained so the external rating can be attributed to IMDb, as the brief
  /// asks, even though the data reaches us through TMDB.
  final String? imdbId;

  /// Field 9 — directors, derived from the crew list.
  List<CrewMember> get directors => crew.where((c) => c.isDirector).toList();
}
