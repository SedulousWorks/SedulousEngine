namespace Sedulous.UI;

using System;

public enum MeasureMode
{
	/// No constraint — child can be any size it wants.
	Unspecified,
	/// Maximum size — child can be smaller but not larger.
	AtMost,
	/// Exact size — child must be exactly this size.
	Exactly
}

/// Encodes both constraint mode AND size for one axis of measurement.
/// Children use Resolve(desiredSize) to compute their final measured size.
public struct MeasureSpec
{
	public MeasureMode Mode;
	public float Size;

	public static MeasureSpec Unspecified() => .() { Mode = .Unspecified };
	public static MeasureSpec AtMost(float size) => .() { Mode = .AtMost, Size = size };
	public static MeasureSpec Exactly(float size) => .() { Mode = .Exactly, Size = size };

	/// Resolve a desired size against this spec.
	public float Resolve(float desired)
	{
		switch (Mode)
		{
		case .Exactly:     return Size;
		case .AtMost:      return Math.Min(desired, Size);
		case .Unspecified: return desired;
		}
	}
}
