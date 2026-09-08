using System;
using Sedulous.Core;

namespace Sedulous.VG.SVG;

/// The character level scanning every SVG parser here shares.
///
/// Hand written rather than routed through a general parser, because SVG's attribute
/// grammars are small, positional, and each slightly different: a path's numbers may be
/// separated by nothing at all, and a transform's may not.
static class SVGScan
{
	public static bool IsDigit(char8 c) => (c >= '0') && (c <= '9');

	/// A character that could START a number. Used to decide whether an optional argument
	/// is present.
	public static bool IsDigitOrSign(char8 c)
		=> IsDigit(c) || (c == '-') || (c == '+') || (c == '.');

	public static char8 ToLower(char8 c)
		=> ((c >= 'A') && (c <= 'Z')) ? (char8)(c - 'A' + 'a') : c;

	public static bool EqualsIgnoreCase(StringView a, StringView b)
	{
		if (a.Length != b.Length)
			return false;
		for (int i = 0; i < a.Length; i++)
		{
			if (ToLower(a[i]) != ToLower(b[i]))
				return false;
		}
		return true;
	}

	public static bool IsWhitespace(char8 c)
		=> (c == ' ') || (c == '\t') || (c == '\n') || (c == '\r');

	public static void SkipWhitespace(StringView s, ref int pos)
	{
		while ((pos < s.Length) && IsWhitespace(s[pos]))
			pos++;
	}

	/// Whitespace, then at most ONE comma, then whitespace. A second comma is a separator
	/// with nothing between it, which the grammar does not allow.
	public static void SkipComma(StringView s, ref int pos)
	{
		SkipWhitespace(s, ref pos);
		if ((pos < s.Length) && (s[pos] == ','))
			pos++;
		SkipWhitespace(s, ref pos);
	}

	/// Path data allows a run of either, in any order.
	public static void SkipWhitespaceAndCommas(StringView s, ref int pos)
	{
		while ((pos < s.Length) && (IsWhitespace(s[pos]) || (s[pos] == ',')))
			pos++;
	}

	public static bool StartsWith(StringView s, int pos, StringView prefix)
	{
		if ((pos + prefix.Length) > s.Length)
			return false;
		for (int i = 0; i < prefix.Length; i++)
		{
			if (s[pos + i] != prefix[i])
				return false;
		}
		return true;
	}

	public static StringView Trim(StringView text)
	{
		var s = text;
		while (!s.IsEmpty && ((s[0] == ' ') || (s[0] == '\t')))
			s = s.Substring(1);
		while (!s.IsEmpty && ((s[s.Length - 1] == ' ') || (s[s.Length - 1] == '\t')))
			s = s.Substring(0, s.Length - 1);
		return s;
	}

	/// Scans one number and advances past it.
	///
	/// The SCAN is hand written and the conversion delegated, so a leading dot, an
	/// exponent, and a sign are all recognised as part of one token rather than ending it.
	public static bool ScanNumber(StringView s, ref int pos, out float value)
	{
		value = 0.0f;
		if (pos >= s.Length)
			return false;

		let start = pos;
		if ((s[pos] == '-') || (s[pos] == '+'))
			pos++;

		while ((pos < s.Length) && IsDigit(s[pos]))
			pos++;

		if ((pos < s.Length) && (s[pos] == '.'))
		{
			pos++;
			while ((pos < s.Length) && IsDigit(s[pos]))
				pos++;
		}

		if ((pos < s.Length) && ((s[pos] == 'e') || (s[pos] == 'E')))
		{
			pos++;
			if ((pos < s.Length) && ((s[pos] == '-') || (s[pos] == '+')))
				pos++;
			while ((pos < s.Length) && IsDigit(s[pos]))
				pos++;
		}

		if (pos == start)
			return false;

		if (float.Parse(s.Substring(start, pos - start)) case .Ok(let parsed))
		{
			value = parsed;
			return true;
		}
		return false;
	}
}
