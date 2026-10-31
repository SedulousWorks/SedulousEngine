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
			return (b case .Transform(let other)) && value.Same(other);
		case .Point(let value):
			return (b case .Point(let other)) && value.Same(other);
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

		return (ka == .Color) || (ka == .Thickness) || (ka == .Shadow) || (ka == .Transform) || (ka == .Point) || (ka == .Filter) || (ka == .Drawable);
	}

	private static float Mix(float a, float b, float t) => a + (b - a) * t;

	private static Color MixColor(Color a, Color b, float t) =>
		.(Mix(a.R, b.R, t), Mix(a.G, b.G, t), Mix(a.B, b.B, t), Mix(a.A, b.A, t));

	/// A length `t` of the way from `a` to `b`, component by component.
	private static Unit MixUnit(Unit a, Unit b, float t)
	{
		var result = b;
		result.dp = Mix(a.dp, b.dp, t);
		result.pt = Mix(a.pt, b.pt, t);
		result.px = Mix(a.px, b.px, t);
		result.percent = Mix(a.percent, b.percent, t);
		result.em = Mix(a.em, b.em, t);
		return result;
	}

	/// A 2D matrix as translation, rotation, skew and scale: M = T * R(angle) * K(skew) * S, K the
	/// x-shear (x' = x + skew y), the scale's y taking a reflection's sign (after CSS's
	/// decomposition).
	private struct DecomposedTransform
	{
		public float Tx = 0.0f;
		public float Ty = 0.0f;
		public float Angle = 0.0f;
		public float Skew = 0.0f;
		public float Sx = 1.0f;
		public float Sy = 1.0f;

		public this() {}

		public static DecomposedTransform Of(Transform2D m)
		{
			DecomposedTransform d = .();
			d.Tx = m.Tx;
			d.Ty = m.Ty;
			d.Sx = Math.Sqrt(m.A * m.A + m.B * m.B);
			if (d.Sx <= 1e-12f)
			{
				d.Sx = 0.0f;
				d.Sy = Math.Sqrt(m.C * m.C + m.D * m.D);
				return d;
			}
			d.Angle = Math.Atan2(m.B, m.A);
			let cs = Math.Cos(d.Angle);
			let sn = Math.Sin(d.Angle);
			let skewed = m.C * cs + m.D * sn;
			d.Sy = -m.C * sn + m.D * cs;
			d.Skew = (d.Sy != 0.0f) ? (skewed / d.Sy) : 0.0f;
			return d;
		}

		public Transform2D Matrix()
		{
			var m = Transform2D();
			m.Translate(Tx, Ty);
			m.Rotate(Angle);
			m.Combine(.(1.0f, 0.0f, Skew, 1.0f, 0.0f, 0.0f));
			m.Scale(Sx, Sy);
			return m;
		}
	}

	/// A transform `t` of the way from `a` to `b` into `outList`, as CSS interpolates them:
	/// function by function when both lists name the same functions (`none` padded with the
	/// other's identities, so `none` to rotate(90deg) turns from 0), else through their
	/// decomposed matrices, turning the short way. A translate's percentages need the view's size
	/// there, so lists that differ and hold one are resolved at a size of 0 (their percent parts
	/// drop out).
	public static void LerpTransforms(TransformList a, TransformList b, float t, TransformList outList)
	{
		let from = new TransformList();
		defer from.ReleaseRef();
		let to = new TransformList();
		defer to.ReleaseRef();
		for (int i < a.Count)
			from.Push(a[i]);
		for (int i < b.Count)
			to.Push(b[i]);
		if (from.Count == 0)
		{
			for (int i < to.Count)
				from.Push(to[i].Identity);
		}
		else if (to.Count == 0)
		{
			for (int i < from.Count)
				to.Push(from[i].Identity);
		}
		var sameShape = from.Count == to.Count;
		for (int i = 0; sameShape && (i < from.Count); i++)
			sameShape = from[i].Kind == to[i].Kind;

		outList.Clear();
		if (sameShape)
		{
			for (int i < from.Count)
			{
				let fa = from[i];
				let fb = to[i];
				var f = fa;
				f.X = MixUnit(fa.X, fb.X, t);
				f.Y = MixUnit(fa.Y, fb.Y, t);
				f.A = Mix(fa.A, fb.A, t);
				f.B = Mix(fa.B, fb.B, t);
				for (int k < 6)
					f.M[k] = Mix(fa.M[k], fb.M[k], t);
				outList.Push(f);
			}
			return;
		}
		let x = DecomposedTransform.Of(from.Compose(.(0.0f, 0.0f), 1.0f));
		let y = DecomposedTransform.Of(to.Compose(.(0.0f, 0.0f), 1.0f));
		var turn = y.Angle - x.Angle; // the short way round
		while (turn > Math.PI_f)
			turn -= 2.0f * Math.PI_f;
		while (turn < -Math.PI_f)
			turn += 2.0f * Math.PI_f;
		DecomposedTransform mixed = .();
		mixed.Tx = Mix(x.Tx, y.Tx, t);
		mixed.Ty = Mix(x.Ty, y.Ty, t);
		mixed.Angle = x.Angle + turn * t;
		mixed.Skew = Mix(x.Skew, y.Skew, t);
		mixed.Sx = Mix(x.Sx, y.Sx, t);
		mixed.Sy = Mix(x.Sy, y.Sy, t);
		let m = mixed.Matrix();
		TransformFunction f = .();
		f.Kind = .Matrix;
		f.M = .(m.A, m.B, m.C, m.D, m.Tx, m.Ty);
		outList.Push(f);
	}

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
			if (scratch == null)
				return (t < 0.5f) ? a : b;
			LerpTransforms(from, b.AsTransform, t, scratch.Transform);
			return .Transform(scratch.Transform);

		case .Point(let from):
			if (scratch == null)
				return (t < 0.5f) ? a : b;
			let to = b.AsPoint;
			scratch.Point.X = MixUnit(from.X, to.X, t);
			scratch.Point.Y = MixUnit(from.Y, to.Y, t);
			return .Point(scratch.Point);

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
