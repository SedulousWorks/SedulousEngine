using System;
using Sedulous.Core;

namespace Sedulous.Net.Replication;

/// Interpolating one reflected field between two received samples.
///
/// Operates on ADDRESSES rather than Raptor's Variants, for the reason FieldCodec gives: this
/// runs per field, per component, per frame.
static class FieldInterpolation
{
	/// Whether this field type is smoothly interpolated rather than snapped.
	public static bool IsInterpolatableType(Type type)
	{
		return (type == typeof(float)) || (type == typeof(double))
			|| (type == typeof(Float2)) || (type == typeof(Float3)) || (type == typeof(Float4))
			|| (type == typeof(Quaternion));
	}

	/// Writes the value between `a` and `b` at `t` into `destination`.
	///
	/// A non interpolatable type SNAPS to `a`, which is the value in effect at the render
	/// time: the earlier bracketing sample is what was true then, and inventing a midpoint for
	/// a bool or an integer would be a value the server never sent.
	public static void Lerp(Type type, void* a, void* b, float t, void* destination)
	{
		if (type == typeof(float))
		{
			*(float*)destination = Lerp(*(float*)a, *(float*)b, t);
			return;
		}
		if (type == typeof(double))
		{
			let from = *(double*)a;
			*(double*)destination = from + (*(double*)b - from) * (double)t;
			return;
		}
		if (type == typeof(Float2))
		{
			let from = *(Float2*)a;
			let to = *(Float2*)b;
			*(Float2*)destination = .(Lerp(from.X, to.X, t), Lerp(from.Y, to.Y, t));
			return;
		}
		if (type == typeof(Float3))
		{
			let from = *(Float3*)a;
			let to = *(Float3*)b;
			*(Float3*)destination =
				.(Lerp(from.X, to.X, t), Lerp(from.Y, to.Y, t), Lerp(from.Z, to.Z, t));
			return;
		}
		if (type == typeof(Float4))
		{
			let from = *(Float4*)a;
			let to = *(Float4*)b;
			*(Float4*)destination = .(Lerp(from.X, to.X, t), Lerp(from.Y, to.Y, t),
				Lerp(from.Z, to.Z, t), Lerp(from.W, to.W, t));
			return;
		}
		if (type == typeof(Quaternion))
		{
			*(Quaternion*)destination = NLerp(*(Quaternion*)a, *(Quaternion*)b, t);
			return;
		}

		// Snap: copy `a` verbatim.
		Internal.MemCpy(destination, a, type.Size);
	}

	private static float Lerp(float a, float b, float t) => a + (b - a) * t;

	/// Normalised lerp with shortest path selection. Cheap and stable for the small per tick
	/// deltas interpolation actually sees; a full slerp is overkill at ten to twenty hertz.
	private static Quaternion NLerp(Quaternion a, Quaternion b, float t)
	{
		let dot = a.X * b.X + a.Y * b.Y + a.Z * b.Z + a.W * b.W;
		let sign = (dot < 0.0f) ? -1.0f : 1.0f;

		var result = Quaternion(Lerp(a.X, sign * b.X, t), Lerp(a.Y, sign * b.Y, t),
			Lerp(a.Z, sign * b.Z, t), Lerp(a.W, sign * b.W, t));

		let length = Sqrt(result.X * result.X + result.Y * result.Y + result.Z * result.Z
			+ result.W * result.W);
		if (length > 1e-6f)
		{
			result.X /= length;
			result.Y /= length;
			result.Z /= length;
			result.W /= length;
		}
		return result;
	}
}
