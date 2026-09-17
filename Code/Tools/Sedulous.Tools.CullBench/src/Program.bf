using System;
using System.Collections;
using System.Diagnostics;
using Sedulous.Core;
using Sedulous.Render;

namespace Sedulous.Tools.CullBench;

/// The shadow cascade cull scan, isolated.
///
/// Built at Release O2 like the engine, over the REAL types, so the nanoseconds per caster are
/// comparable with the same loop written in C++ and with what the profiler reports in a frame.
/// The variants exist to localise a gap: each removes ONE thing from the loop, so whichever
/// removal moves the number is the thing that costs.
static class Program
{
	private const int cCasters = 8000;
	private const int cReps = 4000; // four cascades of a thousand frames

	public static int Main(String[] args)
	{
		let bounds = scope List<Float4>();
		let casters = scope List<DrawItem>();
		for (int i < cCasters)
		{
			// A 90 by 90 grid on the ground, the stress test's shape.
			let gx = i % 90;
			let gz = i / 90;
			bounds.Add(.((float)gx * 2.0f - 90.0f, 0.5f, (float)gz * 2.0f - 90.0f, 1.0f));
			casters.Add(.((uint64)i, null));
		}

		// A cascade shaped box: x and z within 40, y within 100. Outward normals, so D is the
		// negated half extent. It keeps about a fifth of the grid, as a real cascade does.
		var frustum = BoundingFrustum();
		frustum.Planes[0] = .(.(-1, 0, 0), -40.0f);
		frustum.Planes[1] = .(.(1, 0, 0), -40.0f);
		frustum.Planes[2] = .(.(0, -1, 0), -100.0f);
		frustum.Planes[3] = .(.(0, 1, 0), -100.0f);
		frustum.Planes[4] = .(.(0, 0, -1), -40.0f);
		frustum.Planes[5] = .(.(0, 0, 1), -40.0f);

		let scratch = scope List<DrawItem>();
		scratch.Reserve(cCasters);

		Run("current  (Span + List.Add)", scope () => Current(bounds, casters, frustum, scratch));
		Run("pointers (raw ptr + List.Add)", scope () => Pointers(bounds, casters, frustum, scratch));
		Run("count    (Span, no List.Add)", scope () => CountOnly(bounds, frustum));
		Run("flat     (float array planes)", scope () => Flat(bounds, frustum));
		Run("manual   (structs, no Dot call)", scope () => StructsManual(bounds, frustum));
		Run("flatDot  (float planes, Dot call)", scope () => FlatDot(bounds, frustum));
		Run("localDot (Dot defined HERE)", scope () => LocalDot(bounds, frustum));
		Run("scalars  (same call, float args)", scope () => ScalarArgs(bounds, frustum));
		Run("inParams (Dot taking in Float3)", scope () => InParams(bounds, frustum));
		return 0;
	}

	private static void Run(StringView name, delegate int() body)
	{
		body(); // warm
		let clock = scope Stopwatch(true);
		var kept = 0;
		for (int r < cReps)
			kept = body();
		clock.Stop();

		let ms = clock.Elapsed.TotalMilliseconds;
		Console.WriteLine(scope $"{name}: {ms:0.000} ms total, {ms / (cReps / 4):0.000} ms per 4 cascades, {ms * 1000000.0 / ((double)cReps * cCasters):0.00} ns/caster, kept {kept}/{cCasters}");
	}

	/// Exactly what RenderFrame.RecordShadowCasters runs.
	private static int Current(List<Float4> boundsList, List<DrawItem> castersList,
		BoundingFrustum frustum, List<DrawItem> scratch)
	{
		Span<Float4> cullBounds = boundsList;
		Span<DrawItem> casters = castersList;
		scratch.Clear();

		for (int k < casters.Length)
		{
			let bounds = cullBounds[k];
			let center = Float3(bounds.X, bounds.Y, bounds.Z);

			var inside = true;
			for (int p < BoundingFrustum.PlaneCount)
			{
				if ((Dot(frustum.Planes[p].Normal, center) + frustum.Planes[p].D) > bounds.W)
				{
					inside = false;
					break;
				}
			}
			if (inside)
				scratch.Add(casters[k]);
		}
		return scratch.Count;
	}

	/// The same, reaching through raw pointers rather than a Span.
	private static int Pointers(List<Float4> boundsList, List<DrawItem> castersList,
		BoundingFrustum frustum, List<DrawItem> scratch)
	{
		let cullBounds = boundsList.Ptr;
		let casters = castersList.Ptr;
		let count = castersList.Count;
		scratch.Clear();

		for (int k < count)
		{
			let bounds = cullBounds[k];
			let center = Float3(bounds.X, bounds.Y, bounds.Z);

			var inside = true;
			for (int p < BoundingFrustum.PlaneCount)
			{
				if ((Dot(frustum.Planes[p].Normal, center) + frustum.Planes[p].D) > bounds.W)
				{
					inside = false;
					break;
				}
			}
			if (inside)
				scratch.Add(casters[k]);
		}
		return scratch.Count;
	}

	/// The scan alone: no survivor list, so what is left is the test itself.
	private static int CountOnly(List<Float4> boundsList, BoundingFrustum frustum)
	{
		Span<Float4> cullBounds = boundsList;
		var kept = 0;

		for (int k < cullBounds.Length)
		{
			let bounds = cullBounds[k];
			let center = Float3(bounds.X, bounds.Y, bounds.Z);

			var inside = true;
			for (int p < BoundingFrustum.PlaneCount)
			{
				if ((Dot(frustum.Planes[p].Normal, center) + frustum.Planes[p].D) > bounds.W)
				{
					inside = false;
					break;
				}
			}
			if (inside)
				kept++;
		}
		return kept;
	}

	/// The struct arguments taken by IN rather than by value, which is the fix that would not
	/// touch a single call site if it works.
	[Inline]
	private static float InDot(in Float3 a, in Float3 b) => a.X * b.X + a.Y * b.Y + a.Z * b.Z;

	private static int InParams(List<Float4> boundsList, BoundingFrustum frustum)
	{
		let cullBounds = boundsList.Ptr;
		let count = boundsList.Count;
		var kept = 0;

		for (int k < count)
		{
			let bounds = cullBounds[k];
			let center = Float3(bounds.X, bounds.Y, bounds.Z);
			var inside = true;
			for (int p < BoundingFrustum.PlaneCount)
			{
				if ((InDot(frustum.Planes[p].Normal, center) + frustum.Planes[p].D) > bounds.W)
				{
					inside = false;
					break;
				}
			}
			if (inside)
				kept++;
		}
		return kept;
	}

	/// The same inlined call, but taking SCALARS rather than two structs by value. Separates
	/// the call itself from how its struct arguments are passed.
	[Inline]
	private static float ScalarDot(float ax, float ay, float az, float bx, float by, float bz) =>
		ax * bx + ay * by + az * bz;

	private static int ScalarArgs(List<Float4> boundsList, BoundingFrustum frustum)
	{
		let cullBounds = boundsList.Ptr;
		let count = boundsList.Count;
		var kept = 0;

		for (int k < count)
		{
			let bounds = cullBounds[k];
			var inside = true;
			for (int p < BoundingFrustum.PlaneCount)
			{
				let n = frustum.Planes[p].Normal;
				let d = ScalarDot(n.X, n.Y, n.Z, bounds.X, bounds.Y, bounds.Z)
					+ frustum.Planes[p].D;
				if (d > bounds.W)
				{
					inside = false;
					break;
				}
			}
			if (inside)
				kept++;
		}
		return kept;
	}

	/// The same Dot, declared in THIS project rather than in Sedulous.Core. Beef emits each
	/// project separately and Linux Release carries no LTO, so this is the control for whether
	/// [Inline] survives a project boundary.
	[Inline]
	private static float LocalDotProduct(Float3 a, Float3 b) => a.X * b.X + a.Y * b.Y + a.Z * b.Z;

	private static int LocalDot(List<Float4> boundsList, BoundingFrustum frustum)
	{
		let cullBounds = boundsList.Ptr;
		let count = boundsList.Count;
		var kept = 0;

		for (int k < count)
		{
			let bounds = cullBounds[k];
			let center = Float3(bounds.X, bounds.Y, bounds.Z);
			var inside = true;
			for (int p < BoundingFrustum.PlaneCount)
			{
				if ((LocalDotProduct(frustum.Planes[p].Normal, center) + frustum.Planes[p].D)
					> bounds.W)
				{
					inside = false;
					break;
				}
			}
			if (inside)
				kept++;
		}
		return kept;
	}

	/// The structs KEPT, but the dot product written out: isolates the Dot call from the
	/// struct loads that feed it.
	private static int StructsManual(List<Float4> boundsList, BoundingFrustum frustum)
	{
		let cullBounds = boundsList.Ptr;
		let count = boundsList.Count;
		var kept = 0;

		for (int k < count)
		{
			let bounds = cullBounds[k];
			var inside = true;
			for (int p < BoundingFrustum.PlaneCount)
			{
				let n = frustum.Planes[p].Normal;
				let d = n.X * bounds.X + n.Y * bounds.Y + n.Z * bounds.Z + frustum.Planes[p].D;
				if (d > bounds.W)
				{
					inside = false;
					break;
				}
			}
			if (inside)
				kept++;
		}
		return kept;
	}

	/// Flat floats, but rebuilt into Float3 and pushed through Dot: isolates the other way
	/// round, the call and its struct arguments over storage that is known to be cheap.
	private static int FlatDot(List<Float4> boundsList, BoundingFrustum frustum)
	{
		float[24] planes = .();
		for (int p < BoundingFrustum.PlaneCount)
		{
			planes[p * 4 + 0] = frustum.Planes[p].Normal.X;
			planes[p * 4 + 1] = frustum.Planes[p].Normal.Y;
			planes[p * 4 + 2] = frustum.Planes[p].Normal.Z;
			planes[p * 4 + 3] = frustum.Planes[p].D;
		}

		let cullBounds = boundsList.Ptr;
		let count = boundsList.Count;
		var kept = 0;

		for (int k < count)
		{
			let bounds = cullBounds[k];
			let center = Float3(bounds.X, bounds.Y, bounds.Z);
			var inside = true;
			for (int p < BoundingFrustum.PlaneCount)
			{
				let n = Float3(planes[p * 4 + 0], planes[p * 4 + 1], planes[p * 4 + 2]);
				if ((Dot(n, center) + planes[p * 4 + 3]) > bounds.W)
				{
					inside = false;
					break;
				}
			}
			if (inside)
				kept++;
		}
		return kept;
	}

	/// The scan with the planes as PLAIN FLOATS in a local, which removes both the struct
	/// indexing and the Float3 maths from the inner loop.
	private static int Flat(List<Float4> boundsList, BoundingFrustum frustum)
	{
		float[24] planes = .();
		for (int p < BoundingFrustum.PlaneCount)
		{
			planes[p * 4 + 0] = frustum.Planes[p].Normal.X;
			planes[p * 4 + 1] = frustum.Planes[p].Normal.Y;
			planes[p * 4 + 2] = frustum.Planes[p].Normal.Z;
			planes[p * 4 + 3] = frustum.Planes[p].D;
		}

		let cullBounds = boundsList.Ptr;
		let count = boundsList.Count;
		var kept = 0;

		for (int k < count)
		{
			let bounds = cullBounds[k];
			var inside = true;
			for (int p < BoundingFrustum.PlaneCount)
			{
				let d = planes[p * 4 + 0] * bounds.X + planes[p * 4 + 1] * bounds.Y
					+ planes[p * 4 + 2] * bounds.Z + planes[p * 4 + 3];
				if (d > bounds.W)
				{
					inside = false;
					break;
				}
			}
			if (inside)
				kept++;
		}
		return kept;
	}
}
