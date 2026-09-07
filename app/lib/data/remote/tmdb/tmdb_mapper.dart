import '../../../core/l10n/tmdb_localization.dart';
import '../../../domain/entities/credits.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/episode.dart';
import '../../../domain/entities/media_summary.dart';
import '../../../domain/entities/movie.dart';
import '../../../domain/entities/series.dart';

/// Converts the information service's JSON into domain entities.
///
/// This is the *only* file that knows the upstream field names. Everything
/// above it deals in entities, which is what makes NFR-33 ("the structure must
/// allow changing the API or the information service") a one-file change
/// rather than a rewrite.
///
/// The mapping follows the field table in `docs/REQUIREMENTS.md` §5.4.
///
/// Every accessor is defensive. The service omits fields freely — a film with
/// no runtime, a series with no end date, an episode with no still — and
/// FR-20's acceptance criteria require missing data to degrade gracefully
/// rather than crash.
abstract final class TmdbMapper {
  const TmdbMapper._();

  // ── Primitive accessors ───────────────────────────────────────────────

  static String? _str(Object? v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _int(Object? v) => switch (v) {
    final int i => i,
    final num n => n.toInt(),
    final String s => int.tryParse(s),
    _ => null,
  };

  static double? _double(Object? v) => switch (v) {
    final double d => d,
    final num n => n.toDouble(),
    final String s => double.tryParse(s),
    _ => null,
  };

  static List<Map<String, dynamic>> _objects(Object? v) {
    if (v is! List) return const [];
    return v.whereType<Map<String, dynamic>>().toList();
  }

  // ── Summaries (FR-05, FR-18) ──────────────────────────────────────────

  /// The service tags `/search/multi` results with `media_type`; the
  /// type-specific list endpoints do not, so [fallbackType] supplies it.
  static MediaSummary? summary(
    Map<String, dynamic> json, {
    MediaType? fallbackType,
  }) {
    final rawType = _str(json['media_type']);
    final type = switch (rawType) {
      'movie' => MediaType.movie,
      'tv' => MediaType.series,
      // `person` results appear in multi-search and are not titles.
      'person' => null,
      _ => fallbackType,
    };
    if (type == null) return null;

    final id = _int(json['id']);
    if (id == null) return null;

    // Films carry `title`, series carry `name`. Falling back to the original
    // keeps a Persian-locale response from producing a blank card when no
    // translation exists.
    final title =
        _str(json['title']) ??
        _str(json['name']) ??
        _str(json['original_title']) ??
        _str(json['original_name']);
    if (title == null) return null;

    return MediaSummary(
      id: id,
      type: type,
      title: title,
      posterPath: _str(json['poster_path']),
      backdropPath: _str(json['backdrop_path']),
      overview: _str(json['overview']),
      releaseDate: _str(json['release_date']) ?? _str(json['first_air_date']),
      voteAverage: _double(json['vote_average']),
      genreIds: (json['genre_ids'] is List)
          ? (json['genre_ids']! as List).map(_int).whereType<int>().toList()
          : const [],
    );
  }

  /// A paged response. Entries that cannot be mapped — people in multi-search,
  /// malformed rows — are dropped rather than surfaced as broken cards.
  static Paged<MediaSummary> pagedSummaries(
    Map<String, dynamic> json, {
    MediaType? fallbackType,
  }) {
    final items = _objects(json['results'])
        .map((e) => summary(e, fallbackType: fallbackType))
        .whereType<MediaSummary>()
        .toList();

    return Paged(
      items: items,
      page: _int(json['page']) ?? 1,
      totalPages: _int(json['total_pages']) ?? 1,
      totalResults: _int(json['total_results']) ?? items.length,
    );
  }

  // ── Credits ───────────────────────────────────────────────────────────

  static List<CastMember> cast(Map<String, dynamic>? credits) {
    return _objects(credits?['cast'])
        .map(
          (c) => CastMember(
            id: _int(c['id']) ?? 0,
            name: _str(c['name']) ?? '',
            character: _str(c['character']),
            profilePath: _str(c['profile_path']),
            order: _int(c['order']) ?? 999,
          ),
        )
        .where((c) => c.name.isNotEmpty)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  static List<CrewMember> crew(Map<String, dynamic>? credits) {
    return _objects(credits?['crew'])
        .map(
          (c) => CrewMember(
            id: _int(c['id']) ?? 0,
            name: _str(c['name']) ?? '',
            job: _str(c['job']) ?? '',
            department: _str(c['department']),
            profilePath: _str(c['profile_path']),
          ),
        )
        .where((c) => c.name.isNotEmpty && c.job.isNotEmpty)
        .toList();
  }

  /// Genres, with Persian names substituted by id.
  ///
  /// The service has no Persian genre translations — `/genre/*/list` returns
  /// null names under `fa-IR`, and detail responses come back in English
  /// whatever language is requested. "Romance" sitting in a Persian interface
  /// is what NFR-11a forbids, so the name is resolved locally, keeping the
  /// English one only as a fallback for an unmapped id.
  static List<Genre> genres(Object? raw) => _objects(raw)
      .map((g) {
        final id = _int(g['id']) ?? 0;
        final english = _str(g['name']) ?? '';
        return Genre(id: id, name: TmdbLocalization.genre(id, english));
      })
      .where((g) => g.name.isNotEmpty)
      .toList();

  /// Production countries, keyed off the ISO 3166-1 code rather than the
  /// English name — the code is stable, the name is not ("United States of
  /// America" vs "United States").
  static List<String> countries(Object? raw) => _objects(raw)
      .map((c) {
        final english = _str(c['name']);
        if (english == null) return null;
        return TmdbLocalization.country(_str(c['iso_3166_1']), english);
      })
      .whereType<String>()
      .toList();

  // ── Title and overview fallback ───────────────────────────────────────

  /// Picks the best available title and overview: Persian, then English, then
  /// whatever the service delivered.
  ///
  /// Requesting `language=fa-IR` returns the Persian translation **if one
  /// exists** and otherwise falls back to the *original* language — never to
  /// English. So a Korean film with no Persian entry arrives as 기생충 and a
  /// Russian one as Зеркало, which is unreadable for the intended audience.
  ///
  /// `append_to_response=translations` rides along on the detail request we
  /// already make, so this costs no extra round trip. It is only available on
  /// detail endpoints — list and search responses still show the original
  /// title, which is an acceptable trade for not issuing a request per card.
  static ({String? title, String? overview}) _preferred(
    Map<String, dynamic> json, {
    required bool isSeries,
  }) {
    final delivered = isSeries ? _str(json['name']) : _str(json['title']);
    final deliveredOverview = _str(json['overview']);

    final all = _objects(
      (json['translations'] as Map<String, dynamic>?)?['translations'],
    );
    if (all.isEmpty) {
      return (title: delivered, overview: deliveredOverview);
    }

    ({String? title, String? overview})? forLanguage(String language) {
      for (final t in all) {
        if (_str(t['iso_639_1']) != language) continue;
        final data = t['data'] as Map<String, dynamic>?;
        if (data == null) return null;
        return (
          title: isSeries ? _str(data['name']) : _str(data['title']),
          overview: _str(data['overview']),
        );
      }
      return null;
    }

    final persian = forLanguage('fa');
    final english = forLanguage('en');

    // The delivered title is Persian only when a Persian translation exists —
    // otherwise the service handed back the original language. Deciding on the
    // presence of the `fa` entry rather than on the delivered value being
    // non-null is the whole point: "Зеркало" is a perfectly non-null title,
    // and still the wrong one to show.
    final title = persian?.title ?? english?.title ?? delivered;

    // Overviews are treated separately: a title may be translated while the
    // synopsis is not, and vice versa.
    final overview =
        persian?.overview ?? deliveredOverview ?? english?.overview;

    return (title: title, overview: overview);
  }

  // ── FR-06 · Film ──────────────────────────────────────────────────────

  static Movie movie(Map<String, dynamic> json) {
    final credits = json['credits'] as Map<String, dynamic>?;
    final external = json['external_ids'] as Map<String, dynamic>?;

    final preferred = _preferred(json, isSeries: false);

    return Movie(
      id: _int(json['id']) ?? 0,
      title: preferred.title ?? _str(json['original_title']) ?? '',
      originalTitle: _str(json['original_title']),
      posterPath: _str(json['poster_path']),
      backdropPath: _str(json['backdrop_path']),
      overview: preferred.overview,
      releaseDate: _str(json['release_date']),
      runtime: _int(json['runtime']),
      genres: genres(json['genres']),
      productionCountries: countries(json['production_countries']),
      cast: cast(credits),
      crew: crew(credits),
      voteAverage: _double(json['vote_average']),
      voteCount: _int(json['vote_count']),
      imdbId: _str(json['imdb_id']) ?? _str(external?['imdb_id']),
    );
  }

  // ── FR-07 · Series ────────────────────────────────────────────────────

  static Series series(Map<String, dynamic> json) {
    final credits = json['credits'] as Map<String, dynamic>?;
    final external = json['external_ids'] as Map<String, dynamic>?;

    final preferred = _preferred(json, isSeries: true);

    return Series(
      id: _int(json['id']) ?? 0,
      name: preferred.title ?? _str(json['original_name']) ?? '',
      originalName: _str(json['original_name']),
      posterPath: _str(json['poster_path']),
      backdropPath: _str(json['backdrop_path']),
      overview: preferred.overview,
      firstAirDate: _str(json['first_air_date']),
      lastAirDate: _str(json['last_air_date']),
      status: SeriesStatus.fromApi(_str(json['status'])),
      numberOfSeasons: _int(json['number_of_seasons']) ?? 0,
      numberOfEpisodes: _int(json['number_of_episodes']) ?? 0,
      episodeRunTime: (json['episode_run_time'] is List)
          ? (json['episode_run_time']! as List)
                .map(_int)
                .whereType<int>()
                .toList()
          : const [],
      genres: genres(json['genres']),
      productionCountries: countries(json['production_countries']),
      cast: cast(credits),
      crew: crew(credits),
      seasons: _objects(json['seasons']).map(seasonSummary).toList(),
      lastEpisodeToAir: switch (json['last_episode_to_air']) {
        final Map<String, dynamic> last => AiredEpisodeMarker(
          seasonNumber: _int(last['season_number']) ?? 0,
          episodeNumber: _int(last['episode_number']) ?? 0,
        ),
        _ => null,
      },
      voteAverage: _double(json['vote_average']),
      voteCount: _int(json['vote_count']),
      imdbId: _str(external?['imdb_id']),
    );
  }

  static SeasonSummary seasonSummary(Map<String, dynamic> json) =>
      SeasonSummary(
        id: _int(json['id']) ?? 0,
        seasonNumber: _int(json['season_number']) ?? 0,
        name: _str(json['name']) ?? '',
        episodeCount: _int(json['episode_count']) ?? 0,
        airDate: _str(json['air_date']),
        posterPath: _str(json['poster_path']),
        overview: _str(json['overview']),
      );

  // ── FR-08 · Season with episodes ──────────────────────────────────────

  static Season season(Map<String, dynamic> json) {
    final seasonNumber = _int(json['season_number']) ?? 0;

    return Season(
      id: _int(json['id']) ?? 0,
      seasonNumber: seasonNumber,
      name: _str(json['name']) ?? '',
      airDate: _str(json['air_date']),
      posterPath: _str(json['poster_path']),
      overview: _str(json['overview']),
      episodes: _objects(
        json['episodes'],
      ).map((e) => episode(e, fallbackSeasonNumber: seasonNumber)).toList(),
    );
  }

  static Episode episode(
    Map<String, dynamic> json, {
    int fallbackSeasonNumber = 0,
  }) => Episode(
    id: _int(json['id']) ?? 0,
    seasonNumber: _int(json['season_number']) ?? fallbackSeasonNumber,
    episodeNumber: _int(json['episode_number']) ?? 0,
    name: _str(json['name']) ?? '',
    airDate: _str(json['air_date']),
    runtime: _int(json['runtime']),
    overview: _str(json['overview']),
    stillPath: _str(json['still_path']),
    voteAverage: _double(json['vote_average']),
  );

  // ── FR-05 · Person credits ────────────────────────────────────────────

  /// Flattens a person's combined credits into titles, most popular first.
  /// Serves both the "actor name" and "director name" criteria: cast entries
  /// cover the former, crew entries the latter.
  static List<MediaSummary> personCredits(
    Map<String, dynamic> json, {
    bool includeCrew = true,
  }) {
    final entries = <Map<String, dynamic>>[
      ..._objects(json['cast']),
      // Crew is narrowed to directing credits. FR-05 asks for search by
      // "نام کارگردان" — a person's full crew list also carries producer,
      // writer and second-unit roles, which is noise for that question.
      if (includeCrew)
        ..._objects(json['crew']).where((c) => _str(c['job']) == 'Director'),
    ];

    final seen = <String>{};
    final results = <(MediaSummary, double)>[];

    for (final entry in entries) {
      if (_isSelfAppearance(entry)) continue;
      final item = summary(entry);
      if (item == null || !seen.add(item.key)) continue;
      results.add((item, _double(entry['popularity']) ?? 0));
    }

    // Ranked by popularity, **not** rating.
    //
    // Sorting by `vote_average` put a film with a single 10/10 vote above a
    // blockbuster with 22,000 votes — searching "Robert Pattinson" returned an
    // obscure two-vote title and a Korean variety show ahead of Harry Potter
    // and The Batman. Popularity is the service's own relevance signal and is
    // what a viewer means by "this actor's films".
    results.sort((a, b) => b.$2.compareTo(a.$2));
    return results.map((r) => r.$1).toList();
  }

  /// True for talk-show, reality and news credits, and for roles where the
  /// person plays themselves.
  ///
  /// Without this, sorting by popularity floats chat shows to the top of every
  /// actor's filmography — actors appear as guests on shows far more popular
  /// than the films they star in.
  static bool _isSelfAppearance(Map<String, dynamic> entry) {
    const talkShowGenres = {
      10767, // Talk
      10764, // Reality
      10763, // News
    };

    final genreIds = entry['genre_ids'];
    if (genreIds is List &&
        genreIds.map(_int).whereType<int>().any(talkShowGenres.contains)) {
      return true;
    }

    final character = _str(entry['character'])?.toLowerCase();
    if (character == null) return false;
    return const [
      'self',
      'himself',
      'herself',
      'themselves',
    ].any((s) => character == s || character.startsWith('$s '));
  }
}
