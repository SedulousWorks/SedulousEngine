using System;

namespace Sedulous.GUI;

/// Represents size constraints for layout calculation.
/// Provides minimum, maximum, and preferred sizes.
public struct SizeConstraints : IEquatable<SizeConstraints>
{
	/// No size restriction (large value that won't overflow calculations).
	public const float Infinity = 100000.0f;

	public float MinWidth;
	public float MinHeight;
	public float MaxWidth;
	public float MaxHeight;

	public this()
	{
		MinWidth = 0;
		MinHeight = 0;
		MaxWidth = Infinity;
		MaxHeight = Infinity;
	}

	public this(float minWidth, float minHeight, float maxWidth, float maxHeight)
	{
		MinWidth = minWidth;
		MinHeight = minHeight;
		MaxWidth = maxWidth;
		MaxHeight = maxHeight;
	}

	/// Creates constraints with only maximum size specified.
	public static SizeConstraints FromMaximum(float maxWidth, float maxHeight)
	{
		return .(0, 0, maxWidth, maxHeight);
	}

	/// Creates constraints for exact size (min == max).
	public static SizeConstraints Exact(float width, float height)
	{
		return .(width, height, width, height);
	}

	/// No constraints (0 to infinity).
	public static SizeConstraints Unconstrained => .();

	/// Constrains a width value to be within min/max bounds.
	public float ConstrainWidth(float width)
	{
		return Math.Clamp(width, MinWidth, MaxWidth);
	}

	/// Constrains a height value to be within min/max bounds.
	public float ConstrainHeight(float height)
	{
		return Math.Clamp(height, MinHeight, MaxHeight);
	}

	/// Constrains a size to be within min/max bounds.
	public DesiredSize Constrain(DesiredSize size)
	{
		return .(ConstrainWidth(size.Width), ConstrainHeight(size.Height));
	}

	/// Returns constraints reduced by the specified thickness (for padding/margin).
	public SizeConstraints Deflate(Thickness thickness)
	{
		return .(
			Math.Max(0, MinWidth - thickness.TotalHorizontal),
			Math.Max(0, MinHeight - thickness.TotalVertical),
			Math.Max(0, MaxWidth - thickness.TotalHorizontal),
			Math.Max(0, MaxHeight - thickness.TotalVertical)
		);
	}

	/// Whether the maximum width is effectively unbounded.
	public bool HasUnboundedWidth => MaxWidth >= Infinity * 0.5f;

	/// Whether the maximum height is effectively unbounded.
	public bool HasUnboundedHeight => MaxHeight >= Infinity * 0.5f;

	public bool Equals(SizeConstraints other)
	{
		return MinWidth == other.MinWidth && MinHeight == other.MinHeight &&
			   MaxWidth == other.MaxWidth && MaxHeight == other.MaxHeight;
	}

	public override void ToString(String strBuffer)
	{
		strBuffer.AppendF("Constraints(min: {0}x{1}, max: {2}x{3})", MinWidth, MinHeight, MaxWidth, MaxHeight);
	}
}
