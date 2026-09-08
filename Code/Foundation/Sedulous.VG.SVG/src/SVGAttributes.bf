using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG.SVG;

/// One tag's attributes, and the typed reads over them.
///
/// A small owned map rather than views into the source, because a document is parsed once
/// and the values are read several times each, and a view would tie every element to the
/// text it came from.
class SVGAttributes
{
	private Dictionary<String, String> mValues = new .() ~ DeleteDictionaryAndKeysAndValues!(_);

	public int Count => mValues.Count;

	public void Add(StringView name, StringView value)
	{
		// A repeated attribute takes the LAST value, matching how a browser reads one.
		if (mValues.TryGetValue(scope String(name), let existing))
		{
			existing.Set(value);
			return;
		}
		mValues[new String(name)] = new String(value);
	}

	public bool TryGet(StringView name, out StringView value)
	{
		if (mValues.TryGetValue(scope String(name), let found))
		{
			value = found;
			return true;
		}
		value = default;
		return false;
	}

	public bool Has(StringView name) => TryGet(name, let ignored);

	/// A numeric attribute, defaulting when absent or unreadable.
	///
	/// A trailing UNIT is dropped: "12px" reads as twelve. Everything here is in user units
	/// anyway, and refusing a unit would fail on files that are otherwise fine.
	public float Number(StringView name, float fallback = 0.0f)
	{
		if (!TryGet(name, let text))
			return fallback;
		if (ParseNumber(text) case .Ok(let value))
			return value;
		return fallback;
	}

	/// A gradient coordinate or a stop offset, which may be a PERCENTAGE.
	public float Fraction(StringView name, float fallback)
	{
		if (!TryGet(name, let text))
			return fallback;
		return ParseFraction(text, fallback);
	}

	public bool EqualsIgnoreCase(StringView name, StringView expected)
	{
		if (!TryGet(name, let text))
			return false;
		return SVGScan.EqualsIgnoreCase(text, expected);
	}

	public void Clear()
	{
		DeleteDictionaryAndKeysAndValues!(mValues);
		mValues = new .();
	}

	/// The leading number of a value, ignoring any unit after it.
	public static Result<float, ErrorCode> ParseNumber(StringView text)
	{
		var end = 0;
		while ((end < text.Length) && (SVGScan.IsDigit(text[end]) || (text[end] == '.')
			|| (text[end] == '-') || (text[end] == '+')))
			end++;

		if (end == 0)
			return .Err(.InvalidArgument);

		if (float.Parse(text.Substring(0, end)) case .Ok(let value))
			return value;
		return .Err(.InvalidArgument);
	}

	/// A number that may carry a percent sign, which scales it into a fraction.
	public static float ParseFraction(StringView text, float fallback)
	{
		if (!(ParseNumber(text) case .Ok(let value)))
			return fallback;

		let trimmed = SVGScan.Trim(text);
		let percent = !trimmed.IsEmpty && (trimmed[trimmed.Length - 1] == '%');
		return percent ? (value / 100.0f) : value;
	}
}
