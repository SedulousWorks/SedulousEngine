using System;
using System.Collections;

namespace Sedulous.Editor.Scene;

/// A [VisibleWhen] condition: "flag" is truthy, "mode=1,2" is one of the listed raw values.
class PropertyCondition
{
	/// The dependent field's reflected name.
	public String Prop = new .() ~ delete _;
	/// Empty is the truthy test.
	public List<int64> Values = new .() ~ delete _;

	/// Parses a spec; false, with the condition unspecified, for anything malformed: an empty
	/// name, an empty value list, a blank entry, or a non digit.
	public static bool Parse(StringView spec, PropertyCondition outCondition)
	{
		var eq = spec.Length;
		for (int i < spec.Length)
		{
			if (spec[i] == '=')
			{
				eq = i;
				break;
			}
		}
		if (eq == 0)
			return false;
		outCondition.Prop.Set(spec.Substring(0, eq));
		outCondition.Values.Clear();
		if (eq == spec.Length)
			return true; // the truthy form
		int64 value = 0;
		var negative = false;
		var any = false;
		for (int i = eq + 1; i <= spec.Length; i++)
		{
			let c = (i < spec.Length) ? spec[i] : ','; // a sentinel comma flushes the last entry
			if (c == ',')
			{
				if (!any)
					return false;
				outCondition.Values.Add(negative ? -value : value);
				value = 0;
				negative = false;
				any = false;
			}
			else if ((c == '-') && !any && !negative)
			{
				negative = true;
			}
			else if ((c >= '0') && (c <= '9'))
			{
				value = value * 10 + (int64)(c - '0');
				any = true;
			}
			else
			{
				return false;
			}
		}
		return !outCondition.Values.IsEmpty;
	}

	public bool Matches(int64 raw)
	{
		if (Values.IsEmpty)
			return raw != 0;
		for (let v in Values)
		{
			if (v == raw)
				return true;
		}
		return false;
	}
}
