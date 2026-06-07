namespace Sedulous.GUI;

using Sedulous.Core.Mathematics;

/// A tagged value stored in a StyleRule. Discriminated union of all
/// supported style value types.
public enum StyleValue
{
	case ColorVal(Color);
	case FloatVal(float);
	case ThicknessVal(Thickness);
	case DrawableRef(Drawable);   // StyleSheet owns the Drawable
	case BoolVal(bool);
	case None;

	/// Try to get as Color.
	public Color? AsColor
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
}
