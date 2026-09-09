using Sedulous.Core;

namespace Sedulous.UI;

/// Comparing and interpolating style values, which is what transitions are built on.
///
/// Raptor's VariableFallback free function has no counterpart: its only job is to unbox a
/// StyleValueBox, and this port holds the fallback directly on VariableReference.
static class StyleValueOps
{
	/// Whether two values are the same for the purpose of RETARGETING a transition. Drawables
	/// compare by identity; keywords and variables always compare unequal, having been
	/// resolved before this is reached.
	public static bool Equivalent(StyleValue a, StyleValue b)
	{
		if (a.GetKind() != b.GetKind())
			return false;

		switch (a.GetKind())
		{
		case .None: return true;
		case .Color: return a.AsColor.Value == b.AsColor.Value;
		case .Float: return a.AsFloat.Value == b.AsFloat.Value;
		case .Thickness: return a.AsThickness.Value == b.AsThickness.Value;
		case .Drawable: return a.AsDrawable == b.AsDrawable;
		case .Bool: return a.AsBool.Value == b.AsBool.Value;
		case .String: return a.AsString.Value == b.AsString.Value;
		case .Length: return a.AsLength.Value == b.AsLength.Value;
		case .Shadow: return a.AsShadow.Value == b.AsShadow.Value;
		case .Transitions: return a.AsTransitions == b.AsTransitions;
		default: return false;
		}
	}

	private static bool IsNumeric(StyleValue.Kind kind) =>
		(kind == .Float) || (kind == .Length);

	/// Whether a transition can run between these two: both numeric, where a Float and a
	/// Length mix as lengths, or both the same colour, thickness, shadow or drawable.
	public static bool Interpolable(StyleValue a, StyleValue b)
	{
		let ka = a.GetKind();
		let kb = b.GetKind();

		if (IsNumeric(ka) && IsNumeric(kb))
			return true;
		if (ka != kb)
			return false;

		return (ka == .Color) || (ka == .Thickness) || (ka == .Shadow) || (ka == .Drawable);
	}

	private static float Mix(float a, float b, float t) => a + (b - a) * t;

	private static Color MixColor(Color a, Color b, float t) =>
		.(Mix(a.R, b.R, t), Mix(a.G, b.G, t), Mix(a.B, b.B, t), Mix(a.A, b.A, t));

	/// The value `t` of the way from `a` to `b`.
	///
	/// Colours, floats, thicknesses, lengths and shadows interpolate. Every other kind
	/// SWITCHES at the midpoint, which is CSS's discrete animation, drawables included: their
	/// cross fade is the draw path's business, not this one's.
	public static StyleValue Lerp(StyleValue a, StyleValue b, float t)
	{
		if (t <= 0.0f)
			return a;
		if (t >= 1.0f)
			return b;

		let ka = a.GetKind();
		let kb = b.GetKind();

		if ((ka == .Float) && (kb == .Float))
			return StyleValue.FloatVal(Mix(a.AsFloat.Value, b.AsFloat.Value, t));

		if (IsNumeric(ka) && IsNumeric(kb))
		{
			// A Float mixed with a Length is promoted to a dp Length, so the pair has a
			// common footing to interpolate on.
			let from = (ka == .Length) ? a.AsLength.Value : Unit.Dp(a.AsFloat.Value);
			let to = (kb == .Length) ? b.AsLength.Value : Unit.Dp(b.AsFloat.Value);

			var result = to;
			result.dp = Mix(from.dp, to.dp, t);
			result.pt = Mix(from.pt, to.pt, t);
			result.px = Mix(from.px, to.px, t);
			result.percent = Mix(from.percent, to.percent, t);
			result.em = Mix(from.em, to.em, t);
			return StyleValue.LengthVal(result);
		}

		if (ka != kb)
			return (t < 0.5f) ? a : b;

		switch (ka)
		{
		case .Color:
			return StyleValue.ColorVal(MixColor(a.AsColor.Value, b.AsColor.Value, t));

		case .Thickness:
			let from = a.AsThickness.Value;
			let to = b.AsThickness.Value;
			return StyleValue.ThicknessVal(.(Mix(from.Left, to.Left, t), Mix(from.Top, to.Top, t),
				Mix(from.Right, to.Right, t), Mix(from.Bottom, to.Bottom, t)));

		case .Shadow:
			let from = a.AsShadow.Value;
			let to = b.AsShadow.Value;
			BoxShadow result = .();
			result.OffsetX = Mix(from.OffsetX, to.OffsetX, t);
			result.OffsetY = Mix(from.OffsetY, to.OffsetY, t);
			result.Blur = Mix(from.Blur, to.Blur, t);
			result.Spread = Mix(from.Spread, to.Spread, t);
			result.Color = MixColor(from.Color, to.Color, t);
			// Inset is a yes or no, so it switches rather than blending.
			result.Inset = (t < 0.5f) ? from.Inset : to.Inset;
			return StyleValue.ShadowVal(result);

		default:
			return (t < 0.5f) ? a : b;
		}
	}
}
