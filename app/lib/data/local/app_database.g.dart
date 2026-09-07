// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedMediaTable extends CachedMedia
    with TableInfo<$CachedMediaTable, CachedMediaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMediaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<int> mediaId = GeneratedColumn<int>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaType, String> mediaType =
      GeneratedColumn<String>(
        'media_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MediaType>($CachedMediaTable.$convertermediaType);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseDateMeta = const VerificationMeta(
    'releaseDate',
  );
  @override
  late final GeneratedColumn<String> releaseDate = GeneratedColumn<String>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _voteAverageMeta = const VerificationMeta(
    'voteAverage',
  );
  @override
  late final GeneratedColumn<double> voteAverage = GeneratedColumn<double>(
    'vote_average',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _runtimeMinutesMeta = const VerificationMeta(
    'runtimeMinutes',
  );
  @override
  late final GeneratedColumn<int> runtimeMinutes = GeneratedColumn<int>(
    'runtime_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _genresMeta = const VerificationMeta('genres');
  @override
  late final GeneratedColumn<String> genres = GeneratedColumn<String>(
    'genres',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    mediaId,
    mediaType,
    title,
    posterPath,
    overview,
    releaseDate,
    voteAverage,
    runtimeMinutes,
    genres,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_media';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMediaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('release_date')) {
      context.handle(
        _releaseDateMeta,
        releaseDate.isAcceptableOrUnknown(
          data['release_date']!,
          _releaseDateMeta,
        ),
      );
    }
    if (data.containsKey('vote_average')) {
      context.handle(
        _voteAverageMeta,
        voteAverage.isAcceptableOrUnknown(
          data['vote_average']!,
          _voteAverageMeta,
        ),
      );
    }
    if (data.containsKey('runtime_minutes')) {
      context.handle(
        _runtimeMinutesMeta,
        runtimeMinutes.isAcceptableOrUnknown(
          data['runtime_minutes']!,
          _runtimeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('genres')) {
      context.handle(
        _genresMeta,
        genres.isAcceptableOrUnknown(data['genres']!, _genresMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mediaId, mediaType};
  @override
  CachedMediaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMediaData(
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_id'],
      )!,
      mediaType: $CachedMediaTable.$convertermediaType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}media_type'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      releaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_date'],
      ),
      voteAverage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vote_average'],
      ),
      runtimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runtime_minutes'],
      )!,
      genres: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genres'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $CachedMediaTable createAlias(String alias) {
    return $CachedMediaTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaType, String, String> $convertermediaType =
      const EnumNameConverter<MediaType>(MediaType.values);
}

class CachedMediaData extends DataClass implements Insertable<CachedMediaData> {
  final int mediaId;
  final MediaType mediaType;
  final String title;
  final String? posterPath;
  final String? overview;
  final String? releaseDate;
  final double? voteAverage;

  /// Film runtime. Stored so the FR-19 total-watch-time statistic can include
  /// films without re-fetching every title the user has ever marked watched.
  final int runtimeMinutes;

  /// Comma-separated genre names, denormalised for the FR-19 favourite-genre
  /// statistic. A join table would be tidier, but this is read far more often
  /// than written and never queried by individual genre.
  final String genres;
  final DateTime cachedAt;
  const CachedMediaData({
    required this.mediaId,
    required this.mediaType,
    required this.title,
    this.posterPath,
    this.overview,
    this.releaseDate,
    this.voteAverage,
    required this.runtimeMinutes,
    required this.genres,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['media_id'] = Variable<int>(mediaId);
    {
      map['media_type'] = Variable<String>(
        $CachedMediaTable.$convertermediaType.toSql(mediaType),
      );
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<String>(releaseDate);
    }
    if (!nullToAbsent || voteAverage != null) {
      map['vote_average'] = Variable<double>(voteAverage);
    }
    map['runtime_minutes'] = Variable<int>(runtimeMinutes);
    map['genres'] = Variable<String>(genres);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedMediaCompanion toCompanion(bool nullToAbsent) {
    return CachedMediaCompanion(
      mediaId: Value(mediaId),
      mediaType: Value(mediaType),
      title: Value(title),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      voteAverage: voteAverage == null && nullToAbsent
          ? const Value.absent()
          : Value(voteAverage),
      runtimeMinutes: Value(runtimeMinutes),
      genres: Value(genres),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedMediaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMediaData(
      mediaId: serializer.fromJson<int>(json['mediaId']),
      mediaType: $CachedMediaTable.$convertermediaType.fromJson(
        serializer.fromJson<String>(json['mediaType']),
      ),
      title: serializer.fromJson<String>(json['title']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      overview: serializer.fromJson<String?>(json['overview']),
      releaseDate: serializer.fromJson<String?>(json['releaseDate']),
      voteAverage: serializer.fromJson<double?>(json['voteAverage']),
      runtimeMinutes: serializer.fromJson<int>(json['runtimeMinutes']),
      genres: serializer.fromJson<String>(json['genres']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mediaId': serializer.toJson<int>(mediaId),
      'mediaType': serializer.toJson<String>(
        $CachedMediaTable.$convertermediaType.toJson(mediaType),
      ),
      'title': serializer.toJson<String>(title),
      'posterPath': serializer.toJson<String?>(posterPath),
      'overview': serializer.toJson<String?>(overview),
      'releaseDate': serializer.toJson<String?>(releaseDate),
      'voteAverage': serializer.toJson<double?>(voteAverage),
      'runtimeMinutes': serializer.toJson<int>(runtimeMinutes),
      'genres': serializer.toJson<String>(genres),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedMediaData copyWith({
    int? mediaId,
    MediaType? mediaType,
    String? title,
    Value<String?> posterPath = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<String?> releaseDate = const Value.absent(),
    Value<double?> voteAverage = const Value.absent(),
    int? runtimeMinutes,
    String? genres,
    DateTime? cachedAt,
  }) => CachedMediaData(
    mediaId: mediaId ?? this.mediaId,
    mediaType: mediaType ?? this.mediaType,
    title: title ?? this.title,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    overview: overview.present ? overview.value : this.overview,
    releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
    voteAverage: voteAverage.present ? voteAverage.value : this.voteAverage,
    runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
    genres: genres ?? this.genres,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  CachedMediaData copyWithCompanion(CachedMediaCompanion data) {
    return CachedMediaData(
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      title: data.title.present ? data.title.value : this.title,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      overview: data.overview.present ? data.overview.value : this.overview,
      releaseDate: data.releaseDate.present
          ? data.releaseDate.value
          : this.releaseDate,
      voteAverage: data.voteAverage.present
          ? data.voteAverage.value
          : this.voteAverage,
      runtimeMinutes: data.runtimeMinutes.present
          ? data.runtimeMinutes.value
          : this.runtimeMinutes,
      genres: data.genres.present ? data.genres.value : this.genres,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMediaData(')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('posterPath: $posterPath, ')
          ..write('overview: $overview, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('runtimeMinutes: $runtimeMinutes, ')
          ..write('genres: $genres, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    mediaId,
    mediaType,
    title,
    posterPath,
    overview,
    releaseDate,
    voteAverage,
    runtimeMinutes,
    genres,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMediaData &&
          other.mediaId == this.mediaId &&
          other.mediaType == this.mediaType &&
          other.title == this.title &&
          other.posterPath == this.posterPath &&
          other.overview == this.overview &&
          other.releaseDate == this.releaseDate &&
          other.voteAverage == this.voteAverage &&
          other.runtimeMinutes == this.runtimeMinutes &&
          other.genres == this.genres &&
          other.cachedAt == this.cachedAt);
}

class CachedMediaCompanion extends UpdateCompanion<CachedMediaData> {
  final Value<int> mediaId;
  final Value<MediaType> mediaType;
  final Value<String> title;
  final Value<String?> posterPath;
  final Value<String?> overview;
  final Value<String?> releaseDate;
  final Value<double?> voteAverage;
  final Value<int> runtimeMinutes;
  final Value<String> genres;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedMediaCompanion({
    this.mediaId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.title = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.overview = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.runtimeMinutes = const Value.absent(),
    this.genres = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMediaCompanion.insert({
    required int mediaId,
    required MediaType mediaType,
    required String title,
    this.posterPath = const Value.absent(),
    this.overview = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.voteAverage = const Value.absent(),
    this.runtimeMinutes = const Value.absent(),
    this.genres = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : mediaId = Value(mediaId),
       mediaType = Value(mediaType),
       title = Value(title);
  static Insertable<CachedMediaData> custom({
    Expression<int>? mediaId,
    Expression<String>? mediaType,
    Expression<String>? title,
    Expression<String>? posterPath,
    Expression<String>? overview,
    Expression<String>? releaseDate,
    Expression<double>? voteAverage,
    Expression<int>? runtimeMinutes,
    Expression<String>? genres,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mediaId != null) 'media_id': mediaId,
      if (mediaType != null) 'media_type': mediaType,
      if (title != null) 'title': title,
      if (posterPath != null) 'poster_path': posterPath,
      if (overview != null) 'overview': overview,
      if (releaseDate != null) 'release_date': releaseDate,
      if (voteAverage != null) 'vote_average': voteAverage,
      if (runtimeMinutes != null) 'runtime_minutes': runtimeMinutes,
      if (genres != null) 'genres': genres,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMediaCompanion copyWith({
    Value<int>? mediaId,
    Value<MediaType>? mediaType,
    Value<String>? title,
    Value<String?>? posterPath,
    Value<String?>? overview,
    Value<String?>? releaseDate,
    Value<double?>? voteAverage,
    Value<int>? runtimeMinutes,
    Value<String>? genres,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return CachedMediaCompanion(
      mediaId: mediaId ?? this.mediaId,
      mediaType: mediaType ?? this.mediaType,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      overview: overview ?? this.overview,
      releaseDate: releaseDate ?? this.releaseDate,
      voteAverage: voteAverage ?? this.voteAverage,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      genres: genres ?? this.genres,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mediaId.present) {
      map['media_id'] = Variable<int>(mediaId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(
        $CachedMediaTable.$convertermediaType.toSql(mediaType.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<String>(releaseDate.value);
    }
    if (voteAverage.present) {
      map['vote_average'] = Variable<double>(voteAverage.value);
    }
    if (runtimeMinutes.present) {
      map['runtime_minutes'] = Variable<int>(runtimeMinutes.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(genres.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMediaCompanion(')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('posterPath: $posterPath, ')
          ..write('overview: $overview, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('voteAverage: $voteAverage, ')
          ..write('runtimeMinutes: $runtimeMinutes, ')
          ..write('genres: $genres, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WatchStatusesTable extends WatchStatuses
    with TableInfo<$WatchStatusesTable, WatchStatuse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchStatusesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(localUser),
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<int> mediaId = GeneratedColumn<int>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaType, String> mediaType =
      GeneratedColumn<String>(
        'media_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MediaType>($WatchStatusesTable.$convertermediaType);
  @override
  late final GeneratedColumnWithTypeConverter<WatchStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WatchStatus>($WatchStatusesTable.$converterstatus);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    mediaId,
    mediaType,
    status,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watch_statuses';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchStatuse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, mediaId, mediaType};
  @override
  WatchStatuse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchStatuse(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_id'],
      )!,
      mediaType: $WatchStatusesTable.$convertermediaType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}media_type'],
        )!,
      ),
      status: $WatchStatusesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WatchStatusesTable createAlias(String alias) {
    return $WatchStatusesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaType, String, String> $convertermediaType =
      const EnumNameConverter<MediaType>(MediaType.values);
  static JsonTypeConverter2<WatchStatus, String, String> $converterstatus =
      const EnumNameConverter<WatchStatus>(WatchStatus.values);
}

class WatchStatuse extends DataClass implements Insertable<WatchStatuse> {
  final String userId;
  final int mediaId;
  final MediaType mediaType;
  final WatchStatus status;
  final DateTime updatedAt;
  const WatchStatuse({
    required this.userId,
    required this.mediaId,
    required this.mediaType,
    required this.status,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['media_id'] = Variable<int>(mediaId);
    {
      map['media_type'] = Variable<String>(
        $WatchStatusesTable.$convertermediaType.toSql(mediaType),
      );
    }
    {
      map['status'] = Variable<String>(
        $WatchStatusesTable.$converterstatus.toSql(status),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WatchStatusesCompanion toCompanion(bool nullToAbsent) {
    return WatchStatusesCompanion(
      userId: Value(userId),
      mediaId: Value(mediaId),
      mediaType: Value(mediaType),
      status: Value(status),
      updatedAt: Value(updatedAt),
    );
  }

  factory WatchStatuse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchStatuse(
      userId: serializer.fromJson<String>(json['userId']),
      mediaId: serializer.fromJson<int>(json['mediaId']),
      mediaType: $WatchStatusesTable.$convertermediaType.fromJson(
        serializer.fromJson<String>(json['mediaType']),
      ),
      status: $WatchStatusesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'mediaId': serializer.toJson<int>(mediaId),
      'mediaType': serializer.toJson<String>(
        $WatchStatusesTable.$convertermediaType.toJson(mediaType),
      ),
      'status': serializer.toJson<String>(
        $WatchStatusesTable.$converterstatus.toJson(status),
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WatchStatuse copyWith({
    String? userId,
    int? mediaId,
    MediaType? mediaType,
    WatchStatus? status,
    DateTime? updatedAt,
  }) => WatchStatuse(
    userId: userId ?? this.userId,
    mediaId: mediaId ?? this.mediaId,
    mediaType: mediaType ?? this.mediaType,
    status: status ?? this.status,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WatchStatuse copyWithCompanion(WatchStatusesCompanion data) {
    return WatchStatuse(
      userId: data.userId.present ? data.userId.value : this.userId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      status: data.status.present ? data.status.value : this.status,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchStatuse(')
          ..write('userId: $userId, ')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(userId, mediaId, mediaType, status, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchStatuse &&
          other.userId == this.userId &&
          other.mediaId == this.mediaId &&
          other.mediaType == this.mediaType &&
          other.status == this.status &&
          other.updatedAt == this.updatedAt);
}

class WatchStatusesCompanion extends UpdateCompanion<WatchStatuse> {
  final Value<String> userId;
  final Value<int> mediaId;
  final Value<MediaType> mediaType;
  final Value<WatchStatus> status;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WatchStatusesCompanion({
    this.userId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.status = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatchStatusesCompanion.insert({
    this.userId = const Value.absent(),
    required int mediaId,
    required MediaType mediaType,
    required WatchStatus status,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : mediaId = Value(mediaId),
       mediaType = Value(mediaType),
       status = Value(status);
  static Insertable<WatchStatuse> custom({
    Expression<String>? userId,
    Expression<int>? mediaId,
    Expression<String>? mediaType,
    Expression<String>? status,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (mediaId != null) 'media_id': mediaId,
      if (mediaType != null) 'media_type': mediaType,
      if (status != null) 'status': status,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatchStatusesCompanion copyWith({
    Value<String>? userId,
    Value<int>? mediaId,
    Value<MediaType>? mediaType,
    Value<WatchStatus>? status,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WatchStatusesCompanion(
      userId: userId ?? this.userId,
      mediaId: mediaId ?? this.mediaId,
      mediaType: mediaType ?? this.mediaType,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<int>(mediaId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(
        $WatchStatusesTable.$convertermediaType.toSql(mediaType.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $WatchStatusesTable.$converterstatus.toSql(status.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchStatusesCompanion(')
          ..write('userId: $userId, ')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EpisodeWatchesTable extends EpisodeWatches
    with TableInfo<$EpisodeWatchesTable, EpisodeWatche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodeWatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(localUser),
  );
  static const VerificationMeta _episodeIdMeta = const VerificationMeta(
    'episodeId',
  );
  @override
  late final GeneratedColumn<int> episodeId = GeneratedColumn<int>(
    'episode_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta(
    'seasonNumber',
  );
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeNumberMeta = const VerificationMeta(
    'episodeNumber',
  );
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
    'episode_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _runtimeMinutesMeta = const VerificationMeta(
    'runtimeMinutes',
  );
  @override
  late final GeneratedColumn<int> runtimeMinutes = GeneratedColumn<int>(
    'runtime_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _watchedAtMeta = const VerificationMeta(
    'watchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> watchedAt = GeneratedColumn<DateTime>(
    'watched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    episodeId,
    seriesId,
    seasonNumber,
    episodeNumber,
    runtimeMinutes,
    watchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episode_watches';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpisodeWatche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('episode_id')) {
      context.handle(
        _episodeIdMeta,
        episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
        _seasonNumberMeta,
        seasonNumber.isAcceptableOrUnknown(
          data['season_number']!,
          _seasonNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('episode_number')) {
      context.handle(
        _episodeNumberMeta,
        episodeNumber.isAcceptableOrUnknown(
          data['episode_number']!,
          _episodeNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeNumberMeta);
    }
    if (data.containsKey('runtime_minutes')) {
      context.handle(
        _runtimeMinutesMeta,
        runtimeMinutes.isAcceptableOrUnknown(
          data['runtime_minutes']!,
          _runtimeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('watched_at')) {
      context.handle(
        _watchedAtMeta,
        watchedAt.isAcceptableOrUnknown(data['watched_at']!, _watchedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, episodeId};
  @override
  EpisodeWatche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpisodeWatche(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      episodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      )!,
      seasonNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_number'],
      )!,
      episodeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_number'],
      )!,
      runtimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}runtime_minutes'],
      )!,
      watchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}watched_at'],
      )!,
    );
  }

  @override
  $EpisodeWatchesTable createAlias(String alias) {
    return $EpisodeWatchesTable(attachedDatabase, alias);
  }
}

class EpisodeWatche extends DataClass implements Insertable<EpisodeWatche> {
  final String userId;
  final int episodeId;
  final int seriesId;
  final int seasonNumber;
  final int episodeNumber;

  /// Copied in at mark time so the FR-19 total-watch-time statistic can be
  /// computed without re-fetching every season the user has ever watched.
  final int runtimeMinutes;
  final DateTime watchedAt;
  const EpisodeWatche({
    required this.userId,
    required this.episodeId,
    required this.seriesId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.runtimeMinutes,
    required this.watchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['episode_id'] = Variable<int>(episodeId);
    map['series_id'] = Variable<int>(seriesId);
    map['season_number'] = Variable<int>(seasonNumber);
    map['episode_number'] = Variable<int>(episodeNumber);
    map['runtime_minutes'] = Variable<int>(runtimeMinutes);
    map['watched_at'] = Variable<DateTime>(watchedAt);
    return map;
  }

  EpisodeWatchesCompanion toCompanion(bool nullToAbsent) {
    return EpisodeWatchesCompanion(
      userId: Value(userId),
      episodeId: Value(episodeId),
      seriesId: Value(seriesId),
      seasonNumber: Value(seasonNumber),
      episodeNumber: Value(episodeNumber),
      runtimeMinutes: Value(runtimeMinutes),
      watchedAt: Value(watchedAt),
    );
  }

  factory EpisodeWatche.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpisodeWatche(
      userId: serializer.fromJson<String>(json['userId']),
      episodeId: serializer.fromJson<int>(json['episodeId']),
      seriesId: serializer.fromJson<int>(json['seriesId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      episodeNumber: serializer.fromJson<int>(json['episodeNumber']),
      runtimeMinutes: serializer.fromJson<int>(json['runtimeMinutes']),
      watchedAt: serializer.fromJson<DateTime>(json['watchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'episodeId': serializer.toJson<int>(episodeId),
      'seriesId': serializer.toJson<int>(seriesId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'episodeNumber': serializer.toJson<int>(episodeNumber),
      'runtimeMinutes': serializer.toJson<int>(runtimeMinutes),
      'watchedAt': serializer.toJson<DateTime>(watchedAt),
    };
  }

  EpisodeWatche copyWith({
    String? userId,
    int? episodeId,
    int? seriesId,
    int? seasonNumber,
    int? episodeNumber,
    int? runtimeMinutes,
    DateTime? watchedAt,
  }) => EpisodeWatche(
    userId: userId ?? this.userId,
    episodeId: episodeId ?? this.episodeId,
    seriesId: seriesId ?? this.seriesId,
    seasonNumber: seasonNumber ?? this.seasonNumber,
    episodeNumber: episodeNumber ?? this.episodeNumber,
    runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
    watchedAt: watchedAt ?? this.watchedAt,
  );
  EpisodeWatche copyWithCompanion(EpisodeWatchesCompanion data) {
    return EpisodeWatche(
      userId: data.userId.present ? data.userId.value : this.userId,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      runtimeMinutes: data.runtimeMinutes.present
          ? data.runtimeMinutes.value
          : this.runtimeMinutes,
      watchedAt: data.watchedAt.present ? data.watchedAt.value : this.watchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeWatche(')
          ..write('userId: $userId, ')
          ..write('episodeId: $episodeId, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('runtimeMinutes: $runtimeMinutes, ')
          ..write('watchedAt: $watchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    episodeId,
    seriesId,
    seasonNumber,
    episodeNumber,
    runtimeMinutes,
    watchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpisodeWatche &&
          other.userId == this.userId &&
          other.episodeId == this.episodeId &&
          other.seriesId == this.seriesId &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeNumber == this.episodeNumber &&
          other.runtimeMinutes == this.runtimeMinutes &&
          other.watchedAt == this.watchedAt);
}

class EpisodeWatchesCompanion extends UpdateCompanion<EpisodeWatche> {
  final Value<String> userId;
  final Value<int> episodeId;
  final Value<int> seriesId;
  final Value<int> seasonNumber;
  final Value<int> episodeNumber;
  final Value<int> runtimeMinutes;
  final Value<DateTime> watchedAt;
  final Value<int> rowid;
  const EpisodeWatchesCompanion({
    this.userId = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.runtimeMinutes = const Value.absent(),
    this.watchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpisodeWatchesCompanion.insert({
    this.userId = const Value.absent(),
    required int episodeId,
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
    this.runtimeMinutes = const Value.absent(),
    this.watchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : episodeId = Value(episodeId),
       seriesId = Value(seriesId),
       seasonNumber = Value(seasonNumber),
       episodeNumber = Value(episodeNumber);
  static Insertable<EpisodeWatche> custom({
    Expression<String>? userId,
    Expression<int>? episodeId,
    Expression<int>? seriesId,
    Expression<int>? seasonNumber,
    Expression<int>? episodeNumber,
    Expression<int>? runtimeMinutes,
    Expression<DateTime>? watchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (episodeId != null) 'episode_id': episodeId,
      if (seriesId != null) 'series_id': seriesId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (runtimeMinutes != null) 'runtime_minutes': runtimeMinutes,
      if (watchedAt != null) 'watched_at': watchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpisodeWatchesCompanion copyWith({
    Value<String>? userId,
    Value<int>? episodeId,
    Value<int>? seriesId,
    Value<int>? seasonNumber,
    Value<int>? episodeNumber,
    Value<int>? runtimeMinutes,
    Value<DateTime>? watchedAt,
    Value<int>? rowid,
  }) {
    return EpisodeWatchesCompanion(
      userId: userId ?? this.userId,
      episodeId: episodeId ?? this.episodeId,
      seriesId: seriesId ?? this.seriesId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      runtimeMinutes: runtimeMinutes ?? this.runtimeMinutes,
      watchedAt: watchedAt ?? this.watchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<int>(episodeId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (runtimeMinutes.present) {
      map['runtime_minutes'] = Variable<int>(runtimeMinutes.value);
    }
    if (watchedAt.present) {
      map['watched_at'] = Variable<DateTime>(watchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeWatchesCompanion(')
          ..write('userId: $userId, ')
          ..write('episodeId: $episodeId, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('runtimeMinutes: $runtimeMinutes, ')
          ..write('watchedAt: $watchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeriesProgressMetaTable extends SeriesProgressMeta
    with TableInfo<$SeriesProgressMetaTable, SeriesProgressMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesProgressMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _airedEpisodeCountMeta = const VerificationMeta(
    'airedEpisodeCount',
  );
  @override
  late final GeneratedColumn<int> airedEpisodeCount = GeneratedColumn<int>(
    'aired_episode_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hasFinishedAiringMeta = const VerificationMeta(
    'hasFinishedAiring',
  );
  @override
  late final GeneratedColumn<bool> hasFinishedAiring = GeneratedColumn<bool>(
    'has_finished_airing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_finished_airing" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seriesId,
    airedEpisodeCount,
    hasFinishedAiring,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series_progress_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesProgressMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('aired_episode_count')) {
      context.handle(
        _airedEpisodeCountMeta,
        airedEpisodeCount.isAcceptableOrUnknown(
          data['aired_episode_count']!,
          _airedEpisodeCountMeta,
        ),
      );
    }
    if (data.containsKey('has_finished_airing')) {
      context.handle(
        _hasFinishedAiringMeta,
        hasFinishedAiring.isAcceptableOrUnknown(
          data['has_finished_airing']!,
          _hasFinishedAiringMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seriesId};
  @override
  SeriesProgressMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesProgressMetaData(
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      )!,
      airedEpisodeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}aired_episode_count'],
      )!,
      hasFinishedAiring: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_finished_airing'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SeriesProgressMetaTable createAlias(String alias) {
    return $SeriesProgressMetaTable(attachedDatabase, alias);
  }
}

class SeriesProgressMetaData extends DataClass
    implements Insertable<SeriesProgressMetaData> {
  final int seriesId;

  /// Aired episodes only. Unaired episodes are excluded, or a caught-up viewer
  /// could never reach 100%.
  final int airedEpisodeCount;
  final bool hasFinishedAiring;
  final DateTime updatedAt;
  const SeriesProgressMetaData({
    required this.seriesId,
    required this.airedEpisodeCount,
    required this.hasFinishedAiring,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['series_id'] = Variable<int>(seriesId);
    map['aired_episode_count'] = Variable<int>(airedEpisodeCount);
    map['has_finished_airing'] = Variable<bool>(hasFinishedAiring);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SeriesProgressMetaCompanion toCompanion(bool nullToAbsent) {
    return SeriesProgressMetaCompanion(
      seriesId: Value(seriesId),
      airedEpisodeCount: Value(airedEpisodeCount),
      hasFinishedAiring: Value(hasFinishedAiring),
      updatedAt: Value(updatedAt),
    );
  }

  factory SeriesProgressMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesProgressMetaData(
      seriesId: serializer.fromJson<int>(json['seriesId']),
      airedEpisodeCount: serializer.fromJson<int>(json['airedEpisodeCount']),
      hasFinishedAiring: serializer.fromJson<bool>(json['hasFinishedAiring']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seriesId': serializer.toJson<int>(seriesId),
      'airedEpisodeCount': serializer.toJson<int>(airedEpisodeCount),
      'hasFinishedAiring': serializer.toJson<bool>(hasFinishedAiring),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SeriesProgressMetaData copyWith({
    int? seriesId,
    int? airedEpisodeCount,
    bool? hasFinishedAiring,
    DateTime? updatedAt,
  }) => SeriesProgressMetaData(
    seriesId: seriesId ?? this.seriesId,
    airedEpisodeCount: airedEpisodeCount ?? this.airedEpisodeCount,
    hasFinishedAiring: hasFinishedAiring ?? this.hasFinishedAiring,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SeriesProgressMetaData copyWithCompanion(SeriesProgressMetaCompanion data) {
    return SeriesProgressMetaData(
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      airedEpisodeCount: data.airedEpisodeCount.present
          ? data.airedEpisodeCount.value
          : this.airedEpisodeCount,
      hasFinishedAiring: data.hasFinishedAiring.present
          ? data.hasFinishedAiring.value
          : this.hasFinishedAiring,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesProgressMetaData(')
          ..write('seriesId: $seriesId, ')
          ..write('airedEpisodeCount: $airedEpisodeCount, ')
          ..write('hasFinishedAiring: $hasFinishedAiring, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(seriesId, airedEpisodeCount, hasFinishedAiring, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesProgressMetaData &&
          other.seriesId == this.seriesId &&
          other.airedEpisodeCount == this.airedEpisodeCount &&
          other.hasFinishedAiring == this.hasFinishedAiring &&
          other.updatedAt == this.updatedAt);
}

class SeriesProgressMetaCompanion
    extends UpdateCompanion<SeriesProgressMetaData> {
  final Value<int> seriesId;
  final Value<int> airedEpisodeCount;
  final Value<bool> hasFinishedAiring;
  final Value<DateTime> updatedAt;
  const SeriesProgressMetaCompanion({
    this.seriesId = const Value.absent(),
    this.airedEpisodeCount = const Value.absent(),
    this.hasFinishedAiring = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SeriesProgressMetaCompanion.insert({
    this.seriesId = const Value.absent(),
    this.airedEpisodeCount = const Value.absent(),
    this.hasFinishedAiring = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<SeriesProgressMetaData> custom({
    Expression<int>? seriesId,
    Expression<int>? airedEpisodeCount,
    Expression<bool>? hasFinishedAiring,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (seriesId != null) 'series_id': seriesId,
      if (airedEpisodeCount != null) 'aired_episode_count': airedEpisodeCount,
      if (hasFinishedAiring != null) 'has_finished_airing': hasFinishedAiring,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SeriesProgressMetaCompanion copyWith({
    Value<int>? seriesId,
    Value<int>? airedEpisodeCount,
    Value<bool>? hasFinishedAiring,
    Value<DateTime>? updatedAt,
  }) {
    return SeriesProgressMetaCompanion(
      seriesId: seriesId ?? this.seriesId,
      airedEpisodeCount: airedEpisodeCount ?? this.airedEpisodeCount,
      hasFinishedAiring: hasFinishedAiring ?? this.hasFinishedAiring,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (airedEpisodeCount.present) {
      map['aired_episode_count'] = Variable<int>(airedEpisodeCount.value);
    }
    if (hasFinishedAiring.present) {
      map['has_finished_airing'] = Variable<bool>(hasFinishedAiring.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesProgressMetaCompanion(')
          ..write('seriesId: $seriesId, ')
          ..write('airedEpisodeCount: $airedEpisodeCount, ')
          ..write('hasFinishedAiring: $hasFinishedAiring, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $FavouritesTable extends Favourites
    with TableInfo<$FavouritesTable, Favourite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavouritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(localUser),
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<int> mediaId = GeneratedColumn<int>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaType, String> mediaType =
      GeneratedColumn<String>(
        'media_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MediaType>($FavouritesTable.$convertermediaType);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [userId, mediaId, mediaType, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favourites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favourite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, mediaId, mediaType};
  @override
  Favourite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favourite(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_id'],
      )!,
      mediaType: $FavouritesTable.$convertermediaType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}media_type'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FavouritesTable createAlias(String alias) {
    return $FavouritesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaType, String, String> $convertermediaType =
      const EnumNameConverter<MediaType>(MediaType.values);
}

class Favourite extends DataClass implements Insertable<Favourite> {
  final String userId;
  final int mediaId;
  final MediaType mediaType;
  final DateTime createdAt;
  const Favourite({
    required this.userId,
    required this.mediaId,
    required this.mediaType,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['media_id'] = Variable<int>(mediaId);
    {
      map['media_type'] = Variable<String>(
        $FavouritesTable.$convertermediaType.toSql(mediaType),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FavouritesCompanion toCompanion(bool nullToAbsent) {
    return FavouritesCompanion(
      userId: Value(userId),
      mediaId: Value(mediaId),
      mediaType: Value(mediaType),
      createdAt: Value(createdAt),
    );
  }

  factory Favourite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favourite(
      userId: serializer.fromJson<String>(json['userId']),
      mediaId: serializer.fromJson<int>(json['mediaId']),
      mediaType: $FavouritesTable.$convertermediaType.fromJson(
        serializer.fromJson<String>(json['mediaType']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'mediaId': serializer.toJson<int>(mediaId),
      'mediaType': serializer.toJson<String>(
        $FavouritesTable.$convertermediaType.toJson(mediaType),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Favourite copyWith({
    String? userId,
    int? mediaId,
    MediaType? mediaType,
    DateTime? createdAt,
  }) => Favourite(
    userId: userId ?? this.userId,
    mediaId: mediaId ?? this.mediaId,
    mediaType: mediaType ?? this.mediaType,
    createdAt: createdAt ?? this.createdAt,
  );
  Favourite copyWithCompanion(FavouritesCompanion data) {
    return Favourite(
      userId: data.userId.present ? data.userId.value : this.userId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favourite(')
          ..write('userId: $userId, ')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, mediaId, mediaType, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favourite &&
          other.userId == this.userId &&
          other.mediaId == this.mediaId &&
          other.mediaType == this.mediaType &&
          other.createdAt == this.createdAt);
}

class FavouritesCompanion extends UpdateCompanion<Favourite> {
  final Value<String> userId;
  final Value<int> mediaId;
  final Value<MediaType> mediaType;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FavouritesCompanion({
    this.userId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavouritesCompanion.insert({
    this.userId = const Value.absent(),
    required int mediaId,
    required MediaType mediaType,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : mediaId = Value(mediaId),
       mediaType = Value(mediaType);
  static Insertable<Favourite> custom({
    Expression<String>? userId,
    Expression<int>? mediaId,
    Expression<String>? mediaType,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (mediaId != null) 'media_id': mediaId,
      if (mediaType != null) 'media_type': mediaType,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavouritesCompanion copyWith({
    Value<String>? userId,
    Value<int>? mediaId,
    Value<MediaType>? mediaType,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FavouritesCompanion(
      userId: userId ?? this.userId,
      mediaId: mediaId ?? this.mediaId,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<int>(mediaId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(
        $FavouritesTable.$convertermediaType.toSql(mediaType.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavouritesCompanion(')
          ..write('userId: $userId, ')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonalListsTable extends PersonalLists
    with TableInfo<$PersonalListsTable, PersonalListRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonalListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(localUser),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    description,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'personal_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonalListRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonalListRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonalListRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PersonalListsTable createAlias(String alias) {
    return $PersonalListsTable(attachedDatabase, alias);
  }
}

class PersonalListRow extends DataClass implements Insertable<PersonalListRow> {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final DateTime createdAt;
  const PersonalListRow({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PersonalListsCompanion toCompanion(bool nullToAbsent) {
    return PersonalListsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory PersonalListRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonalListRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PersonalListRow copyWith({
    String? id,
    String? userId,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
  }) => PersonalListRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
  );
  PersonalListRow copyWithCompanion(PersonalListsCompanion data) {
    return PersonalListRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonalListRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, name, description, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonalListRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class PersonalListsCompanion extends UpdateCompanion<PersonalListRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PersonalListsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonalListsCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<PersonalListRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonalListsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PersonalListsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonalListsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListItemsTable extends ListItems
    with TableInfo<$ListItemsTable, ListItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES personal_lists (id)',
    ),
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<int> mediaId = GeneratedColumn<int>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaType, String> mediaType =
      GeneratedColumn<String>(
        'media_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MediaType>($ListItemsTable.$convertermediaType);
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    listId,
    mediaId,
    mediaType,
    position,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'list_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {listId, mediaId, mediaType};
  @override
  ListItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListItem(
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_id'],
      )!,
      mediaType: $ListItemsTable.$convertermediaType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}media_type'],
        )!,
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $ListItemsTable createAlias(String alias) {
    return $ListItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaType, String, String> $convertermediaType =
      const EnumNameConverter<MediaType>(MediaType.values);
}

class ListItem extends DataClass implements Insertable<ListItem> {
  final String listId;
  final int mediaId;
  final MediaType mediaType;
  final int position;
  final DateTime addedAt;
  const ListItem({
    required this.listId,
    required this.mediaId,
    required this.mediaType,
    required this.position,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['list_id'] = Variable<String>(listId);
    map['media_id'] = Variable<int>(mediaId);
    {
      map['media_type'] = Variable<String>(
        $ListItemsTable.$convertermediaType.toSql(mediaType),
      );
    }
    map['position'] = Variable<int>(position);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  ListItemsCompanion toCompanion(bool nullToAbsent) {
    return ListItemsCompanion(
      listId: Value(listId),
      mediaId: Value(mediaId),
      mediaType: Value(mediaType),
      position: Value(position),
      addedAt: Value(addedAt),
    );
  }

  factory ListItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListItem(
      listId: serializer.fromJson<String>(json['listId']),
      mediaId: serializer.fromJson<int>(json['mediaId']),
      mediaType: $ListItemsTable.$convertermediaType.fromJson(
        serializer.fromJson<String>(json['mediaType']),
      ),
      position: serializer.fromJson<int>(json['position']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'listId': serializer.toJson<String>(listId),
      'mediaId': serializer.toJson<int>(mediaId),
      'mediaType': serializer.toJson<String>(
        $ListItemsTable.$convertermediaType.toJson(mediaType),
      ),
      'position': serializer.toJson<int>(position),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  ListItem copyWith({
    String? listId,
    int? mediaId,
    MediaType? mediaType,
    int? position,
    DateTime? addedAt,
  }) => ListItem(
    listId: listId ?? this.listId,
    mediaId: mediaId ?? this.mediaId,
    mediaType: mediaType ?? this.mediaType,
    position: position ?? this.position,
    addedAt: addedAt ?? this.addedAt,
  );
  ListItem copyWithCompanion(ListItemsCompanion data) {
    return ListItem(
      listId: data.listId.present ? data.listId.value : this.listId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      position: data.position.present ? data.position.value : this.position,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListItem(')
          ..write('listId: $listId, ')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('position: $position, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(listId, mediaId, mediaType, position, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListItem &&
          other.listId == this.listId &&
          other.mediaId == this.mediaId &&
          other.mediaType == this.mediaType &&
          other.position == this.position &&
          other.addedAt == this.addedAt);
}

class ListItemsCompanion extends UpdateCompanion<ListItem> {
  final Value<String> listId;
  final Value<int> mediaId;
  final Value<MediaType> mediaType;
  final Value<int> position;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const ListItemsCompanion({
    this.listId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.position = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListItemsCompanion.insert({
    required String listId,
    required int mediaId,
    required MediaType mediaType,
    this.position = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : listId = Value(listId),
       mediaId = Value(mediaId),
       mediaType = Value(mediaType);
  static Insertable<ListItem> custom({
    Expression<String>? listId,
    Expression<int>? mediaId,
    Expression<String>? mediaType,
    Expression<int>? position,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (listId != null) 'list_id': listId,
      if (mediaId != null) 'media_id': mediaId,
      if (mediaType != null) 'media_type': mediaType,
      if (position != null) 'position': position,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListItemsCompanion copyWith({
    Value<String>? listId,
    Value<int>? mediaId,
    Value<MediaType>? mediaType,
    Value<int>? position,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return ListItemsCompanion(
      listId: listId ?? this.listId,
      mediaId: mediaId ?? this.mediaId,
      mediaType: mediaType ?? this.mediaType,
      position: position ?? this.position,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<int>(mediaId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(
        $ListItemsTable.$convertermediaType.toSql(mediaType.value),
      );
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListItemsCompanion(')
          ..write('listId: $listId, ')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('position: $position, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, UserRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordSaltMeta = const VerificationMeta(
    'passwordSalt',
  );
  @override
  late final GeneratedColumn<String> passwordSalt = GeneratedColumn<String>(
    'password_salt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
    'bio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarPathMeta = const VerificationMeta(
    'avatarPath',
  );
  @override
  late final GeneratedColumn<String> avatarPath = GeneratedColumn<String>(
    'avatar_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('user'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firstName,
    lastName,
    username,
    passwordHash,
    passwordSalt,
    bio,
    avatarPath,
    role,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('password_salt')) {
      context.handle(
        _passwordSaltMeta,
        passwordSalt.isAcceptableOrUnknown(
          data['password_salt']!,
          _passwordSaltMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordSaltMeta);
    }
    if (data.containsKey('bio')) {
      context.handle(
        _bioMeta,
        bio.isAcceptableOrUnknown(data['bio']!, _bioMeta),
      );
    }
    if (data.containsKey('avatar_path')) {
      context.handle(
        _avatarPathMeta,
        avatarPath.isAcceptableOrUnknown(data['avatar_path']!, _avatarPathMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      passwordSalt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_salt'],
      )!,
      bio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bio'],
      ),
      avatarPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_path'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class UserRow extends DataClass implements Insertable<UserRow> {
  final String id;
  final String firstName;
  final String lastName;
  final String username;

  /// PBKDF2-HMAC-SHA256 output, hex encoded.
  final String passwordHash;

  /// Per-user random salt, so two users with the same password do not share a
  /// hash and a precomputed table is useless.
  final String passwordSalt;
  final String? bio;
  final String? avatarPath;
  final String role;
  final DateTime createdAt;
  const UserRow({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.passwordHash,
    required this.passwordSalt,
    this.bio,
    this.avatarPath,
    required this.role,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    map['username'] = Variable<String>(username);
    map['password_hash'] = Variable<String>(passwordHash);
    map['password_salt'] = Variable<String>(passwordSalt);
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    if (!nullToAbsent || avatarPath != null) {
      map['avatar_path'] = Variable<String>(avatarPath);
    }
    map['role'] = Variable<String>(role);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      firstName: Value(firstName),
      lastName: Value(lastName),
      username: Value(username),
      passwordHash: Value(passwordHash),
      passwordSalt: Value(passwordSalt),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      avatarPath: avatarPath == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarPath),
      role: Value(role),
      createdAt: Value(createdAt),
    );
  }

  factory UserRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRow(
      id: serializer.fromJson<String>(json['id']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      username: serializer.fromJson<String>(json['username']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      passwordSalt: serializer.fromJson<String>(json['passwordSalt']),
      bio: serializer.fromJson<String?>(json['bio']),
      avatarPath: serializer.fromJson<String?>(json['avatarPath']),
      role: serializer.fromJson<String>(json['role']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'username': serializer.toJson<String>(username),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'passwordSalt': serializer.toJson<String>(passwordSalt),
      'bio': serializer.toJson<String?>(bio),
      'avatarPath': serializer.toJson<String?>(avatarPath),
      'role': serializer.toJson<String>(role),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  UserRow copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? username,
    String? passwordHash,
    String? passwordSalt,
    Value<String?> bio = const Value.absent(),
    Value<String?> avatarPath = const Value.absent(),
    String? role,
    DateTime? createdAt,
  }) => UserRow(
    id: id ?? this.id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    username: username ?? this.username,
    passwordHash: passwordHash ?? this.passwordHash,
    passwordSalt: passwordSalt ?? this.passwordSalt,
    bio: bio.present ? bio.value : this.bio,
    avatarPath: avatarPath.present ? avatarPath.value : this.avatarPath,
    role: role ?? this.role,
    createdAt: createdAt ?? this.createdAt,
  );
  UserRow copyWithCompanion(UsersCompanion data) {
    return UserRow(
      id: data.id.present ? data.id.value : this.id,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      username: data.username.present ? data.username.value : this.username,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      passwordSalt: data.passwordSalt.present
          ? data.passwordSalt.value
          : this.passwordSalt,
      bio: data.bio.present ? data.bio.value : this.bio,
      avatarPath: data.avatarPath.present
          ? data.avatarPath.value
          : this.avatarPath,
      role: data.role.present ? data.role.value : this.role,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRow(')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('passwordSalt: $passwordSalt, ')
          ..write('bio: $bio, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    firstName,
    lastName,
    username,
    passwordHash,
    passwordSalt,
    bio,
    avatarPath,
    role,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow &&
          other.id == this.id &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.username == this.username &&
          other.passwordHash == this.passwordHash &&
          other.passwordSalt == this.passwordSalt &&
          other.bio == this.bio &&
          other.avatarPath == this.avatarPath &&
          other.role == this.role &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<UserRow> {
  final Value<String> id;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String> username;
  final Value<String> passwordHash;
  final Value<String> passwordSalt;
  final Value<String?> bio;
  final Value<String?> avatarPath;
  final Value<String> role;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.username = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.passwordSalt = const Value.absent(),
    this.bio = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.role = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String firstName,
    required String lastName,
    required String username,
    required String passwordHash,
    required String passwordSalt,
    this.bio = const Value.absent(),
    this.avatarPath = const Value.absent(),
    this.role = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       firstName = Value(firstName),
       lastName = Value(lastName),
       username = Value(username),
       passwordHash = Value(passwordHash),
       passwordSalt = Value(passwordSalt);
  static Insertable<UserRow> custom({
    Expression<String>? id,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? username,
    Expression<String>? passwordHash,
    Expression<String>? passwordSalt,
    Expression<String>? bio,
    Expression<String>? avatarPath,
    Expression<String>? role,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (username != null) 'username': username,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (passwordSalt != null) 'password_salt': passwordSalt,
      if (bio != null) 'bio': bio,
      if (avatarPath != null) 'avatar_path': avatarPath,
      if (role != null) 'role': role,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? firstName,
    Value<String>? lastName,
    Value<String>? username,
    Value<String>? passwordHash,
    Value<String>? passwordSalt,
    Value<String?>? bio,
    Value<String?>? avatarPath,
    Value<String>? role,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (passwordSalt.present) {
      map['password_salt'] = Variable<String>(passwordSalt.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (avatarPath.present) {
      map['avatar_path'] = Variable<String>(avatarPath.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('passwordSalt: $passwordSalt, ')
          ..write('bio: $bio, ')
          ..write('avatarPath: $avatarPath, ')
          ..write('role: $role, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RatingsTable extends Ratings with TableInfo<$RatingsTable, Rating> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RatingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(localUser),
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<int> mediaId = GeneratedColumn<int>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaType, String> mediaType =
      GeneratedColumn<String>(
        'media_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MediaType>($RatingsTable.$convertermediaType);
  static const VerificationMeta _starsMeta = const VerificationMeta('stars');
  @override
  late final GeneratedColumn<int> stars = GeneratedColumn<int>(
    'stars',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    mediaId,
    mediaType,
    stars,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ratings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Rating> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('stars')) {
      context.handle(
        _starsMeta,
        stars.isAcceptableOrUnknown(data['stars']!, _starsMeta),
      );
    } else if (isInserting) {
      context.missing(_starsMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, mediaId, mediaType};
  @override
  Rating map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Rating(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_id'],
      )!,
      mediaType: $RatingsTable.$convertermediaType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}media_type'],
        )!,
      ),
      stars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stars'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RatingsTable createAlias(String alias) {
    return $RatingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaType, String, String> $convertermediaType =
      const EnumNameConverter<MediaType>(MediaType.values);
}

class Rating extends DataClass implements Insertable<Rating> {
  final String userId;
  final int mediaId;
  final MediaType mediaType;
  final int stars;
  final DateTime updatedAt;
  const Rating({
    required this.userId,
    required this.mediaId,
    required this.mediaType,
    required this.stars,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['media_id'] = Variable<int>(mediaId);
    {
      map['media_type'] = Variable<String>(
        $RatingsTable.$convertermediaType.toSql(mediaType),
      );
    }
    map['stars'] = Variable<int>(stars);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RatingsCompanion toCompanion(bool nullToAbsent) {
    return RatingsCompanion(
      userId: Value(userId),
      mediaId: Value(mediaId),
      mediaType: Value(mediaType),
      stars: Value(stars),
      updatedAt: Value(updatedAt),
    );
  }

  factory Rating.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Rating(
      userId: serializer.fromJson<String>(json['userId']),
      mediaId: serializer.fromJson<int>(json['mediaId']),
      mediaType: $RatingsTable.$convertermediaType.fromJson(
        serializer.fromJson<String>(json['mediaType']),
      ),
      stars: serializer.fromJson<int>(json['stars']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'mediaId': serializer.toJson<int>(mediaId),
      'mediaType': serializer.toJson<String>(
        $RatingsTable.$convertermediaType.toJson(mediaType),
      ),
      'stars': serializer.toJson<int>(stars),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Rating copyWith({
    String? userId,
    int? mediaId,
    MediaType? mediaType,
    int? stars,
    DateTime? updatedAt,
  }) => Rating(
    userId: userId ?? this.userId,
    mediaId: mediaId ?? this.mediaId,
    mediaType: mediaType ?? this.mediaType,
    stars: stars ?? this.stars,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Rating copyWithCompanion(RatingsCompanion data) {
    return Rating(
      userId: data.userId.present ? data.userId.value : this.userId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      stars: data.stars.present ? data.stars.value : this.stars,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Rating(')
          ..write('userId: $userId, ')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('stars: $stars, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, mediaId, mediaType, stars, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Rating &&
          other.userId == this.userId &&
          other.mediaId == this.mediaId &&
          other.mediaType == this.mediaType &&
          other.stars == this.stars &&
          other.updatedAt == this.updatedAt);
}

class RatingsCompanion extends UpdateCompanion<Rating> {
  final Value<String> userId;
  final Value<int> mediaId;
  final Value<MediaType> mediaType;
  final Value<int> stars;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RatingsCompanion({
    this.userId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.stars = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RatingsCompanion.insert({
    this.userId = const Value.absent(),
    required int mediaId,
    required MediaType mediaType,
    required int stars,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : mediaId = Value(mediaId),
       mediaType = Value(mediaType),
       stars = Value(stars);
  static Insertable<Rating> custom({
    Expression<String>? userId,
    Expression<int>? mediaId,
    Expression<String>? mediaType,
    Expression<int>? stars,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (mediaId != null) 'media_id': mediaId,
      if (mediaType != null) 'media_type': mediaType,
      if (stars != null) 'stars': stars,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RatingsCompanion copyWith({
    Value<String>? userId,
    Value<int>? mediaId,
    Value<MediaType>? mediaType,
    Value<int>? stars,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return RatingsCompanion(
      userId: userId ?? this.userId,
      mediaId: mediaId ?? this.mediaId,
      mediaType: mediaType ?? this.mediaType,
      stars: stars ?? this.stars,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<int>(mediaId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(
        $RatingsTable.$convertermediaType.toSql(mediaType.value),
      );
    }
    if (stars.present) {
      map['stars'] = Variable<int>(stars.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RatingsCompanion(')
          ..write('userId: $userId, ')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('stars: $stars, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewsTable extends Reviews with TableInfo<$ReviewsTable, ReviewRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(localUser),
  );
  static const VerificationMeta _mediaIdMeta = const VerificationMeta(
    'mediaId',
  );
  @override
  late final GeneratedColumn<int> mediaId = GeneratedColumn<int>(
    'media_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaType, String> mediaType =
      GeneratedColumn<String>(
        'media_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MediaType>($ReviewsTable.$convertermediaType);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hasSpoilerMeta = const VerificationMeta(
    'hasSpoiler',
  );
  @override
  late final GeneratedColumn<bool> hasSpoiler = GeneratedColumn<bool>(
    'has_spoiler',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_spoiler" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    mediaId,
    mediaType,
    body,
    hasSpoiler,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('media_id')) {
      context.handle(
        _mediaIdMeta,
        mediaId.isAcceptableOrUnknown(data['media_id']!, _mediaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('has_spoiler')) {
      context.handle(
        _hasSpoilerMeta,
        hasSpoiler.isAcceptableOrUnknown(data['has_spoiler']!, _hasSpoilerMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      mediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_id'],
      )!,
      mediaType: $ReviewsTable.$convertermediaType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}media_type'],
        )!,
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      hasSpoiler: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_spoiler'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $ReviewsTable createAlias(String alias) {
    return $ReviewsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaType, String, String> $convertermediaType =
      const EnumNameConverter<MediaType>(MediaType.values);
}

class ReviewRow extends DataClass implements Insertable<ReviewRow> {
  final String id;
  final String userId;
  final int mediaId;
  final MediaType mediaType;
  final String body;
  final bool hasSpoiler;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const ReviewRow({
    required this.id,
    required this.userId,
    required this.mediaId,
    required this.mediaType,
    required this.body,
    required this.hasSpoiler,
    required this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['media_id'] = Variable<int>(mediaId);
    {
      map['media_type'] = Variable<String>(
        $ReviewsTable.$convertermediaType.toSql(mediaType),
      );
    }
    map['body'] = Variable<String>(body);
    map['has_spoiler'] = Variable<bool>(hasSpoiler);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  ReviewsCompanion toCompanion(bool nullToAbsent) {
    return ReviewsCompanion(
      id: Value(id),
      userId: Value(userId),
      mediaId: Value(mediaId),
      mediaType: Value(mediaType),
      body: Value(body),
      hasSpoiler: Value(hasSpoiler),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ReviewRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewRow(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      mediaId: serializer.fromJson<int>(json['mediaId']),
      mediaType: $ReviewsTable.$convertermediaType.fromJson(
        serializer.fromJson<String>(json['mediaType']),
      ),
      body: serializer.fromJson<String>(json['body']),
      hasSpoiler: serializer.fromJson<bool>(json['hasSpoiler']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'mediaId': serializer.toJson<int>(mediaId),
      'mediaType': serializer.toJson<String>(
        $ReviewsTable.$convertermediaType.toJson(mediaType),
      ),
      'body': serializer.toJson<String>(body),
      'hasSpoiler': serializer.toJson<bool>(hasSpoiler),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  ReviewRow copyWith({
    String? id,
    String? userId,
    int? mediaId,
    MediaType? mediaType,
    String? body,
    bool? hasSpoiler,
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => ReviewRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    mediaId: mediaId ?? this.mediaId,
    mediaType: mediaType ?? this.mediaType,
    body: body ?? this.body,
    hasSpoiler: hasSpoiler ?? this.hasSpoiler,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  ReviewRow copyWithCompanion(ReviewsCompanion data) {
    return ReviewRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      mediaId: data.mediaId.present ? data.mediaId.value : this.mediaId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      body: data.body.present ? data.body.value : this.body,
      hasSpoiler: data.hasSpoiler.present
          ? data.hasSpoiler.value
          : this.hasSpoiler,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('body: $body, ')
          ..write('hasSpoiler: $hasSpoiler, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    mediaId,
    mediaType,
    body,
    hasSpoiler,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.mediaId == this.mediaId &&
          other.mediaType == this.mediaType &&
          other.body == this.body &&
          other.hasSpoiler == this.hasSpoiler &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ReviewsCompanion extends UpdateCompanion<ReviewRow> {
  final Value<String> id;
  final Value<String> userId;
  final Value<int> mediaId;
  final Value<MediaType> mediaType;
  final Value<String> body;
  final Value<bool> hasSpoiler;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const ReviewsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.mediaId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.body = const Value.absent(),
    this.hasSpoiler = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewsCompanion.insert({
    required String id,
    this.userId = const Value.absent(),
    required int mediaId,
    required MediaType mediaType,
    required String body,
    this.hasSpoiler = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mediaId = Value(mediaId),
       mediaType = Value(mediaType),
       body = Value(body);
  static Insertable<ReviewRow> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<int>? mediaId,
    Expression<String>? mediaType,
    Expression<String>? body,
    Expression<bool>? hasSpoiler,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (mediaId != null) 'media_id': mediaId,
      if (mediaType != null) 'media_type': mediaType,
      if (body != null) 'body': body,
      if (hasSpoiler != null) 'has_spoiler': hasSpoiler,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<int>? mediaId,
    Value<MediaType>? mediaType,
    Value<String>? body,
    Value<bool>? hasSpoiler,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReviewsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mediaId: mediaId ?? this.mediaId,
      mediaType: mediaType ?? this.mediaType,
      body: body ?? this.body,
      hasSpoiler: hasSpoiler ?? this.hasSpoiler,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (mediaId.present) {
      map['media_id'] = Variable<int>(mediaId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(
        $ReviewsTable.$convertermediaType.toSql(mediaType.value),
      );
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (hasSpoiler.present) {
      map['has_spoiler'] = Variable<bool>(hasSpoiler.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('mediaId: $mediaId, ')
          ..write('mediaType: $mediaType, ')
          ..write('body: $body, ')
          ..write('hasSpoiler: $hasSpoiler, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedMediaTable cachedMedia = $CachedMediaTable(this);
  late final $WatchStatusesTable watchStatuses = $WatchStatusesTable(this);
  late final $EpisodeWatchesTable episodeWatches = $EpisodeWatchesTable(this);
  late final $SeriesProgressMetaTable seriesProgressMeta =
      $SeriesProgressMetaTable(this);
  late final $FavouritesTable favourites = $FavouritesTable(this);
  late final $PersonalListsTable personalLists = $PersonalListsTable(this);
  late final $ListItemsTable listItems = $ListItemsTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $RatingsTable ratings = $RatingsTable(this);
  late final $ReviewsTable reviews = $ReviewsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedMedia,
    watchStatuses,
    episodeWatches,
    seriesProgressMeta,
    favourites,
    personalLists,
    listItems,
    users,
    ratings,
    reviews,
  ];
}

typedef $$CachedMediaTableCreateCompanionBuilder =
    CachedMediaCompanion Function({
      required int mediaId,
      required MediaType mediaType,
      required String title,
      Value<String?> posterPath,
      Value<String?> overview,
      Value<String?> releaseDate,
      Value<double?> voteAverage,
      Value<int> runtimeMinutes,
      Value<String> genres,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });
typedef $$CachedMediaTableUpdateCompanionBuilder =
    CachedMediaCompanion Function({
      Value<int> mediaId,
      Value<MediaType> mediaType,
      Value<String> title,
      Value<String?> posterPath,
      Value<String?> overview,
      Value<String?> releaseDate,
      Value<double?> voteAverage,
      Value<int> runtimeMinutes,
      Value<String> genres,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$CachedMediaTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMediaTable> {
  $$CachedMediaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MediaType, MediaType, String> get mediaType =>
      $composableBuilder(
        column: $table.mediaType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMediaTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMediaTable> {
  $$CachedMediaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMediaTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMediaTable> {
  $$CachedMediaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaType, String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get voteAverage => $composableBuilder(
    column: $table.voteAverage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedMediaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedMediaTable,
          CachedMediaData,
          $$CachedMediaTableFilterComposer,
          $$CachedMediaTableOrderingComposer,
          $$CachedMediaTableAnnotationComposer,
          $$CachedMediaTableCreateCompanionBuilder,
          $$CachedMediaTableUpdateCompanionBuilder,
          (
            CachedMediaData,
            BaseReferences<_$AppDatabase, $CachedMediaTable, CachedMediaData>,
          ),
          CachedMediaData,
          PrefetchHooks Function()
        > {
  $$CachedMediaTableTableManager(_$AppDatabase db, $CachedMediaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMediaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMediaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMediaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> mediaId = const Value.absent(),
                Value<MediaType> mediaType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> releaseDate = const Value.absent(),
                Value<double?> voteAverage = const Value.absent(),
                Value<int> runtimeMinutes = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMediaCompanion(
                mediaId: mediaId,
                mediaType: mediaType,
                title: title,
                posterPath: posterPath,
                overview: overview,
                releaseDate: releaseDate,
                voteAverage: voteAverage,
                runtimeMinutes: runtimeMinutes,
                genres: genres,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int mediaId,
                required MediaType mediaType,
                required String title,
                Value<String?> posterPath = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> releaseDate = const Value.absent(),
                Value<double?> voteAverage = const Value.absent(),
                Value<int> runtimeMinutes = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMediaCompanion.insert(
                mediaId: mediaId,
                mediaType: mediaType,
                title: title,
                posterPath: posterPath,
                overview: overview,
                releaseDate: releaseDate,
                voteAverage: voteAverage,
                runtimeMinutes: runtimeMinutes,
                genres: genres,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMediaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedMediaTable,
      CachedMediaData,
      $$CachedMediaTableFilterComposer,
      $$CachedMediaTableOrderingComposer,
      $$CachedMediaTableAnnotationComposer,
      $$CachedMediaTableCreateCompanionBuilder,
      $$CachedMediaTableUpdateCompanionBuilder,
      (
        CachedMediaData,
        BaseReferences<_$AppDatabase, $CachedMediaTable, CachedMediaData>,
      ),
      CachedMediaData,
      PrefetchHooks Function()
    >;
typedef $$WatchStatusesTableCreateCompanionBuilder =
    WatchStatusesCompanion Function({
      Value<String> userId,
      required int mediaId,
      required MediaType mediaType,
      required WatchStatus status,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$WatchStatusesTableUpdateCompanionBuilder =
    WatchStatusesCompanion Function({
      Value<String> userId,
      Value<int> mediaId,
      Value<MediaType> mediaType,
      Value<WatchStatus> status,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$WatchStatusesTableFilterComposer
    extends Composer<_$AppDatabase, $WatchStatusesTable> {
  $$WatchStatusesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MediaType, MediaType, String> get mediaType =>
      $composableBuilder(
        column: $table.mediaType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<WatchStatus, WatchStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WatchStatusesTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchStatusesTable> {
  $$WatchStatusesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WatchStatusesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchStatusesTable> {
  $$WatchStatusesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaType, String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WatchStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WatchStatusesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchStatusesTable,
          WatchStatuse,
          $$WatchStatusesTableFilterComposer,
          $$WatchStatusesTableOrderingComposer,
          $$WatchStatusesTableAnnotationComposer,
          $$WatchStatusesTableCreateCompanionBuilder,
          $$WatchStatusesTableUpdateCompanionBuilder,
          (
            WatchStatuse,
            BaseReferences<_$AppDatabase, $WatchStatusesTable, WatchStatuse>,
          ),
          WatchStatuse,
          PrefetchHooks Function()
        > {
  $$WatchStatusesTableTableManager(_$AppDatabase db, $WatchStatusesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchStatusesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchStatusesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchStatusesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<int> mediaId = const Value.absent(),
                Value<MediaType> mediaType = const Value.absent(),
                Value<WatchStatus> status = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchStatusesCompanion(
                userId: userId,
                mediaId: mediaId,
                mediaType: mediaType,
                status: status,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                required int mediaId,
                required MediaType mediaType,
                required WatchStatus status,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchStatusesCompanion.insert(
                userId: userId,
                mediaId: mediaId,
                mediaType: mediaType,
                status: status,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WatchStatusesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchStatusesTable,
      WatchStatuse,
      $$WatchStatusesTableFilterComposer,
      $$WatchStatusesTableOrderingComposer,
      $$WatchStatusesTableAnnotationComposer,
      $$WatchStatusesTableCreateCompanionBuilder,
      $$WatchStatusesTableUpdateCompanionBuilder,
      (
        WatchStatuse,
        BaseReferences<_$AppDatabase, $WatchStatusesTable, WatchStatuse>,
      ),
      WatchStatuse,
      PrefetchHooks Function()
    >;
typedef $$EpisodeWatchesTableCreateCompanionBuilder =
    EpisodeWatchesCompanion Function({
      Value<String> userId,
      required int episodeId,
      required int seriesId,
      required int seasonNumber,
      required int episodeNumber,
      Value<int> runtimeMinutes,
      Value<DateTime> watchedAt,
      Value<int> rowid,
    });
typedef $$EpisodeWatchesTableUpdateCompanionBuilder =
    EpisodeWatchesCompanion Function({
      Value<String> userId,
      Value<int> episodeId,
      Value<int> seriesId,
      Value<int> seasonNumber,
      Value<int> episodeNumber,
      Value<int> runtimeMinutes,
      Value<DateTime> watchedAt,
      Value<int> rowid,
    });

class $$EpisodeWatchesTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodeWatchesTable> {
  $$EpisodeWatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EpisodeWatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodeWatchesTable> {
  $$EpisodeWatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get watchedAt => $composableBuilder(
    column: $table.watchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpisodeWatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodeWatchesTable> {
  $$EpisodeWatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<int> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get runtimeMinutes => $composableBuilder(
    column: $table.runtimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get watchedAt =>
      $composableBuilder(column: $table.watchedAt, builder: (column) => column);
}

class $$EpisodeWatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodeWatchesTable,
          EpisodeWatche,
          $$EpisodeWatchesTableFilterComposer,
          $$EpisodeWatchesTableOrderingComposer,
          $$EpisodeWatchesTableAnnotationComposer,
          $$EpisodeWatchesTableCreateCompanionBuilder,
          $$EpisodeWatchesTableUpdateCompanionBuilder,
          (
            EpisodeWatche,
            BaseReferences<_$AppDatabase, $EpisodeWatchesTable, EpisodeWatche>,
          ),
          EpisodeWatche,
          PrefetchHooks Function()
        > {
  $$EpisodeWatchesTableTableManager(
    _$AppDatabase db,
    $EpisodeWatchesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodeWatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodeWatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodeWatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<int> episodeId = const Value.absent(),
                Value<int> seriesId = const Value.absent(),
                Value<int> seasonNumber = const Value.absent(),
                Value<int> episodeNumber = const Value.absent(),
                Value<int> runtimeMinutes = const Value.absent(),
                Value<DateTime> watchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodeWatchesCompanion(
                userId: userId,
                episodeId: episodeId,
                seriesId: seriesId,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                runtimeMinutes: runtimeMinutes,
                watchedAt: watchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                required int episodeId,
                required int seriesId,
                required int seasonNumber,
                required int episodeNumber,
                Value<int> runtimeMinutes = const Value.absent(),
                Value<DateTime> watchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodeWatchesCompanion.insert(
                userId: userId,
                episodeId: episodeId,
                seriesId: seriesId,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                runtimeMinutes: runtimeMinutes,
                watchedAt: watchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpisodeWatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodeWatchesTable,
      EpisodeWatche,
      $$EpisodeWatchesTableFilterComposer,
      $$EpisodeWatchesTableOrderingComposer,
      $$EpisodeWatchesTableAnnotationComposer,
      $$EpisodeWatchesTableCreateCompanionBuilder,
      $$EpisodeWatchesTableUpdateCompanionBuilder,
      (
        EpisodeWatche,
        BaseReferences<_$AppDatabase, $EpisodeWatchesTable, EpisodeWatche>,
      ),
      EpisodeWatche,
      PrefetchHooks Function()
    >;
typedef $$SeriesProgressMetaTableCreateCompanionBuilder =
    SeriesProgressMetaCompanion Function({
      Value<int> seriesId,
      Value<int> airedEpisodeCount,
      Value<bool> hasFinishedAiring,
      Value<DateTime> updatedAt,
    });
typedef $$SeriesProgressMetaTableUpdateCompanionBuilder =
    SeriesProgressMetaCompanion Function({
      Value<int> seriesId,
      Value<int> airedEpisodeCount,
      Value<bool> hasFinishedAiring,
      Value<DateTime> updatedAt,
    });

class $$SeriesProgressMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SeriesProgressMetaTable> {
  $$SeriesProgressMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get airedEpisodeCount => $composableBuilder(
    column: $table.airedEpisodeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasFinishedAiring => $composableBuilder(
    column: $table.hasFinishedAiring,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeriesProgressMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SeriesProgressMetaTable> {
  $$SeriesProgressMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get airedEpisodeCount => $composableBuilder(
    column: $table.airedEpisodeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasFinishedAiring => $composableBuilder(
    column: $table.hasFinishedAiring,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeriesProgressMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeriesProgressMetaTable> {
  $$SeriesProgressMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<int> get airedEpisodeCount => $composableBuilder(
    column: $table.airedEpisodeCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasFinishedAiring => $composableBuilder(
    column: $table.hasFinishedAiring,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SeriesProgressMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeriesProgressMetaTable,
          SeriesProgressMetaData,
          $$SeriesProgressMetaTableFilterComposer,
          $$SeriesProgressMetaTableOrderingComposer,
          $$SeriesProgressMetaTableAnnotationComposer,
          $$SeriesProgressMetaTableCreateCompanionBuilder,
          $$SeriesProgressMetaTableUpdateCompanionBuilder,
          (
            SeriesProgressMetaData,
            BaseReferences<
              _$AppDatabase,
              $SeriesProgressMetaTable,
              SeriesProgressMetaData
            >,
          ),
          SeriesProgressMetaData,
          PrefetchHooks Function()
        > {
  $$SeriesProgressMetaTableTableManager(
    _$AppDatabase db,
    $SeriesProgressMetaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesProgressMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesProgressMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesProgressMetaTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> seriesId = const Value.absent(),
                Value<int> airedEpisodeCount = const Value.absent(),
                Value<bool> hasFinishedAiring = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SeriesProgressMetaCompanion(
                seriesId: seriesId,
                airedEpisodeCount: airedEpisodeCount,
                hasFinishedAiring: hasFinishedAiring,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> seriesId = const Value.absent(),
                Value<int> airedEpisodeCount = const Value.absent(),
                Value<bool> hasFinishedAiring = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SeriesProgressMetaCompanion.insert(
                seriesId: seriesId,
                airedEpisodeCount: airedEpisodeCount,
                hasFinishedAiring: hasFinishedAiring,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeriesProgressMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeriesProgressMetaTable,
      SeriesProgressMetaData,
      $$SeriesProgressMetaTableFilterComposer,
      $$SeriesProgressMetaTableOrderingComposer,
      $$SeriesProgressMetaTableAnnotationComposer,
      $$SeriesProgressMetaTableCreateCompanionBuilder,
      $$SeriesProgressMetaTableUpdateCompanionBuilder,
      (
        SeriesProgressMetaData,
        BaseReferences<
          _$AppDatabase,
          $SeriesProgressMetaTable,
          SeriesProgressMetaData
        >,
      ),
      SeriesProgressMetaData,
      PrefetchHooks Function()
    >;
typedef $$FavouritesTableCreateCompanionBuilder =
    FavouritesCompanion Function({
      Value<String> userId,
      required int mediaId,
      required MediaType mediaType,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$FavouritesTableUpdateCompanionBuilder =
    FavouritesCompanion Function({
      Value<String> userId,
      Value<int> mediaId,
      Value<MediaType> mediaType,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$FavouritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavouritesTable> {
  $$FavouritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MediaType, MediaType, String> get mediaType =>
      $composableBuilder(
        column: $table.mediaType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavouritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavouritesTable> {
  $$FavouritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavouritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavouritesTable> {
  $$FavouritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaType, String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$FavouritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavouritesTable,
          Favourite,
          $$FavouritesTableFilterComposer,
          $$FavouritesTableOrderingComposer,
          $$FavouritesTableAnnotationComposer,
          $$FavouritesTableCreateCompanionBuilder,
          $$FavouritesTableUpdateCompanionBuilder,
          (
            Favourite,
            BaseReferences<_$AppDatabase, $FavouritesTable, Favourite>,
          ),
          Favourite,
          PrefetchHooks Function()
        > {
  $$FavouritesTableTableManager(_$AppDatabase db, $FavouritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavouritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavouritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavouritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<int> mediaId = const Value.absent(),
                Value<MediaType> mediaType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavouritesCompanion(
                userId: userId,
                mediaId: mediaId,
                mediaType: mediaType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                required int mediaId,
                required MediaType mediaType,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavouritesCompanion.insert(
                userId: userId,
                mediaId: mediaId,
                mediaType: mediaType,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavouritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavouritesTable,
      Favourite,
      $$FavouritesTableFilterComposer,
      $$FavouritesTableOrderingComposer,
      $$FavouritesTableAnnotationComposer,
      $$FavouritesTableCreateCompanionBuilder,
      $$FavouritesTableUpdateCompanionBuilder,
      (Favourite, BaseReferences<_$AppDatabase, $FavouritesTable, Favourite>),
      Favourite,
      PrefetchHooks Function()
    >;
typedef $$PersonalListsTableCreateCompanionBuilder =
    PersonalListsCompanion Function({
      required String id,
      Value<String> userId,
      required String name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$PersonalListsTableUpdateCompanionBuilder =
    PersonalListsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$PersonalListsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PersonalListsTable, PersonalListRow> {
  $$PersonalListsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ListItemsTable, List<ListItem>>
  _listItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.listItems,
    aliasName: 'personal_lists__id__list_items__list_id',
  );

  $$ListItemsTableProcessedTableManager get listItemsRefs {
    final manager = $$ListItemsTableTableManager(
      $_db,
      $_db.listItems,
    ).filter((f) => f.listId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_listItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PersonalListsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonalListsTable> {
  $$PersonalListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> listItemsRefs(
    Expression<bool> Function($$ListItemsTableFilterComposer f) f,
  ) {
    final $$ListItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listItems,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListItemsTableFilterComposer(
            $db: $db,
            $table: $db.listItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PersonalListsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonalListsTable> {
  $$PersonalListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonalListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonalListsTable> {
  $$PersonalListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> listItemsRefs<T extends Object>(
    Expression<T> Function($$ListItemsTableAnnotationComposer a) f,
  ) {
    final $$ListItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listItems,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.listItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PersonalListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonalListsTable,
          PersonalListRow,
          $$PersonalListsTableFilterComposer,
          $$PersonalListsTableOrderingComposer,
          $$PersonalListsTableAnnotationComposer,
          $$PersonalListsTableCreateCompanionBuilder,
          $$PersonalListsTableUpdateCompanionBuilder,
          (PersonalListRow, $$PersonalListsTableReferences),
          PersonalListRow,
          PrefetchHooks Function({bool listItemsRefs})
        > {
  $$PersonalListsTableTableManager(_$AppDatabase db, $PersonalListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonalListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonalListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonalListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonalListsCompanion(
                id: id,
                userId: userId,
                name: name,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> userId = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonalListsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PersonalListsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({listItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (listItemsRefs) db.listItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (listItemsRefs)
                    await $_getPrefetchedData<
                      PersonalListRow,
                      $PersonalListsTable,
                      ListItem
                    >(
                      currentTable: table,
                      referencedTable: $$PersonalListsTableReferences
                          ._listItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PersonalListsTableReferences(
                            db,
                            table,
                            p0,
                          ).listItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.listId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PersonalListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonalListsTable,
      PersonalListRow,
      $$PersonalListsTableFilterComposer,
      $$PersonalListsTableOrderingComposer,
      $$PersonalListsTableAnnotationComposer,
      $$PersonalListsTableCreateCompanionBuilder,
      $$PersonalListsTableUpdateCompanionBuilder,
      (PersonalListRow, $$PersonalListsTableReferences),
      PersonalListRow,
      PrefetchHooks Function({bool listItemsRefs})
    >;
typedef $$ListItemsTableCreateCompanionBuilder =
    ListItemsCompanion Function({
      required String listId,
      required int mediaId,
      required MediaType mediaType,
      Value<int> position,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });
typedef $$ListItemsTableUpdateCompanionBuilder =
    ListItemsCompanion Function({
      Value<String> listId,
      Value<int> mediaId,
      Value<MediaType> mediaType,
      Value<int> position,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

final class $$ListItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ListItemsTable, ListItem> {
  $$ListItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PersonalListsTable _listIdTable(_$AppDatabase db) =>
      db.personalLists.createAlias('list_items__list_id__personal_lists__id');

  $$PersonalListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<String>('list_id')!;

    final manager = $$PersonalListsTableTableManager(
      $_db,
      $_db.personalLists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ListItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ListItemsTable> {
  $$ListItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MediaType, MediaType, String> get mediaType =>
      $composableBuilder(
        column: $table.mediaType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PersonalListsTableFilterComposer get listId {
    final $$PersonalListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.personalLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonalListsTableFilterComposer(
            $db: $db,
            $table: $db.personalLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ListItemsTable> {
  $$ListItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PersonalListsTableOrderingComposer get listId {
    final $$PersonalListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.personalLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonalListsTableOrderingComposer(
            $db: $db,
            $table: $db.personalLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListItemsTable> {
  $$ListItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaType, String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$PersonalListsTableAnnotationComposer get listId {
    final $$PersonalListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.personalLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonalListsTableAnnotationComposer(
            $db: $db,
            $table: $db.personalLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListItemsTable,
          ListItem,
          $$ListItemsTableFilterComposer,
          $$ListItemsTableOrderingComposer,
          $$ListItemsTableAnnotationComposer,
          $$ListItemsTableCreateCompanionBuilder,
          $$ListItemsTableUpdateCompanionBuilder,
          (ListItem, $$ListItemsTableReferences),
          ListItem,
          PrefetchHooks Function({bool listId})
        > {
  $$ListItemsTableTableManager(_$AppDatabase db, $ListItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> listId = const Value.absent(),
                Value<int> mediaId = const Value.absent(),
                Value<MediaType> mediaType = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListItemsCompanion(
                listId: listId,
                mediaId: mediaId,
                mediaType: mediaType,
                position: position,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String listId,
                required int mediaId,
                required MediaType mediaType,
                Value<int> position = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListItemsCompanion.insert(
                listId: listId,
                mediaId: mediaId,
                mediaType: mediaType,
                position: position,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ListItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({listId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (listId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.listId,
                                referencedTable: $$ListItemsTableReferences
                                    ._listIdTable(db),
                                referencedColumn: $$ListItemsTableReferences
                                    ._listIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ListItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListItemsTable,
      ListItem,
      $$ListItemsTableFilterComposer,
      $$ListItemsTableOrderingComposer,
      $$ListItemsTableAnnotationComposer,
      $$ListItemsTableCreateCompanionBuilder,
      $$ListItemsTableUpdateCompanionBuilder,
      (ListItem, $$ListItemsTableReferences),
      ListItem,
      PrefetchHooks Function({bool listId})
    >;
typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String id,
      required String firstName,
      required String lastName,
      required String username,
      required String passwordHash,
      required String passwordSalt,
      Value<String?> bio,
      Value<String?> avatarPath,
      Value<String> role,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      Value<String> firstName,
      Value<String> lastName,
      Value<String> username,
      Value<String> passwordHash,
      Value<String> passwordSalt,
      Value<String?> bio,
      Value<String?> avatarPath,
      Value<String> role,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordSalt => $composableBuilder(
    column: $table.passwordSalt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordSalt => $composableBuilder(
    column: $table.passwordSalt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get passwordSalt => $composableBuilder(
    column: $table.passwordSalt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<String> get avatarPath => $composableBuilder(
    column: $table.avatarPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          UserRow,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (UserRow, BaseReferences<_$AppDatabase, $UsersTable, UserRow>),
          UserRow,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<String> passwordSalt = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                firstName: firstName,
                lastName: lastName,
                username: username,
                passwordHash: passwordHash,
                passwordSalt: passwordSalt,
                bio: bio,
                avatarPath: avatarPath,
                role: role,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String firstName,
                required String lastName,
                required String username,
                required String passwordHash,
                required String passwordSalt,
                Value<String?> bio = const Value.absent(),
                Value<String?> avatarPath = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                firstName: firstName,
                lastName: lastName,
                username: username,
                passwordHash: passwordHash,
                passwordSalt: passwordSalt,
                bio: bio,
                avatarPath: avatarPath,
                role: role,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      UserRow,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (UserRow, BaseReferences<_$AppDatabase, $UsersTable, UserRow>),
      UserRow,
      PrefetchHooks Function()
    >;
typedef $$RatingsTableCreateCompanionBuilder =
    RatingsCompanion Function({
      Value<String> userId,
      required int mediaId,
      required MediaType mediaType,
      required int stars,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$RatingsTableUpdateCompanionBuilder =
    RatingsCompanion Function({
      Value<String> userId,
      Value<int> mediaId,
      Value<MediaType> mediaType,
      Value<int> stars,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$RatingsTableFilterComposer
    extends Composer<_$AppDatabase, $RatingsTable> {
  $$RatingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MediaType, MediaType, String> get mediaType =>
      $composableBuilder(
        column: $table.mediaType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RatingsTableOrderingComposer
    extends Composer<_$AppDatabase, $RatingsTable> {
  $$RatingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RatingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RatingsTable> {
  $$RatingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaType, String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<int> get stars =>
      $composableBuilder(column: $table.stars, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RatingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RatingsTable,
          Rating,
          $$RatingsTableFilterComposer,
          $$RatingsTableOrderingComposer,
          $$RatingsTableAnnotationComposer,
          $$RatingsTableCreateCompanionBuilder,
          $$RatingsTableUpdateCompanionBuilder,
          (Rating, BaseReferences<_$AppDatabase, $RatingsTable, Rating>),
          Rating,
          PrefetchHooks Function()
        > {
  $$RatingsTableTableManager(_$AppDatabase db, $RatingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RatingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RatingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RatingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<int> mediaId = const Value.absent(),
                Value<MediaType> mediaType = const Value.absent(),
                Value<int> stars = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RatingsCompanion(
                userId: userId,
                mediaId: mediaId,
                mediaType: mediaType,
                stars: stars,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                required int mediaId,
                required MediaType mediaType,
                required int stars,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RatingsCompanion.insert(
                userId: userId,
                mediaId: mediaId,
                mediaType: mediaType,
                stars: stars,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RatingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RatingsTable,
      Rating,
      $$RatingsTableFilterComposer,
      $$RatingsTableOrderingComposer,
      $$RatingsTableAnnotationComposer,
      $$RatingsTableCreateCompanionBuilder,
      $$RatingsTableUpdateCompanionBuilder,
      (Rating, BaseReferences<_$AppDatabase, $RatingsTable, Rating>),
      Rating,
      PrefetchHooks Function()
    >;
typedef $$ReviewsTableCreateCompanionBuilder =
    ReviewsCompanion Function({
      required String id,
      Value<String> userId,
      required int mediaId,
      required MediaType mediaType,
      required String body,
      Value<bool> hasSpoiler,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$ReviewsTableUpdateCompanionBuilder =
    ReviewsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<int> mediaId,
      Value<MediaType> mediaType,
      Value<String> body,
      Value<bool> hasSpoiler,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

class $$ReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewsTable> {
  $$ReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MediaType, MediaType, String> get mediaType =>
      $composableBuilder(
        column: $table.mediaType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasSpoiler => $composableBuilder(
    column: $table.hasSpoiler,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewsTable> {
  $$ReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mediaId => $composableBuilder(
    column: $table.mediaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasSpoiler => $composableBuilder(
    column: $table.hasSpoiler,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewsTable> {
  $$ReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get mediaId =>
      $composableBuilder(column: $table.mediaId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaType, String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<bool> get hasSpoiler => $composableBuilder(
    column: $table.hasSpoiler,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewsTable,
          ReviewRow,
          $$ReviewsTableFilterComposer,
          $$ReviewsTableOrderingComposer,
          $$ReviewsTableAnnotationComposer,
          $$ReviewsTableCreateCompanionBuilder,
          $$ReviewsTableUpdateCompanionBuilder,
          (ReviewRow, BaseReferences<_$AppDatabase, $ReviewsTable, ReviewRow>),
          ReviewRow,
          PrefetchHooks Function()
        > {
  $$ReviewsTableTableManager(_$AppDatabase db, $ReviewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int> mediaId = const Value.absent(),
                Value<MediaType> mediaType = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<bool> hasSpoiler = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewsCompanion(
                id: id,
                userId: userId,
                mediaId: mediaId,
                mediaType: mediaType,
                body: body,
                hasSpoiler: hasSpoiler,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> userId = const Value.absent(),
                required int mediaId,
                required MediaType mediaType,
                required String body,
                Value<bool> hasSpoiler = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewsCompanion.insert(
                id: id,
                userId: userId,
                mediaId: mediaId,
                mediaType: mediaType,
                body: body,
                hasSpoiler: hasSpoiler,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewsTable,
      ReviewRow,
      $$ReviewsTableFilterComposer,
      $$ReviewsTableOrderingComposer,
      $$ReviewsTableAnnotationComposer,
      $$ReviewsTableCreateCompanionBuilder,
      $$ReviewsTableUpdateCompanionBuilder,
      (ReviewRow, BaseReferences<_$AppDatabase, $ReviewsTable, ReviewRow>),
      ReviewRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedMediaTableTableManager get cachedMedia =>
      $$CachedMediaTableTableManager(_db, _db.cachedMedia);
  $$WatchStatusesTableTableManager get watchStatuses =>
      $$WatchStatusesTableTableManager(_db, _db.watchStatuses);
  $$EpisodeWatchesTableTableManager get episodeWatches =>
      $$EpisodeWatchesTableTableManager(_db, _db.episodeWatches);
  $$SeriesProgressMetaTableTableManager get seriesProgressMeta =>
      $$SeriesProgressMetaTableTableManager(_db, _db.seriesProgressMeta);
  $$FavouritesTableTableManager get favourites =>
      $$FavouritesTableTableManager(_db, _db.favourites);
  $$PersonalListsTableTableManager get personalLists =>
      $$PersonalListsTableTableManager(_db, _db.personalLists);
  $$ListItemsTableTableManager get listItems =>
      $$ListItemsTableTableManager(_db, _db.listItems);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$RatingsTableTableManager get ratings =>
      $$RatingsTableTableManager(_db, _db.ratings);
  $$ReviewsTableTableManager get reviews =>
      $$ReviewsTableTableManager(_db, _db.reviews);
}
