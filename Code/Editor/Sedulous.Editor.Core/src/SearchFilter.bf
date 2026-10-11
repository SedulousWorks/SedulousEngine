using System;

namespace Sedulous.Editor.Core;

/// What the editor's filter fields find, the asset browser's and picker's and the hierarchy's
/// and entity picker's alike: a thing whose name contains the text (any case), or whose guid
/// begins with it. So a guid copied from a log line, an MCP answer or a scene file finds what it
/// names, written whole or as its first few digits, with or without braces and dashes, in any
/// case. A whole guid (FilterAsGuid) is a request for that one thing: the fields select it.
static class SearchFilter
{
	private static bool IsHex(char8 c) => c.IsDigit || ((c.ToLower >= 'a') && (c.ToLower <= 'f'));

	/// The filter's hex digits, lowercased, when it reads as (part of) a guid: hex digits,
	/// dashes, braces and spaces only, at least four digits. False otherwise.
	private static bool GuidDigits(StringView filter, String outDigits)
	{
		outDigits.Clear();
		for (let c in filter)
		{
			if (IsHex(c))
				outDigits.Append(c.ToLower);
			else if ((c != '-') && (c != '{') && (c != '}') && (c != ' '))
				return false;
		}
		return outDigits.Length >= 4;
	}

	/// Whether `text` contains `part`, any case; an empty part is in everything.
	public static bool TextContains(StringView text, StringView part) => part.IsEmpty || (text.IndexOf(part, true) >= 0);

	/// Whether the filter finds the thing called `name` with id `id`: an empty one finds
	/// everything; otherwise its name contains the text (any case), or its guid begins with the
	/// text's hex digits.
	public static bool NameOrGuidMatches(StringView name, Guid id, StringView filter)
	{
		if (TextContains(name, filter))
			return true;
		let digits = scope String();
		if (!GuidDigits(filter, digits))
			return false;
		let text = id.ToString(.. scope .());
		var matched = 0;
		for (int i < text.Length)
		{
			let c = text[i];
			if (matched == digits.Length)
				break;
			if (c == '-')
				continue;
			if (c != digits[matched])
				return false;
			matched++;
		}
		return matched == digits.Length;
	}

	/// The guid the filter spells whole (all 32 digits; braces, case and dashes aside).
	public static bool FilterAsGuid(StringView filter, out Guid outId)
	{
		outId = .Empty;
		let digits = scope String();
		if (!GuidDigits(filter, digits) || (digits.Length != 32))
			return false;
		if (!(Guid.Parse(digits) case .Ok(out outId)))
			return false;
		return true;
	}
}
