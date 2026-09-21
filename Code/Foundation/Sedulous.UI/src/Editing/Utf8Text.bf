using System;
using System.Text;

namespace Sedulous.UI;

/// Character counting and indexing over UTF-8, for the text controls.
///
/// The editing behaviour counts in CHARACTERS while the buffers are bytes, so every host has to
/// convert between the two. EditText and NumericField both need it; it is one thing, so it
/// lives in one place.
///
/// No decoder is needed for either job. A continuation byte is 10xxxxxx and every other byte
/// starts a character: that is the whole rule.
static class Utf8Text
{
	/// The byte offset a character index starts at, or the length when it runs past the end.
	public static int CharToByteOffset(StringView text, int32 charIndex)
	{
		if (charIndex <= 0)
			return 0;

		var chars = 0;
		for (int i < text.Length)
		{
			if ((((uint8)text[i]) & 0xC0) == 0x80)
				continue;

			if (chars == charIndex)
				return i;

			chars++;
		}

		return text.Length;
	}

	/// The number of CHARACTERS, not bytes.
	public static int32 CharCount(StringView text)
	{
		var count = 0;
		for (int i < text.Length)
		{
			if ((((uint8)text[i]) & 0xC0) != 0x80)
				count++;
		}
		return (int32)count;
	}

	/// The byte offset a character STARTS at, given an offset that may be in the middle of one.
	///
	/// Rounds DOWN to the containing character, which is what a caller stepping backwards
	/// through a buffer needs: the previous character's start, not a byte inside it.
	public static int PrevBoundary(StringView text, int byteOffset)
	{
		var index = Math.Min(byteOffset, text.Length) - 1;
		while ((index > 0) && ((((uint8)text[index]) & 0xC0) == 0x80))
			index--;

		return Math.Max(index, 0);
	}

	/// The codepoint starting at an offset, ADVANCING the offset past it.
	///
	/// Nought at or past the end, which every caller here treats as "nothing there" rather than
	/// as a real character.
	public static uint32 DecodeAt(StringView text, ref int byteOffset)
	{
		if ((byteOffset < 0) || (byteOffset >= text.Length))
			return 0;

		let decoded = UTF8.Decode(&text.Ptr[byteOffset], text.Length - byteOffset);
		if (decoded.length <= 0)
		{
			// A malformed byte still has to ADVANCE, or a scan over bad input never ends.
			byteOffset++;
			return 0;
		}

		byteOffset += decoded.length;
		return (uint32)decoded.c;
	}
}
