import '../../core/error/result.dart';
import '../entities/enums.dart';
import '../entities/media_summary.dart';

/// User-created personal lists — FR-17 §5.17, worth 6 points.
///
/// The brief's examples: "best action films", "favourite series", "films I
/// must watch", "best works of the year".
abstract interface class ListRepository {
  Future<Result<List<PersonalList>>> lists();

  Future<Result<PersonalList>> createList({
    required String name,
    String? description,
  });

  Future<Result<PersonalList>> renameList(String listId, String name);

  Future<Result<void>> deleteList(String listId);

  /// Items in a list, in the user's chosen order.
  Future<Result<List<MediaSummary>>> itemsOf(String listId);

  Future<Result<void>> addToList(String listId, MediaSummary item);

  Future<Result<void>> removeFromList(
    String listId,
    int mediaId,
    MediaType type,
  );

  /// Which lists already contain this title — drives the checkbox state in
  /// the "add to list" sheet, so the user can see membership at a glance.
  Future<Result<Set<String>>> listIdsContaining(int mediaId, MediaType type);
}

/// A personal list (FR-17).
class PersonalList {
  const PersonalList({
    required this.id,
    required this.name,
    required this.itemCount,
    this.description,
    this.coverPath,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? description;

  /// Poster of the first item, used as the list's cover.
  final String? coverPath;

  final int itemCount;
  final DateTime? createdAt;

  bool get isEmpty => itemCount == 0;
}
