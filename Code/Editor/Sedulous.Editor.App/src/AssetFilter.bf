using System;
using Sedulous.Content;

namespace Sedulous.Editor.App;

/// What the asset browser's and the asset picker's filter field finds: a name, or a guid or
/// its start, typed or pasted.
static class AssetFilter
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

	/// Whether the filter finds `instance`: an empty one finds everything; otherwise its name
	/// contains the text (any case), or its guid begins with the text's hex digits.
	public static bool Matches(Instance instance, StringView filter)
	{
		if (filter.IsEmpty || (instance.Name.IndexOf(filter, true) >= 0))
			return true;
		let digits = scope String();
		if (!GuidDigits(filter, digits))
			return false;
		let text = instance.Id.ToString(.. scope .());
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
	public static bool AsGuid(StringView filter, out Guid outId)
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
