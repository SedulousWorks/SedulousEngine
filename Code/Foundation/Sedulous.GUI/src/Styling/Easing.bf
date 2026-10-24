using System;
using System.Collections;
using Sedulous.Core;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// CSS easing functions: cubic-bezier(x1, y1, x2, y2), steps(n, position), linear, and the named
// curves (ease, ease-in, ease-out, ease-in-out, step-start, step-end), with the families past
// CSS's (ease-out-back and the like). A cubic Bezier maps time to progress through its x(s) = t,
// solved by Newton's method with a bisection fallback, then y(s).

enum EasingKind : uint8
{
	Linear,
	CubicBezier,
	Steps,
	/// One of the named curves past CSS's: a family eased in, out, or both.
	Named,
}

/// The named curves' families (easings.net's, as Godot's Tween and Zero's eases name them):
/// powers of t, a sine, an exponential, a circle, and three that leave [0, 1] on the way (back
/// overshoots, elastic rings, bounce bounces at the end).
enum EaseFamily : uint8
{
	Sine,
	Quad,
	Cubic,
	Quart,
	Quint,
	Expo,
	Circ,
	Back,
	Elastic,
	Bounce,
}

/// Which end of a family's curve is slow: the start (in), the end (out), or both (in-out).
enum EaseMode : uint8
{
	In,
	Out,
	InOut,
}

/// Where a steps() easing jumps: at the start of each interval, at its end, at both, or at
/// neither (CSS's jump-start, jump-end, jump-both, jump-none; start and end alias the first two).
enum StepPosition : uint8
{
	JumpStart,
	JumpEnd,
	JumpNone,
	JumpBoth,
}

struct Easing
{
	public EasingKind Kind = .Linear;
	/// CubicBezier's control points.
	public float X1 = 0.0f;
	public float Y1 = 0.0f;
	public float X2 = 1.0f;
	public float Y2 = 1.0f;
	public int32 Steps = 1;
	public StepPosition Position = .JumpEnd;
	/// Named's.
	public EaseFamily Family = .Quad;
	public EaseMode Mode = .Out;

	public this() { }

	public static Easing Linear() => .();

	public static Easing Bezier(float x1, float y1, float x2, float y2)
	{
		var e = Easing();
		e.Kind = .CubicBezier;
		e.X1 = x1;
		e.Y1 = y1;
		e.X2 = x2;
		e.Y2 = y2;
		return e;
	}

	public static Easing Stepped(int32 steps, StepPosition position)
	{
		var e = Easing();
		e.Kind = .Steps;
		e.Steps = steps;
		e.Position = position;
		return e;
	}

	public static Easing Named(EaseFamily family, EaseMode mode)
	{
		var e = Easing();
		e.Kind = .Named;
		e.Family = family;
		e.Mode = mode;
		return e;
	}

	/// CSS's default easing.
	public static Easing Ease() => Bezier(0.25f, 0.1f, 0.25f, 1.0f);

	/// Progress at time `t` in [0, 1] (a Bezier's y may leave [0, 1]: overshoot is allowed).
	public float Evaluate(float t)
	{
		let x = Clamp(t, 0.0f, 1.0f);
		switch (Kind)
		{
		case .Linear:
			return x;
		case .CubicBezier:
			return BezierAt(SolveForX(x), Y1, Y2);
		case .Steps:
			return StepAt(x);
		case .Named:
			return NamedAt(x);
		}
	}

	/// Foundation's curves (Sedulous.Core's easings), by family and mode.
	private float NamedAt(float t)
	{
		switch (Family)
		{
		case .Sine: return (Mode == .In) ? EaseInSin(t) : ((Mode == .Out) ? EaseOutSin(t) : EaseInOutSin(t));
		case .Quad: return (Mode == .In) ? EaseInQuadratic(t) : ((Mode == .Out) ? EaseOutQuadratic(t) : EaseInOutQuadratic(t));
		case .Cubic: return (Mode == .In) ? EaseInCubic(t) : ((Mode == .Out) ? EaseOutCubic(t) : EaseInOutCubic(t));
		case .Quart: return (Mode == .In) ? EaseInQuartic(t) : ((Mode == .Out) ? EaseOutQuartic(t) : EaseInOutQuartic(t));
		case .Quint: return (Mode == .In) ? EaseInQuintic(t) : ((Mode == .Out) ? EaseOutQuintic(t) : EaseInOutQuintic(t));
		case .Expo: return (Mode == .In) ? EaseInExponential(t) : ((Mode == .Out) ? EaseOutExponential(t) : EaseInOutExponential(t));
		case .Circ: return (Mode == .In) ? EaseInCircular(t) : ((Mode == .Out) ? EaseOutCircular(t) : EaseInOutCircular(t));
		case .Back: return (Mode == .In) ? EaseInBack(t) : ((Mode == .Out) ? EaseOutBack(t) : EaseInOutBack(t));
		case .Elastic: return (Mode == .In) ? EaseInElastic(t) : ((Mode == .Out) ? EaseOutElastic(t) : EaseInOutElastic(t));
		case .Bounce: return (Mode == .In) ? EaseInBounce(t) : ((Mode == .Out) ? EaseOutBounce(t) : EaseInOutBounce(t));
		}
	}

	/// One coordinate of the curve from (0, 0) through p1, p2 to (1, 1) at parameter s.
	private static float BezierAt(float s, float p1, float p2)
	{
		let u = 1.0f - s;
		return 3.0f * u * u * s * p1 + 3.0f * u * s * s * p2 + s * s * s;
	}

	private static float BezierSlope(float s, float p1, float p2)
	{
		let u = 1.0f - s;
		return 3.0f * u * u * p1 + 6.0f * u * s * (p2 - p1) + 3.0f * s * s * (1.0f - p2);
	}

	/// The parameter s whose x is `x` (x is monotonic in s for x1, x2 in [0, 1]).
	private float SolveForX(float x)
	{
		var s = x;
		for (int32 i = 0; i < 8; i++)
		{
			let error = BezierAt(s, X1, X2) - x;
			if (Math.Abs(error) < 1e-6f)
				return s;
			let slope = BezierSlope(s, X1, X2);
			if (Math.Abs(slope) < 1e-6f)
				break;
			s -= error / slope;
		}
		float lo = 0.0f;
		float hi = 1.0f;
		s = x;
		for (int32 i = 0; i < 32; i++)
		{
			let at = BezierAt(s, X1, X2);
			if (Math.Abs(at - x) < 1e-6f)
				break;
			if (at < x)
				lo = s;
			else
				hi = s;
			s = (lo + hi) * 0.5f;
		}
		return s;
	}

	private float StepAt(float t)
	{
		let n = (Steps > 1) ? Steps : (int32)1;
		// CSS: the step index rounds down, starts a jump earlier for jump-start / jump-both, and
		// the output divides by the number of jumps.
		var step = (int32)Math.Floor(t * (float)n);
		if ((Position == .JumpStart) || (Position == .JumpBoth))
			step++;
		if ((t >= 1.0f) && ((Position == .JumpEnd) || (Position == .JumpNone)))
			step = n; // the last interval's end
		var jumps = n;
		if (Position == .JumpNone)
			jumps = n - 1;
		else if (Position == .JumpBoth)
			jumps = n + 1;
		if (jumps <= 0)
			return (t >= 1.0f) ? 1.0f : 0.0f;
		return Clamp((float)((step < jumps) ? step : jumps) / (float)jumps, 0.0f, 1.0f);
	}
}

/// What Easing.bf keeps out of the public surface: the named curves' words.
internal static class EasingDetail
{
	public static String[10] sFamilyNames = .("sine", "quad", "cubic", "quart", "quint", "expo", "circ", "back", "elastic", "bounce");
	/// By EaseMode.
	public static String[3] sModePrefixes = .("ease-in-", "ease-out-", "ease-in-out-");
	/// In-out first: "ease-in-" is a prefix of it.
	public static EaseMode[3] sModeOrder = .(.InOut, .In, .Out);
}

static
{
	/// A named curve: `ease-in-<family>`, `ease-out-<family>` or `ease-in-out-<family>`, the
	/// family one of sine, quad, cubic, quart, quint, expo, circ, back, elastic, bounce.
	public static Easing? ParseNamedEasing(StringView v)
	{
		for (int m = 0; m < EasingDetail.sModeOrder.Count; m++)
		{
			let mode = EasingDetail.sModeOrder[m];
			StringView prefix = EasingDetail.sModePrefixes[(int)mode];
			if ((v.Length <= prefix.Length) || (v.Substring(0, prefix.Length) != prefix))
				continue;
			let family = v.Substring(prefix.Length, v.Length - prefix.Length);
			for (int i = 0; i < EasingDetail.sFamilyNames.Count; i++)
				if (family == EasingDetail.sFamilyNames[i])
					return Easing.Named((EaseFamily)i, mode);
			return null;
		}
		return null;
	}

	/// A named curve's name, as ParseNamedEasing reads it, appended to `outText`.
	public static void NamedEasingText(Easing e, String outText)
	{
		outText.Append(EasingDetail.sModePrefixes[(int)e.Mode]);
		outText.Append(EasingDetail.sFamilyNames[(int)e.Family]);
	}

	/// A CSS <easing-function>: linear, ease, ease-in, ease-out, ease-in-out, step-start,
	/// step-end, cubic-bezier(x1, y1, x2, y2) (x1 and x2 in [0, 1]) or steps(n[, position]); or
	/// a named curve past CSS's (ParseNamedEasing), so sheets and code ease alike.
	public static Easing? ParseEasing(StringView text)
	{
		let v = ParseUtil.Trim(text);
		let named = ParseNamedEasing(v);
		if (named.HasValue)
			return named;
		if (v == "linear")
			return Easing.Linear();
		if (v == "ease")
			return Easing.Ease();
		if (v == "ease-in")
			return Easing.Bezier(0.42f, 0.0f, 1.0f, 1.0f);
		if (v == "ease-out")
			return Easing.Bezier(0.0f, 0.0f, 0.58f, 1.0f);
		if (v == "ease-in-out")
			return Easing.Bezier(0.42f, 0.0f, 0.58f, 1.0f);
		if (v == "step-start")
			return Easing.Stepped(1, .JumpStart);
		if (v == "step-end")
			return Easing.Stepped(1, .JumpEnd);
		if (!SplitFunction(v, let name, let arguments))
			return null;
		let args = scope List<StringView>();
		SplitTopLevel(arguments, ',', args);
		if (name == "cubic-bezier")
		{
			if (args.Count != 4)
				return null;
			float[4] p = default;
			for (int i = 0; i < 4; i++)
			{
				let n = ParseLength(args[i]);
				if (!n.HasValue)
					return null;
				p[i] = n.Value;
			}
			if ((p[0] < 0.0f) || (p[0] > 1.0f) || (p[2] < 0.0f) || (p[2] > 1.0f))
				return null;
			return Easing.Bezier(p[0], p[1], p[2], p[3]);
		}
		if (name == "steps")
		{
			if (args.IsEmpty || (args.Count > 2))
				return null;
			let n = ParseLength(args[0]);
			if (!n.HasValue || (n.Value < 1.0f) || (n.Value != Math.Floor(n.Value)))
				return null;
			StepPosition position = .JumpEnd;
			if (args.Count == 2)
			{
				let p = args[1];
				if ((p == "jump-start") || (p == "start"))
					position = .JumpStart;
				else if ((p == "jump-end") || (p == "end"))
					position = .JumpEnd;
				else if (p == "jump-none")
					position = .JumpNone;
				else if (p == "jump-both")
					position = .JumpBoth;
				else
					return null;
			}
			if ((position == .JumpNone) && (n.Value < 2.0f))
				return null;
			return Easing.Stepped((int32)n.Value, position);
		}
		return null;
	}

	/// A CSS <time>: `300ms`, `0.3s`; seconds out.
	public static float? ParseTime(StringView text)
	{
		let v = ParseUtil.Trim(text);
		if ((v.Length > 2) && (v.Substring(v.Length - 2, 2) == "ms"))
		{
			let n = ParseLength(v.Substring(0, v.Length - 2));
			if (n.HasValue)
				return n.Value / 1000.0f;
		}
		if ((v.Length > 1) && (v[v.Length - 1] == 's'))
		{
			let n = ParseLength(v.Substring(0, v.Length - 1));
			if (n.HasValue)
				return n.Value;
		}
		return null;
	}
}
