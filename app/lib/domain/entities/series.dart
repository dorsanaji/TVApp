import 'credits.dart';
import 'enums.dart';

/// A television series, carrying every field FR-07 §5.7 requires.
///
/// | # | Brief field        | Property            |
/// |---|--------------------|---------------------|
/// | 1 | عنوان سریال        | [name]              |
/// | 2 | پوستر              | [posterPath]        |
/// | 3 | خلاصه داستان       | [overview]          |
/// | 4 | ژانر               | [genres]            |
/// | 5 | سال شروع پخش       | [firstAirDate]      |
/// | 6 | سال پایان پخش      | [lastAirDate]       |
/// | 7 | وضعیت پخش          | [status]            |
/// | 8 | تعداد فصل‌ها        | [numberOfSeasons]   |
/// | 9 | تعداد قسمت‌ها       | [numberOfEpisodes]  |
/// |10 | بازیگران           | [cast]              |
/// |11 | امتیاز IMDb        | [voteAverage]       |
class Series {
  const Series({
    required this.id,
    required this.name,
    this.originalName,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.firstAirDate,
    this.lastAirDate,
    this.status = SeriesStatus.unknown,
    this.numberOfSeasons = 0,
    this.numberOfEpisodes = 0,
    this.episodeRunTime = const [],
    this.genres = const [],
    this.productionCountries = const [],
    this.cast = const [],
    this.crew = const [],
    this.seasons = const [],
    this.voteAverage,
    this.voteCount,
    this.imdbId,
  });

  final int id;
  final String name;
  final String? originalName;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final String? firstAirDate;

  /// Null while the series is still running — field 6 renders as "—".
  final String? lastAirDate;

  final SeriesStatus status;
  final int numberOfSeasons;
  final int numberOfEpisodes;

  /// Typical episode length in minutes. Feeds the total-watch-time statistic
  /// of FR-19 when an individual episode has no runtime of its own.
  final List<int> episodeRunTime;

  final List<Genre> genres;
  final List<String> productionCountries;
  final List<CastMember> cast;
  final List<CrewMember> crew;

  /// Season stubs, without episodes. Episodes are fetched per season on
  /// demand (FR-08 + NFR-04) rather than all at once.
  final List<SeasonSummary> seasons;

  final double? voteAverage;
  final int? voteCount;
  final String? imdbId;

  /// Average episode length, used to estimate watch time.
  int get averageEpisodeRuntime {
    if (episodeRunTime.isEmpty) return 0;
    return episodeRunTime.reduce((a, b) => a + b) ~/ episodeRunTime.length;
  }

  /// True when no further episodes will be released — drives the purple vs.
  /// green decision in FR-11.
  bool get hasFinishedAiring => status.isFinished;
}

/// A season without its episodes.
///
/// TMDB numbers specials as season 0; [isSpecials] lets the UI and the
/// progress calculation of FR-11 exclude them, since counting specials would
/// make a fully-watched series show as incomplete.
class SeasonSummary {
  const SeasonSummary({
    required this.id,
    required this.seasonNumber,
    required this.name,
    this.episodeCount = 0,
    this.airDate,
    this.posterPath,
    this.overview,
  });

  final int id;
  final int seasonNumber;
  final String name;
  final int episodeCount;
  final String? airDate;
  final String? posterPath;
  final String? overview;

  bool get isSpecials => seasonNumber == 0;
}
