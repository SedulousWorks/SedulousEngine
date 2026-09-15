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
	private float mFillTolerance = 0.0f;

	private List<VGVertex> mStrokeVertices = new .() ~ delete _;
	private List<uint32> mStrokeIndices = new .() ~ delete _;
	private bool mStrokeValid = false;
	private Color mStrokeColor = .White;
	private StrokeStyle mStrokeStyle = .();
	private bool mStrokeAntiAlias = false;
	private float mStrokeTolerance = 0.0f;
	private List<float> mStrokeDash = new .() ~ delete _;

	public bool IsFillValid => mFillValid;
	public bool IsStrokeValid => mStrokeValid;

	/// Whether what is cached was tessellated for EXACTLY this request, the tolerance
	/// included: a finer tolerance flattens the same path into more points.
	public bool FillMatches(Color color, FillRule fillRule, bool antiAlias, float tolerance)
		=> mFillValid && (mFillColor == color) && (mFillRule == fillRule)
			&& (mFillAntiAlias == antiAlias) && (mFillTolerance == tolerance);

	/// The stroke twin, comparing EVERY input of the stroke tessellation: the whole style
	/// (miter limit and dash offset included), the dash pattern and the tolerance.
	///
	/// Comparing the width, cap and join alone served the previous dashing to a caller that
	/// changed only the pattern or animated the offset, which looks like a frozen dash.
	public bool StrokeMatches(Color color, StrokeStyle style, Span<float> dashPattern,
		bool antiAlias, float tolerance)
	{
		if (!mStrokeValid || (mStrokeColor != color) || (mStrokeAntiAlias != antiAlias)
			|| (mStrokeTolerance != tolerance) || (mStrokeStyle.Width != style.Width)
			|| (mStrokeStyle.Cap != style.Cap) || (mStrokeStyle.Join != style.Join)
			|| (mStrokeStyle.MiterLimit != style.MiterLimit)
			|| (mStrokeStyle.DashOffset != style.DashOffset)
			|| (mStrokeDash.Count != dashPattern.Length))
			return false;

		for (int i = 0; i < mStrokeDash.Count; i++)
		{
			if (mStrokeDash[i] != dashPattern[i])
				return false;
		}
		return true;
	}

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
		FillRule fillRule, bool antiAlias, float tolerance)
	{
		mFillVertices.Clear();
		mFillVertices.AddRange(vertices);
		mFillIndices.Clear();
		mFillIndices.AddRange(indices);

		mFillColor = color;
		mFillRule = fillRule;
		mFillAntiAlias = antiAlias;
		mFillTolerance = tolerance;
		mFillValid = true;
	}

	public void SetStrokeData(Span<VGVertex> vertices, Span<uint32> indices, Color color,
		StrokeStyle style, Span<float> dashPattern, bool antiAlias, float tolerance)
	{
		mStrokeVertices.Clear();
		mStrokeVertices.AddRange(vertices);
		mStrokeIndices.Clear();
		mStrokeIndices.AddRange(indices);

		mStrokeColor = color;
		mStrokeStyle = style;
		mStrokeAntiAlias = antiAlias;
		mStrokeTolerance = tolerance;
		mStrokeDash.Clear();
		mStrokeDash.AddRange(dashPattern);
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
