/// A single episode, carrying every field FR-08 §5.8 requires.
///
/// | # | Brief field        | Property         |
/// |---|--------------------|------------------|
/// | 1 | شماره فصل          | [seasonNumber]   |
/// | 2 | شماره قسمت         | [episodeNumber]  |
/// | 3 | عنوان قسمت         | [name]           |
/// | 4 | تاریخ انتشار       | [airDate]        |
/// | 5 | مدت زمان           | [runtime]        |
/// | 6 | خلاصه قسمت         | [overview]       |
/// | 7 | وضعیت مشاهده شدن   | [isWatched]      |
///
/// [isWatched] is per-user local state (FR-10), merged in by the repository
/// rather than coming from the information service.
class Episode {
  const Episode({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.name,
    this.airDate,
    this.runtime,
    this.overview,
    this.stillPath,
    this.voteAverage,
    this.isWatched = false,
  });

  final int id;
  final int seasonNumber;
  final int episodeNumber;
  final String name;

  /// ISO date. Null for an episode announced but not yet dated.
  final String? airDate;

  /// Minutes.
  final int? runtime;

  final String? overview;
  final String? stillPath;
  final double? voteAverage;

  /// Field 7 — whether *this user* has marked it watched.
  final bool isWatched;

  /// `S01E05`, shown as a compact label in the episode list.
  String get code =>
      'S${seasonNumber.toString().padLeft(2, '0')}E${episodeNumber.toString().padLeft(2, '0')}';

  /// True when the episode has aired. An episode dated in the future must not
  /// count towards the FR-11 denominator, or a fully caught-up viewer would
  /// never reach 100%.
  bool get hasAired {
    if (airDate == null || airDate!.isEmpty) return false;
    final date = DateTime.tryParse(airDate!);
    if (date == null) return false;
    return !date.isAfter(DateTime.now());
  }

  Episode copyWith({bool? isWatched}) => Episode(
    id: id,
    seasonNumber: seasonNumber,
    episodeNumber: episodeNumber,
    name: name,
    airDate: airDate,
    runtime: runtime,
    overview: overview,
    stillPath: stillPath,
    voteAverage: voteAverage,
    isWatched: isWatched ?? this.isWatched,
  );
}

/// A season together with its episodes, as returned by the season endpoint.
class Season {
  const Season({
    required this.id,
    required this.seasonNumber,
    required this.name,
    required this.episodes,
    this.airDate,
    this.posterPath,
    this.overview,
  });

  final int id;
  final int seasonNumber;
  final String name;
  final List<Episode> episodes;
  final String? airDate;
  final String? posterPath;
  final String? overview;

  int get watchedCount => episodes.where((e) => e.isWatched).length;

  /// Only aired episodes count — see [Episode.hasAired].
  int get airedCount => episodes.where((e) => e.hasAired).length;

  bool get isFullyWatched => airedCount > 0 && watchedCount >= airedCount;
}
