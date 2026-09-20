using System;
using System.Collections;

namespace Sedulous.Editor.Fonts;

/// The raster ramp's size list as the page shows and parses it: comma separated pixel
/// sizes, each above zero and at most 512, one decimal shown when it is not whole.
static class FontSizes
{
	/// False, `outSizes` untouched, on junk, an empty list or an out of range size.
	public static bool Parse(StringView text, List<float> outSizes)
	{
		let parsed = scope List<float>();
		double value = 0.0;
		double fraction = 0.0;
		var inNumber = false;
		var inFraction = false;
		for (int i = 0; i <= text.Length; i++)
		{
			let c = (i < text.Length) ? text[i] : ',';
			if ((c >= '0') && (c <= '9'))
			{
				if (inFraction)
				{
					fraction *= 0.1;
					value += (c - '0') * fraction;
				}
				else
					value = value * 10.0 + (c - '0');
				inNumber = true;
			}
			else if ((c == '.') && inNumber && !inFraction)
			{
				inFraction = true;
				fraction = 1.0;
			}
			else if ((c == ',') || (c == ' ') || (c == '\t') || (c == ';'))
			{
				if (inNumber)
				{
					if ((value <= 0.0) || (value > 512.0))
						return false;
					parsed.Add((float)value);
					value = 0.0;
					inNumber = false;
					inFraction = false;
				}
			}
			else
				return false; // a junk character
		}
		if (parsed.IsEmpty)
			return false;
		outSizes.Clear();
		outSizes.AddRange(parsed);
		return true;
	}

	public static void Format(List<float> sizes, String outText)
	{
		for (int i < sizes.Count)
		{
			if (i != 0)
				outText.Append(", ");
			let s = sizes[i];
			let whole = (int32)s;
			let tenth = (int32)((s - (float)whole) * 10.0f + 0.5f);
			if (tenth != 0)
				outText.AppendF("{}.{}", whole, tenth);
			else
				outText.AppendF("{}", whole);
		}
	}
}
