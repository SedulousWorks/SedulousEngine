using System;
using Sedulous.Fonts;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Where a caret may stand and what a word is, over UTF-8 byte offsets. A grapheme is what a
// reader sees as one character: a base with the marks that combine with it, CR LF, an emoji with
// its modifiers, variation selectors and zero-width-joined parts, a flag's pair of regional
// indicators. The rules are UAX #29's that an editor feels, over tables of the common ranges rather
// than the whole Unicode database: neither fonts nor core segments text, and a caret that splits
// "é" written as e + U+0301 is the bug these rules exist for.
//
// Words are runs of letters, digits and '_' (any character past ASCII that is not a space or
// punctuation counts as a letter); word movement and deletion follow foundation.ui's editor: to the
// right, over the rest of a word and the gap after it; to the left, over the gap and then the word,
// never across a line break.

/// What a character is to word movement.
enum WordClass : uint8
{
	Word,
	Space,
	Punctuation,
	LineBreak,
}

/// A range of bytes.
struct TextRange : IEquatable<TextRange>
{
	public int Start = 0;
	public int End = 0;

	public this() { }

	public this(int start, int end)
	{
		Start = start;
		End = end;
	}

	public bool IsEmpty => Start == End;

	public bool Equals(TextRange other) => this == other;

	[Commutable]
	public static bool operator==(TextRange a, TextRange b) => (a.Start == b.Start) && (a.End == b.End);
}

static
{
	/// Whether `c` is of the ideographic line-break class: a line may break before and after it.
	public static bool IsIdeographic(uint32 c) => (c >= 0x1100) && TextSegmentationDetail.InRanges(c, TextSegmentationDetail.sIdeographic);

	/// Whether a line may break between `before` and `after` without a space: either is
	/// ideographic, `after` may start a line and `before` may end one.
	///
	/// Space-separated text breaks after its spaces; CJK has none, and breaks between its characters
	/// (ideographs, kana, Hangul syllables, full-width forms). Two exceptions keep punctuation where a
	/// reader expects it: no line starts with a closing mark or a small kana ("。", "、", "）", "ー",
	/// "っ"), and none ends with an opening mark ("「", "（").
	public static bool IsLineBreakBetween(uint32 before, uint32 after)
	{
		if (!IsIdeographic(before) && !IsIdeographic(after))
			return false;
		if (TextSegmentationDetail.IsIn(after, TextSegmentationDetail.sNoLineStart))
			return false;
		return !TextSegmentationDetail.IsIn(before, TextSegmentationDetail.sNoLineEnd);
	}

	/// Whether a caret may stand between the codepoints before and after `offset`.
	public static bool IsGraphemeBoundary(StringView text, int offset)
	{
		if ((offset == 0) || (offset >= text.Length))
			return true;
		int next = 0;
		int start = 0;
		let after = TextSegmentationDetail.CodepointAt(text, offset, out next);
		let before = TextSegmentationDetail.CodepointBefore(text, offset, out start);
		if ((before == (uint32)'\r') && (after == (uint32)'\n'))
			return false;
		if ((before == (uint32)'\r') || (before == (uint32)'\n') || (after == (uint32)'\r') || (after == (uint32)'\n'))
			return true;
		if (TextSegmentationDetail.IsExtend(after) || (after == TextSegmentationDetail.cZeroWidthJoiner))
			return false;
		if ((before == TextSegmentationDetail.cZeroWidthJoiner) && (after >= 0x80))
			return false; // an emoji's parts, joined
		if (TextSegmentationDetail.IsRegionalIndicator(before) && TextSegmentationDetail.IsRegionalIndicator(after))
		{
			// Flags pair up: a break falls after an even count of indicators.
			int count = 0;
			int at = offset;
			while (at > 0)
			{
				int s = 0;
				if (!TextSegmentationDetail.IsRegionalIndicator(TextSegmentationDetail.CodepointBefore(text, at, out s)))
					break;
				count++;
				at = s;
			}
			return count % 2 == 0;
		}
		return true;
	}

	/// The next caret position after `offset` (the text's end at most).
	public static int NextGrapheme(StringView text, int offset)
	{
		if (offset >= text.Length)
			return text.Length;
		int at = TextSegmentationDetail.Utf8NextBoundary(text, offset);
		while ((at < text.Length) && !IsGraphemeBoundary(text, at))
			at = TextSegmentationDetail.Utf8NextBoundary(text, at);
		return at;
	}

	/// The caret position before `offset` (0 at least).
	public static int PrevGrapheme(StringView text, int offset)
	{
		if (offset == 0)
			return 0;
		int at = TextSegmentationDetail.Utf8PrevBoundary(text, Math.Min(offset, text.Length));
		while ((at > 0) && !IsGraphemeBoundary(text, at))
			at = TextSegmentationDetail.Utf8PrevBoundary(text, at);
		return at;
	}

	/// How many graphemes `text` holds (what a reader counts as characters).
	public static int GraphemeCount(StringView text)
	{
		int count = 0;
		for (int at = 0; at < text.Length; at = NextGrapheme(text, at))
			count++;
		return count;
	}

	public static WordClass ClassifyForWords(uint32 c)
	{
		if ((c == (uint32)'\n') || (c == (uint32)'\r'))
			return .LineBreak;
		if ((c == (uint32)' ') || (c == (uint32)'\t') || (c == 0xA0) || ((c >= 0x2000) && (c <= 0x200B)) || (c == 0x3000))
			return .Space;
		if (((c >= (uint32)'0') && (c <= (uint32)'9')) || ((c >= (uint32)'a') && (c <= (uint32)'z')) || ((c >= (uint32)'A') && (c <= (uint32)'Z')) || (c == (uint32)'_'))
			return .Word;
		if (c < 0x80)
			return .Punctuation;
		if (((c >= 0x2010) && (c <= 0x206F)) || ((c >= 0x3001) && (c <= 0x303F)) || ((c >= 0xFF01) && (c <= 0xFF0F)) ||
			((c >= 0x00A1) && (c <= 0x00BF) && (c != 0xAA) && (c != 0xB5) && (c != 0xBA)) || (c == 0xD7) || (c == 0xF7))
			return .Punctuation;
		return .Word; // a letter of some script, or a mark (which stays with its word)
	}

	/// Where word movement to the right from `offset` stops: past the rest of a word and the gap
	/// after it (the next word's start), at a line break at the latest.
	public static int NextWordBoundary(StringView text, int offset)
	{
		int at = Math.Min(offset, text.Length);
		if ((at < text.Length) && (TextSegmentationDetail.ClassAt(text, at) == .LineBreak))
			return NextGrapheme(text, at); // over the break itself
		while ((at < text.Length) && (TextSegmentationDetail.ClassAt(text, at) == .Word))
			at = NextGrapheme(text, at);
		while ((at < text.Length) && (TextSegmentationDetail.ClassAt(text, at) != .Word) &&
			(TextSegmentationDetail.ClassAt(text, at) != .LineBreak))
			at = NextGrapheme(text, at);
		return at;
	}

	/// Where word movement to the left from `offset` stops: back over the gap and then the word (a
	/// word's start), after a line break at the latest.
	public static int PrevWordBoundary(StringView text, int offset)
	{
		int at = Math.Min(offset, text.Length);
		if ((at > 0) && (TextSegmentationDetail.ClassBefore(text, at) == .LineBreak))
			return PrevGrapheme(text, at);
		while ((at > 0) && (TextSegmentationDetail.ClassBefore(text, at) != .Word) &&
			(TextSegmentationDetail.ClassBefore(text, at) != .LineBreak))
			at = PrevGrapheme(text, at);
		while ((at > 0) && (TextSegmentationDetail.ClassBefore(text, at) == .Word))
			at = PrevGrapheme(text, at);
		return at;
	}

	/// The run a double click selects at `offset`: the word, the spaces or the punctuation there
	/// (the character after the offset decides, the one before it at the end of a line).
	public static TextRange WordRangeAt(StringView text, int offset)
	{
		var offset;
		offset = Math.Min(offset, text.Length);
		if (text.Length == 0)
			return .();
		WordClass kind;
		if ((offset < text.Length) && (TextSegmentationDetail.ClassAt(text, offset) != .LineBreak))
			kind = TextSegmentationDetail.ClassAt(text, offset);
		else if ((offset > 0) && (TextSegmentationDetail.ClassBefore(text, offset) != .LineBreak))
			kind = TextSegmentationDetail.ClassBefore(text, offset);
		else
			return .(offset, offset);
		int start = offset;
		while ((start > 0) && (TextSegmentationDetail.ClassBefore(text, start) == kind))
			start = PrevGrapheme(text, start);
		int end = offset;
		while ((end < text.Length) && (TextSegmentationDetail.ClassAt(text, end) == kind))
			end = NextGrapheme(text, end);
		return .(start, end);
	}

	/// The logical line (between line breaks) holding `offset`, its break left out.
	public static TextRange LineRangeAt(StringView text, int offset)
	{
		let at = Math.Min(offset, text.Length);
		int start = at;
		while ((start > 0) && (text[start - 1] != '\n'))
			start--;
		int end = at;
		while ((end < text.Length) && (text[end] != '\n'))
			end++;
		if ((end > start) && (text[end - 1] == '\r'))
			end--;
		return .(start, end);
	}
}

/// The tables and steps TextSegmentation.bf keeps out of the public surface.
internal static class TextSegmentationDetail
{
	public struct CodeRange
	{
		public uint32 First;
		public uint32 Last;

		public this(uint32 first, uint32 last)
		{
			First = first;
			Last = last;
		}
	}

	/// Marks that combine with what comes before them (Unicode's Extend and SpacingMark, the
	/// common ranges).
	public static CodeRange[36] sExtend = .(
		.(0x0300, 0x036F), .(0x0483, 0x0489), .(0x0591, 0x05BD), .(0x05BF, 0x05BF), .(0x05C1, 0x05C2),
		.(0x05C4, 0x05C5), .(0x05C7, 0x05C7), .(0x0610, 0x061A), .(0x064B, 0x065F), .(0x0670, 0x0670),
		.(0x06D6, 0x06DC), .(0x06DF, 0x06E4), .(0x06E7, 0x06E8), .(0x06EA, 0x06ED), .(0x0900, 0x0903),
		.(0x093A, 0x093C), .(0x093E, 0x094F), .(0x0951, 0x0957), .(0x0962, 0x0963), .(0x0981, 0x0983),
		.(0x09BC, 0x09BC), .(0x09BE, 0x09CD), .(0x0E31, 0x0E31), .(0x0E34, 0x0E3A), .(0x0E47, 0x0E4E),
		.(0x1AB0, 0x1AFF), .(0x1DC0, 0x1DFF), .(0x200C, 0x200C), .(0x20D0, 0x20FF), .(0x302A, 0x302F),
		.(0x3099, 0x309A), .(0xFE00, 0xFE0F), .(0xFE20, 0xFE2F), .(0x1F3FB, 0x1F3FF), .(0xE0020, 0xE007F),
		.(0xE0100, 0xE01EF));

	public const uint32 cZeroWidthJoiner = 0x200D;

	/// The ideographic line-break class (UAX #14's ID, the common ranges): ideographs, kana,
	/// Hangul, full-width forms.
	public static CodeRange[18] sIdeographic = .(
		.(0x1100, 0x115F), .(0x2E80, 0x2FFF), .(0x3040, 0x309F), .(0x30A0, 0x30FF), .(0x3100, 0x312F),
		.(0x3130, 0x318F), .(0x3190, 0x31FF), .(0x3200, 0x33FF), .(0x3400, 0x4DBF), .(0x4E00, 0x9FFF),
		.(0xA000, 0xA4CF), .(0xAC00, 0xD7AF), .(0xF900, 0xFAFF), .(0xFE30, 0xFE4F), .(0xFF00, 0xFF60),
		.(0xFFE0, 0xFFE6), .(0x20000, 0x2FFFD), .(0x30000, 0x3FFFD));

	/// No line starts with these: closing punctuation, iteration and prolonged-sound marks, and the
	/// small kana (UAX #14's CL, CP, EX and NS, as Japanese kinsoku rules use them).
	public static uint32[58] sNoLineStart = .(
		0x3001, 0x3002, 0xFF0C, 0xFF0E, 0xFF01, 0xFF1F, 0xFF1A, 0xFF1B, 0x30FB, 0x300D, 0x300F, 0x3011,
		0x3015, 0x3009, 0x300B, 0x3017, 0x3019, 0x301B, 0xFF09, 0xFF3D, 0xFF5D, 0x30FC, 0x3005, 0x309D,
		0x309E, 0x30FD, 0x30FE, 0x3041, 0x3043, 0x3045, 0x3047, 0x3049, 0x3063, 0x3083, 0x3085, 0x3087,
		0x308E, 0x30A1, 0x30A3, 0x30A5, 0x30A7, 0x30A9, 0x30C3, 0x30E3, 0x30E5, 0x30E7, 0x30EE, 0x30F5,
		0x30F6, 0x0021, 0x0029, 0x002C, 0x002E, 0x003A, 0x003B, 0x003F, 0x005D, 0x007D);

	/// No line ends with these: opening punctuation (OP).
	public static uint32[15] sNoLineEnd = .(
		0x300C, 0x300E, 0x3010, 0x3014, 0x3008, 0x300A, 0x3016, 0x3018, 0x301A, 0xFF08, 0xFF3B, 0xFF5B,
		0x0028, 0x005B, 0x007B);

	public static bool IsIn(uint32 c, Span<uint32> list)
	{
		for (let entry in list)
			if (entry == c)
				return true;
		return false;
	}

	public static bool InRanges(uint32 c, Span<CodeRange> ranges)
	{
		for (let range in ranges)
			if ((c >= range.First) && (c <= range.Last))
				return true;
		return false;
	}

	public static bool IsExtend(uint32 c) => (c >= 0x0300) && InRanges(c, sExtend);

	public static bool IsRegionalIndicator(uint32 c) => (c >= 0x1F1E6) && (c <= 0x1F1FF);

	/// A UTF-8 continuation byte (0b10xxxxxx): not where a codepoint starts.
	public static bool IsUtf8Continuation(char8 c) => ((uint8)c & 0xC0) == 0x80;

	/// The start of the codepoint before `index` (0 at or before the start).
	public static int Utf8PrevBoundary(StringView s, int index)
	{
		var index;
		if (index == 0)
			return 0;
		if (index > s.Length)
			index = s.Length;
		index--;
		while ((index > 0) && IsUtf8Continuation(s[index]))
			index--;
		return index;
	}

	/// Just past the codepoint starting at `index` (the size at or past the end).
	public static int Utf8NextBoundary(StringView s, int index)
	{
		var index;
		let size = s.Length;
		if (index >= size)
			return size;
		index++;
		while ((index < size) && IsUtf8Continuation(s[index]))
			index++;
		return index;
	}

	/// The codepoint at `offset` (which is on a codepoint boundary), and where the next starts.
	public static uint32 CodepointAt(StringView text, int offset, out int next)
	{
		next = offset;
		return DecodeCodepoint(text, ref next);
	}

	/// The codepoint before `offset`, and where it starts.
	public static uint32 CodepointBefore(StringView text, int offset, out int start)
	{
		start = Utf8PrevBoundary(text, offset);
		int next = start;
		return DecodeCodepoint(text, ref next);
	}

	public static WordClass ClassAt(StringView text, int offset) => ClassifyForWords(CodepointAt(text, offset, ?));

	public static WordClass ClassBefore(StringView text, int offset) => ClassifyForWords(CodepointBefore(text, offset, ?));
}
