using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// Keeps tessellated geometry for reuse across frames, evicting the least recently used.
///
/// Tessellation is the expensive part of drawing a path, and a user interface redraws
/// mostly the same shapes every frame. Caching by IDENTITY rather than by content means a
/// path that has not changed costs a lookup.
class PathCache
{
	private Dictionary<uint64, CachedPath> mCache = new .() ~ DeleteDictionaryAndValues!(_);
	private int32 mCapacity = 256;
	private int64 mAccessCounter = 0;

	public this(int32 capacity = 256)
	{
		mCapacity = capacity;
	}

	/// Appends the path's filled mesh, tessellating it if what is cached does not match.
	public void GetOrTessellateFill(Path path, Color color, FillRule fillRule, bool antiAlias,
		List<VGVertex> outVertices, List<uint32> outIndices, float tolerance = 0.25f)
	{
		let cached = GetOrCreate(path);
		cached.LastAccessTime = mAccessCounter++;

		if (cached.FillMatches(color, fillRule, antiAlias))
		{
			cached.GetFillMesh(let vertices, let indices);
			Append(outVertices, outIndices, vertices, indices);
			return;
		}

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();
		FillTessellator.Tessellate(path, fillRule, color, antiAlias, vertices, indices, tolerance);

		cached.SetFillData(vertices, indices, color, fillRule, antiAlias);
		Append(outVertices, outIndices, vertices, indices);
	}

	/// The stroke twin.
	///
	/// The dash pattern is NOT part of the match, matching Raptor: a caller that changes it
	/// between frames on the same path gets the previous dashing until something else
	/// invalidates the entry. Animating a dash offset therefore wants Invalidate.
	public void GetOrTessellateStroke(Path path, Color color, StrokeStyle style,
		Span<float> dashPattern, bool antiAlias, List<VGVertex> outVertices,
		List<uint32> outIndices, float tolerance = 0.25f)
	{
		let cached = GetOrCreate(path);
		cached.LastAccessTime = mAccessCounter++;

		if (cached.StrokeMatches(color, style, antiAlias))
		{
			cached.GetStrokeMesh(let vertices, let indices);
			Append(outVertices, outIndices, vertices, indices);
			return;
		}

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		let subPaths = scope List<FlattenedSubPath>();
		defer { ClearAndDeleteItems!(subPaths); }
		PathFlattener.Flatten(path, tolerance, subPaths);

		// Each subpath is stroked on its own, so a shape of several contours gets caps and
		// joins per contour rather than one run joining them all.
		for (let subPath in subPaths)
		{
			if (subPath.Points.Count >= 2)
			{
				StrokeTessellator.Tessellate(subPath.Points, subPath.IsClosed, style, dashPattern,
					antiAlias, color, vertices, indices);
			}
		}

		cached.SetStrokeData(vertices, indices, color, style, antiAlias);
		Append(outVertices, outIndices, vertices, indices);
	}

	/// Marks one path's geometry stale, so the next request retessellates.
	public void Invalidate(Path path)
	{
		if (mCache.TryGetValue(path.InstanceId, let cached))
			cached.Invalidate();
	}

	public void Clear()
	{
		DeleteDictionaryAndValues!(mCache);
		mCache = new .();
		mAccessCounter = 0;
	}

	public void SetCapacity(int32 capacity)
	{
		mCapacity = capacity;
		EvictIfNeeded();
	}

	public int Count => mCache.Count;

	/// Copies a cached mesh onto the end of the output, REBASING its indices: the cached
	/// ones start at zero, and the output already holds other geometry.
	private static void Append(List<VGVertex> outVertices, List<uint32> outIndices,
		Span<VGVertex> vertices, Span<uint32> indices)
	{
		let baseIndex = (uint32)outVertices.Count;
		outVertices.AddRange(vertices);

		for (let index in indices)
			outIndices.Add(baseIndex + index);
	}

	private CachedPath GetOrCreate(Path path)
	{
		if (mCache.TryGetValue(path.InstanceId, let existing))
			return existing;

		EvictIfNeeded();

		let created = new CachedPath();
		mCache[path.InstanceId] = created;
		return created;
	}

	/// Evicts down to the capacity, oldest first.
	///
	/// A linear scan per eviction, which is what Raptor does: the cache holds a few hundred
	/// entries and evicts rarely, so a heap would cost more to maintain than it saves.
	private void EvictIfNeeded()
	{
		while (mCache.Count >= mCapacity)
		{
			uint64 oldestKey = 0;
			var oldestTime = int64.MaxValue;
			var found = false;

			for (let entry in mCache)
			{
				if (entry.value.LastAccessTime >= oldestTime)
					continue;
				oldestTime = entry.value.LastAccessTime;
				oldestKey = entry.key;
				found = true;
			}

			if (!found)
				break;

			delete mCache[oldestKey];
			mCache.Remove(oldestKey);
		}
	}
}
