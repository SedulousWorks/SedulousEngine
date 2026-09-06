using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Spline;

/// An authorable 3D spline, cubic Bezier natively.
///
/// Every point carries its own handles plus a mode, so the same curve serves a smooth
/// path dropped point by point, an editor keeping tangents collinear, and a corner. Arc
/// length rides a per segment lookup table, which is what makes even spacing and distance
/// parameterised queries possible; closest point is a coarse sample followed by a refine.
///
/// Both the handles and the arc length table are STORED and rebuilt explicitly after an
/// edit. Deriving either on demand would make evaluation depend on when it last happened.
class SplineCurve
{
	/// Chord samples per segment in the arc length table.
	public const uint32 SamplesPerSegment = 16;

	public List<SplinePoint> Points = new .() ~ delete _;
	public bool Closed;

	private List<float> mArcLength = new .() ~ delete _;
	private float mTotalLength;

	/// Open curves have one fewer segment than points; a closed one has the wrap segment
	/// as well.
	public uint32 SegmentCount
	{
		get
		{
			let n = Points.Count;
			if (n < 2)
				return 0;
			return (uint32)(Closed ? n : n - 1);
		}
	}

	/// The largest global parameter, so t runs over [0, MaxT].
	public float MaxT => (float)SegmentCount;

	/// The total length as of the last RebuildArcLength, and zero until one has run.
	public float Length => mTotalLength;

	/// Recomputes the handles of every Auto point from its neighbours. Smooth and Broken
	/// points are left exactly as authored.
	public void UpdateAutoHandles()
	{
		let n = Points.Count;
		if (n < 2)
			return;

		for (int i < n)
		{
			if (Points[i].Mode != .Auto)
				continue;

			// The Catmull-Rom rule: the tangent is the chord between the neighbours and
			// each handle is a sixth of it, which is the standard Bezier conversion. An
			// open endpoint has only one neighbour, so it falls back to that chord.
			let hasPrev = Closed || (i > 0);
			let hasNext = Closed || (i + 1 < n);
			let prev = hasPrev ? Points[(i + n - 1) % n].Position : Points[i].Position;
			let next = hasNext ? Points[(i + 1) % n].Position : Points[i].Position;
			let tangent = (next - prev) * (1.0f / 6.0f);

			Points[i].OutHandle = hasNext ? tangent : Float3.Zero;
			Points[i].InHandle = hasPrev ? tangent * -1.0f : Float3.Zero;
		}
	}

	/// The position at a global parameter, clamped on an open curve and wrapped on a
	/// closed one.
	public Float3 Evaluate(float t)
	{
		let segments = SegmentCount;
		if (segments == 0)
			return Points.IsEmpty ? Float3.Zero : Points[0].Position;

		let local = Localise(t, segments, var index);
		SegmentControls(index, var b0, var b1, var b2, var b3);
		return EvalCubic(b0, b1, b2, b3, local);
	}

	/// The unit tangent at a global parameter, or zero where the curve is genuinely
	/// degenerate.
	public Float3 Tangent(float t)
	{
		let segments = SegmentCount;
		if (segments == 0)
			return Float3.Zero;

		let local = Localise(t, segments, var index);
		SegmentControls(index, var b0, var b1, var b2, var b3);

		var derivative = EvalCubicDerivative(b0, b1, b2, b3, local);
		let length = Sedulous.Core.Length(derivative);
		if (length >= 0.000001f)
			return derivative * (1.0f / length);

		// A knot with zero handles has no derivative exactly at the parameter, but the
		// curve either side of it still has a direction. Nudge off the point rather than
		// reporting that a perfectly ordinary curve has no tangent here.
		derivative = EvalCubicDerivative(b0, b1, b2, b3, Clamp(local + 0.001f, 0.0f, 1.0f));
		let retry = Sedulous.Core.Length(derivative);
		return (retry < 0.000001f) ? Float3.Zero : derivative * (1.0f / retry);
	}

	/// Rebuilds the arc length table. Call after any edit; distance queries read it.
	public void RebuildArcLength()
	{
		mArcLength.Clear();
		mTotalLength = 0.0f;

		let segments = SegmentCount;
		if (segments == 0)
			return;

		mArcLength.Reserve((int)(segments * SamplesPerSegment) + 1);
		mArcLength.Add(0.0f);

		var previous = Evaluate(0.0f);
		for (uint32 s < segments)
		{
			for (uint32 i = 1; i <= SamplesPerSegment; i++)
			{
				let t = (float)s + (float)i / (float)SamplesPerSegment;
				let position = Evaluate(t);
				mTotalLength += Sedulous.Core.Length(position - previous);
				mArcLength.Add(mTotalLength);
				previous = position;
			}
		}
	}

	/// The global parameter at a distance along the curve, clamped to its ends. Needs
	/// RebuildArcLength, and answers zero without one.
	public float DistanceToT(float distance)
	{
		if ((SegmentCount == 0) || (mArcLength.Count < 2) || (mTotalLength <= 0.0f))
			return 0.0f;

		let target = Clamp(distance, 0.0f, mTotalLength);

		// Binary search the cumulative table, then interpolate within the chord it lands
		// in. The table is what makes spacing even: parameter space is not.
		int lo = 0;
		int hi = mArcLength.Count - 1;
		while (lo + 1 < hi)
		{
			let mid = (lo + hi) / 2;
			if (mArcLength[mid] <= target)
				lo = mid;
			else
				hi = mid;
		}

		let span = mArcLength[hi] - mArcLength[lo];
		let within = (span > 0.000001f) ? ((target - mArcLength[lo]) / span) : 0.0f;
		let step = 1.0f / (float)SamplesPerSegment;
		return ((float)lo + within) * step;
	}

	/// The position at a distance along the curve, which is what evenly spaced placement
	/// wants. Needs RebuildArcLength.
	public Float3 EvaluateAtDistance(float distance) => Evaluate(DistanceToT(distance));

	/// The closest point on the curve to a target.
	///
	/// A coarse sweep followed by a ternary refine around the winner. Ternary rather than
	/// Newton because it needs no derivative of the distance function and cannot diverge
	/// on the kinds of curve an author actually draws.
	public SplineSample ClosestPoint(Float3 target)
	{
		let segments = SegmentCount;
		if (segments == 0)
			return .(Points.IsEmpty ? Float3.Zero : Points[0].Position, 0.0f);

		let coarse = segments * SamplesPerSegment;
		var bestT = 0.0f;
		var bestDistance = FloatMax;

		for (uint32 i = 0; i <= coarse; i++)
		{
			let t = MaxT * (float)i / (float)coarse;
			let distance = LengthSquared(Evaluate(t) - target);
			if (distance < bestDistance)
			{
				bestDistance = distance;
				bestT = t;
			}
		}

		let window = MaxT / (float)coarse;
		var lo = (bestT - window > 0.0f) ? (bestT - window) : 0.0f;
		var hi = (bestT + window < MaxT) ? (bestT + window) : MaxT;
		for (int i < 24)
		{
			let m1 = lo + (hi - lo) / 3.0f;
			let m2 = hi - (hi - lo) / 3.0f;
			if (LengthSquared(Evaluate(m1) - target) < LengthSquared(Evaluate(m2) - target))
				hi = m2;
			else
				lo = m1;
		}

		let t = (lo + hi) * 0.5f;
		return .(Evaluate(t), t);
	}

	/// Maps a global parameter onto a segment index and the local parameter within it.
	private float Localise(float t, uint32 segments, out uint32 index)
	{
		var value = t;
		if (Closed)
			value = value - Floor(value / (float)segments) * (float)segments;
		value = Clamp(value, 0.0f, (float)segments);

		var segment = (uint32)value;
		// t exactly at MaxT belongs to the END of the last segment, not the start of one
		// that is not there.
		if (segment >= segments)
			segment = segments - 1;

		index = segment;
		return value - (float)segment;
	}

	/// The Bezier control points of one segment.
	private void SegmentControls(uint32 index, out Float3 b0, out Float3 b1, out Float3 b2, out Float3 b3)
	{
		let n = Points.Count;
		let a = Points[(int)index % n];
		let b = Points[((int)index + 1) % n];
		b0 = a.Position;
		b1 = a.Position + a.OutHandle;
		b2 = b.Position + b.InHandle;
		b3 = b.Position;
	}

	private static Float3 EvalCubic(Float3 b0, Float3 b1, Float3 b2, Float3 b3, float u)
	{
		let v = 1.0f - u;
		return b0 * (v * v * v) + b1 * (3.0f * v * v * u) + b2 * (3.0f * v * u * u) + b3 * (u * u * u);
	}

	private static Float3 EvalCubicDerivative(Float3 b0, Float3 b1, Float3 b2, Float3 b3, float u)
	{
		let v = 1.0f - u;
		return (b1 - b0) * (3.0f * v * v) + (b2 - b1) * (6.0f * v * u) + (b3 - b2) * (3.0f * u * u);
	}
}
