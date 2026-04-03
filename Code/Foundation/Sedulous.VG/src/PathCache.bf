using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Caches pre-tessellated path data for reuse across frames
public class PathCache
{
	private Dictionary<Path, CachedPath> mCache = new .() ~ {
		for (let entry in _)
			delete entry.value;
		delete _;
	};
	private int mCapacity = 256;
	private int64 mAccessCounter = 0;

	public this(int capacity = 256)
	{
		mCapacity = capacity;
	}

	/// Get or tessellate a filled path
	public void GetOrTessellateFill(Path path, Color color, FillRule fillRule, bool antiAlias,
		List<VGVertex> outVertices, List<uint32> outIndices, float tolerance = 0.25f)
	{
		var cached = GetOrCreate(path);
		cached.LastAccessTime = mAccessCounter++;

		if (cached.FillMatches(color, fillRule, antiAlias))
		{
			Span<VGVertex> verts = ?;
			Span<uint32> idx = ?;
			cached.GetFillMesh(out verts, out idx);

			let baseIndex = (uint32)outVertices.Count;
			for (let v in verts)
				outVertices.Add(v);
			for (let i in idx)
				outIndices.Add(baseIndex + i);
			return;
		}

		// Tessellate and cache
		let tempVerts = scope List<VGVertex>();
		let tempIndices = scope List<uint32>();
		FillTessellator.Tessellate(path, fillRule, color, antiAlias, tempVerts, tempIndices, tolerance);

		cached.SetFillData(tempVerts, tempIndices, color, fillRule, antiAlias);

		let baseIndex = (uint32)outVertices.Count;
		for (let v in tempVerts)
			outVertices.Add(v);
		for (let i in tempIndices)
			outIndices.Add(baseIndex + i);
	}

	/// Get or tessellate a stroked path
	public void GetOrTessellateStroke(Path path, Color color, StrokeStyle style,
		Span<float> dashPattern, bool antiAlias,
		List<VGVertex> outVertices, List<uint32> outIndices, float tolerance = 0.25f)
	{
		var cached = GetOrCreate(path);
		cached.LastAccessTime = mAccessCounter++;

		if (cached.StrokeMatches(color, style, antiAlias))
		{
			Span<VGVertex> verts = ?;
			Span<uint32> idx = ?;
			cached.GetStrokeMesh(out verts, out idx);

			let baseIndex = (uint32)outVertices.Count;
			for (let v in verts)
				outVertices.Add(v);
			for (let i in idx)
				outIndices.Add(baseIndex + i);
			return;
		}

		// Tessellate and cache
		let tempVerts = scope List<VGVertex>();
		let tempIndices = scope List<uint32>();

		let subPaths = scope List<FlattenedSubPath>();
		PathFlattener.Flatten(path, tolerance, subPaths);
		defer { for (let sp in subPaths) delete sp; }

		for (let subPath in subPaths)
		{
			if (subPath.Points.Count >= 2)
				StrokeTessellator.Tessellate(subPath.Points, subPath.IsClosed, style, dashPattern, antiAlias, color, tempVerts, tempIndices);
		}

		cached.SetStrokeData(tempVerts, tempIndices, color, style, antiAlias);

		let baseIndex = (uint32)outVertices.Count;
		for (let v in tempVerts)
			outVertices.Add(v);
		for (let i in tempIndices)
			outIndices.Add(baseIndex + i);
	}

	/// Invalidate cached data for a specific path
	public void Invalidate(Path path)
	{
		if (mCache.TryGetValue(path, let cached))
			cached.Invalidate();
	}

	/// Clear all cached data
	public void Clear()
	{
		for (let entry in mCache)
			delete entry.value;
		mCache.Clear();
		mAccessCounter = 0;
	}

	/// Set the maximum number of cached paths
	public void SetCapacity(int capacity)
	{
		mCapacity = capacity;
		EvictIfNeeded();
	}

	private CachedPath GetOrCreate(Path path)
	{
		if (mCache.TryGetValue(path, let existing))
			return existing;

		EvictIfNeeded();

		let cached = new CachedPath();
		mCache[path] = cached;
		return cached;
	}

	private void EvictIfNeeded()
	{
		while (mCache.Count >= mCapacity)
		{
			// Find least recently used
			Path oldestPath = null;
			int64 oldestTime = int64.MaxValue;
			for (let entry in mCache)
			{
				if (entry.value.LastAccessTime < oldestTime)
				{
					oldestTime = entry.value.LastAccessTime;
					oldestPath = entry.key;
				}
			}

			if (oldestPath != null)
			{
				if (mCache.TryGetValue(oldestPath, let cached))
				{
					delete cached;
					mCache.Remove(oldestPath);
				}
			}
			else
				break;
		}
	}
}
