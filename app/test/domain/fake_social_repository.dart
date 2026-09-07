import 'package:cinetrack/core/error/result.dart';
import 'package:cinetrack/domain/entities/social/social_activity.dart';
import 'package:cinetrack/domain/repositories/social_repository.dart';

/// Serves a fixed activity log; every other member is unused by these tests.
class FakeSocialRepository implements SocialRepository {
  FakeSocialRepository(this.activities);

  final List<SocialActivity> activities;

  @override
  Future<Result<List<SocialActivity>>> getUserActivities(
    String userId, {
    int limit = 30,
  }) async => Ok(activities.take(limit).toList());

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
