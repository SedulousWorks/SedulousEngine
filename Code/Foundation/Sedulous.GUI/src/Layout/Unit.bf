namespace Sedulous.GUI;

using System;

/// Type-safe dimensional value. Carries intent (dp/pt/px) and resolves
/// to pixels at layout time when the DPI scale is available.
public enum Unit
{
	/// Density-independent pixels. Scaled by DPI (1dp = 1px at 96dpi).
	case Dp(float value);

	/// Points (1/72 inch). Used for font sizes.
	case Pt(float value);

	/// Raw pixels. No DPI scaling.
	case Px(float value);

	/// Resolves this unit to pixels given the current DPI scale.
	/// dpiScale: ratio of physical pixels to logical pixels (1.0 at 96dpi, 2.0 at 192dpi).
	public float Resolve(float dpiScale)
	{
		switch (this)
		{
		case .Dp(let v): return v * dpiScale;
		case .Pt(let v): return v * dpiScale * (96.0f / 72.0f);
		case .Px(let v): return v;
		}
	}

	/// Gets the raw value without DPI conversion.
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
