using System;

namespace Sedulous.Core;

/// How the colours between two gradient stops are blended.
enum GradientInterpolation : uint8
{
	/// The sRGB values blended: what a CSS gradient and an image editor do.
	case Srgb;
	/// Blended as light: decoded to linear, blended, encoded back.
	case LinearLight;
	/// Blended in OKLab: even in lightness and hue.
	case OkLab;
	/// A stop's colour held until the next.
	case Constant;
}

/// A colour at a time. Its alpha is the alpha stops', not its own.
struct GradientColorStop
{
	public float Time = 0.0f;
	/// sRGB, as an authored colour is.
	public Color Color = .(1.0f, 1.0f, 1.0f, 1.0f);

	public this() { }

	public this(float time, Color color)
	{
		Time = time;
		Color = color;
	}
}

/// An alpha at a time, apart from the colours, so a fade is edited without touching them.
struct GradientAlphaStop
{
	public float Time = 0.0f;
	public float Alpha = 1.0f;

	public this() { }

	public this(float time, float alpha)
	{
		Time = time;
		Alpha = alpha;
	}
}

/// EvaluateGradient is the engine's ONE gradient: the particles' colour over life samples
/// with it, and an editor draws with it, so what is edited is what plays.
static
{
	/// The sRGB colour of the gradient at time: its colour stops blended by interpolation, its
	/// alpha from the alpha stops (held under Constant, else straight between them). No colour
	/// stops is white; no alpha stops is opaque. Stops sorted by time.
	public static Color EvaluateGradient(Span<GradientColorStop> colors, Span<GradientAlphaStop> alphas,
		GradientInterpolation interpolation, float time)
	{
		var result = Color(1.0f, 1.0f, 1.0f, 1.0f);
		if (GradientBracket(colors, (stop) => stop.Time, time, var a, var b, var t))
		{
			let from = colors[a].Color;
			let to = colors[b].Color;
			switch (interpolation)
			{
			case .Constant:
				result = from;
			case .Srgb:
				result = .(Lerp(from.R, to.R, t), Lerp(from.G, to.G, t), Lerp(from.B, to.B, t));
			case .LinearLight:
				let x = ToLinear(from);
				let y = ToLinear(to);
				result = ToSrgb(.(Lerp(x.R, y.R, t), Lerp(x.G, y.G, t), Lerp(x.B, y.B, t)));
			case .OkLab:
				LinearToOkLab(ToLinear(from), let l0, let a0, let b0);
				LinearToOkLab(ToLinear(to), let l1, let a1, let b1);
				let mixed = OkLabToLinear(Lerp(l0, l1, t), Lerp(a0, a1, t), Lerp(b0, b1, t));
				result = ToSrgb(.(Clamp(mixed.R, 0.0f, 1.0f), Clamp(mixed.G, 0.0f, 1.0f), Clamp(mixed.B, 0.0f, 1.0f)));
			}
		}
		result.A = 1.0f;
		if (GradientBracket(alphas, (stop) => stop.Time, time, var a, var b, var t))
			result.A = (interpolation == .Constant) ? alphas[a].Alpha : Lerp(alphas[a].Alpha, alphas[b].Alpha, t);
		return result;
	}

	/// The two stops either side of time and how far between them (stops sorted by time);
	/// false for none. Outside the stops, the nearest end both sides.
	private static bool GradientBracket<TStop>(Span<TStop> stops, function float(TStop stop) timeOf, float time,
		out int a, out int b, out float t)
	{
		a = 0;
		b = 0;
		t = 0.0f;
		let count = stops.Length;
		if (count == 0)
			return false;
		if ((count == 1) || (time <= timeOf(stops[0])))
			return true;
		if (time >= timeOf(stops[count - 1]))
		{
			a = count - 1;
			b = count - 1;
			return true;
		}
		var i = 0;
		while ((i + 1 < count) && (timeOf(stops[i + 1]) <= time))
			i++;
		a = i;
		b = i + 1;
		let span = timeOf(stops[b]) - timeOf(stops[a]);
		t = (span > 1e-6f) ? (time - timeOf(stops[a])) / span : 1.0f;
		return true;
	}

	private static float SignedCubeRoot(float x) => (x < 0.0f) ? -Pow(-x, 1.0f / 3.0f) : Pow(x, 1.0f / 3.0f);

	/// Linear sRGB to OKLab and back (Björn Ottosson's matrices).
	private static void LinearToOkLab(Color c, out float l, out float a, out float b)
	{
		let lms0 = SignedCubeRoot(0.4122214708f * c.R + 0.5363325363f * c.G + 0.0514459929f * c.B);
		let lms1 = SignedCubeRoot(0.2119034982f * c.R + 0.6806995451f * c.G + 0.1073969566f * c.B);
		let lms2 = SignedCubeRoot(0.0883024619f * c.R + 0.2817188376f * c.G + 0.6299787005f * c.B);
		l = 0.2104542553f * lms0 + 0.7936177850f * lms1 - 0.0040720468f * lms2;
		a = 1.9779984951f * lms0 - 2.4285922050f * lms1 + 0.4505937099f * lms2;
		b = 0.0259040371f * lms0 + 0.7827717662f * lms1 - 0.8086757660f * lms2;
	}

	private static Color OkLabToLinear(float l, float a, float b)
	{
		let lms0 = l + 0.3963377774f * a + 0.2158037573f * b;
		let lms1 = l - 0.1055613458f * a - 0.0638541728f * b;
		let lms2 = l - 0.0894841775f * a - 1.2914855480f * b;
		let l3 = lms0 * lms0 * lms0;
		let m3 = lms1 * lms1 * lms1;
		let s3 = lms2 * lms2 * lms2;
		return .(4.0767416621f * l3 - 3.3077115913f * m3 + 0.2309699292f * s3,
			-1.2684380046f * l3 + 2.6097574011f * m3 - 0.3413193965f * s3,
			-0.0041960863f * l3 - 0.7034186147f * m3 + 1.7076147010f * s3);
	}
}
