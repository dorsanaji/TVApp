/// Status of a collaboration access request.
enum CollaborationRequestStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected');

  const CollaborationRequestStatus(this.value);
  final String value;

  static CollaborationRequestStatus fromString(String raw) => switch (raw) {
        'accepted' => CollaborationRequestStatus.accepted,
        'rejected' => CollaborationRequestStatus.rejected,
        _ => CollaborationRequestStatus.pending,
      };
}

/// Domain entity representing a user's request to collaborate on a CustomList.
class CollaborationRequest {
  const CollaborationRequest({
    required this.requestId,
    required this.listId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
    this.status = CollaborationRequestStatus.pending,
  });

  final String requestId;
  final String listId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;
  final CollaborationRequestStatus status;

  CollaborationRequest copyWith({
    String? requestId,
    String? listId,
    String? userId,
    String? username,
    String? avatarUrl,
    DateTime? createdAt,
    CollaborationRequestStatus? status,
  }) {
    return CollaborationRequest(
      requestId: requestId ?? this.requestId,
      listId: listId ?? this.listId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollaborationRequest &&
          runtimeType == other.runtimeType &&
          requestId == other.requestId;

  @override
  int get hashCode => requestId.hashCode;
}
