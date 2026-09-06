/// Domain entity for a ListCollaborator (Task 1).
///
/// Allows multiple users to add/remove movies to the same list.
/// Clean Architecture: independent of database and UI frameworks.
class ListCollaborator {
  const ListCollaborator({
    required this.listId,
    required this.userId,
    this.username,
    this.avatarUrl,
    this.addedAt,
  });

  final String listId;
  final String userId;
  final String? username;
  final String? avatarUrl;
  final DateTime? addedAt;

  ListCollaborator copyWith({
    String? listId,
    String? userId,
    String? username,
    String? avatarUrl,
    DateTime? addedAt,
  }) {
    return ListCollaborator(
      listId: listId ?? this.listId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListCollaborator &&
          runtimeType == other.runtimeType &&
          listId == other.listId &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(listId, userId);
}
