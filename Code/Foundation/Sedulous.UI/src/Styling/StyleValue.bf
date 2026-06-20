namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// A tagged value stored in a StyleRule. Discriminated union of all
/// supported style value types.
public enum StyleValue
{
	case ColorVal(Color32);
	case FloatVal(float);
	case ThicknessVal(Thickness);
	case DrawableRef(Drawable);   // Container holds the ref
	case BoolVal(bool);
	case StringRef(String);       // Container owns the String
	case None;

	/// Try to get as Color.
	public Color32? AsColor
	{
		get
		{
			if (this case .ColorVal(let c)) return c;
			return null;
		}
	}

	/// Try to get as float.
	public float? AsFloat
	{
		get
		{
			if (this case .FloatVal(let f)) return f;
			return null;
		}
	}

	/// Try to get as Thickness.
	public Thickness? AsThickness
	{
		get
		{
			if (this case .ThicknessVal(let t)) return t;
			return null;
		}
	}

	/// Try to get as Drawable.
	public Drawable AsDrawable
	{
		get
		{
			if (this case .DrawableRef(let d)) return d;
			return null;
		}
	}

	/// Try to get as bool.
	public bool? AsBool
	{
		get
		{
			if (this case .BoolVal(let b)) return b;
			return null;
		}
	}

	/// Try to get as a borrowed StringView. The backing String is
	/// owned by the container that stored the value (typically a
	/// StyleRule) - do not delete.
	public StringView? AsString
	{
		get
		{
			if (this case .StringRef(let s) && s != null) return StringView(s);
			return null;
		}
	}
}
