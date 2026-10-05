using System;
using Sedulous.Core;

namespace Sedulous.Animation;

/// A step of root motion (root-motion.md P1): how far the character moves, in the frame it faces
/// at the step's start (model space when the clip does not extract its turn), and how far it
/// turns about +Y.
struct RootMotionDelta
{
	public Float3 Translation = .(0, 0, 0);
	/// Radians about +Y.
	public float Yaw = 0.0f;

	public this() {}

	public this(Float3 translation, float yaw)
	{
		Translation = translation;
		Yaw = yaw;
	}

	public bool IsZero => (LengthSquared(Translation) == 0.0f) && (Yaw == 0.0f);
}

/// The travel a clip's baked root motion curve carries between two of its times. A delta is
/// expressed in the frame the character faces at its start, so applying deltas one after another
/// (Compose) turns each by the turns before it, the way a character that already turned walks on
/// in its new direction. A step that wraps a looping clip is split at the end, and a step spanning
/// whole loops adds the full loop's delta once per loop: nothing is lost however far one step goes.
static class RootMotion
{
	/// `a`, then `b`: b's translation was measured after a's turn.
	public static RootMotionDelta Compose(RootMotionDelta a, RootMotionDelta b)
		=> .(a.Translation + RotateVector(Quaternion.FromAxisAngle(.(0, 1, 0), a.Yaw), b.Translation), a.Yaw + b.Yaw);

	/// Deltas blend as poses do: `t` of the way from `a` to `b` (a crossfade, a blend tree).
	public static RootMotionDelta Blend(RootMotionDelta a, RootMotionDelta b, float t)
		=> .(a.Translation + (b.Translation - a.Translation) * t, a.Yaw + (b.Yaw - a.Yaw) * t);

	/// The curve at `time`, clamped to its ends, linear between its samples.
	private static void At(RootMotionCurve curve, float time, out Float3 outPosition, out float outYaw)
	{
		let n = Math.Min(curve.Times.Count, Math.Min(curve.Positions.Count, curve.Yaws.Count));
		outPosition = .(0, 0, 0);
		outYaw = 0.0f;
		if (n == 0)
			return;
		if (time <= curve.Times[0])
		{
			outPosition = curve.Positions[0];
			outYaw = curve.Yaws[0];
			return;
		}
		if (time >= curve.Times[n - 1])
		{
			outPosition = curve.Positions[n - 1];
			outYaw = curve.Yaws[n - 1];
			return;
		}
		var lo = 0;
		var hi = n - 1;
		while (hi - lo > 1)
		{
			let mid = (lo + hi) / 2;
			if (curve.Times[mid] <= time)
				lo = mid;
			else
				hi = mid;
		}
		let span = curve.Times[hi] - curve.Times[lo];
		let t = (span > 0.0f) ? ((time - curve.Times[lo]) / span) : 0.0f;
		outPosition = curve.Positions[lo] + (curve.Positions[hi] - curve.Positions[lo]) * t;
		outYaw = curve.Yaws[lo] + (curve.Yaws[hi] - curve.Yaws[lo]) * t;
	}

	/// From `from` to `to`, both within the clip: the extracted parts only, in the facing frame at
	/// `from` (a clip that does not extract its turn moves in model space).
	private static RootMotionDelta Between(AnimationClip clip, float from, float to)
	{
		let curve = clip.RootMotion;
		At(curve, from, let aPosition, let aYaw);
		At(curve, to, let bPosition, let bYaw);
		var travel = bPosition - aPosition;
		if (!curve.Horizontal)
		{
			travel.X = 0.0f;
			travel.Z = 0.0f;
		}
		if (!curve.Vertical)
			travel.Y = 0.0f;
		if (!curve.Yaw)
			return .(travel, 0.0f);
		// The character already turned by (a's yaw less the clip's first): measure in its frame.
		let turned = aYaw - (curve.Yaws.IsEmpty ? 0.0f : curve.Yaws[0]);
		return .(RotateVector(Quaternion.FromAxisAngle(.(0, 1, 0), -turned), travel), bYaw - aYaw);
	}

	/// The root motion `clip` carries from `from` to `to`, seconds, UNWRAPPED: for a looping clip
	/// a time past the end is a later loop (0.9 to 2.1 in a one second clip crosses the end twice),
	/// and a backward step (to below from) runs it in reverse. A clip that does not loop clamps
	/// both times to its length. Zero for a clip with no root motion.
	public static RootMotionDelta ClipRootMotion(AnimationClip clip, float from, float to, bool looping)
	{
		let duration = clip.Duration;
		if (clip.RootMotion.IsEmpty || (duration <= 0.0f) || (from == to))
			return .();
		if (!looping)
			return Between(clip, Math.Clamp(from, 0.0f, duration), Math.Clamp(to, 0.0f, duration));
		let loopFrom = Floor(from / duration);
		let loopTo = Floor(to / duration);
		let inFrom = from - loopFrom * duration;
		let inTo = to - loopTo * duration;
		if (loopFrom == loopTo)
			return Between(clip, inFrom, inTo);
		let forward = to > from;
		let end = forward ? duration : 0.0f;
		let start = forward ? 0.0f : duration;
		var delta = Between(clip, inFrom, end);
		let loop = Between(clip, start, end);
		let whole = (int)Math.Abs(loopTo - loopFrom) - 1;
		for (int i < whole)
			delta = Compose(delta, loop);
		return Compose(delta, Between(clip, start, inTo));
	}

	/// A clip's root motion over normalized, unwrapped times.
	public static RootMotionDelta ClipRootMotionNormalized(AnimationClip clip, float from, float to, bool looping)
		=> (clip != null) ? ClipRootMotion(clip, from * clip.Duration, to * clip.Duration, looping) : .();
}
