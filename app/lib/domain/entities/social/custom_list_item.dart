import '../enums.dart';

/// An item (film or series) inside a collaborative CustomList.
///
/// Clean Architecture: independent of database and UI frameworks.
class CustomListItem {
  const CustomListItem({
    required this.id,
    required this.listId,
    required this.mediaId,
    required this.mediaType,
    required this.title,
    this.posterPath,
    this.overview,
    this.releaseDate,
    this.voteAverage,
    this.addedBy,
    this.addedAt,
  });

  final String id;
  final String listId;
  final int mediaId;
  final MediaType mediaType;
  final String title;
  final String? posterPath;
  final String? overview;
  final String? releaseDate;
  final double? voteAverage;
  final String? addedBy;
  final DateTime? addedAt;

  CustomListItem copyWith({
    String? id,
    String? listId,
    int? mediaId,
    MediaType? mediaType,
    String? title,
    String? posterPath,
    String? overview,
    String? releaseDate,
    double? voteAverage,
    String? addedBy,
    DateTime? addedAt,
  }) {
    return CustomListItem(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      mediaId: mediaId ?? this.mediaId,
      mediaType: mediaType ?? this.mediaType,
      title: title ?? this.title,
      posterPath: posterPath ?? this.posterPath,
      overview: overview ?? this.overview,
      releaseDate: releaseDate ?? this.releaseDate,
      voteAverage: voteAverage ?? this.voteAverage,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomListItem &&
          runtimeType == other.runtimeType &&
          listId == other.listId &&
          mediaId == other.mediaId &&
          mediaType == other.mediaType;

  @override
  int get hashCode => Object.hash(listId, mediaId, mediaType);
}
