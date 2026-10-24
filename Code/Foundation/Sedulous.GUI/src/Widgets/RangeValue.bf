using System;

namespace Sedulous.GUI;

/// The value of a slider, a scroll bar, a progress bar or a number field, after Godot's Range: a
/// value between a minimum and a maximum, snapped to a step, a page (a scroll bar's visible
/// part, PageShown: the value goes no further than the maximum less it; a slider's and a number
/// field's page-key step), optionally exponential (its place along the track by logarithm, for a
/// frequency or a zoom) and optionally allowed past either end (a number field typed beyond its
/// range). The controls derive from RangeWidget, which holds one and reflects its properties (so
/// a progress bar carries a page it hides).
struct RangeValue : IEquatable<RangeValue>
{
	public double Min = 0.0;
	public double Max = 1.0;
	/// What the value snaps to, from Min; 0: continuous.
	public double Step = 0.0;
	/// A scroll bar's visible part; a page key's step elsewhere (0: a tenth).
	public double Page = 0.0;
	public double Value = 0.0;
	/// Its place along the track by logarithm (with Min above 0).
	public bool Exponential = false;
	public bool AllowGreater = false;
	public bool AllowLesser = false;
	/// The page is a visible part (a scroll bar's), not just a key's step.
	public bool PageShown = false;

	/// The largest value: the maximum, less the page when the page is shown past it.
	public double Upper => Math.Max(Min, PageShown ? Max - Page : Max);

	/// `v` as the range takes it: snapped to the step, kept within the range unless allowed past
	/// it.
	public double Constrain(double v)
	{
		var v;
		if (Step > 0.0)
			v = Min + RoundHalfAway((v - Min) / Step) * Step;
		if (!AllowGreater)
			v = Math.Min(v, Upper);
		if (!AllowLesser)
			v = Math.Max(v, Min);
		return v;
	}

	/// Where the value lies along [Min, Upper], 0 to 1 (by logarithm when exponential).
	public double Ratio => RatioOf(Value);

	public double RatioOf(double v)
	{
		let lo = Min;
		let hi = Upper;
		if (hi <= lo)
			return 0.0;
		if (UsesLog)
		{
			// Through float, as the C++ is.
			let l = (double)Math.Log((float)lo);
			let h = (double)Math.Log((float)hi);
			let x = (double)Math.Log((float)Math.Max(v, lo));
			return Clamp01((x - l) / (h - l));
		}
		return Clamp01((v - lo) / (hi - lo));
	}

	/// The value at `ratio` along [Min, Upper] (not yet snapped: Constrain does).
	public double FromRatio(double ratio)
	{
		let lo = Min;
		let hi = Upper;
		let r = Clamp01(ratio);
		if (UsesLog)
		{
			let l = (double)Math.Log((float)lo);
			let h = (double)Math.Log((float)hi);
			return (double)Math.Exp((float)(l + (h - l) * r));
		}
		return lo + (hi - lo) * r;
	}

	/// An arrow key's step: the step, else a twentieth of the range.
	public double KeyStep => (Step > 0.0) ? Step : (Max - Min) / 20.0;

	/// A page key's step: the page, else a tenth of the range (never less than a key step).
	public double PageStep => Math.Max((Page > 0.0) ? Page : (Max - Min) / 10.0, KeyStep);

	/// How many decimals the step shows (0.25: 2; 1: 0; continuous: 3).
	public int32 Decimals
	{
		get
		{
			if (Step <= 0.0)
				return 3;
			int32 decimals = 0;
			var s = Step;
			while ((decimals < 8) && (Math.Abs(s - RoundHalfAway(s)) > 1e-9))
			{
				s *= 10.0;
				decimals++;
			}
			return decimals;
		}
	}

	public bool Equals(RangeValue other) => this == other;

	[Commutable]
	public static bool operator==(RangeValue a, RangeValue b) =>
		(a.Min == b.Min) && (a.Max == b.Max) && (a.Step == b.Step) && (a.Page == b.Page) && (a.Value == b.Value) &&
		(a.Exponential == b.Exponential) && (a.AllowGreater == b.AllowGreater) && (a.AllowLesser == b.AllowLesser) &&
		(a.PageShown == b.PageShown);

	private bool UsesLog => Exponential && (Min > 0.0);

	private static double Clamp01(double r) => (r < 0.0) ? 0.0 : ((r > 1.0) ? 1.0 : r);

	private static double RoundHalfAway(double x) => (double)(int64)((x < 0.0) ? x - 0.5 : x + 0.5);
}
