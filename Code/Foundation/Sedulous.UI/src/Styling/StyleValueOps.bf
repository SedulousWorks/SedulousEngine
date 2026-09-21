using Sedulous.Core;

namespace Sedulous.UI;

/// Comparing and interpolating style values, which is what transitions are built on.
///
/// A variable's fallback is held on VariableReference directly, so there is no boxed
/// fallback to unwrap here.
static class StyleValueOps
{
	/// Whether two values are the same for the purpose of RETARGETING a transition.
	///
	/// Drawables compare by identity. Keywords and variables always compare unequal, having
	/// been resolved into concrete values well before this is reached, so a plain generated
	/// equality would answer the wrong question for them.
	public static bool Equivalent(StyleValue a, StyleValue b)
	{
		switch (a)
		{
		case .None:
			return b case .None;
		case .Color(let value):
			return (b case .Color(let other)) && (value == other);
		case .Float(let value):
			return (b case .Float(let other)) && (value == other);
		case .Thickness(let value):
			return (b case .Thickness(let other)) && (value == other);
		case .Drawable(let value):
			return (b case .Drawable(let other)) && (value == other);
		case .Bool(let value):
			return (b case .Bool(let other)) && (value == other);
		case .String(let value):
			return (b case .String(let other)) && (value == other);
		case .Length(let value):
			return (b case .Length(let other)) && (value == other);
		case .Shadow(let value):
			return (b case .Shadow(let other)) && (value == other);
		case .Transitions(let value):
			return (b case .Transitions(let other)) && (value == other);
		default:
			return false;
		}
	}

	private static bool IsNumeric(StyleValueKind kind) => (kind == .Float) || (kind == .Length);

	/// Whether a transition can run between these two: both numeric, where a Float and a
	/// Length mix as lengths, or both the same colour, thickness, shadow or drawable.
	public static bool Interpolable(StyleValue a, StyleValue b)
	{
		let ka = a.Kind;
		let kb = b.Kind;

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

		if ((a case .Float(let fa)) && (b case .Float(let fb)))
			return .Float(Mix(fa, fb, t));

		let ka = a.Kind;
		let kb = b.Kind;

		if (IsNumeric(ka) && IsNumeric(kb))
		{
			// A Float mixed with a Length is promoted to a dp Length, so the pair has common
			// footing to interpolate on.
			let from = (ka == .Length) ? a.AsLength.Value : Unit.Dp(a.AsFloat.Value);
			let to = (kb == .Length) ? b.AsLength.Value : Unit.Dp(b.AsFloat.Value);

			var result = to;
			result.dp = Mix(from.dp, to.dp, t);
			result.pt = Mix(from.pt, to.pt, t);
			result.px = Mix(from.px, to.px, t);
			result.percent = Mix(from.percent, to.percent, t);
			result.em = Mix(from.em, to.em, t);
			return .Length(result);
		}

		if (ka != kb)
			return (t < 0.5f) ? a : b;

		switch (a)
		{
		case .Color(let from):
			return .Color(MixColor(from, b.AsColor.Value, t));

		case .Thickness(let from):
			let to = b.AsThickness.Value;
			return .Thickness(.(Mix(from.Left, to.Left, t), Mix(from.Top, to.Top, t),
				Mix(from.Right, to.Right, t), Mix(from.Bottom, to.Bottom, t)));

		case .Shadow(let from):
			let to = b.AsShadow.Value;
			BoxShadow result = .();
			result.OffsetX = Mix(from.OffsetX, to.OffsetX, t);
			result.OffsetY = Mix(from.OffsetY, to.OffsetY, t);
			result.Blur = Mix(from.Blur, to.Blur, t);
			result.Spread = Mix(from.Spread, to.Spread, t);
			result.Color = MixColor(from.Color, to.Color, t);
			// Inset is a yes or no, so it switches rather than blending.
			result.Inset = (t < 0.5f) ? from.Inset : to.Inset;
			return .Shadow(result);

		default:
			return (t < 0.5f) ? a : b;
		}
	}
}
