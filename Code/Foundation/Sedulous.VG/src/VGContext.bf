using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.Image;

namespace Sedulous.VG;

/// The drawing surface: what a caller talks to, and what produces the batch a renderer
/// consumes.
///
/// Everything is IMMEDIATE. A call appends geometry and, when the render state changed,
/// closes the previous command and opens a new one. Nothing is retained between frames
/// except the baked gradient ramps, which are content keyed so the renderer's own texture
/// cache stays valid.
class VGContext
{
	/// How many distinct gradient ramps the cache holds before the whole of it is dropped.
	///
	/// Generous: a interface with a handful of static gradients never approaches it. Only
	/// a continuously ANIMATED ramp colour mints new entries every frame.
	public const int cMaxGradientLutCacheEntries = 256;

	/// The baked ramp's width. Two hundred and fifty six steps is enough that a ramp reads
	/// as smooth, and one row keeps it a trivial texture.
	private const uint32 cGradientLutWidth = 256;

	/// The fringe width the tessellators get before the transform scale is divided out.
	private const float cBaseFringe = 0.75f;

	private VGBatch mBatch = new .() ~ delete _;
	/// One white texel at index zero, which is what lets a solid colour draw share the
	/// textured pipeline rather than needing one of its own.
	private OwnedImageData mWhiteTexture ~ delete _;

	/// Baked ramps keyed by their CONTENT, persisted across frames.
	///
	/// Content keyed so identical ramps share one image: the stable identity the renderer's
	/// GPU texture cache keys on. A per frame pool made freed and reallocated ramps hit
	/// stale GPU textures, or leaked one per fill.
	private Dictionary<uint64, OwnedImageData> mGradientLutCache = new .() ~ DeleteDictionaryAndValues!(_);
	/// Evicted ramps held one more frame, so the identities announced to the renderer are
	/// not already dangling while its own frame is still in flight.
	private List<OwnedImageData> mEvictedLutHold = new .() ~ DeleteContainerAndItems!(_);

	private PathBuilder mCurrentPath = new .() ~ delete _;
	private IFontService mFontService;

	private List<VGState> mStateStack = new .() ~ delete _;
	private List<Rectangle> mClipStack = new .() ~ delete _;
	private List<float> mOpacityStack = new .() ~ delete _;
	private VGState mCurrentState = .();

	/// The DEVICE space bounds of the active stencil clip, needed to clear it on pop.
	private Rectangle mClipPathBounds = .();
	private bool mClipPathActive = false;

	private VGBlendMode mCurrentBlendMode = .Normal;
	private VGDrawMode mCurrentDrawMode = .Default;
	private VGGradientSpread mCurrentGradientSpread = .Pad;
	private int32 mCurrentTextureIndex = 0;
	private int32 mCommandStartIndex = 0;

	private bool mPerPixelGradients = false;
	private bool mStencilFills = false;
	private bool mPixelSnap = true;
	private float mTolerance = 0.05f;

	public this(IFontService fontService = null)
	{
		mFontService = fontService;
		mStateStack.Reserve(16);

		uint8[4] whitePixel = .(255, 255, 255, 255);
		mWhiteTexture = new OwnedImageData(1, 1, .RGBA8, .(&whitePixel[0], 4), .Linear);
		mBatch.Textures.Add(mWhiteTexture);
	}

	public IFontService FontService => mFontService;

	/// Replaces the font service.
	///
	/// A caller PUSHES its current service before drawing, because a context built against
	/// a service that has since been replaced would resolve atlases the new one never made:
	/// null, a silent skip, and invisible text.
	public void SetFontService(IFontService fontService) => mFontService = fontService;

	// === output ===

	/// The batch, with the command in progress closed so it is complete.
	public VGBatch GetBatch()
	{
		FlushCurrentCommand();
		return mBatch;
	}

	/// Empties everything and resets the state for the next frame.
	public void Clear()
	{
		mBatch.Clear();
		mStateStack.Clear();
		mClipStack.Clear();
		mOpacityStack.Clear();
		mCurrentState = .();
		mCurrentBlendMode = .Normal;
		mCurrentDrawMode = .Default;
		mCurrentGradientSpread = .Pad;
		mCurrentTextureIndex = 0;
		mCommandStartIndex = 0;
		mClipPathActive = false;

		// Last frame's eviction list has been consumed by now, so the images it named can
		// finally go.
		ClearAndDeleteItems!(mEvictedLutHold);

		if (mGradientLutCache.Count > cMaxGradientLutCacheEntries)
		{
			// Over budget, which means many DISTINCT ramps rather than many uses of a few.
			// The whole cache goes, and the renderer is told which identities died so it can
			// drop the textures it built from them. It never dereferences them, and they are
			// held one more frame regardless.
			for (let entry in mGradientLutCache)
			{
				mBatch.EvictedTextures.Add(entry.value);
				mEvictedLutHold.Add(entry.value);
			}
			mGradientLutCache.Clear();
		}

		mBatch.Textures.Add(mWhiteTexture);
	}

	// === settings ===

	/// Lower means smoother curves and more vertices.
	public float Tolerance => mTolerance;
	public void SetTolerance(float tolerance) => mTolerance = tolerance;

	/// Turns on the per pixel radial and conic gradient pipelines.
	///
	/// A host must ONLY enable this once its renderer has those shaders: without them those
	/// draw modes have no pipeline at all. Off, radial and conic fall back to the affine
	/// approximation every renderer can draw. A linear gradient is exact either way.
	public void SetPerPixelGradients(bool enabled) => mPerPixelGradients = enabled;
	public bool PerPixelGradients => mPerPixelGradients;

	/// Turns on stencil then cover for COMPLEX fills: holes, self intersection, and the even
	/// odd rule, which ear clipping gets wrong.
	///
	/// Opt in by the host, and only once it has given the renderer a stencil attachment: a
	/// renderer without stencil pipelines drops the write and cover commands. A convex
	/// single contour keeps the direct path either way.
	public void SetStencilFills(bool enabled) => mStencilFills = enabled;
	public bool StencilFills => mStencilFills;

	/// Snaps axis aligned rectangles, borders and straight lines to the device pixel grid
	/// and draws them WITHOUT a fringe, because an edge already on a pixel boundary is
	/// crisp and antialiasing it only blurs it. Rotated, curved and diagonal geometry is
	/// untouched.
	public void SetPixelSnapEnabled(bool enabled) => mPixelSnap = enabled;
	public bool PixelSnapEnabled => mPixelSnap;

	// === state stack ===

	public void PushState() => mStateStack.Add(mCurrentState);

	public void PopState()
	{
		if (!mStateStack.IsEmpty)
			mCurrentState = mStateStack.PopBack();
	}

	// === transform ===

	public void SetTransform(Float4x4 transform) => mCurrentState.Transform = transform;
	public Float4x4 GetTransform() => mCurrentState.Transform;
	public void ResetTransform() => mCurrentState.Transform = .Identity();

	// Pre multiplied, so a translate then a rotate rotates about the translated origin,
	// which is what a nested drawing expects.
	public void Translate(float x, float y)
		=> mCurrentState.Transform = Float4x4.Translation(.(x, y, 0.0f)) * mCurrentState.Transform;

	public void Rotate(float radians)
		=> mCurrentState.Transform = Float4x4.RotationZ(radians) * mCurrentState.Transform;

	public void Scale(float sx, float sy)
		=> mCurrentState.Transform = Float4x4.Scale(.(sx, sy, 1.0f)) * mCurrentState.Transform;

	// === scissor clipping ===

	public void PushClipRect(Rectangle rect)
	{
		FlushCurrentCommand();
		mClipStack.Add(mCurrentState.ClipRect);

		let transformed = TransformRect(rect);
		// INTERSECTED with whatever is already active, so a nested clip can only ever
		// shrink the visible region.
		mCurrentState.ClipRect = HasClip(mCurrentState.ClipRect)
			? Rectangle.Intersect(mCurrentState.ClipRect, transformed) : transformed;
		mCurrentState.ClipMode = .Scissor;
	}

	public void PopClip()
	{
		FlushCurrentCommand();

		if (mClipStack.IsEmpty)
		{
			mCurrentState.ClipRect = .();
			mCurrentState.ClipMode = .None;
			return;
		}

		mCurrentState.ClipRect = mClipStack.PopBack();
		mCurrentState.ClipMode = HasClip(mCurrentState.ClipRect) ? .Scissor : .None;
	}

	/// Whether a rectangle in CURRENT local coordinates could contribute any pixels.
	///
	/// A caller uses this to skip tessellating geometry the scissor would discard anyway: a
	/// scrolled list draws its viewport rather than its whole contents, which is the
	/// difference between a frame and a frame that exceeds the renderer's vertex ceiling.
	public bool IsRectVisible(Rectangle rect)
	{
		if (mCurrentState.ClipMode != .Scissor)
			return true;
		if (!HasClip(mCurrentState.ClipRect))
			return false;
		return TransformRect(rect).Intersects(mCurrentState.ClipRect);
	}

	// === path clipping ===

	/// Clips subsequent draws to a path, by the non zero rule.
	///
	/// Requires stencil fills. WITHOUT them it degrades to a scissor of the path's
	/// transformed bounds, which is coarse but contained: too much is drawn rather than the
	/// wrong thing.
	///
	/// ONE LEVEL DEEP. A nested push replaces the active clip rather than intersecting with
	/// it.
	public void PushClipPath(Path path)
	{
		let subPaths = scope List<FlattenedSubPath>();
		defer { ClearAndDeleteItems!(subPaths); }
		PathFlattener.Flatten(path, GetScaledTolerance(), subPaths);

		if (!mStencilFills)
		{
			PushClipPathAsScissor(subPaths);
			return;
		}

		// The clip's OWN geometry must not be clipped by whatever is already active, or the
		// stencil it writes would be cut by the previous clip.
		FlushCurrentCommand();
		let savedMode = mCurrentState.ClipMode;
		mCurrentState.ClipMode = .None;

		let deviceBounds = EmitWindingFans(subPaths, .NonZero);
		mClipPathBounds = deviceBounds;

		if ((deviceBounds.Width <= 0.0f) || (deviceBounds.Height <= 0.0f))
		{
			mCurrentState.ClipMode = savedMode;
			return;
		}

		// One pass converts the accumulated winding into the clip mask bit and zeroes the
		// winding bits behind itself.
		EmitDeviceQuad(deviceBounds, .ClipApply);
		mClipPathActive = true;
		mCurrentState.ClipMode = .Stencil;
	}

	private void PushClipPathAsScissor(List<FlattenedSubPath> subPaths)
	{
		var min = Float2(FloatMax, FloatMax);
		var max = Float2(-FloatMax, -FloatMax);

		for (let subPath in subPaths)
		{
			for (let point in subPath.Points)
			{
				let device = TransformPoint(point);
				min.X = Min(min.X, device.X);
				min.Y = Min(min.Y, device.Y);
				max.X = Max(max.X, device.X);
				max.Y = Max(max.Y, device.Y);
			}
		}

		if ((max.X <= min.X) || (max.Y <= min.Y))
			return;

		FlushCurrentCommand();
		let deviceRect = Rectangle(min.X, min.Y, max.X - min.X, max.Y - min.Y);
		mCurrentState.ClipRect = HasClip(mCurrentState.ClipRect)
			? Rectangle.Intersect(mCurrentState.ClipRect, deviceRect) : deviceRect;
		mCurrentState.ClipMode = .Scissor;
	}

	/// Ends the active path clip, zeroing its mask over the bounds it covered.
	public void PopClipPath()
	{
		if (!mClipPathActive)
		{
			mCurrentState.ClipMode = .None;
			return;
		}

		FlushCurrentCommand();
		mCurrentState.ClipMode = .None;
		EmitDeviceQuad(mClipPathBounds, .ClipClear);
		mClipPathActive = false;
	}

	// === opacity ===

	/// MULTIPLIES into whatever is already in effect, so nesting two halves gives a
	/// quarter rather than a half.
	public void PushOpacity(float opacity)
	{
		mOpacityStack.Add(mCurrentState.Opacity);
		mCurrentState.Opacity *= Clamp(opacity, 0.0f, 1.0f);
	}

	public void PopOpacity()
	{
		mCurrentState.Opacity = mOpacityStack.IsEmpty ? 1.0f : mOpacityStack.PopBack();
	}

	public float Opacity => mCurrentState.Opacity;

	// === modes ===

	/// Each of these CUTS the batch when it changes, because they are properties of a draw
	/// call rather than of a vertex.
	public void SetBlendMode(VGBlendMode mode)
	{
		if (mode == mCurrentBlendMode)
			return;
		FlushCurrentCommand();
		mCurrentBlendMode = mode;
	}

	public void SetDrawMode(VGDrawMode mode)
	{
		if (mode == mCurrentDrawMode)
			return;
		FlushCurrentCommand();
		mCurrentDrawMode = mode;
	}

	/// The ramp sampler's address mode. Two fills sharing one cached ramp may still spread
	/// differently, which is why this cuts the batch rather than riding on the texture.
	public void SetGradientSpread(VGGradientSpread spread)
	{
		if (spread == mCurrentGradientSpread)
			return;
		FlushCurrentCommand();
		mCurrentGradientSpread = spread;
	}

	// === filling and stroking paths ===

	/// Fills a path with one colour.
	public void FillPath(Path path, Color color, FillRule fillRule = .EvenOdd,
		bool antiAlias = true)
	{
		if (mStencilFills)
		{
			let subPaths = scope List<FlattenedSubPath>();
			defer { ClearAndDeleteItems!(subPaths); }
			PathFlattener.Flatten(path, GetScaledTolerance(), subPaths);

			if (NeedsStencilFill(subPaths))
			{
				EmitStencilFill(subPaths, fillRule, ApplyOpacity(color), null);
				return;
			}
		}

		SetupForSolidDraw();
		let startVertex = mBatch.Vertices.Count;
		FillTessellator.Tessellate(path, fillRule, ApplyOpacity(color), antiAlias, mBatch.Vertices,
			mBatch.Indices, GetScaledTolerance(), GetScaledFringe());
		TransformVertices(startVertex);
	}

	/// Fills a path with a style.
	///
	/// A gradient bakes its ramp into a texture and the tessellator emits the gradient
	/// parameter per vertex, so the ramp is sampled PER PIXEL: exact for any number of
	/// stops, with none of the banding an interpolated colour gives.
	public void FillPath(Path path, IVGFill fill, FillRule fillRule = .EvenOdd,
		bool antiAlias = true)
	{
		if (mStencilFills)
		{
			let subPaths = scope List<FlattenedSubPath>();
			defer { ClearAndDeleteItems!(subPaths); }
			PathFlattener.Flatten(path, GetScaledTolerance(), subPaths);

			if (NeedsStencilFill(subPaths))
			{
				EmitStencilFill(subPaths, fillRule, .White, fill);
				return;
			}
		}

		let gradientTess = BindGradientLut(fill);
		let startVertex = mBatch.Vertices.Count;

		FillTessellator.TessellateWithFill(path, fillRule, fill, antiAlias, mBatch.Vertices,
			mBatch.Indices, GetScaledTolerance(), GetScaledFringe(), gradientTess);

		ApplyOpacityToVertices(startVertex);
		TransformVertices(startVertex);

		if (gradientTess != .Gouraud)
			RestoreDefaultSampling();
	}

	public void StrokePath(Path path, Color color, StrokeStyle style,
		Span<float> dashPattern = default, bool antiAlias = true)
	{
		SetupForSolidDraw();

		let subPaths = scope List<FlattenedSubPath>();
		defer { ClearAndDeleteItems!(subPaths); }
		PathFlattener.Flatten(path, GetScaledTolerance(), subPaths);

		let startVertex = mBatch.Vertices.Count;
		let opaqueColor = ApplyOpacity(color);
		let fringe = GetScaledFringe();

		for (let subPath in subPaths)
		{
			if (subPath.Points.Count < 2)
				continue;
			StrokeTessellator.Tessellate(subPath.Points, subPath.IsClosed, style, dashPattern,
				antiAlias, opaqueColor, mBatch.Vertices, mBatch.Indices, fringe);
		}

		TransformVertices(startVertex);
	}

	// === filled shapes ===

	public void FillRect(Rectangle rect, Color color)
	{
		// Snapped and fringeless when it can be: an axis aligned edge on a pixel boundary
		// is already crisp, and a fringe would only blur it.
		if (mPixelSnap && TransformIsAxisAligned())
		{
			let p0 = TransformPoint(.(rect.X, rect.Y));
			let p1 = TransformPoint(.(rect.X + rect.Width, rect.Y + rect.Height));
			SetupForSolidDraw();
			EmitDeviceRect(Round(Min(p0.X, p1.X)), Round(Min(p0.Y, p1.Y)), Round(Max(p0.X, p1.X)),
				Round(Max(p0.Y, p1.Y)), ApplyOpacity(color));
			return;
		}

		let builder = scope PathBuilder();
		AppendRect(builder, rect);
		let path = builder.ToPath();
		defer delete path;
		FillPath(path, color);
	}

	public void FillRoundedRect(Rectangle rect, float radius, Color color)
		=> FillRoundedRect(rect, CornerRadii(radius), color);

	public void FillRoundedRect(Rectangle rect, CornerRadii radii, Color color)
	{
		// No radius means it is a rectangle, which has a crisper path.
		if (radii.IsZero)
		{
			FillRect(rect, color);
			return;
		}

		let builder = scope PathBuilder();
		ShapeBuilder.BuildRoundedRect(rect, radii, builder);
		let path = builder.ToPath();
		defer delete path;
		FillPath(path, color);
	}

	public void FillCircle(Float2 center, float radius, Color color)
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildCircle(center, radius, builder);
		let path = builder.ToPath();
		defer delete path;
		FillPath(path, color);
	}

	public void FillEllipse(Float2 center, float rx, float ry, Color color)
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildEllipse(center, rx, ry, builder);
		let path = builder.ToPath();
		defer delete path;
		FillPath(path, color);
	}

	public void FillRegularPolygon(Float2 center, float radius, int32 sides, Color color)
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildRegularPolygon(center, radius, sides, builder);
		let path = builder.ToPath();
		defer delete path;
		FillPath(path, color);
	}

	public void FillStar(Float2 center, float outerRadius, float innerRadius, int32 points,
		Color color)
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildStar(center, outerRadius, innerRadius, points, builder);
		let path = builder.ToPath();
		defer delete path;
		FillPath(path, color);
	}

	/// Fills a polygon given as points.
	public void FillPolygon(Span<Float2> points, Color color)
	{
		if (points.Length < 3)
			return;

		let builder = scope PathBuilder();
		builder.MoveTo(points[0]);
		for (int i = 1; i < points.Length; i++)
			builder.LineTo(points[i]);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;
		FillPath(path, color);
	}

	// === stroked shapes ===

	public void StrokeRect(Rectangle rect, Color color, float width = 1.0f)
	{
		// Four pixel snapped bars rather than a stroked path. The top and bottom span the
		// full outer width and so OWN the corners, and the sides fill vertically between
		// them: coverage is then exact, with no seam and no corner blended twice.
		if (mPixelSnap && TransformIsAxisAligned())
		{
			let p0 = TransformPoint(.(rect.X, rect.Y));
			let p1 = TransformPoint(.(rect.X + rect.Width, rect.Y + rect.Height));
			let x0 = Min(p0.X, p1.X);
			let x1 = Max(p0.X, p1.X);
			let y0 = Min(p0.Y, p1.Y);
			let y1 = Max(p0.Y, p1.Y);

			let scale = DeviceScale();
			let thicknessX = width * scale.X;
			let thicknessY = width * scale.Y;
			// At least one device pixel: a sub pixel border must still be visible.
			let barWidth = Max(1.0f, Round(thicknessX));
			let barHeight = Max(1.0f, Round(thicknessY));

			let left = Round(x0 - (thicknessX * 0.5f));
			let right = Round(x1 - (thicknessX * 0.5f));
			let top = Round(y0 - (thicknessY * 0.5f));
			let bottom = Round(y1 - (thicknessY * 0.5f));

			let opaqueColor = ApplyOpacity(color);
			SetupForSolidDraw();
			EmitDeviceRect(left, top, right + barWidth, top + barHeight, opaqueColor);
			EmitDeviceRect(left, bottom, right + barWidth, bottom + barHeight, opaqueColor);
			EmitDeviceRect(left, top + barHeight, left + barWidth, bottom, opaqueColor);
			EmitDeviceRect(right, top + barHeight, right + barWidth, bottom, opaqueColor);
			return;
		}

		let builder = scope PathBuilder();
		AppendRect(builder, rect);
		let path = builder.ToPath();
		defer delete path;
		StrokePath(path, color, .(width));
	}

	public void StrokeRoundedRect(Rectangle rect, float radius, Color color, float width = 1.0f)
		=> StrokeRoundedRect(rect, CornerRadii(radius), color, width);

	public void StrokeRoundedRect(Rectangle rect, CornerRadii radii, Color color,
		float width = 1.0f)
	{
		// The corners keep the analytic stroke; only the PLACEMENT and the thickness snap,
		// so each straight edge's centreline lands where the pixel snapped bars would. That
		// is the difference between a one pixel border and a two pixel blur.
		if (mPixelSnap && TransformIsAxisAligned())
		{
			let p0 = TransformPoint(.(rect.X, rect.Y));
			let p1 = TransformPoint(.(rect.X + rect.Width, rect.Y + rect.Height));

			// A flipped transform would put the far corner before the near one, and the
			// snapping below assumes it does not.
			if ((p1.X > p0.X) && (p1.Y > p0.Y))
			{
				let scale = DeviceScale();
				let thicknessX = Max(1.0f, Round(width * scale.X));
				let thicknessY = Max(1.0f, Round(width * scale.Y));

				float SnapEdge(float center, float thickness)
					=> Round(center - (thickness * 0.5f)) + (thickness * 0.5f);

				let dx0 = SnapEdge(p0.X, thicknessX);
				let dx1 = SnapEdge(p1.X, thicknessX);
				let dy0 = SnapEdge(p0.Y, thicknessY);
				let dy1 = SnapEdge(p1.Y, thicknessY);

				// Back into local space, because the path is built there and transformed
				// on the way out.
				let snapped = Rectangle(
					rect.X + ((dx0 - p0.X) / scale.X),
					rect.Y + ((dy0 - p0.Y) / scale.Y),
					rect.Width + (((dx1 - p1.X) - (dx0 - p0.X)) / scale.X),
					rect.Height + (((dy1 - p1.Y) - (dy0 - p0.Y)) / scale.Y));

				let builder = scope PathBuilder();
				ShapeBuilder.BuildRoundedRect(snapped, radii, builder);
				let path = builder.ToPath();
				defer delete path;
				StrokePath(path, color, .(thicknessX / scale.X));
				return;
			}
		}

		let builder = scope PathBuilder();
		ShapeBuilder.BuildRoundedRect(rect, radii, builder);
		let path = builder.ToPath();
		defer delete path;
		StrokePath(path, color, .(width));
	}

	public void StrokeCircle(Float2 center, float radius, Color color, float width = 1.0f)
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildCircle(center, radius, builder);
		let path = builder.ToPath();
		defer delete path;
		StrokePath(path, color, .(width));
	}

	public void StrokeEllipse(Float2 center, float rx, float ry, Color color, float width = 1.0f)
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildEllipse(center, rx, ry, builder);
		let path = builder.ToPath();
		defer delete path;
		StrokePath(path, color, .(width));
	}

	public void DrawLine(Float2 a, Float2 b, Color color, float thickness = 1.0f)
	{
		// A horizontal or vertical line becomes a snapped bar. A diagonal keeps the
		// analytically antialiased stroke, because there is no pixel grid to align it to.
		if (mPixelSnap && TransformIsAxisAligned())
		{
			let da = TransformPoint(a);
			let db = TransformPoint(b);
			let scale = DeviceScale();

			if (Abs(da.Y - db.Y) < 0.001f)
			{
				let barHeight = Max(1.0f, Round(thickness * scale.Y));
				let y0 = Round(da.Y - (thickness * scale.Y * 0.5f));
				SetupForSolidDraw();
				EmitDeviceRect(Round(Min(da.X, db.X)), y0, Round(Max(da.X, db.X)), y0 + barHeight,
					ApplyOpacity(color));
				return;
			}

			if (Abs(da.X - db.X) < 0.001f)
			{
				let barWidth = Max(1.0f, Round(thickness * scale.X));
				let x0 = Round(da.X - (thickness * scale.X * 0.5f));
				SetupForSolidDraw();
				EmitDeviceRect(x0, Round(Min(da.Y, db.Y)), x0 + barWidth, Round(Max(da.Y, db.Y)),
					ApplyOpacity(color));
				return;
			}
		}

		let builder = scope PathBuilder();
		builder.MoveTo(a.X, a.Y);
		builder.LineTo(b.X, b.Y);
		let path = builder.ToPath();
		defer delete path;
		StrokePath(path, color, .(thickness));
	}

	/// A border drawn fully INSIDE the rectangle, rather than centred on its edge.
	public void DrawBorderRect(Rectangle rect, Color color, float thickness = 1.0f)
		=> StrokeRect(Inset(rect, thickness), color, thickness);

	public void DrawBorderRoundedRect(Rectangle rect, float radius, Color color,
		float thickness = 1.0f)
		=> DrawBorderRoundedRect(rect, CornerRadii(radius), color, thickness);

	public void DrawBorderRoundedRect(Rectangle rect, CornerRadii radii, Color color,
		float thickness = 1.0f)
	{
		let half = thickness * 0.5f;
		// The radii shrink with the inset, so the border stays concentric with the shape
		// rather than bulging at the corners.
		let insetRadii = CornerRadii(Max(0.0f, radii.TopLeft - half),
			Max(0.0f, radii.TopRight - half), Max(0.0f, radii.BottomRight - half),
			Max(0.0f, radii.BottomLeft - half));

		StrokeRoundedRect(Inset(rect, thickness), insetRadii, color, thickness);
	}

	private static Rectangle Inset(Rectangle rect, float thickness)
	{
		let half = thickness * 0.5f;
		return .(rect.X + half, rect.Y + half, rect.Width - thickness, rect.Height - thickness);
	}

	private static void AppendRect(PathBuilder builder, Rectangle rect)
	{
		builder.MoveTo(rect.X, rect.Y);
		builder.LineTo(rect.X + rect.Width, rect.Y);
		builder.LineTo(rect.X + rect.Width, rect.Y + rect.Height);
		builder.LineTo(rect.X, rect.Y + rect.Height);
		builder.Close();
	}

	// === the immediate mode path ===

	public void BeginPath() => mCurrentPath.Clear();

	public void MoveTo(float x, float y) => mCurrentPath.MoveTo(x, y);
	public void MoveTo(Float2 point) => mCurrentPath.MoveTo(point);
	public void LineTo(float x, float y) => mCurrentPath.LineTo(x, y);
	public void LineTo(Float2 point) => mCurrentPath.LineTo(point);
	public void QuadTo(float cx, float cy, float x, float y) => mCurrentPath.QuadTo(cx, cy, x, y);
	public void QuadTo(Float2 control, Float2 end) => mCurrentPath.QuadTo(control, end);

	public void CubicTo(float c1x, float c1y, float c2x, float c2y, float x, float y)
		=> mCurrentPath.CubicTo(c1x, c1y, c2x, c2y, x, y);
	public void CubicTo(Float2 c1, Float2 c2, Float2 end) => mCurrentPath.CubicTo(c1, c2, end);

	public void ArcTo(float rx, float ry, float xAxisRotation, bool largeArc, bool sweep,
		float x, float y) => mCurrentPath.ArcTo(rx, ry, xAxisRotation, largeArc, sweep, x, y);
	public void ArcTo(float rx, float ry, float xAxisRotation, bool largeArc, bool sweep,
		Float2 to) => mCurrentPath.ArcTo(rx, ry, xAxisRotation, largeArc, sweep, to);

	public void ClosePath() => mCurrentPath.Close();
	public Float2 CurrentPoint => mCurrentPath.CurrentPoint;

	public void Fill(Color color, FillRule fillRule = .EvenOdd, bool antiAlias = true)
	{
		if (mCurrentPath.CommandCount == 0)
			return;
		let path = mCurrentPath.ToPath();
		defer delete path;
		FillPath(path, color, fillRule, antiAlias);
	}

	public void Fill(IVGFill fill, FillRule fillRule = .EvenOdd, bool antiAlias = true)
	{
		if (mCurrentPath.CommandCount == 0)
			return;
		let path = mCurrentPath.ToPath();
		defer delete path;
		FillPath(path, fill, fillRule, antiAlias);
	}

	public void Stroke(Color color, StrokeStyle style, Span<float> dashPattern = default,
		bool antiAlias = true)
	{
		if (mCurrentPath.CommandCount == 0)
			return;
		let path = mCurrentPath.ToPath();
		defer delete path;
		StrokePath(path, color, style, dashPattern, antiAlias);
	}

	public void Stroke(Color color, float thickness = 1.0f)
		=> Stroke(color, StrokeStyle(thickness));

	// === images ===

	public void DrawImage(ImageData texture, Float2 position, Color tint = .White)
	{
		if (texture == null)
			return;
		let size = Rectangle(0, 0, (float)texture.Width, (float)texture.Height);
		DrawImage(texture, .(position.X, position.Y, size.Width, size.Height), size, tint);
	}

	public void DrawImage(ImageData texture, Rectangle destRect)
	{
		if (texture == null)
			return;
		DrawImage(texture, destRect, .(0, 0, (float)texture.Width, (float)texture.Height), .White);
	}

	public void DrawImage(ImageData texture, Rectangle destRect, Rectangle srcRect, Color tint)
	{
		if (texture == null)
			return;

		SetupForTextureDraw(GetOrAddTexture(texture));
		let startVertex = mBatch.Vertices.Count;
		EmitTexturedQuad(destRect, srcRect, texture.Width, texture.Height, ApplyOpacity(tint));
		TransformVertices(startVertex);
	}

	/// The same, with the destination snapped to the device pixel grid.
	///
	/// A baked bitmap drawn at a fractional origin smears under bilinear sampling and reads
	/// differently for every instance of it. Snapping makes every instance sample the same
	/// texels.
	public void DrawImageSnapped(ImageData texture, Rectangle destRect, Rectangle srcRect,
		Color tint = .White)
	{
		if (texture == null)
			return;

		if (!(mPixelSnap && TransformIsAxisAligned()))
		{
			DrawImage(texture, destRect, srcRect, tint);
			return;
		}

		let p0 = TransformPoint(.(destRect.X, destRect.Y));
		let p1 = TransformPoint(.(destRect.X + destRect.Width, destRect.Y + destRect.Height));
		let x0 = Round(Min(p0.X, p1.X));
		let y0 = Round(Min(p0.Y, p1.Y));
		let x1 = Round(Max(p0.X, p1.X));
		let y1 = Round(Max(p0.Y, p1.Y));

		SetupForTextureDraw(GetOrAddTexture(texture));
		// Already in DEVICE space, so these are not transformed on the way out.
		EmitTexturedQuad(.(x0, y0, x1 - x0, y1 - y0), srcRect, texture.Width, texture.Height,
			ApplyOpacity(tint));
	}

	/// A nine slice: the corners keep their size, the edges stretch along one axis, and the
	/// middle stretches along both.
	public void DrawNineSlice(ImageData texture, Rectangle destRect, Rectangle srcRect,
		NineSlice slices, Color tint)
	{
		if (texture == null)
			return;

		SetupForTextureDraw(GetOrAddTexture(texture));
		let startVertex = mBatch.Vertices.Count;
		let opaqueTint = ApplyOpacity(tint);

		let sx = scope float[3](srcRect.X, srcRect.X + slices.Left,
			srcRect.X + srcRect.Width - slices.Right);
		let sy = scope float[3](srcRect.Y, srcRect.Y + slices.Top,
			srcRect.Y + srcRect.Height - slices.Bottom);
		let dx = scope float[3](destRect.X, destRect.X + slices.Left,
			destRect.X + destRect.Width - slices.Right);
		let dy = scope float[3](destRect.Y, destRect.Y + slices.Top,
			destRect.Y + destRect.Height - slices.Bottom);

		// The outer columns and rows keep their own size; the middle takes whatever is
		// left, which is what makes the panel scale without distorting its border.
		let widths = scope float[3](slices.Left, dx[2] - dx[1], slices.Right);
		let heights = scope float[3](slices.Top, dy[2] - dy[1], slices.Bottom);
		let sourceWidths = scope float[3](slices.Left, sx[2] - sx[1], slices.Right);
		let sourceHeights = scope float[3](slices.Top, sy[2] - sy[1], slices.Bottom);

		for (int row = 0; row < 3; row++)
		{
			for (int column = 0; column < 3; column++)
			{
				EmitTexturedQuad(.(dx[column], dy[row], widths[column], heights[row]),
					.(sx[column], sy[row], sourceWidths[column], sourceHeights[row]),
					texture.Width, texture.Height, opaqueTint);
			}
		}

		TransformVertices(startVertex);
	}

	// === text ===

	/// Draws text at a BASELINE position from a pre rendered atlas.
	public void DrawText(StringView text, IFontAtlas atlas, ImageData atlasTexture,
		Float2 position, Color color)
	{
		if (text.IsEmpty || (atlas == null) || (atlasTexture == null))
			return;

		let textureIndex = GetOrAddTexture(atlasTexture);
		let isDistanceField = BeginDistanceFieldIfNeeded(atlas);
		SetupForTextureDraw(textureIndex);

		let startVertex = mBatch.Vertices.Count;
		let opaqueColor = ApplyOpacity(color);

		var cursorX = position.X;
		var index = 0;
		while (index < text.Length)
		{
			let codepoint = (int32)DecodeCodepoint(text, ref index);
			if (atlas.GetGlyphQuad(codepoint, ref cursorX, position.Y, let quad))
				EmitGlyphQuad(quad, opaqueColor);
		}

		TransformVertices(startVertex);
		EndDistanceField(isDistanceField);
	}

	/// Horizontally aligned within bounds, vertically centred.
	public void DrawText(StringView text, IFont font, IFontAtlas atlas, ImageData atlasTexture,
		Rectangle bounds, TextAlignment align, Color color)
	{
		if (text.IsEmpty || (font == null))
			return;

		let metrics = font.Metrics;
		let offsetY = bounds.Y + ((bounds.Height - metrics.LineHeight) * 0.5f) + metrics.Ascent;
		DrawText(text, atlas, atlasTexture,
			.(HorizontalOffset(bounds, font.MeasureString(text), align), offsetY), color);
	}

	/// Aligned on both axes.
	public void DrawText(StringView text, IFont font, IFontAtlas atlas, ImageData atlasTexture,
		Rectangle bounds, TextAlignment horizontal, VerticalAlignment vertical, Color color)
	{
		if (text.IsEmpty || (font == null))
			return;

		let metrics = font.Metrics;
		float offsetY;
		switch (vertical)
		{
		case .Top: offsetY = bounds.Y + metrics.Ascent;
		case .Middle:
			offsetY = bounds.Y + ((bounds.Height - metrics.LineHeight) * 0.5f) + metrics.Ascent;
		case .Bottom: offsetY = bounds.Y + bounds.Height - metrics.Descent;
		// The caller has already worked out the baseline, so it is taken as given.
		case .Baseline: offsetY = bounds.Y;
		}

		DrawText(text, atlas, atlasTexture,
			.(HorizontalOffset(bounds, font.MeasureString(text), horizontal), offsetY), color);
	}

	/// Through a cached font, which needs a font service to resolve its atlas texture.
	public void DrawText(StringView text, CachedFont font, Float2 position, Color color)
	{
		if ((font == null) || (mFontService == null))
			return;

		let atlasTexture = mFontService.GetAtlasTexture(font);
		if (atlasTexture == null)
			return;

		DrawText(text, font.Atlas, atlasTexture, position, color);
	}

	public void DrawText(StringView text, CachedFont font, Rectangle bounds,
		TextAlignment horizontal, VerticalAlignment vertical, Color color)
	{
		if ((font == null) || (mFontService == null))
			return;

		let atlasTexture = mFontService.GetAtlasTexture(font);
		if (atlasTexture == null)
			return;

		DrawText(text, font.Font, font.Atlas, atlasTexture, bounds, horizontal, vertical, color);
	}

	/// The default font at a size, which needs a font service.
	public void DrawText(StringView text, float fontSize, Float2 position, Color color)
	{
		if (text.IsEmpty || (mFontService == null))
			return;

		let font = mFontService.GetFont(fontSize);
		if (font == null)
			return;

		DrawText(text, font, position, color);
	}

	/// Draws already shaped glyphs at an offset.
	///
	/// The path every real control takes, since anything wrapped or edited is shaped first.
	/// It repeats the distance field handling rather than routing through DrawText, because
	/// its glyphs are placed rather than advanced.
	public void DrawPositionedGlyphs(Span<GlyphPosition> positions, CachedFont font,
		float offsetX, float offsetY, Color color)
	{
		if (positions.IsEmpty || (font == null) || (mFontService == null))
			return;

		let atlasTexture = mFontService.GetAtlasTexture(font);
		if ((atlasTexture == null) || (font.Atlas == null))
			return;

		let textureIndex = GetOrAddTexture(atlasTexture);
		let isDistanceField = BeginDistanceFieldIfNeeded(font.Atlas);
		SetupForTextureDraw(textureIndex);

		let startVertex = mBatch.Vertices.Count;
		let opaqueColor = ApplyOpacity(color);

		for (let position in positions)
		{
			if (font.Atlas.GetGlyphQuadAt(position.Codepoint, offsetX + position.X,
				offsetY + position.Y, let quad))
				EmitGlyphQuad(quad, opaqueColor);
		}

		TransformVertices(startVertex);
		EndDistanceField(isDistanceField);
	}

	/// Word wrapped, with the position being the TOP LEFT of the block rather than a
	/// baseline.
	public void DrawTextWrapped(StringView text, CachedFont font, Float2 position, float maxWidth,
		Color color, TextAlignment horizontal = .Left)
	{
		if (text.IsEmpty || (font == null) || (font.Shaper == null) || (mFontService == null))
			return;

		let atlasTexture = mFontService.GetAtlasTexture(font);
		if (atlasTexture == null)
			return;

		let positions = scope List<GlyphPosition>();
		if (font.Shaper.ShapeTextWrapped(font.Font, text, maxWidth, positions, let totalHeight)
			case .Err)
			return;

		if (horizontal != .Left)
			ApplyLineAlignment(positions, maxWidth, horizontal);

		DrawPositionedGlyphs(positions, font, position.X,
			position.Y + font.Font.Metrics.Ascent, color);
	}

	public void DrawTextWrapped(StringView text, CachedFont font, Rectangle bounds, Color color,
		TextAlignment horizontal = .Left)
		=> DrawTextWrapped(text, font, .(bounds.X, bounds.Y), bounds.Width, color, horizontal);

	/// The height wrapped text would occupy, without drawing it. Zero when there is no
	/// shaper to ask.
	public float MeasureTextWrapped(StringView text, CachedFont font, float maxWidth)
	{
		if (text.IsEmpty || (font == null) || (font.Shaper == null))
			return 0.0f;

		let positions = scope List<GlyphPosition>();
		if (font.Shaper.ShapeTextWrapped(font.Font, text, maxWidth, positions, let totalHeight)
			case .Err)
			return 0.0f;

		return totalHeight;
	}

	public Float2 MeasureText(StringView text, IFont font)
	{
		if (font == null)
			return .Zero;
		return .(font.MeasureString(text), font.Metrics.LineHeight);
	}

	public float MeasureTextWidth(StringView text, IFont font)
		=> (font != null) ? font.MeasureString(text) : 0.0f;

	private static float HorizontalOffset(Rectangle bounds, float textWidth, TextAlignment align)
	{
		switch (align)
		{
		case .Left: return bounds.X;
		case .Center: return bounds.X + ((bounds.Width - textWidth) * 0.5f);
		case .Right: return bounds.X + bounds.Width - textWidth;
		}
	}

	/// Shifts each LINE of shaped glyphs for its alignment.
	///
	/// Lines are found by a change in the vertical position, which is what the shaper varies
	/// between them.
	private static void ApplyLineAlignment(List<GlyphPosition> positions, float maxWidth,
		TextAlignment align)
	{
		if (positions.IsEmpty)
			return;

		var lineStart = 0;
		var lineY = positions[0].Y;

		for (int i = 0; i <= positions.Count; i++)
		{
			let newLine = (i == positions.Count) || (positions[i].Y != lineY);
			if (!newLine)
				continue;

			if (lineStart < i)
			{
				let last = positions[i - 1];
				let lineWidth = last.X + last.Advance;

				var offset = 0.0f;
				if (align == .Center)
					offset = (maxWidth - lineWidth) * 0.5f;
				else if (align == .Right)
					offset = maxWidth - lineWidth;

				if (offset != 0.0f)
				{
					for (int j = lineStart; j < i; j++)
						positions[j].X += offset;
				}
			}

			if (i < positions.Count)
			{
				lineStart = i;
				lineY = positions[i].Y;
			}
		}
	}

	/// Switches to the distance field pipeline when the atlas is one, and publishes the
	/// parameters its shader needs for screen space antialiasing.
	///
	/// Without this a multi channel field renders as rainbow coloured glyphs: the shader
	/// would be sampling distances as if they were colours.
	private bool BeginDistanceFieldIfNeeded(IFontAtlas atlas)
	{
		if (atlas.Mode != .DistanceField)
			return false;

		SetDrawMode(.DistanceField);
		mBatch.DistanceFieldPixelRange = atlas.DistanceFieldRange;
		mBatch.DistanceFieldAtlasWidth = (float)atlas.Width;
		mBatch.DistanceFieldAtlasHeight = (float)atlas.Height;
		return true;
	}

	private void EndDistanceField(bool wasDistanceField)
	{
		if (wasDistanceField)
			SetDrawMode(.Default);
	}

	// === emission ===

	private void EmitGlyphQuad(GlyphQuad quad, Color color)
	{
		let baseIndex = (uint32)mBatch.Vertices.Count;

		mBatch.Vertices.Add(.(Float2(quad.X0, quad.Y0), .(quad.U0, quad.V0), color, 1.0f));
		mBatch.Vertices.Add(.(Float2(quad.X1, quad.Y0), .(quad.U1, quad.V0), color, 1.0f));
		mBatch.Vertices.Add(.(Float2(quad.X1, quad.Y1), .(quad.U1, quad.V1), color, 1.0f));
		mBatch.Vertices.Add(.(Float2(quad.X0, quad.Y1), .(quad.U0, quad.V1), color, 1.0f));

		AddQuadIndices(baseIndex);
	}

	private void EmitTexturedQuad(Rectangle destRect, Rectangle srcRect, uint32 textureWidth,
		uint32 textureHeight, Color color)
	{
		// A degenerate destination has nothing to cover, and a zero sized quad would still
		// cost four vertices and two triangles.
		if ((destRect.Width <= 0.0f) || (destRect.Height <= 0.0f))
			return;

		let baseIndex = (uint32)mBatch.Vertices.Count;

		let u0 = srcRect.X / (float)textureWidth;
		let v0 = srcRect.Y / (float)textureHeight;
		let u1 = (srcRect.X + srcRect.Width) / (float)textureWidth;
		let v1 = (srcRect.Y + srcRect.Height) / (float)textureHeight;

		let x1 = destRect.X + destRect.Width;
		let y1 = destRect.Y + destRect.Height;

		mBatch.Vertices.Add(.(Float2(destRect.X, destRect.Y), .(u0, v0), color, 1.0f));
		mBatch.Vertices.Add(.(Float2(x1, destRect.Y), .(u1, v0), color, 1.0f));
		mBatch.Vertices.Add(.(Float2(x1, y1), .(u1, v1), color, 1.0f));
		mBatch.Vertices.Add(.(Float2(destRect.X, y1), .(u0, v1), color, 1.0f));

		AddQuadIndices(baseIndex);
	}

	/// A crisp filled rectangle whose corners are ALREADY in device space: the caller has
	/// snapped them, so there is nothing to antialias and nothing to transform.
	private void EmitDeviceRect(float x0, float y0, float x1, float y1, Color color)
	{
		if ((x1 <= x0) || (y1 <= y0))
			return;

		let baseIndex = (uint32)mBatch.Vertices.Count;
		mBatch.Vertices.Add(VGVertex.Solid(.(x0, y0), color));
		mBatch.Vertices.Add(VGVertex.Solid(.(x1, y0), color));
		mBatch.Vertices.Add(VGVertex.Solid(.(x1, y1), color));
		mBatch.Vertices.Add(VGVertex.Solid(.(x0, y1), color));
		AddQuadIndices(baseIndex);
	}

	private void AddQuadIndices(uint32 baseIndex)
	{
		mBatch.Indices.Add(baseIndex);
		mBatch.Indices.Add(baseIndex + 1);
		mBatch.Indices.Add(baseIndex + 2);
		mBatch.Indices.Add(baseIndex);
		mBatch.Indices.Add(baseIndex + 2);
		mBatch.Indices.Add(baseIndex + 3);
	}

	/// The index of a texture in the batch, appending it if it is not there. Index zero is
	/// the white texture, which is also what a null resolves to.
	private int32 GetOrAddTexture(ImageData texture)
	{
		if (texture == null)
			return 0;

		for (int i = 0; i < mBatch.Textures.Count; i++)
		{
			if (mBatch.Textures[i] == texture)
				return (int32)i;
		}

		mBatch.Textures.Add(texture);
		return (int32)(mBatch.Textures.Count - 1);
	}

	// === gradients ===

	/// Bakes a gradient's ramp, binds it, and picks the draw mode. Returns what the
	/// tessellator should emit per vertex.
	private VGGradientTess BindGradientLut(IVGFill fill)
	{
		if (!fill.RequiresInterpolation)
		{
			SetDrawMode(.Default);
			SetGradientSpread(.Pad);
			SetupForSolidDraw();
			return .Gouraud;
		}

		let pixels = scope uint8[cGradientLutWidth * 4];
		for (uint32 i = 0; i < cGradientLutWidth; i++)
		{
			let t = (float)i / (float)(cGradientLutWidth - 1);
			let color = ToColor32(fill.SampleRamp(t));
			pixels[(i * 4) + 0] = color.R;
			pixels[(i * 4) + 1] = color.G;
			pixels[(i * 4) + 2] = color.B;
			pixels[(i * 4) + 3] = color.A;
		}

		// Keyed by the ramp's CONTENT, so a hundred fills of one gradient, and the same
		// gradient across frames, share one image and therefore one GPU texture.
		let rampHash = HashBytes(&pixels[0], pixels.Count);
		OwnedImageData lut;
		if (mGradientLutCache.TryGetValue(rampHash, let cached))
		{
			lut = cached;
		}
		else
		{
			lut = new OwnedImageData(cGradientLutWidth, 1, .RGBA8,
				Span<uint8>(&pixels[0], pixels.Count), .Srgb);
			mGradientLutCache[rampHash] = lut;
		}

		// A linear gradient stays on the default pipeline: its parameter is affine, so
		// interpolating it is exact. Radial and conic upgrade only when the host has said
		// its renderer has those shaders.
		var tess = VGGradientTess.LinearLut;
		var mode = VGDrawMode.Default;
		if (mPerPixelGradients)
		{
			switch (fill.GradientKind)
			{
			case .Radial:
				tess = .RadialCoord;
				mode = .GradientRadial;
			case .Conic:
				tess = .ConicCoord;
				mode = .GradientConic;
			case .Solid, .Linear:
			}
		}

		SetDrawMode(mode);
		SetGradientSpread(fill.Spread);
		SetupForTextureDraw(GetOrAddTexture(lut));
		return tess;
	}

	/// Back to the solid white passthrough, so a later plain draw is not left bound to the
	/// gradient pipeline and its ramp.
	private void RestoreDefaultSampling()
	{
		SetDrawMode(.Default);
		SetupForSolidDraw();
	}

	private void SetupForSolidDraw()
	{
		if (mCurrentTextureIndex == 0)
			return;
		FlushCurrentCommand();
		mCurrentTextureIndex = 0;
	}

	private void SetupForTextureDraw(int32 textureIndex)
	{
		if (mCurrentTextureIndex == textureIndex)
			return;
		FlushCurrentCommand();
		mCurrentTextureIndex = textureIndex;
	}

	// === stencil then cover ===

	/// Whether a fill's contours are beyond what the direct tessellator gets right.
	///
	/// Several contours mean holes or disjoint pieces, which ear clipping cannot resolve
	/// under either rule; a single NON convex contour may self intersect, which it also
	/// gets wrong.
	private static bool NeedsStencilFill(List<FlattenedSubPath> subPaths)
	{
		var contours = 0;
		FlattenedSubPath single = null;

		for (let subPath in subPaths)
		{
			if (subPath.Points.Count < 3)
				continue;
			contours++;
			single = subPath;
		}

		if (contours == 0)
			return false;
		if (contours > 1)
			return true;

		return !IsConvexSimpleLoop(single.Points);
	}

	/// Convex AND simple: every turn the same way, and the total turning exactly one
	/// revolution.
	///
	/// The revolution check is what the sign test alone misses. A pentagram's turns all go
	/// the same way but total TWO revolutions, and its core must fill under the non zero
	/// rule and not under even odd. Only the stencil gets both right.
	private static bool IsConvexSimpleLoop(List<Float2> points)
	{
		var n = points.Count;

		// An explicitly closed polyline repeats its first point, which would register as a
		// zero length edge.
		if ((n >= 2) && (points[0].X == points[n - 1].X) && (points[0].Y == points[n - 1].Y))
			n--;

		// Nothing the stencil would improve.
		if (n < 3)
			return true;

		var turnSign = 0.0f;
		var totalTurn = 0.0f;

		for (int i = 0; i < n; i++)
		{
			let a = points[i];
			let b = points[(i + 1) % n];
			let c = points[(i + 2) % n];
			let ab = Float2(b.X - a.X, b.Y - a.Y);
			let bc = Float2(c.X - b.X, c.Y - b.Y);

			let cross = (ab.X * bc.Y) - (ab.Y * bc.X);
			let dot = (ab.X * bc.X) + (ab.Y * bc.Y);

			// A collinear corner turns neither way and says nothing about convexity.
			if (Abs(cross) > 1.0e-6f)
			{
				let sign = (cross > 0.0f) ? 1.0f : -1.0f;
				if (turnSign == 0.0f)
					turnSign = sign;
				else if (sign != turnSign)
					return false;
			}

			totalTurn += Atan2(cross, dot);
		}

		return Abs(Abs(totalTurn) - TwoPi) < 0.1f;
	}

	/// Emits the colour masked winding pass: one fan per contour, in device space.
	///
	/// Returns the DEVICE space bounds of what was emitted, which the cover quad needs.
	/// Shared with the path clip, whose apply pass covers the same region.
	private Rectangle EmitWindingFans(List<FlattenedSubPath> subPaths, FillRule fillRule)
	{
		SetDrawMode(.Default);
		SetupForSolidDraw();
		FlushCurrentCommand();

		let startVertex = mBatch.Vertices.Count;
		let startIndex = (int32)mBatch.Indices.Count;

		for (let subPath in subPaths)
		{
			let n = subPath.Points.Count;
			if (n < 3)
				continue;

			let @base = (uint32)mBatch.Vertices.Count;
			for (let point in subPath.Points)
				mBatch.Vertices.Add(.(point, .(VGVertex.SolidUV, VGVertex.SolidUV), .White));

			// A fan from the contour's first point. The triangles OVERLAP wherever the
			// contour is concave, which is the entire point: the stencil counts the
			// overlaps and the winding falls out.
			for (int i = 1; (i + 1) < n; i++)
			{
				mBatch.Indices.Add(@base);
				mBatch.Indices.Add(@base + (uint32)i);
				mBatch.Indices.Add(@base + (uint32)i + 1);
			}
		}

		TransformVertices(startVertex);

		var min = Float2(FloatMax, FloatMax);
		var max = Float2(-FloatMax, -FloatMax);
		for (int i = startVertex; i < mBatch.Vertices.Count; i++)
		{
			let point = mBatch.Vertices[i].Position;
			min.X = Min(min.X, point.X);
			min.Y = Min(min.Y, point.Y);
			max.X = Max(max.X, point.X);
			max.Y = Max(max.Y, point.Y);
		}

		PushExplicitCommand(startIndex, .StencilWrite, fillRule);

		if ((max.X <= min.X) || (max.Y <= min.Y))
			return .();
		return .(min.X, min.Y, max.X - min.X, max.Y - min.Y);
	}

	/// A colour masked quad already in DEVICE space, for the clip apply and clear phases.
	private void EmitDeviceQuad(Rectangle rect, VGFillPhase phase)
	{
		SetDrawMode(.Default);
		SetupForSolidDraw();
		FlushCurrentCommand();

		let startIndex = (int32)mBatch.Indices.Count;
		let @base = (uint32)mBatch.Vertices.Count;
		let uv = Float2(VGVertex.SolidUV, VGVertex.SolidUV);

		mBatch.Vertices.Add(.(Float2(rect.X, rect.Y), uv, .White));
		mBatch.Vertices.Add(.(Float2(rect.X + rect.Width, rect.Y), uv, .White));
		mBatch.Vertices.Add(.(Float2(rect.X + rect.Width, rect.Y + rect.Height), uv, .White));
		mBatch.Vertices.Add(.(Float2(rect.X, rect.Y + rect.Height), uv, .White));

		AddQuadIndices(@base);
		PushExplicitCommand(startIndex, phase, .NonZero);
	}

	/// The two pass fill: accumulate the winding, then cover the bounds with the shading.
	private void EmitStencilFill(List<FlattenedSubPath> subPaths, FillRule fillRule,
		Color solidColor, IVGFill fill)
	{
		var min = Float2(FloatMax, FloatMax);
		var max = Float2(-FloatMax, -FloatMax);
		var totalPoints = 0;

		for (let subPath in subPaths)
		{
			for (let point in subPath.Points)
			{
				min.X = Min(min.X, point.X);
				min.Y = Min(min.Y, point.Y);
				max.X = Max(max.X, point.X);
				max.Y = Max(max.Y, point.Y);
			}
			totalPoints += subPath.Points.Count;
		}

		if ((totalPoints < 3) || (max.X <= min.X) || (max.Y <= min.Y))
			return;

		// LOCAL space bounds: the cover quad is built here and transformed on the way out,
		// like any other geometry.
		let bounds = Rectangle(min.X, min.Y, max.X - min.X, max.Y - min.Y);

		EmitWindingFans(subPaths, fillRule);

		var gradientTess = VGGradientTess.Gouraud;
		if (fill != null)
			gradientTess = BindGradientLut(fill);

		let coverStartVertex = mBatch.Vertices.Count;
		let coverStartIndex = (int32)mBatch.Indices.Count;
		let coverBase = (uint32)mBatch.Vertices.Count;

		let corners = scope Float2[4](
			.(bounds.X, bounds.Y),
			.(bounds.X + bounds.Width, bounds.Y),
			.(bounds.X + bounds.Width, bounds.Y + bounds.Height),
			.(bounds.X, bounds.Y + bounds.Height));

		for (let corner in corners)
		{
			var uv = Float2(VGVertex.SolidUV, VGVertex.SolidUV);
			var color = solidColor;

			if (fill != null)
			{
				if (gradientTess == .Gouraud)
				{
					// No gradient shader to hand it to, so the corners carry the colour and
					// the hardware interpolates between them.
					color = fill.GetColorAt(corner, bounds);
				}
				else
				{
					uv = FillTessellator.GradientTexCoord(gradientTess, fill, corner, bounds);
					color = .White;
				}
			}

			mBatch.Vertices.Add(.(corner, uv, color));
		}

		AddQuadIndices(coverBase);

		// A solid colour already had opacity applied by the caller; a fill's colours were
		// sampled raw, so they take it here.
		if (fill != null)
			ApplyOpacityToVertices(coverStartVertex);

		TransformVertices(coverStartVertex);
		PushExplicitCommand(coverStartIndex, .StencilCover, fillRule);

		if (gradientTess != .Gouraud)
			RestoreDefaultSampling();
	}

	// === commands ===

	/// Closes a command with an explicit fill phase.
	///
	/// The stencil passes use this rather than the ordinary flush because neither can ever
	/// merge with a neighbour: each is a distinct stencil operation.
	private void PushExplicitCommand(int32 startIndex, VGFillPhase phase, FillRule fillRule)
	{
		let indexCount = (int32)mBatch.Indices.Count - startIndex;
		if (indexCount <= 0)
			return;

		var command = CurrentCommand(startIndex, indexCount);
		command.FillPhase = phase;
		command.FillRule = fillRule;
		mBatch.Commands.Add(command);
		mCommandStartIndex = (int32)mBatch.Indices.Count;
	}

	/// Closes the command in progress, if it has any geometry.
	///
	/// Called before every state change, so a command covers exactly the run of indices
	/// drawn under one state.
	private void FlushCurrentCommand()
	{
		let indexCount = (int32)mBatch.Indices.Count - mCommandStartIndex;
		if (indexCount <= 0)
			return;

		mBatch.Commands.Add(CurrentCommand(mCommandStartIndex, indexCount));
		mCommandStartIndex = (int32)mBatch.Indices.Count;
	}

	private VGCommand CurrentCommand(int32 startIndex, int32 indexCount)
	{
		var command = VGCommand();
		command.StartIndex = startIndex;
		command.IndexCount = indexCount;
		command.TextureIndex = mCurrentTextureIndex;
		command.ClipRect = mCurrentState.ClipRect;
		command.ClipMode = mCurrentState.ClipMode;
		command.BlendMode = mCurrentBlendMode;
		command.StencilRef = mCurrentState.StencilRef;
		command.DrawMode = mCurrentDrawMode;
		command.GradientSpread = mCurrentGradientSpread;
		return command;
	}

	// === transform helpers ===

	private static bool HasClip(Rectangle rect) => (rect.Width > 0.0f) && (rect.Height > 0.0f);

	/// The largest scale the current transform applies, which both the tolerance and the
	/// fringe divide by.
	private float TransformScale()
	{
		let m = mCurrentState.Transform;
		let sx = Length(Float2(m[0, 0], m[0, 1]));
		let sy = Length(Float2(m[1, 0], m[1, 1]));
		return Max(sx, sy);
	}

	/// The tolerance adjusted for the transform: a shape scaled up needs a TIGHTER tolerance
	/// in local space to look as smooth on screen.
	private float GetScaledTolerance()
	{
		if (mCurrentState.Transform == Float4x4.Identity())
			return mTolerance;

		let scale = TransformScale();
		return (scale > 0.0001f) ? (mTolerance / scale) : mTolerance;
	}

	/// The fringe width, kept roughly constant in SCREEN pixels.
	///
	/// The fringe is built in local space and then scaled by the transform, so it is
	/// pre divided here. Without that a scaled up shape gets a proportionally wider and
	/// blurrier edge.
	private float GetScaledFringe()
	{
		if (mCurrentState.Transform == Float4x4.Identity())
			return cBaseFringe;

		let scale = TransformScale();
		return (scale > 0.0001f) ? (cBaseFringe / scale) : cBaseFringe;
	}

	/// Whether the transform has no rotation or skew, so device axis aligned geometry maps
	/// to axis aligned pixels and snapping is safe.
	private bool TransformIsAxisAligned()
	{
		let m = mCurrentState.Transform;
		return (Abs(m[0, 1]) < 1.0e-4f) && (Abs(m[1, 0]) < 1.0e-4f);
	}

	/// The per axis device scale, valid only when the transform is axis aligned.
	private Float2 DeviceScale()
	{
		let m = mCurrentState.Transform;
		return .(Abs(m[0, 0]), Abs(m[1, 1]));
	}

	private Float2 TransformPoint(Float2 point)
	{
		if (mCurrentState.Transform == Float4x4.Identity())
			return point;
		return TransformPoint2D(point, mCurrentState.Transform);
	}

	private void TransformVertices(int startVertex)
	{
		if (mCurrentState.Transform == Float4x4.Identity())
			return;

		for (int i = startVertex; i < mBatch.Vertices.Count; i++)
			mBatch.Vertices[i].Position = TransformPoint2D(mBatch.Vertices[i].Position,
				mCurrentState.Transform);
	}

	private Rectangle TransformRect(Rectangle rect)
	{
		if (mCurrentState.Transform == Float4x4.Identity())
			return rect;

		let topLeft = TransformPoint(.(rect.X, rect.Y));
		let bottomRight = TransformPoint(.(rect.X + rect.Width, rect.Y + rect.Height));
		return .(topLeft.X, topLeft.Y, bottomRight.X - topLeft.X, bottomRight.Y - topLeft.Y);
	}

	/// Folds the state's opacity into a colour's alpha.
	private Color ApplyOpacity(Color color)
	{
		if (mCurrentState.Opacity >= 1.0f)
			return color;
		return .(color.R, color.G, color.B, color.A * mCurrentState.Opacity);
	}

	private void ApplyOpacityToVertices(int startVertex)
	{
		if (mCurrentState.Opacity >= 1.0f)
			return;

		for (int i = startVertex; i < mBatch.Vertices.Count; i++)
			mBatch.Vertices[i].Color = ApplyOpacity(mBatch.Vertices[i].Color);
	}
}
