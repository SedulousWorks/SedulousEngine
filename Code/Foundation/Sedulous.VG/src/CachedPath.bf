using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Pre-tessellated path data for reuse across frames
public class CachedPath
{
	// Fill cache
	private List<VGVertex> mFillVertices ~ delete _;
	private List<uint32> mFillIndices ~ delete _;
	private bool mFillValid;
	private Color mFillColor;
	private FillRule mFillRule;
	private bool mFillAA;

	// Stroke cache
	private List<VGVertex> mStrokeVertices ~ delete _;
	private List<uint32> mStrokeIndices ~ delete _;
	private bool mStrokeValid;
	private StrokeStyle mStrokeStyle;
	private Color mStrokeColor;
	private bool mStrokeAA;

	/// Access count for LRU eviction
	public int64 LastAccessTime;

	public this()
	{
	}

	/// Whether fill tessellation is cached
	public bool IsFillValid => mFillValid;

	/// Whether stroke tessellation is cached
	public bool IsStrokeValid => mStrokeValid;

	/// Check if the cached fill matches the requested style
	public bool FillMatches(Color color, FillRule fillRule, bool antiAlias)
	{
		return mFillValid && mFillColor == color && mFillRule == fillRule && mFillAA == antiAlias;
	}

	/// Check if the cached stroke matches the requested style
	public bool StrokeMatches(Color color, StrokeStyle style, bool antiAlias)
	{
		return mStrokeValid && mStrokeColor == color &&
			   mStrokeStyle.Width == style.Width &&
			   mStrokeStyle.Cap == style.Cap &&
			   mStrokeStyle.Join == style.Join &&
			   mStrokeAA == antiAlias;
	}

	/// Get the cached fill mesh data
	public void GetFillMesh(out Span<VGVertex> vertices, out Span<uint32> meshIndices)
	{
		if (mFillVertices != null && mFillValid)
		{
			vertices = mFillVertices;
			meshIndices = mFillIndices;
		}
		else
		{
			vertices = default;
			meshIndices = default;
		}
	}

	/// Get the cached stroke mesh data
	public void GetStrokeMesh(out Span<VGVertex> vertices, out Span<uint32> meshIndices)
	{
		if (mStrokeVertices != null && mStrokeValid)
		{
			vertices = mStrokeVertices;
			meshIndices = mStrokeIndices;
		}
		else
		{
			vertices = default;
			meshIndices = default;
		}
	}

	/// Store fill tessellation data
	public void SetFillData(List<VGVertex> vertices, List<uint32> fillIndices, Color color, FillRule fillRule, bool antiAlias)
	{
		if (mFillVertices == null)
		{
			mFillVertices = new List<VGVertex>();
			mFillIndices = new List<uint32>();
		}

		mFillVertices.Clear();
		mFillVertices.AddRange(vertices);
		mFillIndices.Clear();
		mFillIndices.AddRange(fillIndices);
		mFillColor = color;
		mFillRule = fillRule;
		mFillAA = antiAlias;
		mFillValid = true;
	}

	/// Store stroke tessellation data
	public void SetStrokeData(List<VGVertex> vertices, List<uint32> strokeIndices, Color color, StrokeStyle style, bool antiAlias)
	{
		if (mStrokeVertices == null)
		{
			mStrokeVertices = new List<VGVertex>();
			mStrokeIndices = new List<uint32>();
		}

		mStrokeVertices.Clear();
		mStrokeVertices.AddRange(vertices);
		mStrokeIndices.Clear();
		mStrokeIndices.AddRange(strokeIndices);
		mStrokeColor = color;
		mStrokeStyle = style;
		mStrokeAA = antiAlias;
		mStrokeValid = true;
	}

	/// Invalidate all cached data
	public void Invalidate()
	{
		mFillValid = false;
		mStrokeValid = false;
	}
}
