import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/error_mapper.dart';
import '../../core/error/failure.dart';
import '../../core/error/result.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/media_summary.dart';
import '../../domain/entities/social/collaboration_request.dart';
import '../../domain/entities/social/custom_list.dart';
import '../../domain/entities/social/custom_list_item.dart';
import '../../domain/entities/social/list_collaborator.dart';
import '../../domain/entities/social/public_profile.dart';
import '../../domain/entities/social/social_activity.dart';
import '../../domain/repositories/social_repository.dart';
import '../local/app_database.dart';
import '../remote/supabase/supabase_mapper.dart';
import '../remote/supabase/supabase_tables.dart';


/// Implementation of [SocialRepository] backed by Supabase with an in-memory
/// fallback for offline resilience, testing, and unconfigured states.
///
/// Clean Architecture: encapsulates BaaS details inside the data layer.
class SupabaseSocialRepository implements SocialRepository {
  SupabaseSocialRepository({
    SupabaseClient? client,
    AppDatabase? db,
  })  : _client = client,
        _db = db {
    _seedInitialProfiles();
  }

  final SupabaseClient? _client;
  final AppDatabase? _db;

  // ── Offline / In-Memory Mock Fallback Storage ──────────────────────────
  static final Map<String, PublicProfile> _mockProfiles = {};
  static final Set<String> _mockFollows = {}; // 'followerId:followedId'
  static final Map<String, CustomList> _mockLists = {};
  static final Map<String, List<ListCollaborator>> _mockCollaborators = {};
  static final Map<String, List<CustomListItem>> _mockListItems = {};
  static final List<SocialActivity> _mockActivities = [];
  static final Map<String, List<CollaborationRequest>> _mockRequests = {};

  // Stream controllers for real-time reactivity in offline/mock mode
  static final StreamController<CustomList?> _listStreamController =
      StreamController<CustomList?>.broadcast();
  static final StreamController<List<ListCollaborator>> _collabStreamController =
      StreamController<List<ListCollaborator>>.broadcast();
  static final StreamController<List<CustomListItem>> _itemsStreamController =
      StreamController<List<CustomListItem>>.broadcast();
  static final StreamController<List<CollaborationRequest>> _requestStreamController =
      StreamController<List<CollaborationRequest>>.broadcast();
  static final StreamController<List<SocialActivity>> _activityStreamController =
      StreamController<List<SocialActivity>>.broadcast();

  /// Visible for testing to reset mock storage between test runs.
  @visibleForTesting
  static void resetMockStorage() {
    _mockProfiles.clear();
    _mockFollows.clear();
    _mockLists.clear();
    _mockCollaborators.clear();
    _mockListItems.clear();
    _mockActivities.clear();
    _mockRequests.clear();
  }

  void _seedInitialProfiles() {
    if (_mockProfiles.isNotEmpty) return;
    _mockProfiles['u_sara'] = const PublicProfile(
      userId: 'u_sara',
      username: 'sara_movie',
      bio: 'منتقد سینما، عاشق فیلم‌های نولان و تارکوفسکی 🎬',
      totalWatched: 74,
      favoriteGenre: 'علمی‌تخیلی',
      followersCount: 15,
      followingCount: 8,
    );
    _mockProfiles['u_reza'] = const PublicProfile(
      userId: 'u_reza',
      username: 'reza_film',
      bio: 'شیفته سینمای کلاسیک، فیلم‌های نوآر و تاریخ سینما 🍿',
      totalWatched: 112,
      favoriteGenre: 'درام',
      followersCount: 26,
      followingCount: 14,
    );
    _mockProfiles['u_maryam'] = const PublicProfile(
      userId: 'u_maryam',
      username: 'maryam_cinema',
      bio: 'نویسنده و تماشاگر پرشور فیلم‌های مستقل و بین‌المللی 🎥',
      totalWatched: 58,
      favoriteGenre: 'انیمیشن',
      followersCount: 19,
      followingCount: 11,
    );
  }

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } catch (e, stack) {
      debugPrint('[SupabaseSocialRepository] Error: $e\n$stack');
      return Err(ErrorMapper.fromUnknown(e, stack));
    }
  }

  // ── Public Profile Operations ─────────────────────────────────────────

  @override
  Future<Result<PublicProfile>> getProfile(String userId) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        var data = await client
            .from(SupabaseTables.publicProfiles)
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        data ??= await client
            .from(SupabaseTables.publicProfiles)
            .select()
            .ilike('username', userId)
            .maybeSingle();

        if (data != null) {
          final realUserId = data['user_id'] as String;
          final followersRes = await client
              .from(SupabaseTables.userFollows)
              .count(CountOption.exact)
              .eq('followed_id', realUserId);
          final followingRes = await client
              .from(SupabaseTables.userFollows)
              .count(CountOption.exact)
              .eq('follower_id', realUserId);

          return SupabaseMapper.profileFromMap(
            data,
            followers: followersRes,
            following: followingRes,
          );
        }
      }

      // 1. Check local database for registered users
      final db = _db;
      if (db != null) {
        final row = await (db.select(db.users)..where(
          (t) => t.id.equals(userId) | t.username.equals(userId),
        )).getSingleOrNull();

        if (row != null) {
          final watchedCount = await (db.select(db.watchStatuses)..where(
            (t) => t.userId.equals(row.id) & t.status.equalsValue(WatchStatus.watched),
          )).get().then((list) => list.length);

          final followers = _mockFollows.where((f) => f.endsWith(':${row.id}')).length;
          final following = _mockFollows.where((f) => f.startsWith('${row.id}:')).length;

          return PublicProfile(
            userId: row.id,
            username: row.username,
            bio: row.bio ?? '${row.firstName} ${row.lastName}'.trim(),
            avatarUrl: row.avatarPath,
            totalWatched: watchedCount,
            followersCount: followers,
            followingCount: following,
          );
        }
      }

      // 2. Check mock/seed profiles by exact ID
      final byId = _mockProfiles[userId];
      if (byId != null) {
        final followers = _mockFollows.where((f) => f.endsWith(':${byId.userId}')).length;
        final following = _mockFollows.where((f) => f.startsWith('${byId.userId}:')).length;
        return byId.copyWith(
          followersCount: byId.followersCount + followers,
          followingCount: byId.followingCount + following,
        );
      }

      // 3. Check mock/seed profiles by username
      for (final p in _mockProfiles.values) {
        if (p.username.toLowerCase() == userId.toLowerCase()) {
          final followers = _mockFollows.where((f) => f.endsWith(':${p.userId}')).length;
          final following = _mockFollows.where((f) => f.startsWith('${p.userId}:')).length;
          return p.copyWith(
            followersCount: p.followersCount + followers,
            followingCount: p.followingCount + following,
          );
        }
      }

      throw const NotFoundFailure(
        message: 'کاربری با این شناسه یا نام کاربری یافت نشد',
      );
    });
  }

  @override
  Future<Result<List<PublicProfile>>> searchUsers(String query) {
    return _guard(() async {
      final q = query.trim().toLowerCase();
      final results = <String, PublicProfile>{};

      // 1. Registered users in local database
      final db = _db;
      if (db != null) {
        final rows = await (db.select(db.users)..where(
          (t) =>
              q.isEmpty
                  ? const Constant(true)
                  : (t.username.like('%$q%') |
                     t.firstName.like('%$q%') |
                     t.lastName.like('%$q%')),
        )).get();

        for (final row in rows) {
          final watchedCount = await (db.select(db.watchStatuses)..where(
            (t) => t.userId.equals(row.id) & t.status.equalsValue(WatchStatus.watched),
          )).get().then((list) => list.length);

          final followers = _mockFollows.where((f) => f.endsWith(':${row.id}')).length;
          final following = _mockFollows.where((f) => f.startsWith('${row.id}:')).length;

          results[row.id] = PublicProfile(
            userId: row.id,
            username: row.username,
            bio: row.bio ?? '${row.firstName} ${row.lastName}'.trim(),
            avatarUrl: row.avatarPath,
            totalWatched: watchedCount,
            followersCount: followers,
            followingCount: following,
          );
        }
      }

      // 2. In-memory / seed profiles
      for (final p in _mockProfiles.values) {
        if (q.isEmpty ||
            p.username.toLowerCase().contains(q) ||
            p.userId.toLowerCase().contains(q) ||
            (p.bio?.toLowerCase().contains(q) ?? false)) {
          final followers = _mockFollows.where((f) => f.endsWith(':${p.userId}')).length;
          final following = _mockFollows.where((f) => f.startsWith('${p.userId}:')).length;
          results.putIfAbsent(
            p.userId,
            () => p.copyWith(
              followersCount: p.followersCount + followers,
              followingCount: p.followingCount + following,
            ),
          );
        }
      }

      // 3. Supabase if configured
      final client = _client;
      if (client != null) {
        final queryBuilder = client
            .from(SupabaseTables.publicProfiles)
            .select();
        final data = q.isNotEmpty
            ? await queryBuilder
                .or('username.ilike.%$q%,user_id.ilike.%$q%,bio.ilike.%$q%')
                .limit(30)
            : await queryBuilder.limit(30);
        for (final map in (data as List)) {
          final p = SupabaseMapper.profileFromMap(map as Map<String, dynamic>);
          results[p.userId] = p;
        }
      }

      return results.values.toList();
    });
  }


  @override
  Future<Result<PublicProfile>> upsertProfile(PublicProfile profile) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        final map = SupabaseMapper.profileToMap(profile);
        final res = await client
            .from(SupabaseTables.publicProfiles)
            .upsert(map)
            .select()
            .single();
        return SupabaseMapper.profileFromMap(res);
      } else {
        _mockProfiles[profile.userId] = profile;
        return profile;
      }
    });
  }

  @override
  Future<Result<void>> followUser({
    required String followerId,
    required String followedId,
  }) {
    return _guard(() async {
      var resolvedFollowedId = followedId;
      final prof = await getProfile(followedId);
      if (prof.isOk) {
        resolvedFollowedId = prof.valueOrNull!.userId;
      }

      var resolvedFollowerId = followerId;
      final fProf = await getProfile(followerId);
      if (fProf.isOk) {
        resolvedFollowerId = fProf.valueOrNull!.userId;
      }

      if (resolvedFollowerId == resolvedFollowedId) {
        throw const ValidationFailure('نمی‌توانید خودتان را دنبال کنید');
      }

      final client = _client;
      if (client != null) {
        await client.from(SupabaseTables.userFollows).upsert({
          'follower_id': resolvedFollowerId,
          'followed_id': resolvedFollowedId,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      } else {
        _mockFollows.add('$resolvedFollowerId:$resolvedFollowedId');
      }
    });
  }

  @override
  Future<Result<void>> unfollowUser({
    required String followerId,
    required String followedId,
  }) {
    return _guard(() async {
      var resolvedFollowedId = followedId;
      final prof = await getProfile(followedId);
      if (prof.isOk) {
        resolvedFollowedId = prof.valueOrNull!.userId;
      }

      var resolvedFollowerId = followerId;
      final fProf = await getProfile(followerId);
      if (fProf.isOk) {
        resolvedFollowerId = fProf.valueOrNull!.userId;
      }

      final client = _client;
      if (client != null) {
        await client
            .from(SupabaseTables.userFollows)
            .delete()
            .match({'follower_id': resolvedFollowerId, 'followed_id': resolvedFollowedId});
      } else {
        _mockFollows.remove('$resolvedFollowerId:$resolvedFollowedId');
      }
    });
  }

  @override
  Future<Result<bool>> isFollowing({
    required String followerId,
    required String followedId,
  }) {
    return _guard(() async {
      var resolvedFollowedId = followedId;
      final prof = await getProfile(followedId);
      if (prof.isOk) {
        resolvedFollowedId = prof.valueOrNull!.userId;
      }

      var resolvedFollowerId = followerId;
      final fProf = await getProfile(followerId);
      if (fProf.isOk) {
        resolvedFollowerId = fProf.valueOrNull!.userId;
      }

      final client = _client;
      if (client != null) {
        final res = await client
            .from(SupabaseTables.userFollows)
            .select()
            .match({'follower_id': resolvedFollowerId, 'followed_id': resolvedFollowedId})
            .maybeSingle();
        return res != null;
      } else {
        return _mockFollows.contains('$resolvedFollowerId:$resolvedFollowedId');
      }
    });
  }

  @override
  Future<Result<List<String>>> getFollowedUserIds(String userId) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        final res = await client
            .from(SupabaseTables.userFollows)
            .select('followed_id')
            .eq('follower_id', userId);
        return (res as List)
            .cast<Map<String, dynamic>>()
            .map((r) => r['followed_id'] as String)
            .toList();
      } else {
        return _mockFollows
            .where((key) => key.startsWith('$userId:'))
            .map((key) => key.split(':')[1])
            .toList();
      }
    });
  }

  // ── Custom Collaborative Lists ────────────────────────────────────────

  @override
  Future<Result<CustomList>> createList({
    required String ownerId,
    required String title,
    String? description,
    bool isPublic = true,
  }) {
    return _guard(() async {
      final listId = 'list_${DateTime.now().microsecondsSinceEpoch}';
      final now = DateTime.now();

      final list = CustomList(
        listId: listId,
        ownerId: ownerId,
        title: title.trim(),
        description: description?.trim(),
        isPublic: isPublic,
        itemCount: 0,
        collaboratorCount: 0,
        createdAt: now,
        updatedAt: now,
      );

      final client = _client;
      if (client != null) {
        final map = SupabaseMapper.customListToMap(list);
        await client.from(SupabaseTables.customLists).insert(map);
      } else {
        _mockLists[listId] = list;
        _mockCollaborators[listId] = [];
        _mockListItems[listId] = [];
        _listStreamController.add(list);
      }

      return list;
    });
  }

  @override
  Future<Result<CustomList>> getList(String listId) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        final res = await client
            .from(SupabaseTables.customLists)
            .select()
            .eq('list_id', listId)
            .maybeSingle();

        if (res == null) throw const NotFoundFailure();

        final collabCount = await client
            .from(SupabaseTables.listCollaborators)
            .count(CountOption.exact)
            .eq('list_id', listId);

        return SupabaseMapper.customListFromMap(
          res,
          collaboratorCount: collabCount,
        );
      } else {
        final list = _mockLists[listId];
        if (list == null) throw const NotFoundFailure();
        return list;
      }
    });
  }

  @override
  Future<Result<List<CustomList>>> getPublicListsOfUser(String userId) {
    return _guard(() async {
      var resolvedUserId = userId;
      final prof = await getProfile(userId);
      if (prof.isOk) {
        resolvedUserId = prof.valueOrNull!.userId;
      }

      final client = _client;
      if (client != null) {
        final res = await client
            .from(SupabaseTables.customLists)
            .select()
            .eq('owner_id', resolvedUserId)
            .eq('is_public', true)
            .order('created_at', ascending: false);

        return (res as List)
            .cast<Map<String, dynamic>>()
            .map(SupabaseMapper.customListFromMap)
            .toList();
      } else {
        return _mockLists.values
            .where((l) => l.ownerId == resolvedUserId && l.isPublic)
            .toList();
      }
    });
  }

  @override
  Future<Result<List<CustomList>>> getUserAccessibleLists(String userId) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        final profile = await getProfile(userId).then((r) => r.valueOrNull);
        final realId = profile?.userId ?? userId;

        // Fetch lists where user is owner
        final ownedRes = await client
            .from(SupabaseTables.customLists)
            .select()
            .eq('owner_id', realId);

        // Fetch list_ids where user is collaborator
        final collabRes = await client
            .from(SupabaseTables.listCollaborators)
            .select('list_id')
            .eq('user_id', realId);

        final collabListIds = (collabRes as List)
            .cast<Map<String, dynamic>>()
            .map((r) => r['list_id'] as String)
            .toSet();

        final List<Map<String, dynamic>> collabListsRes;
        if (collabListIds.isNotEmpty) {
          final fetched = await client
              .from(SupabaseTables.customLists)
              .select()
              .inFilter('list_id', collabListIds.toList());
          collabListsRes = (fetched as List).cast<Map<String, dynamic>>();
        } else {
          collabListsRes = [];
        }

        final allMaps = <String, Map<String, dynamic>>{};
        for (final m in (ownedRes as List).cast<Map<String, dynamic>>()) {
          allMaps[m['list_id'] as String] = m;
        }
        for (final m in collabListsRes) {
          allMaps[m['list_id'] as String] = m;
        }

        return allMaps.values
            .map(SupabaseMapper.customListFromMap)
            .toList();
      } else {
        final result = <CustomList>[];
        for (final l in _mockLists.values) {
          if (l.ownerId == userId) {
            result.add(l);
          } else {
            final collabs = _mockCollaborators[l.listId] ?? [];
            if (collabs.any((c) => c.userId == userId)) {
              result.add(l);
            }
          }
        }
        return result;
      }
    });
  }

  @override
  Future<Result<List<CustomList>>> getAllPublicLists() {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        final res = await client
            .from(SupabaseTables.customLists)
            .select()
            .eq('is_public', true)
            .order('updated_at', ascending: false);
        return (res as List)
            .cast<Map<String, dynamic>>()
            .map(SupabaseMapper.customListFromMap)
            .toList();
      } else {
        return _mockLists.values.where((l) => l.isPublic).toList();
      }
    });
  }

  @override
  Future<Result<Set<String>>> getCollaborativeListIdsContaining({
    required int mediaId,
    required MediaType mediaType,
  }) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        final res = await client
            .from(SupabaseTables.customListItems)
            .select('list_id')
            .eq('media_id', mediaId)
            .eq('media_type', mediaType.name);
        return (res as List)
            .cast<Map<String, dynamic>>()
            .map((r) => r['list_id'] as String)
            .toSet();
      } else {
        final set = <String>{};
        for (final entry in _mockListItems.entries) {
          if (entry.value.any((item) =>
              item.mediaId == mediaId && item.mediaType == mediaType)) {
            set.add(entry.key);
          }
        }
        return set;
      }
    });
  }

  @override
  Future<Result<CustomList>> updateList(CustomList list) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        final map = SupabaseMapper.customListToMap(list);
        await client
            .from(SupabaseTables.customLists)
            .update(map)
            .eq('list_id', list.listId);
      } else {
        _mockLists[list.listId] = list;
        _listStreamController.add(list);
      }
      return list;
    });
  }

  @override
  Future<Result<void>> deleteList(String listId) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        await client
            .from(SupabaseTables.customLists)
            .delete()
            .eq('list_id', listId);
      } else {
        _mockLists.remove(listId);
        _mockCollaborators.remove(listId);
        _mockListItems.remove(listId);
        _listStreamController.add(null);
      }
    });
  }

  @override
  Stream<CustomList?> watchList(String listId) async* {
    final client = _client;
    if (client != null) {
      CustomList? initial;
      try {
        final direct = await getList(listId);
        if (direct.isOk) {
          initial = direct.valueOrNull;
          if (initial != null) {
            yield initial;
          }
        }
      } catch (_) {}

      try {
        final stream = client
            .from(SupabaseTables.customLists)
            .stream(primaryKey: ['list_id'])
            .eq('list_id', listId)
            .map((data) {
          if (data.isNotEmpty) {
            return SupabaseMapper.customListFromMap(data.first);
          }
          return initial;
        }).handleError((Object e) {
          debugPrint('[SupabaseSocialRepository] Realtime watchList error: $e');
        });
        yield* stream;
      } catch (_) {
        if (initial != null) {
          yield initial;
        }
      }
    } else {
      yield _mockLists[listId];
      yield* _listStreamController.stream.map((_) => _mockLists[listId]);
    }
  }

  // ── List Collaborators ────────────────────────────────────────────────

  @override
  Future<Result<void>> addCollaborator({
    required String listId,
    required String userId,
  }) {
    return _guard(() async {
      var resolvedUserId = userId;
      String? resolvedUsername;
      String? resolvedAvatarUrl;

      // Try resolving user by username or userId
      final profileRes = await getProfile(userId);
      final profile = profileRes.valueOrNull;
      if (profile != null) {
        resolvedUserId = profile.userId;
        resolvedUsername = profile.username;
        resolvedAvatarUrl = profile.avatarUrl;
      }

      final collab = ListCollaborator(
        listId: listId,
        userId: resolvedUserId,
        username: resolvedUsername,
        avatarUrl: resolvedAvatarUrl,
        addedAt: DateTime.now(),
      );

      final client = _client;
      if (client != null) {
        await client
            .from(SupabaseTables.listCollaborators)
            .upsert(SupabaseMapper.collaboratorToMap(collab));

        await client.from(SupabaseTables.customLists).update({
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('list_id', listId);
      } else {
        final list = _mockCollaborators.putIfAbsent(listId, () => []);
        if (!list.any((c) => c.userId == resolvedUserId)) {
          list.add(collab);
        }
        final existingList = _mockLists[listId];
        if (existingList != null) {
          final updatedList = existingList.copyWith(
            collaboratorCount: list.length,
          );
          _mockLists[listId] = updatedList;
          _listStreamController.add(updatedList);
        }
        _collabStreamController.add(list);
      }
    });
  }

  @override
  Future<Result<void>> removeCollaborator({
    required String listId,
    required String userId,
  }) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        await client
            .from(SupabaseTables.listCollaborators)
            .delete()
            .match({'list_id': listId, 'user_id': userId});
      } else {
        final list = _mockCollaborators[listId];
        list?.removeWhere((c) => c.userId == userId);
        final existingList = _mockLists[listId];
        if (existingList != null) {
          final updatedList = existingList.copyWith(
            collaboratorCount: list?.length ?? 0,
          );
          _mockLists[listId] = updatedList;
          _listStreamController.add(updatedList);
        }
        _collabStreamController.add(list ?? []);
      }
    });
  }

  @override
  Future<Result<List<ListCollaborator>>> getCollaborators(String listId) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        final res = await client
            .from(SupabaseTables.listCollaborators)
            .select()
            .eq('list_id', listId);

        return (res as List)
            .cast<Map<String, dynamic>>()
            .map(SupabaseMapper.collaboratorFromMap)
            .toList();
      } else {
        return List.from(_mockCollaborators[listId] ?? []);
      }
    });
  }

  @override
  Future<Result<bool>> isCollaborator({
    required String listId,
    required String userId,
  }) {
    return _guard(() async {
      final listRes = await getList(listId);
      final list = listRes.valueOrNull;
      if (list != null && list.isOwner(userId)) return true;

      final client = _client;
      if (client != null) {
        final res = await client
            .from(SupabaseTables.listCollaborators)
            .select()
            .match({'list_id': listId, 'user_id': userId})
            .maybeSingle();
        return res != null;
      } else {
        final collabs = _mockCollaborators[listId] ?? [];
        return collabs.any((c) => c.userId == userId);
      }
    });
  }

  @override
  Stream<List<ListCollaborator>> watchCollaborators(String listId) async* {
    final client = _client;
    if (client != null) {
      List<ListCollaborator>? initialCollabs;
      try {
        final res = await getCollaborators(listId);
        initialCollabs = res.valueOrNull;
        if (initialCollabs != null) {
          yield initialCollabs;
        }
      } catch (_) {}

      try {
        final stream = client
            .from(SupabaseTables.listCollaborators)
            .stream(primaryKey: ['list_id', 'user_id'])
            .eq('list_id', listId)
            .map((data) {
          final mapped = data.map(SupabaseMapper.collaboratorFromMap).toList();
          if (mapped.isEmpty && initialCollabs != null && initialCollabs.isNotEmpty) {
            return initialCollabs;
          }
          return mapped;
        }).handleError((Object e) {
          debugPrint('[SupabaseSocialRepository] Realtime watchCollaborators error: $e');
        });
        yield* stream;
      } catch (_) {
        if (initialCollabs != null) {
          yield initialCollabs;
        }
      }
    } else {
      yield List<ListCollaborator>.from(_mockCollaborators[listId] ?? []);
      yield* _collabStreamController.stream.map(
        (_) => List<ListCollaborator>.from(_mockCollaborators[listId] ?? []),
      );
    }
  }

  // ── Collaboration Access Requests ─────────────────────────────────────

  @override
  Future<Result<void>> requestCollaboratorAccess({
    required String listId,
    required String userId,
  }) {
    return _guard(() async {
      final listRes = await getList(listId);
      final list = listRes.valueOrNull;
      final listTitle = list?.title ?? 'فهرست مشترک';

      final profileRes = await getProfile(userId);
      final profile = profileRes.valueOrNull;
      final username = profile?.username ?? 'کاربر';
      final avatarUrl = profile?.avatarUrl;

      final req = CollaborationRequest(
        requestId: 'collab_req_${listId}_$userId',
        listId: listId,
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
        createdAt: DateTime.now(),
        status: CollaborationRequestStatus.pending,
      );

      final client = _client;
      if (client != null) {
        await client.from(SupabaseTables.socialActivities).upsert({
          'activity_id': req.requestId,
          'user_id': userId,
          'action_type': 'collab_request',
          'movie_id': 0,
          'movie_title': listId,
          'movie_poster': null,
          'username': username,
          'user_avatar': avatarUrl,
          'rating': null,
          'review_text': 'pending',
          'list_title': listTitle,
          'created_at': req.createdAt.toUtc().toIso8601String(),
        });
      }

      final listReqs = _mockRequests.putIfAbsent(listId, () => []);
      listReqs.removeWhere((r) => r.userId == userId);
      listReqs.add(req);
      _requestStreamController.add(List.from(listReqs));
    });
  }

  @override
  Future<Result<void>> cancelCollaboratorRequest({
    required String listId,
    required String userId,
  }) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        await client
            .from(SupabaseTables.socialActivities)
            .delete()
            .eq('activity_id', 'collab_req_${listId}_$userId');
      }

      final listReqs = _mockRequests[listId];
      listReqs?.removeWhere((r) => r.userId == userId);
      _requestStreamController.add(List.from(listReqs ?? []));
    });
  }

  @override
  Future<Result<void>> acceptCollaboratorRequest({
    required String listId,
    required String userId,
  }) {
    return _guard(() async {
      // 1. Officially add the user to list_collaborators
      await addCollaborator(listId: listId, userId: userId);

      // 2. Remove the pending request
      final client = _client;
      if (client != null) {
        await client
            .from(SupabaseTables.socialActivities)
            .delete()
            .eq('activity_id', 'collab_req_${listId}_$userId');
      }

      final listReqs = _mockRequests[listId];
      listReqs?.removeWhere((r) => r.userId == userId);
      _requestStreamController.add(List.from(listReqs ?? []));
    });
  }

  @override
  Future<Result<void>> rejectCollaboratorRequest({
    required String listId,
    required String userId,
  }) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        await client
            .from(SupabaseTables.socialActivities)
            .delete()
            .eq('activity_id', 'collab_req_${listId}_$userId');
      }

      final listReqs = _mockRequests[listId];
      listReqs?.removeWhere((r) => r.userId == userId);
      _requestStreamController.add(List.from(listReqs ?? []));
    });
  }

  @override
  Future<Result<List<CollaborationRequest>>> getCollaborationRequests(String listId) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        final res = await client
            .from(SupabaseTables.socialActivities)
            .select()
            .eq('action_type', 'collab_request')
            .eq('movie_title', listId)
            .eq('review_text', 'pending');

        return (res as List).cast<Map<String, dynamic>>().map((m) {
          return CollaborationRequest(
            requestId: m['activity_id'] as String? ?? '',
            listId: m['movie_title'] as String? ?? listId,
            userId: m['user_id'] as String? ?? '',
            username: m['username'] as String? ?? 'کاربر',
            avatarUrl: m['user_avatar'] as String?,
            createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
            status: CollaborationRequestStatus.fromString(m['review_text'] as String? ?? 'pending'),
          );
        }).toList();
      } else {
        return List.from(_mockRequests[listId] ?? []);
      }
    });
  }

  @override
  Stream<List<CollaborationRequest>> watchCollaborationRequests(String listId) async* {
    final client = _client;
    if (client != null) {
      List<CollaborationRequest>? initial;
      try {
        final res = await getCollaborationRequests(listId);
        initial = res.valueOrNull;
        if (initial != null) {
          yield initial;
        }
      } catch (_) {}

      try {
        final stream = client
            .from(SupabaseTables.socialActivities)
            .stream(primaryKey: ['activity_id'])
            .map((rows) {
          final filtered = rows
              .where((r) =>
                  r['action_type'] == 'collab_request' &&
                  r['movie_title'] == listId &&
                  r['review_text'] == 'pending')
              .map((m) => CollaborationRequest(
                    requestId: m['activity_id'] as String? ?? '',
                    listId: m['movie_title'] as String? ?? listId,
                    userId: m['user_id'] as String? ?? '',
                    username: m['username'] as String? ?? 'کاربر',
                    avatarUrl: m['user_avatar'] as String?,
                    createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
                        DateTime.now(),
                    status: CollaborationRequestStatus.fromString(
                        m['review_text'] as String? ?? 'pending'),
                  ))
              .toList();
          if (filtered.isEmpty && initial != null && initial.isNotEmpty) {
            return initial;
          }
          return filtered;
        }).handleError((Object e) {
          debugPrint('[SupabaseSocialRepository] Realtime watchCollaborationRequests error: $e');
        });
        yield* stream;
      } catch (_) {
        if (initial != null) yield initial;
      }
    } else {
      yield List<CollaborationRequest>.from(_mockRequests[listId] ?? []);
      yield* _requestStreamController.stream.map(
        (_) => List<CollaborationRequest>.from(_mockRequests[listId] ?? []),
      );
    }
  }

  // ── List Items (Collaborative additions/removals) ──────────────────────

  @override
  Future<Result<void>> addMovieToList({
    required String listId,
    required MediaSummary item,
    required String addedByUserId,
  }) {
    return _guard(() async {
      // Permission check: only owner or accepted collaborators can add items
      final listRes = await getList(listId);
      final list = listRes.valueOrNull;
      if (list == null) {
        throw Exception('فهرست موردنظر یافت نشد.');
      }

      final isOwner = list.isOwner(addedByUserId);
      final isCollab = await isCollaborator(listId: listId, userId: addedByUserId)
          .then((r) => r.valueOrNull ?? false);

      if (!isOwner && !isCollab) {
        throw Exception('تنها سازنده فهرست یا همکاران تأییدشده می‌توانند به این فهرست اثر اضافه کنند.');
      }

      final customItem = CustomListItem(
        id: '${listId}_${item.id}_${item.type.name}',
        listId: listId,
        mediaId: item.id,
        mediaType: item.type,
        title: item.title,
        posterPath: item.posterPath,
        overview: item.overview,
        releaseDate: item.releaseDate,
        voteAverage: item.voteAverage,
        addedBy: addedByUserId,
        addedAt: DateTime.now(),
      );

      final client = _client;
      if (client != null) {
        await client
            .from(SupabaseTables.customListItems)
            .upsert(SupabaseMapper.listItemToMap(customItem));

        // Update cover and count
        try {
          final countRes = await client
              .from(SupabaseTables.customListItems)
              .count(CountOption.exact)
              .eq('list_id', listId);

          await client.from(SupabaseTables.customLists).update({
            'item_count': countRes,
            'cover_path': item.posterPath,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('list_id', listId);
        } catch (_) {}
      }

      // In-memory cache update for instant UI feedback
      final items = _mockListItems.putIfAbsent(listId, () => []);
      items.removeWhere((i) => i.mediaId == item.id);
      items.insert(0, customItem);

      final mockList = _mockLists[listId];
      if (mockList != null) {
        final updated = mockList.copyWith(
          itemCount: items.length,
          coverPath: item.posterPath ?? mockList.coverPath,
        );
        _mockLists[listId] = updated;
        _listStreamController.add(updated);
      }
      _itemsStreamController.add(items);
    });
  }

  @override
  Future<Result<void>> removeMovieFromList({
    required String listId,
    required int mediaId,
  }) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        await client
            .from(SupabaseTables.customListItems)
            .delete()
            .match({'list_id': listId, 'media_id': mediaId});

        try {
          final countRes = await client
              .from(SupabaseTables.customListItems)
              .count(CountOption.exact)
              .eq('list_id', listId);

          await client.from(SupabaseTables.customLists).update({
            'item_count': countRes,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('list_id', listId);
        } catch (_) {}
      }

      // In-memory cache update
      final items = _mockListItems[listId];
      items?.removeWhere((i) => i.mediaId == mediaId);
      final list = _mockLists[listId];
      if (list != null) {
        final updated = list.copyWith(itemCount: items?.length ?? 0);
        _mockLists[listId] = updated;
        _listStreamController.add(updated);
      }
      _itemsStreamController.add(items ?? []);
    });
  }

  @override
  Future<Result<List<CustomListItem>>> getListItems(String listId) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        final res = await client
            .from(SupabaseTables.customListItems)
            .select()
            .eq('list_id', listId)
            .order('added_at', ascending: false);

        return (res as List)
            .cast<Map<String, dynamic>>()
            .map(SupabaseMapper.listItemFromMap)
            .toList();
      } else {
        return List.from(_mockListItems[listId] ?? []);
      }
    });
  }

  @override
  Stream<List<CustomListItem>> watchListItems(String listId) async* {
    final client = _client;
    if (client != null) {
      List<CustomListItem>? initialItems;
      try {
        final direct = await getListItems(listId);
        initialItems = direct.valueOrNull;
        if (initialItems != null) {
          yield initialItems;
        }
      } catch (_) {}

      try {
        final stream = client
            .from(SupabaseTables.customListItems)
            .stream(primaryKey: ['id'])
            .eq('list_id', listId)
            .map((data) {
          final mapped = data.map(SupabaseMapper.listItemFromMap).toList();
          if (mapped.isEmpty && initialItems != null && initialItems.isNotEmpty) {
            return initialItems;
          }
          return mapped;
        }).handleError((Object e) {
          debugPrint('[SupabaseSocialRepository] Realtime watchListItems error: $e');
        });
        yield* stream;
      } catch (_) {
        if (initialItems != null) {
          yield initialItems;
        }
      }
    } else {
      yield List<CustomListItem>.from(_mockListItems[listId] ?? []);
      yield* _itemsStreamController.stream.map(
        (_) => List<CustomListItem>.from(_mockListItems[listId] ?? []),
      );
    }
  }

  // ── Social Activities ─────────────────────────────────────────────────

  @override
  Future<Result<void>> logActivity(SocialActivity activity) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        String? cloudAvatar = activity.userAvatar;
        if (cloudAvatar != null &&
            !cloudAvatar.startsWith('http') &&
            !cloudAvatar.startsWith('data:')) {
          try {
            final file = File(cloudAvatar);
            if (file.existsSync()) {
              final bytes = await file.readAsBytes();
              if (bytes.length <= 500 * 1024) {
                cloudAvatar = 'data:image/jpeg;base64,${base64Encode(bytes)}';
              }
            }
          } catch (_) {}
        }

        final toInsert = activity.copyWith(userAvatar: cloudAvatar);
        await client
            .from(SupabaseTables.socialActivities)
            .upsert(SupabaseMapper.activityToMap(toInsert));
      } else {
        _mockActivities.insert(0, activity);
        _activityStreamController.add(_mockActivities);
      }
    });
  }

  @override
  Future<Result<List<SocialActivity>>> getActivityFeed({
    required List<String> userIds,
    int limit = 30,
  }) {
    return _guard(() async {
      if (userIds.isEmpty) return const [];

      final client = _client;
      if (client != null) {
        final res = await client
            .from(SupabaseTables.socialActivities)
            .select()
            .neq('action_type', 'collab_request')
            .inFilter('user_id', userIds)
            .order('created_at', ascending: false)
            .limit(limit);

        return (res as List)
            .cast<Map<String, dynamic>>()
            .map(SupabaseMapper.activityFromMap)
            .toList();
      } else {
        return _mockActivities
            .where((a) => userIds.contains(a.userId))
            .take(limit)
            .toList();
      }
    });
  }

  @override
  Future<Result<List<SocialActivity>>> getUserActivities(
    String userId, {
    int limit = 30,
  }) {
    return _guard(() async {
      final client = _client;
      if (client != null) {
        final res = await client
            .from(SupabaseTables.socialActivities)
            .select()
            .neq('action_type', 'collab_request')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(limit);

        return (res as List)
            .cast<Map<String, dynamic>>()
            .map(SupabaseMapper.activityFromMap)
            .toList();
      } else {
        return _mockActivities
            .where((a) => a.userId == userId)
            .take(limit)
            .toList();
      }
    });
  }

  @override
  Stream<List<SocialActivity>> watchActivityFeed(List<String> userIds) {
    if (userIds.isEmpty) {
      return Stream.value(const []);
    }

    final client = _client;
    if (client != null) {
      return client
          .from(SupabaseTables.socialActivities)
          .stream(primaryKey: ['activity_id'])
          .order('created_at', ascending: false)
          .limit(50)
          .map(
            (rows) => rows
                .where((r) =>
                    r['action_type'] != 'collab_request' &&
                    userIds.contains(r['user_id'] as String?))
                .map(SupabaseMapper.activityFromMap)
                .toList(),
          );
    } else {
      return _activityStreamController.stream.map(
        (list) => list.where((a) => userIds.contains(a.userId)).toList(),
      );
    }
  }
}
