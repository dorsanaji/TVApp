/// Domain entity for a collaborative / social CustomList (Task 1).
///
/// Clean Architecture: independent of database and UI frameworks.
class CustomList {
  const CustomList({
    required this.listId,
    required this.ownerId,
    required this.title,
    this.description,
    this.isPublic = true,
    this.coverPath,
    this.itemCount = 0,
    this.collaboratorCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String listId;
  final String ownerId;
  final String title;
  final String? description;
  final bool isPublic;
  final String? coverPath;
  final int itemCount;
  final int collaboratorCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool isOwner(String userId) => ownerId == userId;

  CustomList copyWith({
    String? listId,
    String? ownerId,
    String? title,
    String? description,
    bool? isPublic,
    String? coverPath,
    int? itemCount,
    int? collaboratorCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomList(
      listId: listId ?? this.listId,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      coverPath: coverPath ?? this.coverPath,
      itemCount: itemCount ?? this.itemCount,
      collaboratorCount: collaboratorCount ?? this.collaboratorCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomList &&
          runtimeType == other.runtimeType &&
          listId == other.listId &&
          ownerId == other.ownerId &&
          title == other.title &&
          description == other.description &&
          isPublic == other.isPublic &&
          coverPath == other.coverPath &&
          itemCount == other.itemCount &&
          collaboratorCount == other.collaboratorCount;

  @override
  int get hashCode => Object.hash(
    listId,
    ownerId,
    title,
    description,
    isPublic,
    coverPath,
    itemCount,
    collaboratorCount,
  );
}
