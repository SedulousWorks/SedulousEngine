using System;

namespace Sedulous.GUI;

/// CSS identifier scanning for the styling parsers: the CSS identifier grammar ([A-Za-z0-9_-],
/// which includes '-' for kebab-case names), CSS-flavoured rather than generic. Also the ASCII
/// classification and trimming the value parsers share: CSS's whitespace is ASCII's six, wider
/// than char8.IsWhiteSpace (which leaves out form feed and vertical tab).
static class ParseUtil
{
	/// Space, tab, line feed, carriage return, form feed or vertical tab.
	public static bool IsWhiteSpace(char8 c) =>
		(c == ' ') || (c == '\t') || (c == '\n') || (c == '\r') || ((uint8)c == 0x0C) || ((uint8)c == 0x0B);

	public static bool IsDigit(char8 c) => (c >= '0') && (c <= '9');

	/// A hex digit's value (0 to 15), or -1 when `c` is none.
	public static int32 HexValue(char8 c)
	{
		if ((c >= '0') && (c <= '9'))
			return (int32)c - (int32)'0';
		if ((c >= 'a') && (c <= 'f'))
			return (int32)c - (int32)'a' + 10;
		if ((c >= 'A') && (c <= 'F'))
			return (int32)c - (int32)'A' + 10;
		return -1;
	}

	/// `s` without its leading and trailing whitespace.
	public static StringView Trim(StringView s)
	{
		int begin = 0;
		int end = s.Length;
		while ((begin < end) && IsWhiteSpace(s[begin]))
			begin++;
		while ((end > begin) && IsWhiteSpace(s[end - 1]))
			end--;
		return s.Substring(begin, end - begin);
	}

	/// A CSS identifier character: letters, digits, '-' (kebab-case) and '_'.
	public static bool IsIdentChar(char8 c) =>
		((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) || ((c >= '0') && (c <= '9')) || (c == '-') || (c == '_');

	/// Reads an identifier starting at `i`, advancing `i` past it.
	public static StringView ReadIdent(StringView s, ref int i)
	{
		let start = i;
		while ((i < s.Length) && IsIdentChar(s[i]))
			i++;
		return s.Substring(start, i - start);
	}
}
