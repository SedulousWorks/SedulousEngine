using System;

namespace Sedulous.Fonts;

/// Walking UTF-8 text a codepoint at a time, and fitting text into a box.
///
/// Beef strings are UTF-8 and carry a decoder of their own, but shaping needs the BYTE
/// index alongside the codepoint: hit testing and caret placement answer in terms of the
/// caller's string, so the decoder here hands back both.
static
{
	/// Decodes the codepoint starting at `index`, advancing `index` past what it consumed.
	///
	/// Malformed or truncated input decodes to U+FFFD rather than trapping, and always
	/// consumes at least one byte, so a caller looping to the end of the string always
	/// terminates. The caller guarantees `index < text.Length`.
	public static uint32 DecodeCodepoint(StringView text, ref int index)
	{
		let lead = (uint8)text[index];
		index++;

		if (lead < 0x80)
			return lead;

		uint32 codepoint;
		int extra;
		if ((lead & 0xE0) == 0xC0) { codepoint = lead & 0x1F; extra = 1; }
		else if ((lead & 0xF0) == 0xE0) { codepoint = lead & 0x0F; extra = 2; }
		else if ((lead & 0xF8) == 0xF0) { codepoint = lead & 0x07; extra = 3; }
		else return 0xFFFD; // A continuation byte or an invalid lead: not the start of anything.

		for (int k < extra)
		{
			if (index >= text.Length)
				return 0xFFFD; // Truncated at the end of the string.
			let cont = (uint8)text[index];
			if ((cont & 0xC0) != 0x80)
				return 0xFFFD; // Not a continuation byte, so the sequence is broken.
			codepoint = (codepoint << 6) | (cont & 0x3F);
			index++;
		}
		return codepoint;
	}

	/// The text if it fits, otherwise the longest prefix that fits WITH the ellipsis, plus
	/// the ellipsis.
	///
	/// Each candidate prefix is measured whole rather than by summing per glyph advances,
	/// because kerning makes the sum wrong: the pair that spans the cut contributes an
	/// adjustment that a running total already counted.
	public static void TruncateToWidth(IFont font, StringView text, float maxWidth, String outText,
		StringView ellipsis = "...")
	{
		let textWidth = font.MeasureString(text);

		// A pixel of slack. A control sized to exactly fit its own text can measure a
		// fraction short after layout rounding, and without this a snug button turns its
		// label into an ellipsis: "OK" becomes "...".
		if ((text.Length == 0) || (textWidth <= maxWidth + 1.0f))
		{
			outText.Append(text);
			return;
		}

		let ellipsisWidth = font.MeasureString(ellipsis);

		// Text no wider than the ellipsis cannot be narrowed by becoming one, and usually
		// gets WIDER: a "+" or "x" button is the case that matters.
		if (textWidth <= ellipsisWidth)
		{
			outText.Append(text);
			return;
		}

		let available = maxWidth - ellipsisWidth;

		int fitBytes = 0;
		int i = 0;
		// A non positive `available` means the ellipsis alone does not fit, so nothing of
		// the text can be kept and the result is just the ellipsis.
		while ((available > 0.0f) && (i < text.Length))
		{
			var probe = i;
			DecodeCodepoint(text, ref probe); // Only the advanced index matters here.
			if (font.MeasureString(text.Substring(0, probe)) > available)
				break;
			fitBytes = probe;
			i = probe;
		}

		outText.Append(text.Substring(0, fitBytes));
		outText.Append(ellipsis);
	}
}
