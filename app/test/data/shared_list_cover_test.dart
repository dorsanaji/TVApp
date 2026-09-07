import 'package:cinetrack/data/repositories/supabase_social_repository.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:cinetrack/domain/entities/media_summary.dart';
import 'package:flutter_test/flutter_test.dart';

/// A shared list's cover and count must describe what is actually in it.
void main() {
  late SupabaseSocialRepository repo;

  const first = MediaSummary(
    id: 1,
    type: MediaType.movie,
    title: 'اولی',
    posterPath: '/first.jpg',
  );
  const second = MediaSummary(
    id: 2,
    type: MediaType.movie,
    title: 'دومی',
    posterPath: '/second.jpg',
  );

  setUp(() {
    SupabaseSocialRepository.resetMockStorage();
    repo = SupabaseSocialRepository(client: null);
  });

  Future<String> listWithBoth() async {
    final created = await repo.createList(ownerId: 'u1', title: 'مشترک');
    final id = created.valueOrNull!.listId;
    await repo.addMovieToList(listId: id, item: first, addedByUserId: 'u1');
    await repo.addMovieToList(listId: id, item: second, addedByUserId: 'u1');
    return id;
  }

  test('removing the cover title moves the cover to what is left', () async {
    final id = await listWithBoth();

    // The most recent addition is the cover.
    expect((await repo.getList(id)).valueOrNull!.coverPath, '/second.jpg');

    await repo.removeMovieFromList(listId: id, mediaId: second.id);

    final after = (await repo.getList(id)).valueOrNull!;
    expect(
      after.coverPath,
      '/first.jpg',
      reason: 'the cover must not keep showing a removed title',
    );
    expect(after.itemCount, 1);
  });

  test('emptying a list clears its cover', () async {
    final id = await listWithBoth();

    await repo.removeMovieFromList(listId: id, mediaId: second.id);
    await repo.removeMovieFromList(listId: id, mediaId: first.id);

    final after = (await repo.getList(id)).valueOrNull!;
    expect(after.itemCount, 0);
    expect(
      after.coverPath,
      isNull,
      reason: 'an empty list should fall back to its placeholder',
    );
  });

  test('removing a title that is not the cover leaves the cover alone',
      () async {
    final id = await listWithBoth();

    await repo.removeMovieFromList(listId: id, mediaId: first.id);

    final after = (await repo.getList(id)).valueOrNull!;
    expect(after.coverPath, '/second.jpg');
    expect(after.itemCount, 1);
  });
}
