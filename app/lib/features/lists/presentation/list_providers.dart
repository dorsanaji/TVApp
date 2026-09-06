import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/result.dart';
import '../../../domain/entities/enums.dart';
import '../../../domain/entities/media_summary.dart';
import '../../../domain/repositories/list_repository.dart';
import '../../tracking/presentation/tracking_providers.dart';

/// Bumped after every list mutation so the screens showing lists refresh.
final listRevisionProvider = StateProvider<int>((ref) => 0);

/// FR-17 — all of the user's personal lists.
final personalListsProvider = FutureProvider<List<PersonalList>>((ref) async {
  // Account switches arrive on the tracking stream, which the repository
  // emits on when the signed-in user changes — so a new account does not
  // inherit the previous one's lists on screen.
  ref.watch(trackingRevisionProvider);
  ref.watch(listRevisionProvider);
  final result = await ref.watch(listRepositoryProvider).lists();
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// FR-17 — the contents of one list.
final listItemsProvider = FutureProvider.family<List<MediaSummary>, String>((
  ref,
  listId,
) async {
  // Account switches arrive on the tracking stream, which the repository
  // emits on when the signed-in user changes — so a new account does not
  // inherit the previous one's lists on screen.
  ref.watch(trackingRevisionProvider);
  ref.watch(listRevisionProvider);
  final result = await ref.watch(listRepositoryProvider).itemsOf(listId);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => throw failure,
  };
});

/// Which lists already contain a title — drives the checkbox state in the
/// "add to list" sheet, so membership is visible at a glance.
final listsContainingProvider = FutureProvider.family<Set<String>, MediaKey>((
  ref,
  key,
) async {
  // Account switches arrive on the tracking stream, which the repository
  // emits on when the signed-in user changes — so a new account does not
  // inherit the previous one's lists on screen.
  ref.watch(trackingRevisionProvider);
  ref.watch(listRevisionProvider);
  final result = await ref
      .watch(listRepositoryProvider)
      .listIdsContaining(key.id, key.type);
  return result.valueOrNull ?? const {};
});

/// Write-side helper for FR-17.
class ListActions {
  const ListActions(this._repository, this._ref);

  final ListRepository _repository;
  final Ref _ref;

  void _notify() => _ref.read(listRevisionProvider.notifier).state++;

  Future<Result<PersonalList>> create(
    String name, {
    String? description,
  }) async {
    final result = await _repository.createList(
      name: name,
      description: description,
    );
    if (result.isOk) _notify();
    return result;
  }

  Future<Result<PersonalList>> rename(String listId, String name) async {
    final result = await _repository.renameList(listId, name);
    if (result.isOk) _notify();
    return result;
  }

  Future<void> delete(String listId) async {
    await _repository.deleteList(listId);
    _notify();
  }

  Future<void> add(String listId, MediaSummary item) async {
    await _repository.addToList(listId, item);
    _notify();
  }

  Future<void> remove(String listId, int mediaId, MediaType type) async {
    await _repository.removeFromList(listId, mediaId, type);
    _notify();
  }
}

final listActionsProvider = Provider<ListActions>((ref) {
  return ListActions(ref.watch(listRepositoryProvider), ref);
});
