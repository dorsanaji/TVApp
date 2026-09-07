import 'package:cinetrack/domain/entities/social/list_invite_code.dart';
import 'package:flutter_test/flutter_test.dart';

/// Invitation codes for private shared lists.
void main() {
  const listId = 'list_1788627402529799';

  test('a code round-trips back to its list', () {
    final code = ListInviteCode.forList(listId);

    expect(code, isNotNull);
    expect(ListInviteCode.toListId(code!), listId);
  });

  test('different lists get different codes', () {
    final a = ListInviteCode.forList('list_1788627402529799');
    final b = ListInviteCode.forList('list_1788627402529800');

    expect(a, isNot(b));
  });

  test('codes are read back regardless of case, spaces or dashes', () {
    final code = ListInviteCode.forList(listId)!;
    final messy = ' ${code.toLowerCase().replaceAll('-', ' ')} ';

    expect(ListInviteCode.toListId(messy), listId);
  });

  test('a typo is rejected rather than resolving to another list', () {
    final code = ListInviteCode.forList(listId)!;
    // Corrupt one character of the body.
    final chars = code.replaceAll('-', '').split('');
    chars[0] = chars[0] == 'A' ? 'B' : 'A';

    expect(ListInviteCode.isValid(chars.join()), isFalse);
  });

  test('nonsense is rejected', () {
    for (final junk in ['', 'X', '----', 'NOT A CODE']) {
      expect(ListInviteCode.toListId(junk), isNull, reason: junk);
    }
  });

  test('ids this app did not mint have no code', () {
    expect(ListInviteCode.forList('something-else'), isNull);
  });
}
