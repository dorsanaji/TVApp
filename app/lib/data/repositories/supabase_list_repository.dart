import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/error_mapper.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/media_summary.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/list_repository.dart';

/// FR-17 — the user's own lists, held in Supabase so they follow the account.
///
/// Distinct from the shared `custom_lists` of the social feature: these are
/// private, have no collaborators, and are never published. Their rows are
/// visible only to their owner, enforced by policy rather than by this code.
class SupabaseListRepository implements ListRepository {
  SupabaseListRepository(this._client, this._auth);

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
      debugPrint('[SupabaseListRepository] $e\n$stack');
      return Err(ErrorMapper.fromUnknown(e, stack));
    }
  }

  @override
  Future<Result<List<PersonalList>>> lists() {
    return _guard(() async {
      final rows = await _client
          .from('personal_lists')
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false);

      final lists = (rows as List).cast<Map<String, dynamic>>();
      if (lists.isEmpty) return <PersonalList>[];

      // Counts and covers for every list in two reads rather than two per
      // list — the lists screen draws all of them at once.
      final ids = lists.map((l) => l['id'] as String).toList();
      final itemRows = await _client
          .from('personal_list_items')
          .select('list_id,media_id,media_type,position')
          .inFilter('list_id', ids)
          .order('position');

      final items = (itemRows as List).cast<Map<String, dynamic>>();
      final byList = <String, List<Map<String, dynamic>>>{};
      for (final item in items) {
        byList.putIfAbsent(item['list_id'] as String, () => []).add(item);
      }

      final covers = await _postersFor(items);

      return [
        for (final list in lists)
          () {
            final contents = byList[list['id']] ?? const [];
            final first = contents.isEmpty ? null : contents.first;
            return PersonalList(
              id: list['id'] as String,
              name: list['name'] as String? ?? '',
              description: list['description'] as String?,
              itemCount: contents.length,
              coverPath: first == null
                  ? null
                  : covers['${first['media_id']}:${first['media_type']}'],
              createdAt: DateTime.tryParse(list['created_at'] as String? ?? ''),
            );
          }(),
      ];
    });
  }

  @override
  Future<Result<PersonalList>> createList({
    required String name,
    String? description,
  }) {
    return _guard(() async {
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        throw const ValidationFailure('نام فهرست نمی‌تواند خالی باشد');
      }

      final id = 'plist_${DateTime.now().microsecondsSinceEpoch}';
      await _client.from('personal_lists').insert({
        'id': id,
        'user_id': _userId,
        'name': trimmed,
        'description': description?.trim(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

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
      final trimmed = name.trim();
      if (trimmed.isEmpty) {
        throw const ValidationFailure('نام فهرست نمی‌تواند خالی باشد');
      }

      await _client
          .from('personal_lists')
          .update({'name': trimmed})
          .match({'id': listId, 'user_id': _userId});

      final row = await _client
          .from('personal_lists')
          .select()
          .eq('id', listId)
          .maybeSingle();
      if (row == null) throw const NotFoundFailure();

      final count = await _client
          .from('personal_list_items')
          .count(CountOption.exact)
          .eq('list_id', listId);

      return PersonalList(
        id: listId,
        name: row['name'] as String? ?? trimmed,
        description: row['description'] as String?,
        itemCount: count,
        createdAt: DateTime.tryParse(row['created_at'] as String? ?? ''),
      );
    });
  }

  @override
  Future<Result<void>> deleteList(String listId) {
    return _guard(() async {
      // Items go with it through the foreign key's cascade.
      await _client
          .from('personal_lists')
          .delete()
          .match({'id': listId, 'user_id': _userId});
    });
  }

  @override
  Future<Result<List<MediaSummary>>> itemsOf(String listId) {
    return _guard(() async {
      final rows = await _client
          .from('personal_list_items')
          .select('media_id,media_type,position')
          .eq('list_id', listId)
          .order('position');

      final items = (rows as List).cast<Map<String, dynamic>>();
      if (items.isEmpty) return <MediaSummary>[];

      final ids = items.map((i) => (i['media_id'] as num).toInt()).toList();
      final cachedRows = await _client
          .from('cached_media')
          .select()
          .inFilter('media_id', ids);

      final cached = {
        for (final row in (cachedRows as List).cast<Map<String, dynamic>>())
          '${row['media_id']}:${row['media_type']}': row,
      };

      return [
        for (final item in items)
          if (cached['${item['media_id']}:${item['media_type']}']
              case final row?)
            MediaSummary(
              id: (row['media_id'] as num).toInt(),
              type: row['media_type'] == MediaType.series.name
                  ? MediaType.series
                  : MediaType.movie,
              title: row['title'] as String? ?? '',
              posterPath: row['poster_path'] as String?,
              overview: row['overview'] as String?,
              releaseDate: row['release_date'] as String?,
              voteAverage: (row['vote_average'] as num?)?.toDouble(),
            ),
      ];
    });
  }

  @override
  Future<Result<void>> addToList(String listId, MediaSummary item) {
    return _guard(() async {
      // Cache the title first, or the list would hold a reference to
      // something it cannot draw.
      await _client.from('cached_media').upsert({
        'media_id': item.id,
        'media_type': item.type.name,
        'title': item.title,
        'poster_path': item.posterPath,
        'overview': item.overview,
        'release_date': item.releaseDate,
        'vote_average': item.voteAverage,
        'cached_at': DateTime.now().toUtc().toIso8601String(),
      });

      final position = await _client
          .from('personal_list_items')
          .count(CountOption.exact)
          .eq('list_id', listId);

      // The composite key makes this idempotent: adding a title already in
      // the list moves nothing rather than duplicating it.
      await _client.from('personal_list_items').upsert({
        'list_id': listId,
        'media_id': item.id,
        'media_type': item.type.name,
        'position': position,
        'added_at': DateTime.now().toUtc().toIso8601String(),
      });
    });
  }

  @override
  Future<Result<void>> removeFromList(
    String listId,
    int mediaId,
    MediaType type,
  ) {
    return _guard(() async {
      await _client.from('personal_list_items').delete().match({
        'list_id': listId,
        'media_id': mediaId,
        'media_type': type.name,
      });
    });
  }

  @override
  Future<Result<Set<String>>> listIdsContaining(int mediaId, MediaType type) {
    return _guard(() async {
      final mine = await _client
          .from('personal_lists')
          .select('id')
          .eq('user_id', _userId);

      final ids = (mine as List)
          .cast<Map<String, dynamic>>()
          .map((l) => l['id'] as String)
          .toList();
      if (ids.isEmpty) return <String>{};

      final rows = await _client
          .from('personal_list_items')
          .select('list_id')
          .match({'media_id': mediaId, 'media_type': type.name})
          .inFilter('list_id', ids);

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map((r) => r['list_id'] as String)
          .toSet();
    });
  }

  /// Poster paths for a set of list items, keyed by id and type together so a
  /// film and a series sharing an id do not borrow each other's artwork.
  Future<Map<String, String?>> _postersFor(
    List<Map<String, dynamic>> items,
  ) async {
    if (items.isEmpty) return {};

    final ids = items.map((i) => (i['media_id'] as num).toInt()).toSet();
    final rows = await _client
        .from('cached_media')
        .select('media_id,media_type,poster_path')
        .inFilter('media_id', ids.toList());

    return {
      for (final row in (rows as List).cast<Map<String, dynamic>>())
        '${row['media_id']}:${row['media_type']}':
            row['poster_path'] as String?,
    };
  }
}
