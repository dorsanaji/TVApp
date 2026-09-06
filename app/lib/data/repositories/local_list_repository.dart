import 'package:drift/drift.dart';

import '../../core/error/error_mapper.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/media_summary.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/list_repository.dart';
import '../local/app_database.dart';

/// FR-17 §5.17 — user-created personal lists, worth 6 points.
class LocalListRepository implements ListRepository {
  LocalListRepository(this._db, this._auth);

  final AppDatabase _db;
  final AuthRepository _auth;

  /// The owner of every list. See the note in `LocalTrackingRepository`:
  /// scoping to a constant let one account see another's lists (NFR-16).
  String get _userId => _auth.currentUserOrNull?.id ?? localUser;

  /// §4.1 makes signing in a precondition for keeping personal lists.
  String _requireUserId() {
    final id = _auth.currentUserOrNull?.id;
    if (id == null) throw const UnauthorizedFailure();
    return id;
  }

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } catch (e, stack) {
      return Err(ErrorMapper.fromUnknown(e, stack));
    }
  }

  /// Ids are generated locally. Time-ordered so lists sort naturally by
  /// creation without a separate sequence.
  String _newId() => 'list_${DateTime.now().microsecondsSinceEpoch}';

  @override
  Future<Result<List<PersonalList>>> lists() {
    return _guard(() async {
      final rows =
          await (_db.select(_db.personalLists)
                ..where((t) => t.userId.equals(_userId))
                ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
              .get();

      // Item counts and covers in two set-based queries rather than two per
      // list, so a user with twenty lists still costs three queries total.
      final counts = await _itemCounts();
      final covers = await _covers();

      return [
        for (final row in rows)
          PersonalList(
            id: row.id,
            name: row.name,
            description: row.description,
            itemCount: counts[row.id] ?? 0,
            coverPath: covers[row.id],
            createdAt: row.createdAt,
          ),
      ];
    });
  }

  Future<Map<String, int>> _itemCounts() async {
    final count = _db.listItems.mediaId.count();
    final query = _db.selectOnly(_db.listItems)
      ..addColumns([_db.listItems.listId, count])
      ..groupBy([_db.listItems.listId]);

    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(_db.listItems.listId)!: row.read(count) ?? 0,
    };
  }

  /// Poster of each list's first item, used as its cover.
  Future<Map<String, String>> _covers() async {
    final query = _db.select(_db.listItems).join([
      innerJoin(
        _db.cachedMedia,
        _db.cachedMedia.mediaId.equalsExp(_db.listItems.mediaId) &
            _db.cachedMedia.mediaType.equalsExp(_db.listItems.mediaType),
      ),
    ])..orderBy([OrderingTerm.asc(_db.listItems.position)]);

    final rows = await query.get();
    final covers = <String, String>{};
    for (final row in rows) {
      final listId = row.readTable(_db.listItems).listId;
      final poster = row.readTable(_db.cachedMedia).posterPath;
      if (poster != null && !covers.containsKey(listId)) {
        covers[listId] = poster;
      }
    }
    return covers;
  }

  @override
  Future<Result<PersonalList>> createList({
    required String name,
    String? description,
  }) {
    return _guard(() async {
      _requireUserId();
      final trimmed = name.trim();
      // NFR-10 — validated before it reaches storage. An unnamed list cannot
      // be told apart from another unnamed list.
      if (trimmed.isEmpty) {
        throw const ValidationFailure(
          'نام فهرست نمی‌تواند خالی باشد',
          field: 'name',
        );
      }

      final id = _newId();
      await _db
          .into(_db.personalLists)
          .insert(
            PersonalListsCompanion.insert(
              id: id,
              userId: Value(_userId),
              name: trimmed,
              description: Value(description?.trim()),
            ),
          );

      return PersonalList(
        id: id,
        name: trimmed,
        description: description?.trim(),
        itemCount: 0,
        createdAt: DateTime.now(),
      );
    });
  }

  @override
  Future<Result<PersonalList>> renameList(String listId, String name) {
    return _guard(() async {
      _requireUserId();
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        throw const ValidationFailure(
          'نام فهرست نمی‌تواند خالی باشد',
          field: 'name',
        );
      }

      await (_db.update(_db.personalLists)..where((t) => t.id.equals(listId)))
          .write(PersonalListsCompanion(name: Value(trimmed)));

      final row = await (_db.select(
        _db.personalLists,
      )..where((t) => t.id.equals(listId))).getSingle();
      final counts = await _itemCounts();

      return PersonalList(
        id: row.id,
        name: row.name,
        description: row.description,
        itemCount: counts[row.id] ?? 0,
        createdAt: row.createdAt,
      );
    });
  }

  @override
  Future<Result<void>> deleteList(String listId) {
    return _guard(() async {
      _requireUserId();
      // Items first: the foreign key would otherwise reject the delete.
      await _db.transaction(() async {
        await (_db.delete(
          _db.listItems,
        )..where((t) => t.listId.equals(listId))).go();
        await (_db.delete(
          _db.personalLists,
        )..where((t) => t.id.equals(listId))).go();
      });
    });
  }

  @override
  Future<Result<List<MediaSummary>>> itemsOf(String listId) {
    return _guard(() async {
      final query =
          _db.select(_db.listItems).join([
              innerJoin(
                _db.cachedMedia,
                _db.cachedMedia.mediaId.equalsExp(_db.listItems.mediaId) &
                    _db.cachedMedia.mediaType.equalsExp(
                      _db.listItems.mediaType,
                    ),
              ),
            ])
            ..where(_db.listItems.listId.equals(listId))
            ..orderBy([OrderingTerm.asc(_db.listItems.position)]);

      final rows = await query.get();
      return rows.map((r) {
        final media = r.readTable(_db.cachedMedia);
        return MediaSummary(
          id: media.mediaId,
          type: media.mediaType,
          title: media.title,
          posterPath: media.posterPath,
          overview: media.overview,
          releaseDate: media.releaseDate,
          voteAverage: media.voteAverage,
        );
      }).toList();
    });
  }

  @override
  Future<Result<void>> addToList(String listId, MediaSummary item) {
    return _guard(() async {
      _requireUserId();
      await _db.transaction(() async {
        // The card must render offline once added (NFR-20), so the title is
        // cached alongside the membership row.
        //
        // `insertOrIgnore`, not an upsert: a [MediaSummary] carries no runtime
        // or genres, and overwriting a richer row cached by a detail screen
        // would quietly empty the FR-19 statistics.
        await _db
            .into(_db.cachedMedia)
            .insert(
              mode: InsertMode.insertOrIgnore,
              CachedMediaCompanion.insert(
                mediaId: item.id,
                mediaType: item.type,
                title: item.title,
                posterPath: Value(item.posterPath),
                overview: Value(item.overview),
                releaseDate: Value(item.releaseDate),
                voteAverage: Value(item.voteAverage),
              ),
            );

        final position = await _nextPosition(listId);
        // Upsert on (listId, mediaId, mediaType): adding twice is a no-op
        // rather than a duplicate row.
        await _db
            .into(_db.listItems)
            .insertOnConflictUpdate(
              ListItemsCompanion.insert(
                listId: listId,
                mediaId: item.id,
                mediaType: item.type,
                position: Value(position),
              ),
            );
      });
    });
  }

  Future<int> _nextPosition(String listId) async {
    final max = _db.listItems.position.max();
    final query = _db.selectOnly(_db.listItems)
      ..addColumns([max])
      ..where(_db.listItems.listId.equals(listId));

    final row = await query.getSingleOrNull();
    return (row?.read(max) ?? -1) + 1;
  }

  @override
  Future<Result<void>> removeFromList(
    String listId,
    int mediaId,
    MediaType type,
  ) {
    return _guard(() async {
      _requireUserId();
      await (_db.delete(_db.listItems)..where(
            (t) =>
                t.listId.equals(listId) &
                t.mediaId.equals(mediaId) &
                t.mediaType.equalsValue(type),
          ))
          .go();
    });
  }

  @override
  Future<Result<Set<String>>> listIdsContaining(int mediaId, MediaType type) {
    return _guard(() async {
      // Joined to `personal_lists` so the result is restricted to this user's
      // lists. `list_items` carries no owner of its own — it inherits one from
      // its parent list — so querying it by media alone would return list ids
      // belonging to other accounts (NFR-16).
      final query =
          _db.select(_db.listItems).join([
            innerJoin(
              _db.personalLists,
              _db.personalLists.id.equalsExp(_db.listItems.listId) &
                  _db.personalLists.userId.equals(_userId),
            ),
          ])..where(
            _db.listItems.mediaId.equals(mediaId) &
                _db.listItems.mediaType.equalsValue(type),
          );

      final rows = await query.get();
      return rows.map((r) => r.readTable(_db.listItems).listId).toSet();
    });
  }
}
