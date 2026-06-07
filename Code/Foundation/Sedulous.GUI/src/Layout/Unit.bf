namespace Sedulous.GUI;

/// Type-safe dimensional value with DPI awareness.
public enum Unit
{
	/// Density-independent pixels (scaled by DPI factor).
	case Dp(float value);
	/// Points (1/72 inch, scaled for font rendering).
	case Pt(float value);
	/// Raw pixels (no scaling).
	case Px(float value);

	/// Resolves to physical pixels given a DPI scale factor.
	public float Resolve(float dpiScale)
	{
		switch (this)
		{
		case .Dp(let v): return v * dpiScale;
		case .Pt(let v): return v * dpiScale;
		case .Px(let v): return v;
		}
	}

	/// Returns the raw numeric value regardless of unit type.
	public float RawValue
	{
		get
		{
			switch (this)
			{
			case .Dp(let v): return v;
			case .Pt(let v): return v;
			case .Px(let v): return v;
			}
		}
	}
}
