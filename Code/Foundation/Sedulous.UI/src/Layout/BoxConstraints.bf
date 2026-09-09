using Sedulous.Core;

namespace Sedulous.UI;

/// Layout constraints: a minimum and maximum on each axis, and the clamping that goes with
/// them. No modes, just numbers.
struct BoxConstraints
{
	public float MinWidth = 0.0f;
	public float MaxWidth = 0.0f;
	public float MinHeight = 0.0f;
	public float MaxHeight = 0.0f;

	public this() {}

	public this(float minWidth, float maxWidth, float minHeight, float maxHeight)
	{
		MinWidth = minWidth;
		MaxWidth = maxWidth;
		MinHeight = minHeight;
		MaxHeight = maxHeight;
	}

	/// An exact size on both axes.
	public static BoxConstraints Tight(float width, float height) =>
		.(width, width, height, height);

	/// No minimum, a stated maximum.
	public static BoxConstraints Loose(float maxWidth, float maxHeight) =>
		.(0.0f, maxWidth, 0.0f, maxHeight);

	/// Unconstrained on both axes.
	public static BoxConstraints Expand() => .(0.0f, FloatMax, 0.0f, FloatMax);

	/// Shrinks by padding or margin on all sides, never below nought.
	public BoxConstraints Deflate(Thickness padding)
	{
		let horizontal = padding.Left + padding.Right;
		let vertical = padding.Top + padding.Bottom;
		return .(Max(0.0f, MinWidth - horizontal), Max(0.0f, MaxWidth - horizontal),
			Max(0.0f, MinHeight - vertical), Max(0.0f, MaxHeight - vertical));
	}

	public float ConstrainWidth(float width) => Max(MinWidth, Min(width, MaxWidth));
	public float ConstrainHeight(float height) => Max(MinHeight, Min(height, MaxHeight));

	/// THE unbounded test, so that the check lives in one place rather than as a scattered
	/// comparison against a large number.
	public static bool IsBounded(float extent) => extent < FloatMax;

	/// The available extent on an axis, or `fallback` when the parent gave no bound.
	///
	/// This is what fill style views use instead of reading MaxWidth raw: under an unbounded
	/// parent, such as a scroll axis, that measured to FloatMax and blew the layout apart.
	public float BoundedMaxWidth(float fallback) => IsBounded(MaxWidth) ? MaxWidth : fallback;
	public float BoundedMaxHeight(float fallback) => IsBounded(MaxHeight) ? MaxHeight : fallback;

	/// Both axes exact.
	public bool IsTight => (MinWidth == MaxWidth) && (MinHeight == MaxHeight);
	/// Both axes free at the bottom.
	public bool IsLoose => (MinWidth == 0.0f) && (MinHeight == 0.0f);

	/// The same maxima with no minimum.
	public BoxConstraints Loosen() => .(0.0f, MaxWidth, 0.0f, MaxHeight);
	/// Exact, at the maximum size.
	public BoxConstraints TightenToMax() => .(MaxWidth, MaxWidth, MaxHeight, MaxHeight);
}
