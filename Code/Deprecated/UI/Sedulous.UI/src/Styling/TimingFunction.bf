using System;

namespace Sedulous.UI;

/// A CSS timing function: the cubic Bezier from (0, 0) to (1, 1) through (X1, Y1) and
/// (X2, Y2) that `cubic-bezier()` writes (the named easings are presets of it), or `steps(n)`,
/// which holds each of n levels and jumps at a step's end (or, with StepsJumpStart, its
/// start).
struct TimingFunction
{
	public float X1 = 0.25f;
	public float Y1 = 0.1f;
	public float X2 = 0.25f;
	public float Y2 = 1.0f;
	/// Zero: the curve.
	public uint16 Steps = 0;
	public bool StepsJumpStart = false;

	public this() {}

	public static TimingFunction CubicBezier(float x1, float y1, float x2, float y2)
	{
		TimingFunction f = .();
		f.X1 = x1;
		f.Y1 = y1;
		f.X2 = x2;
		f.Y2 = y2;
		return f;
	}

	public static TimingFunction Linear => CubicBezier(0.0f, 0.0f, 1.0f, 1.0f);
	public static TimingFunction Ease => CubicBezier(0.25f, 0.1f, 0.25f, 1.0f);
	public static TimingFunction EaseIn => CubicBezier(0.42f, 0.0f, 1.0f, 1.0f);
	public static TimingFunction EaseOut => CubicBezier(0.0f, 0.0f, 0.58f, 1.0f);
	public static TimingFunction EaseInOut => CubicBezier(0.42f, 0.0f, 0.58f, 1.0f);

	public static TimingFunction StepsOf(uint16 count, bool jumpStart = false)
	{
		var f = Linear;
		f.Steps = count;
		f.StepsJumpStart = jumpStart;
		return f;
	}

	/// The eased progress at `t` (0 to 1): the curve's y where its x is t. Y may leave 0 to 1
	/// for a curve that overshoots (a back-out bounce).
	public float Evaluate(float time)
	{
		let t = Math.Clamp(time, 0.0f, 1.0f);
		if (Steps > 0)
		{
			let n = (float)Steps;
			let step = StepsJumpStart ? Math.Ceiling(t * n) : Math.Floor(t * n);
			return (t >= 1.0f) ? 1.0f : (Math.Min(step, n) / n);
		}
		if ((X1 == Y1) && (X2 == Y2))
			return t; // the straight line

		// Solve x(u) = t for the curve's parameter u (Newton, then bisection if it stalls), then
		// read y(u).
		var u = t;
		for (int i < 8)
		{
			let error = Bezier(X1, X2, u) - t;
			if (Math.Abs(error) < 1e-5f)
				return Bezier(Y1, Y2, u);
			let slope = Slope(X1, X2, u);
			if (Math.Abs(slope) < 1e-6f)
				break;
			u -= error / slope;
		}
		var lo = 0.0f;
		var hi = 1.0f;
		u = t;
		for (int i < 32)
		{
			let x = Bezier(X1, X2, u);
			if (Math.Abs(x - t) < 1e-5f)
				break;
			if (x < t)
				lo = u;
			else
				hi = u;
			u = (lo + hi) * 0.5f;
		}
		return Bezier(Y1, Y2, u);
	}

	/// One coordinate of the curve at `u`, its control points' coordinates `a` and `b`.
	private static float Bezier(float a, float b, float u)
	{
		let v = 1.0f - u;
		return 3.0f * v * v * u * a + 3.0f * v * u * u * b + u * u * u;
	}

	private static float Slope(float a, float b, float u)
	{
		let v = 1.0f - u;
		return 3.0f * v * v * a + 6.0f * v * u * (b - a) + 3.0f * u * u * (1.0f - b);
	}

	[Commutable]
	public static bool operator==(TimingFunction a, TimingFunction b) =>
		(a.X1 == b.X1) && (a.Y1 == b.Y1) && (a.X2 == b.X2) && (a.Y2 == b.Y2) && (a.Steps == b.Steps)
		&& (a.StepsJumpStart == b.StepsJumpStart);
}
