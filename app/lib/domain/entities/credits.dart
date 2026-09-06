/// A genre (FR-06, FR-07, and the favourite-genre statistic in FR-19).
class Genre {
  const Genre({required this.id, required this.name});

  final int id;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Genre && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// A performer (FR-06 "بازیگران", FR-07 "بازیگران").
class CastMember {
  const CastMember({
    required this.id,
    required this.name,
    this.character,
    this.profilePath,
    this.order = 0,
  });

  final int id;
  final String name;

  /// Role played, when the service supplies it.
  final String? character;
  final String? profilePath;

  /// Billing order; lower is more prominent.
  final int order;
}

/// A crew member (FR-06 "کارگردان" and "عوامل تولید" in §4.4).
class CrewMember {
  const CrewMember({
    required this.id,
    required this.name,
    required this.job,
    this.department,
    this.profilePath,
  });

  final int id;
  final String name;

  /// e.g. `Director`, `Writer`, `Producer`.
  final String job;
  final String? department;
  final String? profilePath;

  bool get isDirector => job.toLowerCase() == 'director';
}
