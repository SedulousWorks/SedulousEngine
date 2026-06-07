namespace Sedulous.GUI;

using System;

/// Immutable layout constraints carrying min/max on both axes.
/// Replaces MeasureSpec - no modes, just min/max bounds. The math is just clamping.
public struct BoxConstraints
{
	public float MinWidth;
	public float MaxWidth;
	public float MinHeight;
	public float MaxHeight;

	public this(float minWidth, float maxWidth, float minHeight, float maxHeight)
	{
		MinWidth = minWidth;
		MaxWidth = maxWidth;
		MinHeight = minHeight;
		MaxHeight = maxHeight;
	}

	/// Exact size on both axes (min == max).
	public static BoxConstraints Tight(float width, float height)
	{
		return .(width, width, height, height);
	}

	/// Zero minimum, specified maximum. Child can be any size up to max.
	public static BoxConstraints Loose(float maxWidth, float maxHeight)
	{
		return .(0, maxWidth, 0, maxHeight);
	}

	/// Unconstrained on both axes.
	public static BoxConstraints Expand()
	{
		return .(0, float.MaxValue, 0, float.MaxValue);
	}

	/// Shrinks constraints by padding/margin on all sides.
	public BoxConstraints Deflate(Thickness padding)
	{
		let hPad = padding.Left + padding.Right;
		let vPad = padding.Top + padding.Bottom;
		return .(
			Math.Max(0, MinWidth - hPad),
			Math.Max(0, MaxWidth - hPad),
			Math.Max(0, MinHeight - vPad),
			Math.Max(0, MaxHeight - vPad)
		);
	}

	/// Clamps a width value to the constraint range.
	public float ConstrainWidth(float width)
	{
		return Math.Clamp(width, MinWidth, MaxWidth);
	}

	/// Clamps a height value to the constraint range.
	public float ConstrainHeight(float height)
	{
		return Math.Clamp(height, MinHeight, MaxHeight);
	}

	/// Whether both axes are tight (min == max).
	public bool IsTight => MinWidth == MaxWidth && MinHeight == MaxHeight;

	/// Whether both axes have zero minimum (child can be any size up to max).
	public bool IsLoose => MinWidth == 0 && MinHeight == 0;

	/// Returns a loose version of these constraints (zero min, same max).
	public BoxConstraints Loosen()
	{
		return .(0, MaxWidth, 0, MaxHeight);
	}

	/// Returns tight constraints at the maximum size.
	public BoxConstraints TightenToMax()
	{
		return .(MaxWidth, MaxWidth, MaxHeight, MaxHeight);
	}
}
