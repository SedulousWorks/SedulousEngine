using System;

namespace Sedulous.UI;

/// Character counting and indexing over UTF-8, for the text controls.
///
/// The editing behaviour counts in CHARACTERS while the buffers are bytes, so every host has to
/// convert between the two. Raptor carries the same conversion separately in EditText and in
/// NumericField; it is one thing, so it lives in one place.
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
}
