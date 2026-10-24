using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// Interpolating typed style values, so every property a sheet sets can transition and be
// keyframed, not only opacity and colour: numbers, lengths of one unit, colours (straight RGBA),
// shadow lists (the shorter padded with transparent shadows, as CSS does), transform lists of the
// same functions (function by function), transform origins, and gradient layers of the same shape
// (angle, stop colours and positions). With a context (the length context and the box's size),
// lengths in different units move in pixels, and transform lists of different functions move
// through their matrices, decomposed into translation, rotation, skew and scale (the rotation the
// short way round). What cannot interpolate (keywords, a percentage against another unit)
// switches at the halfway point: CSS's discrete animation.

/// What interpolating lengths of different units and different transform lists needs: the
/// length context (em, rem, vw, vh) and the size of the box the value is for.
struct StyleInterpolationContext
{
	public LengthContext Lengths = .();
	public Float2 BoxSize = .();

	public this() { }

	public this(LengthContext lengths, Float2 boxSize)
	{
		Lengths = lengths;
		BoxSize = boxSize;
	}
}

/// What StyleInterpolation.bf keeps out of the public surface: the mixing of each kind of value.
internal static class StyleInterpolationDetail
{
	public static float Mix(float a, float b, float t) => a + (b - a) * t;

	public static Color MixColor(Color a, Color b, float t) => .(Mix(a.R, b.R, t), Mix(a.G, b.G, t), Mix(a.B, b.B, t), Mix(a.A, b.A, t));

	public static bool MixLength(LengthValue a, LengthValue b, float t, out LengthValue outValue, StyleInterpolationContext? ctx = null)
	{
		var a;
		var b;
		outValue = default;
		// A calc() on either side: term by term, each unit as it is.
		if ((a.Unit == .Calc) || (b.Unit == .Calc))
		{
			let x = a.ToTerms();
			let y = b.ToTerms();
			float[cLengthUnitCount] mixed = default;
			for (int i = 0; i < cLengthUnitCount; i++)
				mixed[i] = Mix(x[i], y[i], t);
			outValue = LengthValue.FromTerms(mixed);
			return true;
		}
		// A zero converts to any unit (CSS writes 0 unitless).
		if (a.Value == 0.0f)
			a.Unit = b.Unit;
		if (b.Value == 0.0f)
			b.Unit = a.Unit;
		if (a.Unit != b.Unit)
		{
			// Different units meet in pixels, when neither is a percentage (whose base the
			// property decides).
			if (!ctx.HasValue || (a.Unit == .Percent) || (b.Unit == .Percent))
				return false;
			let lengths = ctx.Value.Lengths;
			outValue = LengthValue(Mix(ResolveLengthValue(a, lengths), ResolveLengthValue(b, lengths), t), .Px);
			return true;
		}
		outValue = LengthValue(Mix(a.Value, b.Value, t), a.Unit);
		return true;
	}

	public static bool MixShadows(List<ShadowValue> a, List<ShadowValue> b, float t, List<ShadowValue> outShadows, StyleInterpolationContext? ctx)
	{
		let n = Math.Max(a.Count, b.Count);
		outShadows.Clear();
		for (int i = 0; i < n; i++)
		{
			// The shorter list is padded with a transparent shadow of the other's insetness.
			var from = (i < a.Count) ? a[i] : ShadowValue();
			var to = (i < b.Count) ? b[i] : ShadowValue();
			if (i >= a.Count)
			{
				from.Inset = to.Inset;
				from.ShadowColor = Color(to.ShadowColor.R, to.ShadowColor.G, to.ShadowColor.B, 0.0f);
			}
			if (i >= b.Count)
			{
				to.Inset = from.Inset;
				to.ShadowColor = Color(from.ShadowColor.R, from.ShadowColor.G, from.ShadowColor.B, 0.0f);
			}
			if (from.Inset != to.Inset)
				return false;
			var mixed = ShadowValue();
			mixed.Inset = from.Inset;
			if (!MixLength(from.OffsetX, to.OffsetX, t, out mixed.OffsetX, ctx) ||
				!MixLength(from.OffsetY, to.OffsetY, t, out mixed.OffsetY, ctx) ||
				!MixLength(from.Blur, to.Blur, t, out mixed.Blur, ctx) ||
				!MixLength(from.Spread, to.Spread, t, out mixed.Spread, ctx))
				return false;
			mixed.ShadowColor = MixColor(from.ShadowColor, to.ShadowColor, t);
			outShadows.Add(mixed);
		}
		return true;
	}

	/// A 2D matrix as translation, rotation, skew and scale: M = T * R(angle) * K(skew) * S, K the
	/// x-shear (x' = x + skew y); the scale's y takes a reflection's sign.
	public struct Decomposed
	{
		public float Tx = 0.0f;
		public float Ty = 0.0f;
		public float Angle = 0.0f;
		public float Skew = 0.0f;
		public float Sx = 1.0f;
		public float Sy = 1.0f;

		public this() { }
	}

	public static Decomposed Decompose(Transform2D m)
	{
		var d = Decomposed();
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
		let skewed = m.C * cs + m.D * sn; // the second column along the rotated x axis
		d.Sy = -m.C * sn + m.D * cs; // ... and along the rotated y axis
		d.Skew = (d.Sy != 0.0f) ? skewed / d.Sy : 0.0f;
		return d;
	}

	public static Transform2D Recompose(Decomposed d)
	{
		var m = Transform2D();
		m.Translate(d.Tx, d.Ty);
		m.Rotate(d.Angle);
		m.Combine(Transform2D(1.0f, 0.0f, d.Skew, 1.0f, 0.0f, 0.0f));
		m.Scale(d.Sx, d.Sy);
		return m;
	}

	/// Two transform lists of different functions, through their matrices.
	public static TransformFunction MixMatrices(List<TransformFunction> a, List<TransformFunction> b, float t, Float2 size)
	{
		let x = Decompose(ComposeTransforms(a, size));
		let y = Decompose(ComposeTransforms(b, size));
		const float cPi = 3.14159265358979f;
		var turn = y.Angle - x.Angle; // the short way round
		while (turn > cPi)
			turn -= 2.0f * cPi;
		while (turn < -cPi)
			turn += 2.0f * cPi;
		var mixed = Decomposed();
		mixed.Tx = Mix(x.Tx, y.Tx, t);
		mixed.Ty = Mix(x.Ty, y.Ty, t);
		mixed.Angle = x.Angle + turn * t;
		mixed.Skew = Mix(x.Skew, y.Skew, t);
		mixed.Sx = Mix(x.Sx, y.Sx, t);
		mixed.Sy = Mix(x.Sy, y.Sy, t);
		let m = Recompose(mixed);
		var f = TransformFunction();
		f.Kind = .Matrix;
		f.M = .(m.A, m.B, m.C, m.D, m.Tx, m.Ty);
		return f;
	}

	/// none against a list: the list's identity functions (CSS), so `none -> rotate(90deg)` turns
	/// from 0.
	private static TransformFunction IdentityLike(TransformFunction like)
	{
		var id = TransformFunction();
		id.Kind = like.Kind;
		id.A = LengthValue(0.0f, like.A.Unit);
		id.B = LengthValue(0.0f, like.B.Unit);
		return id; // angle 0, scale 1, matrix identity by default
	}

	public static bool MixTransforms(List<TransformFunction> a, List<TransformFunction> b, float t, List<TransformFunction> outFunctions,
		StyleInterpolationContext? ctx)
	{
		var from = a;
		var to = b;
		let padded = scope List<TransformFunction>();
		if (a.IsEmpty && !b.IsEmpty)
		{
			for (let f in b)
				padded.Add(IdentityLike(f));
			from = padded;
		}
		else if (b.IsEmpty && !a.IsEmpty)
		{
			for (let f in a)
				padded.Add(IdentityLike(f));
			to = padded;
		}
		// Lists of different functions (or lengths that cannot meet) go through their matrices.
		bool same = from.Count == to.Count;
		for (int i = 0; same && (i < from.Count); i++)
			same = from[i].Kind == to[i].Kind;
		if (!same)
			return ThroughMatrices(a, b, t, outFunctions, ctx);
		outFunctions.Clear();
		for (int i = 0; i < from.Count; i++)
		{
			let x = from[i];
			let y = to[i];
			var m = x;
			if (!MixLength(x.A, y.A, t, out m.A, ctx) || !MixLength(x.B, y.B, t, out m.B, ctx))
				return ThroughMatrices(a, b, t, outFunctions, ctx);
			m.Angle = Mix(x.Angle, y.Angle, t);
			m.AngleY = Mix(x.AngleY, y.AngleY, t);
			m.ScaleX = Mix(x.ScaleX, y.ScaleX, t);
			m.ScaleY = Mix(x.ScaleY, y.ScaleY, t);
			for (int k = 0; k < 6; k++)
				m.M[k] = Mix(x.M[k], y.M[k], t);
			outFunctions.Add(m);
		}
		return true;
	}

	private static bool ThroughMatrices(List<TransformFunction> a, List<TransformFunction> b, float t, List<TransformFunction> outFunctions,
		StyleInterpolationContext? ctx)
	{
		outFunctions.Clear();
		outFunctions.Add(MixMatrices(a, b, t, ctx.HasValue ? ctx.Value.BoxSize : Float2()));
		return true;
	}

	/// `outLayers` owns its items: the ones there are deleted, the mixed ones added.
	public static bool MixLayers(List<BackgroundLayer> a, List<BackgroundLayer> b, float t, List<BackgroundLayer> outLayers)
	{
		if (a.Count != b.Count)
			return false;
		ClearAndDeleteItems(outLayers);
		for (int i = 0; i < a.Count; i++)
		{
			let x = a[i];
			let y = b[i];
			if (x.Kind != y.Kind)
				return false;
			let m = new BackgroundLayer();
			m.Set(x);
			if (x.Kind == .Gradient)
			{
				let sx = scope List<GradientStopValue>();
				let sy = scope List<GradientStopValue>();
				SettleStops(x.Gradient.Stops, sx);
				SettleStops(y.Gradient.Stops, sy);
				if ((x.Gradient.Kind != y.Gradient.Kind) || (x.Gradient.Repeating != y.Gradient.Repeating) || (sx.Count != sy.Count))
				{
					delete m;
					return false;
				}
				m.Gradient.Angle = Mix(x.Gradient.Angle, y.Gradient.Angle, t);
				m.Gradient.Stops.Clear();
				for (int k = 0; k < sx.Count; k++)
					m.Gradient.Stops.Add(GradientStopValue(MixColor(sx[k].StopColor, sy[k].StopColor, t), Mix(sx[k].Position, sy[k].Position, t)));
			}
			else if (x.Kind == .Color)
			{
				m.LayerColor = MixColor(x.LayerColor, y.LayerColor, t);
			}
			else if (x.Image != y.Image)
			{
				delete m;
				return false; // two images do not blend
			}
			outLayers.Add(m);
		}
		return true;
	}

	/// Filter lists: the shorter padded with the other's functions at their identity (blur(0)),
	/// then function by function; lists of different functions switch.
	public static bool MixFilters(List<FilterFunction> a, List<FilterFunction> b, float t, List<FilterFunction> outFilters,
		StyleInterpolationContext? ctx)
	{
		let n = Math.Max(a.Count, b.Count);
		outFilters.Clear();
		for (int i = 0; i < n; i++)
		{
			let from = (i < a.Count) ? a[i] : FilterFunction(b[i].Kind, LengthValue());
			let to = (i < b.Count) ? b[i] : FilterFunction(a[i].Kind, LengthValue());
			if (from.Kind != to.Kind)
				return false;
			var mixed = FilterFunction(from.Kind, LengthValue());
			if (!MixLength(from.Amount, to.Amount, t, out mixed.Amount, ctx))
				return false;
			mixed.Amount.Value = Math.Max(0.0f, mixed.Amount.Value); // an overshooting easing
			outFilters.Add(mixed);
		}
		return true;
	}
}

static
{
	/// `a` toward `b` at `t` (0: a, 1: b; t may leave [0, 1] for an overshooting easing), into
	/// `outValue`, which must be neither `a` nor `b`. Values that cannot interpolate switch at
	/// t = 0.5.
	public static void InterpolateStyleValue(StyleValue a, StyleValue b, float t, StyleValue outValue, StyleInterpolationContext? ctx = null)
	{
		Debug.Assert((outValue !== a) && (outValue !== b));
		let discrete = (t < 0.5f) ? a : b;
		if (a.Kind != b.Kind)
		{
			outValue.Set(discrete);
			return;
		}
		outValue.Set(a);
		bool mixed = false;
		switch (a.Kind)
		{
		case .Number:
			outValue.Number = StyleInterpolationDetail.Mix(a.Number, b.Number, t);
			mixed = true;
		case .Length:
			mixed = StyleInterpolationDetail.MixLength(a.Length, b.Length, t, out outValue.Length, ctx);
		case .ColorValue:
			outValue.ColorValue = StyleInterpolationDetail.MixColor(a.ColorValue, b.ColorValue, t);
			mixed = true;
		case .Shadows:
			mixed = StyleInterpolationDetail.MixShadows(a.Shadows, b.Shadows, t, outValue.Shadows, ctx);
		case .Transforms:
			mixed = StyleInterpolationDetail.MixTransforms(a.Transforms, b.Transforms, t, outValue.Transforms, ctx);
		case .Origin:
			mixed = StyleInterpolationDetail.MixLength(a.OriginX, b.OriginX, t, out outValue.OriginX, ctx) &&
				StyleInterpolationDetail.MixLength(a.OriginY, b.OriginY, t, out outValue.OriginY, ctx);
		case .Layers:
			mixed = StyleInterpolationDetail.MixLayers(a.Layers, b.Layers, t, outValue.Layers);
		case .Filters:
			mixed = StyleInterpolationDetail.MixFilters(a.Filters, b.Filters, t, outValue.Filters, ctx);
		case .Keyword, .None:
			mixed = false;
		}
		if (!mixed)
			outValue.Set(discrete);
	}
}
