using System;

namespace Sedulous.GUI;

/// CSS identifier scanning for the styling parsers: the CSS identifier grammar ([A-Za-z0-9_-],
/// which includes '-' for kebab-case names), CSS-flavoured rather than generic.
static class ParseUtil
{
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
