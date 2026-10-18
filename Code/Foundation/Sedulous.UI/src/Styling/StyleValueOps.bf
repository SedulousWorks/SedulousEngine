using System;
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
		case .Shadow, .Shadows:
			// Shadow by shadow, whichever case carries them.
			let count = a.ShadowCount;
			if (b.ShadowCount != count)
				return false;
			for (int i < count)
			{
				if (a.ShadowAt(i) != b.ShadowAt(i))
					return false;
			}
			return true;
		case .Transform(let value):
			return (b case .Transform(let other)) && (value == other);
		case .Filter(let value):
			return (b case .Filter(let other)) && (value == other);
		case .Animations(let value):
			return (b case .Animations(let other)) && (value == other);
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

		return (ka == .Color) || (ka == .Thickness) || (ka == .Shadow) || (ka == .Transform) || (ka == .Filter) || (ka == .Drawable);
	}

	private static float Mix(float a, float b, float t) => a + (b - a) * t;

	private static Color MixColor(Color a, Color b, float t) =>
		.(Mix(a.R, b.R, t), Mix(a.G, b.G, t), Mix(a.B, b.B, t), Mix(a.A, b.A, t));

	private static BoxShadow MixShadow(BoxShadow from, BoxShadow to, float t)
	{
		BoxShadow result = .();
		result.OffsetX = Mix(from.OffsetX, to.OffsetX, t);
		result.OffsetY = Mix(from.OffsetY, to.OffsetY, t);
		result.Blur = Mix(from.Blur, to.Blur, t);
		result.Spread = Mix(from.Spread, to.Spread, t);
		result.Color = MixColor(from.Color, to.Color, t);
		// Inset is a yes or no, so it switches rather than blending.
		result.Inset = (t < 0.5f) ? from.Inset : to.Inset;
		return result;
	}

	/// A shadow that casts nothing, standing in for `like` where a list is shorter.
	private static BoxShadow ClearShadowLike(BoxShadow like)
	{
		BoxShadow none = .();
		none.Color = .(like.Color.R, like.Color.G, like.Color.B, 0.0f);
		none.Inset = like.Inset;
		return none;
	}

	/// The value `t` of the way from `a` to `b`.
	///
	/// Colours, floats, thicknesses, lengths and shadows interpolate. Every other kind
	/// SWITCHES at the midpoint, which is CSS's discrete animation, drawables included: their
	/// cross fade is the draw path's business, not this one's.
	///
	/// Shadow lists go shadow by shadow, the shorter padded with clear shadows of the other's,
	/// as CSS pads them, so one added on hover fades in. An in-between of two or more is
	/// written into `scratch`, which the CALLER owns and the result borrows; without one such
	/// a pair switches at the midpoint.
	public static StyleValue Lerp(StyleValue a, StyleValue b, float t, StyleLerpScratch scratch = null)
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

		case .Filter(let from):
			let to = b.AsFilter.Value;
			StyleFilter result = .();
			result.Blur = Mix(from.Blur, to.Blur, t);
			result.Saturation = Mix(from.Saturation, to.Saturation, t);
			result.Brightness = Mix(from.Brightness, to.Brightness, t);
			return .Filter(result);

		case .Transform(let from):
			let to = b.AsTransform.Value;
			StyleTransform result = .();
			result.Translate = .(Mix(from.Translate.X, to.Translate.X, t), Mix(from.Translate.Y, to.Translate.Y, t));
			result.RotateDegrees = Mix(from.RotateDegrees, to.RotateDegrees, t);
			result.Scale = .(Mix(from.Scale.X, to.Scale.X, t), Mix(from.Scale.Y, to.Scale.Y, t));
			return .Transform(result);

		case .Shadow, .Shadows:
			let count = Math.Max(a.ShadowCount, b.ShadowCount);
			if (count == 1)
				return .Shadow(MixShadow(a.ShadowAt(0), b.ShadowAt(0), t));
			if (scratch == null)
				return (t < 0.5f) ? a : b;
			let shadows = scratch.Shadows;
			shadows.Clear();
			for (int i < count)
			{
				let from = (i < a.ShadowCount) ? a.ShadowAt(i) : ClearShadowLike(b.ShadowAt(i));
				let to = (i < b.ShadowCount) ? b.ShadowAt(i) : ClearShadowLike(a.ShadowAt(i));
				shadows.Add(MixShadow(from, to, t));
			}
			return .Shadows(shadows);

		default:
			return (t < 0.5f) ? a : b;
		}
	}
}
