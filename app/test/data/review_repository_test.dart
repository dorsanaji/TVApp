import 'package:cinetrack/core/error/failure.dart';
import 'package:cinetrack/data/local/app_database.dart';
import 'package:cinetrack/data/repositories/local_auth_repository.dart';
import 'package:cinetrack/data/repositories/local_review_repository.dart';
import 'package:cinetrack/data/services/email_sender.dart';
import 'package:cinetrack/domain/entities/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// FR-13, FR-14 and FR-15 against a real database.
void main() {
  late AppDatabase db;
  late LocalAuthRepository auth;
  late LocalReviewRepository repository;

  const dune = 438631;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    auth = LocalAuthRepository(
      db: db,
      storage: const FlutterSecureStorage(),
      emailSender: DebugEmailSender(),
    );
    repository = LocalReviewRepository(db: db, auth: auth);

    await auth.register(
      firstName: 'آریا',
      lastName: 'تمکین',
      username: 'arya',
      email: 'arya@example.com',
      password: 'correct-horse',
    );
  });

  tearDown(() async {
    repository.dispose();
    auth.dispose();
    await db.close();
  });

  group('FR-13 · rating', () {
    test('a rating is stored and read back', () async {
      await repository.rate(dune, MediaType.movie, 4);

      expect((await repository.myRating(dune, MediaType.movie)).valueOrNull, 4);
    });

    test('re-rating edits rather than adding a second vote', () async {
      await repository.rate(dune, MediaType.movie, 3);
      await repository.rate(dune, MediaType.movie, 5);

      expect((await repository.myRating(dune, MediaType.movie)).valueOrNull, 5);
      final summary = (await repository.ratingSummary(
        dune,
        MediaType.movie,
      )).valueOrNull!;
      expect(summary.total, 1);
      expect(summary.percentFor(5), 100);
    });

    test('a rating outside 1–5 is rejected', () async {
      expect((await repository.rate(dune, MediaType.movie, 0)).isErr, isTrue);
      expect((await repository.rate(dune, MediaType.movie, 6)).isErr, isTrue);
      expect(
        (await repository.ratingSummary(
          dune,
          MediaType.movie,
        )).valueOrNull?.total,
        0,
      );
    });

    test('a rating can be cleared', () async {
      await repository.rate(dune, MediaType.movie, 4);
      await repository.clearRating(dune, MediaType.movie);

      expect(
        (await repository.myRating(dune, MediaType.movie)).valueOrNull,
        isNull,
      );
    });

    test('the average reflects the ratings submitted', () async {
      await repository.rate(dune, MediaType.movie, 4);
      await repository.rate(1396, MediaType.series, 5);

      expect(await repository.averageRatingOfCurrentUser(), 4.5);
    });

    test('rating while signed out is refused', () async {
      await auth.logout();

      final result = await repository.rate(dune, MediaType.movie, 4);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });
  });

  group('FR-14 · reviews', () {
    test('a review carries all five fields the brief lists', () async {
      final result = await repository.submitReview(
        id: dune,
        type: MediaType.movie,
        body: 'فیلم فوق‌العاده‌ای بود',
        hasSpoiler: false,
      );
      expect(result.isOk, isTrue);

      final reviews = (await repository.reviews(
        dune,
        MediaType.movie,
      )).valueOrNull!;
      final review = reviews.single;

      expect(review.body, 'فیلم فوق‌العاده‌ای بود'); // 1 · متن نظر
      expect(review.authorName, 'آریا تمکین'); // 2 · نام کاربر
      expect(review.createdAt, isNotNull); // 4 · تاریخ ثبت
      expect(review.hasSpoiler, isFalse); // 5 · وضعیت اسپویل
    });

    test('empty review text is rejected', () async {
      final result = await repository.submitReview(
        id: dune,
        type: MediaType.movie,
        body: '   ',
        hasSpoiler: false,
      );

      expect((result.failureOrNull! as ValidationFailure).field, 'body');
    });

    test('reviews come back newest first', () async {
      await repository.submitReview(
        id: dune,
        type: MediaType.movie,
        body: 'اولین نظر',
        hasSpoiler: false,
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository.submitReview(
        id: dune,
        type: MediaType.movie,
        body: 'دومین نظر',
        hasSpoiler: false,
      );

      final reviews = (await repository.reviews(
        dune,
        MediaType.movie,
      )).valueOrNull!;
      expect(reviews.first.body, 'دومین نظر');
    });

    test('a review shows the rating its author gave', () async {
      await repository.rate(dune, MediaType.movie, 5);
      await repository.submitReview(
        id: dune,
        type: MediaType.movie,
        body: 'عالی',
        hasSpoiler: false,
      );

      final reviews = (await repository.reviews(
        dune,
        MediaType.movie,
      )).valueOrNull!;
      expect(reviews.single.stars, 5);
    });

    test('a review can be edited and deleted by its author', () async {
      final created = (await repository.submitReview(
        id: dune,
        type: MediaType.movie,
        body: 'نظر اولیه',
        hasSpoiler: false,
      )).valueOrNull!;

      final edited = await repository.editReview(
        reviewId: created.id,
        body: 'نظر ویرایش‌شده',
        hasSpoiler: true,
      );
      expect(edited.valueOrNull?.body, 'نظر ویرایش‌شده');
      expect(edited.valueOrNull?.isEdited, isTrue);

      await repository.deleteReview(created.id);
      expect(
        (await repository.reviews(dune, MediaType.movie)).valueOrNull,
        isEmpty,
      );
    });

    test("a user cannot edit someone else's review", () async {
      final created = (await repository.submitReview(
        id: dune,
        type: MediaType.movie,
        body: 'نظر من',
        hasSpoiler: false,
      )).valueOrNull!;

      await auth.logout();
      await auth.register(
        firstName: 'کسی',
        lastName: 'دیگر',
        username: 'someone',
        email: 'someone@example.com',
        password: 'another-password',
      );

      final result = await repository.editReview(
        reviewId: created.id,
        body: 'دستکاری',
        hasSpoiler: false,
      );

      // NFR-16 — users reach only their own data.
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });
  });

  group('FR-15 · spoilers', () {
    test('the spoiler flag is stored with the review', () async {
      await repository.submitReview(
        id: dune,
        type: MediaType.movie,
        body: 'در پایان فیلم…',
        hasSpoiler: true,
      );

      final reviews = (await repository.reviews(
        dune,
        MediaType.movie,
      )).valueOrNull!;
      expect(reviews.single.hasSpoiler, isTrue);
    });
  });
}
