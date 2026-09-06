using System;
using System.Collections;

namespace Sedulous.Core;

/// An ordered scalar curve.
///
/// Keys are kept sorted by time, since AddKey inserts in order. Evaluate clamps to the
/// end values outside the key range: loop and pingpong wrapping is the clip's job, not
/// the curve's.
///
/// Raptor holds the keys in its own Array; this uses corlib's List until Containers is
/// ported, which is the only difference in shape.
class Curve
{
	private List<CurveKey> mKeys = new .() ~ delete _;

	public int KeyCount => mKeys.Count;
	public List<CurveKey> Keys => mKeys;
	public bool IsEmpty => mKeys.IsEmpty;

	/// The curve's time span: the last key's time, or zero when empty. A normalized clip
	/// is expected to have its first key at t = 0, but that is a convention rather than
	/// something enforced here.
	public float Duration => mKeys.IsEmpty ? 0.0f : mKeys[mKeys.Count - 1].time;

	/// Inserts a key, keeping the list sorted by time. Stable for equal times: the new
	/// key lands after existing keys at the same time.
	public void AddKey(CurveKey key)
	{
		var i = mKeys.Count;
		while ((i > 0) && (mKeys[i - 1].time > key.time))
			i--;
		mKeys.Insert(i, key);
	}

	public void Clear() => mKeys.Clear();

	/// Samples the curve. Empty gives zero, a single key gives its value, and outside
	/// the key range the nearest end value. Between two keys the LEFT key's
	/// interpolation mode drives the segment.
	public float Evaluate(float time)
	{
		let count = mKeys.Count;
		if (count == 0)
			return 0.0f;
		if ((count == 1) || (time <= mKeys[0].time))
			return mKeys[0].value;
		if (time >= mKeys[count - 1].time)
			return mKeys[count - 1].value;

		// Find the segment containing time. A linear scan, since key counts are small.
		var i = 0;
		while ((i + 1 < count) && (mKeys[i + 1].time <= time))
			i++;

		let a = mKeys[i];
		let b = mKeys[i + 1];

		let segment = b.time - a.time;
		if (segment <= 1e-6f)
			return b.value;   // coincident keys: jump to the later value

		let localT = (time - a.time) / segment;

		switch (a.interpolation)
		{
		case .Constant:
			return a.value;
		case .Linear:
			return a.value + (b.value - a.value) * localT;
		case .Cubic:
			// Tangents are slopes, scaled by the segment length into the [0,1] basis.
			return Hermite(a.value, a.tangentOut * segment, b.value, b.tangentIn * segment, localT);
		}
	}

	/// Cubic Hermite basis: p0 at t = 0, p1 at t = 1, with m0 and m1 the endpoint
	/// tangents, already scaled.
	private static float Hermite(float p0, float m0, float p1, float m1, float t)
	{
		let t2 = t * t;
		let t3 = t2 * t;
		return (2.0f * t3 - 3.0f * t2 + 1.0f) * p0 +
			(t3 - 2.0f * t2 + t) * m0 +
			(-2.0f * t3 + 3.0f * t2) * p1 +
			(t3 - t2) * m1;
	}
}
