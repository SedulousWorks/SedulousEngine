using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// One path's tessellated geometry, kept for reuse across frames.
///
/// The fill and the stroke are cached SEPARATELY, because a shape is commonly both filled
/// and stroked and the two are tessellated by different code with different inputs.
class CachedPath
{
	/// When this was last used, for eviction. A counter rather than a clock: it only has
	/// to order accesses, and a clock would tie the cache to a frame rate.
	public int64 LastAccessTime = 0;

	private List<VGVertex> mFillVertices = new .() ~ delete _;
	private List<uint32> mFillIndices = new .() ~ delete _;
	private bool mFillValid = false;
	private Color mFillColor = .White;
	private FillRule mFillRule = .NonZero;
	private bool mFillAntiAlias = false;

	private List<VGVertex> mStrokeVertices = new .() ~ delete _;
	private List<uint32> mStrokeIndices = new .() ~ delete _;
	private bool mStrokeValid = false;
	private Color mStrokeColor = .White;
	private StrokeStyle mStrokeStyle = .();
	private bool mStrokeAntiAlias = false;

	public bool IsFillValid => mFillValid;
	public bool IsStrokeValid => mStrokeValid;

	/// Whether what is cached was tessellated for exactly this request.
	public bool FillMatches(Color color, FillRule fillRule, bool antiAlias)
		=> mFillValid && (mFillColor == color) && (mFillRule == fillRule)
			&& (mFillAntiAlias == antiAlias);

	/// The MITER LIMIT and the dash offset are deliberately not compared, matching Raptor:
	/// the width, cap and join are what change the geometry's shape, and comparing every
	/// field would miss the cache on a difference that produces identical vertices.
	public bool StrokeMatches(Color color, StrokeStyle style, bool antiAlias)
		=> mStrokeValid && (mStrokeColor == color) && (mStrokeStyle.Width == style.Width)
			&& (mStrokeStyle.Cap == style.Cap) && (mStrokeStyle.Join == style.Join)
			&& (mStrokeAntiAlias == antiAlias);

	/// EMPTY when invalid, so a caller that forgot to check appends nothing rather than
	/// stale geometry.
	public void GetFillMesh(out Span<VGVertex> vertices, out Span<uint32> indices)
	{
		vertices = mFillValid ? Span<VGVertex>(mFillVertices.Ptr, mFillVertices.Count) : .();
		indices = mFillValid ? Span<uint32>(mFillIndices.Ptr, mFillIndices.Count) : .();
	}

	public void GetStrokeMesh(out Span<VGVertex> vertices, out Span<uint32> indices)
	{
		vertices = mStrokeValid ? Span<VGVertex>(mStrokeVertices.Ptr, mStrokeVertices.Count) : .();
		indices = mStrokeValid ? Span<uint32>(mStrokeIndices.Ptr, mStrokeIndices.Count) : .();
	}

	public void SetFillData(Span<VGVertex> vertices, Span<uint32> indices, Color color,
		FillRule fillRule, bool antiAlias)
	{
		mFillVertices.Clear();
		mFillVertices.AddRange(vertices);
		mFillIndices.Clear();
		mFillIndices.AddRange(indices);

		mFillColor = color;
		mFillRule = fillRule;
		mFillAntiAlias = antiAlias;
		mFillValid = true;
	}

	public void SetStrokeData(Span<VGVertex> vertices, Span<uint32> indices, Color color,
		StrokeStyle style, bool antiAlias)
	{
		mStrokeVertices.Clear();
		mStrokeVertices.AddRange(vertices);
		mStrokeIndices.Clear();
		mStrokeIndices.AddRange(indices);

		mStrokeColor = color;
		mStrokeStyle = style;
		mStrokeAntiAlias = antiAlias;
		mStrokeValid = true;
	}

	/// Marks both meshes stale. The geometry is KEPT rather than freed, because the next
	/// tessellation will overwrite it and the buffers are already the right size.
	public void Invalidate()
	{
		mFillValid = false;
		mStrokeValid = false;
	}
}
