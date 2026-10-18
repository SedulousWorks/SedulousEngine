using System;

namespace Sedulous.I18N;

/// Locale ids shaped as BCP 47 (`en`, `pt-BR`, `zh-Hans-CN`), with no database of locales: a
/// locale's parent, a normal form for comparing, and whether an id has the shape. Which way a
/// language is written and how it counts are the string tables' to say, never this code's.
static class LocaleId
{
	/// The locale one subtag shorter (`pt-BR` to `pt`, `zh-Hans-CN` to `zh-Hans`); empty when
	/// there is none. Takes `-` or `_` between subtags.
	public static StringView Parent(StringView locale)
	{
		for (int i = locale.Length - 1; i >= 0; i--)
		{
			if ((locale[i] == '-') || (locale[i] == '_'))
				return locale.Substring(0, i);
		}
		return .();
	}

	/// The form two ids compare in: the language lowercased, subtags joined by `-`, the rest as
	/// written (`en_us` and `en-us` are both `en-us`; `EN-US` is `en-US`).
	public static void Normalize(StringView locale, String outLocale)
	{
		bool inLanguage = true;
		for (var c in locale)
		{
			if ((c == '_') || (c == '-'))
			{
				inLanguage = false;
				outLocale.Append('-');
				continue;
			}
			if (inLanguage && (c >= 'A') && (c <= 'Z'))
				c = (char8)(c - 'A' + 'a');
			outLocale.Append(c);
		}
	}

	/// Whether two ids name the same locale, by their normal forms and ignoring the case of the
	/// region and script subtags as well.
	public static bool Same(StringView a, StringView b)
	{
		if (a.Length != b.Length)
			return false;
		for (int i < a.Length)
		{
			if (Folded(a[i]) != Folded(b[i]))
				return false;
		}
		return true;
	}

	private static char8 Folded(char8 c)
	{
		if (c == '_')
			return '-';
		if ((c >= 'A') && (c <= 'Z'))
			return (char8)(c - 'A' + 'a');
		return c;
	}

	/// Whether `locale` has a locale's shape: a language of two or three letters, then a script
	/// of four letters, a region of two letters or three digits, or both in that order (`en`,
	/// `fil`, `pt-BR`, `zh-Hans`, `zh-Hans-CN`, `es-419`). The shape only: never whether it
	/// exists.
	public static bool IsShaped(StringView locale)
	{
		StringView[4] parts = default;
		int count = 0;
		int start = 0;
		for (int i = 0; i <= locale.Length; i++)
		{
			if ((i == locale.Length) || (locale[i] == '-') || (locale[i] == '_'))
			{
				if (count == 4)
					return false;
				parts[count++] = locale.Substring(start, i - start);
				start = i + 1;
			}
		}

		if ((parts[0].Length < 2) || (parts[0].Length > 3) || !AllLetters(parts[0]))
			return false;
		int at = 1;
		// A script.
		if ((at < count) && (parts[at].Length == 4) && AllLetters(parts[at]))
			at++;
		// A region.
		if ((at < count) && (((parts[at].Length == 2) && AllLetters(parts[at]))
			|| ((parts[at].Length == 3) && AllDigits(parts[at]))))
			at++;
		return at == count;
	}

	private static bool AllLetters(StringView text)
	{
		for (let c in text)
		{
			if (!(((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z'))))
				return false;
		}
		return true;
	}

	private static bool AllDigits(StringView text)
	{
		for (let c in text)
		{
			if ((c < '0') || (c > '9'))
				return false;
		}
		return true;
	}
}
