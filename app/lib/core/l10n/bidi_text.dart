import 'package:flutter/widgets.dart';

/// Reading direction for a run of text whose language is not known in advance.
///
/// The interface is pinned to Persian, so `Directionality` is RTL everywhere —
/// correct for the chrome, wrong for the content. TMDB has no Persian synopsis
/// for most titles, so an English paragraph inherited RTL and was laid out
/// against the right margin with its full stop pushed to the *left* of the
/// closing line. Proper bidirectional handling (NFR-28) means leaving an LTR
/// run left-to-right, not forcing everything one way.
///
/// The rule is majority-of-strong-characters, which is the same principle as
/// the Unicode "first strong" heuristic but less brittle: a Persian synopsis
/// that opens with a Latin proper noun stays RTL.
TextDirection? directionOf(String text) {
  var rtl = 0;
  var ltr = 0;

  for (final rune in text.runes) {
    if (_isRtl(rune)) {
      rtl++;
    } else if (_isLtr(rune)) {
      ltr++;
    }
  }

  // Digits and punctuation only — nothing to go on, so defer to the ambient
  // direction rather than guess.
  if (rtl == 0 && ltr == 0) return null;
  return rtl >= ltr ? TextDirection.rtl : TextDirection.ltr;
}

/// Arabic, Persian, and Hebrew letters, including the presentation forms that
/// some sources still emit.
///
/// Arabic-Indic digits sit inside these blocks but are deliberately excluded:
/// Unicode classes them as *Arabic Number*, not as strong right-to-left, and a
/// release year rendered as ۲۰۰۴ should not be enough on its own to decide the
/// direction of the line it sits on.
bool _isRtl(int rune) {
  if ((rune >= 0x0660 && rune <= 0x0669) || // Arabic-Indic digits
      (rune >= 0x06F0 && rune <= 0x06F9)) {
    // Extended Arabic-Indic digits (Persian)
    return false;
  }

  return (rune >= 0x0590 && rune <= 0x05FF) || // Hebrew
      (rune >= 0x0600 && rune <= 0x06FF) || // Arabic (covers Persian)
      (rune >= 0x0750 && rune <= 0x077F) || // Arabic Supplement
      (rune >= 0x08A0 && rune <= 0x08FF) || // Arabic Extended-A
      (rune >= 0xFB1D && rune <= 0xFDFF) || // Presentation Forms-A
      (rune >= 0xFE70 && rune <= 0xFEFF); // Presentation Forms-B
}

/// Latin letters, including the accented ranges — enough to catch the European
/// titles TMDB falls back to. CJK is intentionally not counted: it is neither
/// direction's evidence, and Korean or Chinese content should follow the
/// ambient layout rather than flip it.
bool _isLtr(int rune) =>
    (rune >= 0x0041 && rune <= 0x005A) || // A–Z
    (rune >= 0x0061 && rune <= 0x007A) || // a–z
    (rune >= 0x00C0 && rune <= 0x024F); // Latin-1 Supplement + Extended-A/B

/// [Text] that picks its own direction from its content.
///
/// Use for anything written by the information service or by another user —
/// synopses, episode summaries, reviews — where the language cannot be assumed.
/// Interface strings are Persian by construction and should use plain [Text].
class BidiText extends StatelessWidget {
  const BidiText(
    this.data, {
    this.style,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final direction = directionOf(data);

    return Text(
      data,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textDirection: direction,
      // `start` resolves against the direction chosen above, so English lands
      // left and Persian lands right without either being hard-coded.
      textAlign: TextAlign.start,
    );
  }
}
