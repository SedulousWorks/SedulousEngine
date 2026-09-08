using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// Reusing tessellated geometry across frames.
class PathCacheTests
{
	private static Path Rect(float x, float y, float w, float h)
	{
		let builder = scope PathBuilder();
		builder.MoveTo(x, y);
		builder.LineTo(x + w, y);
		builder.LineTo(x + w, y + h);
		builder.LineTo(x, y + h);
		builder.Close();
		return builder.ToPath();
	}

	/// Every path gets its own identity, so a cache keyed on it cannot confuse two.
	[Test]
	public static void EveryPathHasItsOwnIdentity()
	{
		let first = Rect(0, 0, 10, 10);
		defer delete first;
		let second = Rect(0, 0, 10, 10);
		defer delete second;

		Test.Assert(first.InstanceId != 0);
		Test.Assert(first.InstanceId != second.InstanceId,
			"identical geometry, still two paths");
	}

	[Test]
	public static void TheSameRequestTwiceProducesTheSameGeometry()
	{
		let cache = scope PathCache();
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		let first = scope List<VGVertex>();
		let firstIndices = scope List<uint32>();
		cache.GetOrTessellateFill(path, .Red, .NonZero, false, first, firstIndices);

		let second = scope List<VGVertex>();
		let secondIndices = scope List<uint32>();
		cache.GetOrTessellateFill(path, .Red, .NonZero, false, second, secondIndices);

		Test.Assert(first.Count == second.Count);
		Test.Assert(firstIndices.Count == secondIndices.Count);
		for (int i = 0; i < first.Count; i++)
			Test.Assert(first[i].Position == second[i].Position);

		Test.Assert(cache.Count == 1, "one entry, hit twice");
	}

	/// Appending REBASES the cached indices: they start at zero, and the output already
	/// holds other geometry.
	[Test]
	public static void AppendedIndicesAreOffsetByWhatIsAlreadyThere()
	{
		let cache = scope PathCache();
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		cache.GetOrTessellateFill(path, .Red, .NonZero, false, vertices, indices);
		let firstCount = vertices.Count;
		let firstIndexCount = indices.Count;

		cache.GetOrTessellateFill(path, .Red, .NonZero, false, vertices, indices);

		Test.Assert(vertices.Count == firstCount * 2);
		Test.Assert(indices.Count == firstIndexCount * 2);

		// The second copy's indices point at the second copy's vertices.
		for (int i = firstIndexCount; i < indices.Count; i++)
			Test.Assert(indices[i] >= (uint32)firstCount);
		for (let index in indices)
			Test.Assert(index < (uint32)vertices.Count);
	}

	/// A different style retessellates. The geometry COUNT is the same for a colour change,
	/// which is what makes this worth checking: only the colour moved.
	[Test]
	public static void ADifferentStyleRetessellates()
	{
		let cache = scope PathCache();
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		let red = scope List<VGVertex>();
		let redIndices = scope List<uint32>();
		cache.GetOrTessellateFill(path, .Red, .NonZero, false, red, redIndices);

		let blue = scope List<VGVertex>();
		let blueIndices = scope List<uint32>();
		cache.GetOrTessellateFill(path, .Blue, .NonZero, false, blue, blueIndices);

		Test.Assert(blue.Count == red.Count, "the same shape");
		Test.Assert(blue[0].Color == Color.Blue, "in the colour asked for");
		Test.Assert(cache.Count == 1, "still one entry, overwritten");
	}

	/// Antialiasing is part of the match, because it changes the geometry rather than just
	/// the colour.
	[Test]
	public static void AntiAliasingIsPartOfTheMatch()
	{
		let cache = scope PathCache();
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		let plain = scope List<VGVertex>();
		let plainIndices = scope List<uint32>();
		cache.GetOrTessellateFill(path, .Red, .NonZero, false, plain, plainIndices);

		let aa = scope List<VGVertex>();
		let aaIndices = scope List<uint32>();
		cache.GetOrTessellateFill(path, .Red, .NonZero, true, aa, aaIndices);

		Test.Assert(aa.Count > plain.Count);
	}

	/// The fill and the stroke are cached separately, so a shape that is both does not
	/// evict itself every frame.
	[Test]
	public static void FillsAndStrokesDoNotEvictEachOther()
	{
		let cache = scope PathCache();
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		cache.GetOrTessellateFill(path, .Red, .NonZero, false, vertices, indices);
		cache.GetOrTessellateStroke(path, .Blue, .(2.0f), .(), false, vertices, indices);

		let afterBoth = vertices.Count;
		vertices.Clear();
		indices.Clear();

		// Both still hit.
		cache.GetOrTessellateFill(path, .Red, .NonZero, false, vertices, indices);
		cache.GetOrTessellateStroke(path, .Blue, .(2.0f), .(), false, vertices, indices);

		Test.Assert(vertices.Count == afterBoth);
		Test.Assert(cache.Count == 1, "one entry holding both meshes");
	}

	/// A stroke walks each subpath on its own, so a shape of several contours gets caps and
	/// joins per contour rather than one run joining them.
	[Test]
	public static void EachSubPathIsStrokedSeparately()
	{
		let cache = scope PathCache();

		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.MoveTo(0, 10);
		builder.LineTo(10, 10);
		let path = builder.ToPath();
		defer delete path;

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();
		cache.GetOrTessellateStroke(path, .Red, .(2.0f), .(), false, vertices, indices);

		Test.Assert(vertices.Count == 8, "four per open segment, twice");
	}

	[Test]
	public static void InvalidatingForcesARetessellation()
	{
		let cache = scope PathCache();
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();
		cache.GetOrTessellateFill(path, .Red, .NonZero, false, vertices, indices);

		cache.Invalidate(path);

		vertices.Clear();
		indices.Clear();
		cache.GetOrTessellateFill(path, .Red, .NonZero, false, vertices, indices);

		Test.Assert(vertices.Count == 4, "tessellated again, same result");
		Test.Assert(cache.Count == 1, "the entry stayed, only its geometry went stale");
	}

	/// Invalidating something that was never cached is harmless.
	[Test]
	public static void InvalidatingAnUncachedPathIsHarmless()
	{
		let cache = scope PathCache();
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		cache.Invalidate(path);
		Test.Assert(cache.Count == 0);
	}

	[Test]
	public static void ClearingEmptiesTheCache()
	{
		let cache = scope PathCache();
		let first = Rect(0, 0, 10, 10);
		defer delete first;
		let second = Rect(20, 20, 10, 10);
		defer delete second;

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();
		cache.GetOrTessellateFill(first, .Red, .NonZero, false, vertices, indices);
		cache.GetOrTessellateFill(second, .Red, .NonZero, false, vertices, indices);
		Test.Assert(cache.Count == 2);

		cache.Clear();
		Test.Assert(cache.Count == 0);
	}

	/// The cache never grows past its capacity.
	///
	/// Eviction runs BEFORE the insert, trimming to one below the capacity and then filling
	/// the slot, so a full cache settles at exactly the capacity rather than one over it.
	[Test]
	public static void TheCacheNeverGrowsPastItsCapacity()
	{
		let cache = scope PathCache(3);

		let paths = scope List<Path>();
		defer { ClearAndDeleteItems!(paths); }
		for (int i = 0; i < 6; i++)
			paths.Add(Rect((float)i * 20, 0, 10, 10));

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		for (let path in paths)
		{
			cache.GetOrTessellateFill(path, .Red, .NonZero, false, vertices, indices);
			Test.Assert(cache.Count <= 3, "never past the capacity");
		}
	}

	/// A path drawn every frame survives eviction; one drawn once does not.
	[Test]
	public static void AFrequentlyUsedPathSurvives()
	{
		let cache = scope PathCache(3);

		let hot = Rect(0, 0, 10, 10);
		defer delete hot;

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();
		cache.GetOrTessellateFill(hot, .Red, .NonZero, false, vertices, indices);

		let cold = scope List<Path>();
		defer { ClearAndDeleteItems!(cold); }
		for (int i = 0; i < 8; i++)
		{
			cold.Add(Rect((float)i * 20 + 100, 0, 10, 10));
			cache.GetOrTessellateFill(cold[i], .Red, .NonZero, false, vertices, indices);
			// Touched every round, so it is never the oldest.
			cache.GetOrTessellateFill(hot, .Red, .NonZero, false, vertices, indices);
		}

		// Still a hit: the geometry comes back without retessellating.
		vertices.Clear();
		indices.Clear();
		cache.GetOrTessellateFill(hot, .Red, .NonZero, false, vertices, indices);
		Test.Assert(vertices.Count == 4);
	}

	/// Lowering the capacity evicts immediately rather than waiting for the next insert.
	[Test]
	public static void LoweringTheCapacityEvictsAtOnce()
	{
		let cache = scope PathCache(16);

		let paths = scope List<Path>();
		defer { ClearAndDeleteItems!(paths); }
		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		for (int i = 0; i < 8; i++)
		{
			paths.Add(Rect((float)i * 20, 0, 10, 10));
			cache.GetOrTessellateFill(paths[i], .Red, .NonZero, false, vertices, indices);
		}
		Test.Assert(cache.Count == 8);

		// Trimmed to one BELOW the new capacity, because the same eviction runs and it
		// leaves room for the insert that normally follows.
		cache.SetCapacity(3);
		Test.Assert(cache.Count == 2);
	}
}
