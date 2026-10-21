using System;
using System.Collections;

namespace Sedulous.Core;

/// EvaluateCurve is the engine's ONE cubic Hermite over keys: Curve samples with it, the
/// particles' fixed curves do, and an editor draws with it, so what is edited is what plays.
/// A key's tangent mode says how its tangents are kept (ApplyCurveTangentModes sets them), so an
/// editor and an importer agree.
static
{
	/// Cubic Hermite basis: p0 at t = 0, p1 at t = 1, with m0 and m1 the endpoint
	/// tangents, already scaled.
	public static float HermiteBasis(float p0, float m0, float p1, float m1, float t)
	{
		let t2 = t * t;
		let t3 = t2 * t;
		return (2.0f * t3 - 3.0f * t2 + 1.0f) * p0 +
			(t3 - 2.0f * t2 + t) * m0 +
			(-2.0f * t3 + 3.0f * t2) * p1 +
			(t3 - t2) * m1;
	}

	/// Samples keys sorted by time. None gives zero, one gives its value, and outside the
	/// keys the nearest end value. Between two keys the LEFT key's interpolation drives the
	/// segment; coincident keys jump to the later value.
	public static float EvaluateCurve(Span<CurveKey> keys, float time)
	{
		let count = keys.Length;
		if (count == 0)
			return 0.0f;
		if ((count == 1) || (time <= keys[0].Time))
			return keys[0].Value;
		if (time >= keys[count - 1].Time)
			return keys[count - 1].Value;

		// Find the segment containing time. A linear scan, since key counts are small.
		var i = 0;
		while ((i + 1 < count) && (keys[i + 1].Time <= time))
			i++;

		let a = keys[i];
		let b = keys[i + 1];

		let segment = b.Time - a.Time;
		if (segment <= 1e-6f)
			return b.Value;

		let localT = (time - a.Time) / segment;

		switch (a.Interpolation)
		{
		case .Constant:
			return a.Value;
		case .Linear:
			return a.Value + (b.Value - a.Value) * localT;
		case .Cubic:
			// Tangents are slopes, scaled by the segment length into the [0,1] basis.
			return HermiteBasis(a.Value, a.TangentOut * segment, b.Value, b.TangentIn * segment, localT);
		}
	}

	/// Sets each key's tangents by its mode: Auto from its neighbours, Smooth in from out,
	/// Flat to zero; Broken keys are left as they are. Keys sorted by time.
	public static void ApplyCurveTangentModes(Span<CurveKey> keys)
	{
		let count = keys.Length;
		for (int i < count)
		{
			ref CurveKey key = ref keys[i];
			switch (key.TangentMode)
			{
			case .Broken:
				break;
			case .Flat:
				key.TangentIn = 0.0f;
				key.TangentOut = 0.0f;
			case .Smooth:
				key.TangentIn = key.TangentOut;
			case .Auto:
				let before = keys[(i > 0) ? i - 1 : i];
				let after = keys[(i + 1 < count) ? i + 1 : i];
				let span = after.Time - before.Time;
				let slope = (span > 1e-6f) ? (after.Value - before.Value) / span : 0.0f;
				key.TangentIn = slope;
				key.TangentOut = slope;
			}
		}
	}
}

/// An ordered scalar curve.
///
/// Keys are kept sorted by time, since AddKey inserts in order. Evaluate clamps to the
/// end values outside the key range: loop and pingpong wrapping is the clip's job, not
/// the curve's.
///
/// The keys are a corlib List.
class Curve
{
	private List<CurveKey> mKeys = new .() ~ delete _;

	public int KeyCount => mKeys.Count;
	public List<CurveKey> Keys => mKeys;
	public bool IsEmpty => mKeys.IsEmpty;

	/// The curve's time span: the last key's time, or zero when empty. A normalized clip
	/// is expected to have its first key at t = 0, but that is a convention rather than
	/// something enforced here.
	public float Duration => mKeys.IsEmpty ? 0.0f : mKeys[mKeys.Count - 1].Time;

	/// Inserts a key, keeping the list sorted by time. Stable for equal times: the new
	/// key lands after existing keys at the same time.
	public void AddKey(CurveKey key)
	{
		var i = mKeys.Count;
		while ((i > 0) && (mKeys[i - 1].Time > key.Time))
			i--;
		mKeys.Insert(i, key);
	}

	public void Clear() => mKeys.Clear();

	/// Samples the curve: EvaluateCurve over its keys.
	public float Evaluate(float time) => EvaluateCurve(mKeys, time);

	/// Sets its keys' tangents by their modes.
	public void ApplyTangentModes() => ApplyCurveTangentModes(mKeys);
}
