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

	/// Shaped single-line text, kept across frames: drawing a label shapes it once, not every
	/// frame it redraws. An entry is good while the CachedFont, its font and its atlas are the
	/// ones it was shaped for; the cache is dropped whole when it grows past cShapedTextLimit.
	class ShapedTextEntry
	{
		public String Text = new .() ~ delete _;
		/// Identities, compared and never dereferenced.
		public CachedFont Cached;
		public IFont Font;
		public IFontAtlas Atlas;
		public List<GlyphPosition> Glyphs = new .() ~ delete _;
		public float Width;
	}
	private const int cShapedTextLimit = 4096;
	private Dictionary<uint64, ShapedTextEntry> mShapedText = new .() ~ DeleteDictionaryAndValues!(_);
	/// Texts shaped rather than found shaped already, for tests.
	private uint64 mShapeCount = 0;

	private List<VGState> mStateStack = new .() ~ delete _;
	private List<ClipRectSave> mClipStack = new .() ~ delete _;
	/// The stencil clips, outermost first.
	private List<ClipPathLevel> mClipPaths = new .() ~ DeleteContainerAndItems!(_);
	/// The scissor fallback's saves, when there is no stencil.
	private List<ClipRectSave> mClipPathScissors = new .() ~ delete _;
	private List<float> mOpacityStack = new .() ~ delete _;
	/// What each open layer set aside; a save with no layer is an opacity push (layers off).
	private List<LayerSave> mLayerStack = new .() ~ DeleteContainerAndItems!(_);
	/// The layer draws go into, -1 for the target.
	private int32 mCurrentLayer = -1;
	private VGState mCurrentState = .();

	private VGBlendMode mCurrentBlendMode = .Normal;
	private VGDrawMode mCurrentDrawMode = .Default;
	private VGGradientSpread mCurrentGradientSpread = .Pad;
	private int32 mCurrentTextureIndex = 0;
	private int32 mCommandStartIndex = 0;

	private bool mPerPixelGradients = false;
	private bool mAnalyticBoxes = false;
	private bool mLayersEnabled = false;
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
		ClearAndDeleteItems!(mClipPaths);
		mClipPathScissors.Clear();
		mOpacityStack.Clear();
		ClearAndDeleteItems!(mLayerStack);
		mCurrentLayer = -1;
		mCurrentState = .();
		mCurrentBlendMode = .Normal;
		mCurrentDrawMode = .Default;
		mCurrentGradientSpread = .Pad;
		mCurrentTextureIndex = 0;
		mCommandStartIndex = 0;

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

	/// DrawBox draws analytically: one quad, its fill and border from a signed distance in the
	/// box shader.
	///
	/// The HOST opts in, once it gave the renderer the box shaders: without them a Box command
	/// has no pipeline. Off, DrawBox tessellates its fill and border as FillRoundedRect does.
	public void SetAnalyticBoxes(bool enabled) => mAnalyticBoxes = enabled;
	public bool AnalyticBoxes => mAnalyticBoxes;

	/// PushLayer draws into offscreen layers.
	///
	/// The HOST opts in, once its renderer was given the layer composite shader and it calls
	/// VGRenderer.RenderLayers before its pass. Off, a layer is an opacity push: each shape fades
	/// on its own and overlaps show through.
	public void SetLayers(bool enabled) => mLayersEnabled = enabled;
	public bool Layers => mLayersEnabled;

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

	/// Inside a path clip, both apply: the draw is scissored and stencil tested.
	public void PushClipRect(Rectangle rect)
	{
		FlushCurrentCommand();
		mClipStack.Add(.(mCurrentState.ClipRect, mCurrentState.Scissored));

		let transformed = TransformRect(rect);
		// INTERSECTED with whatever is already active, so a nested clip can only ever
		// shrink the visible region.
		mCurrentState.ClipRect = mCurrentState.Scissored
			? Rectangle.Intersect(mCurrentState.ClipRect, transformed) : transformed;
		mCurrentState.Scissored = true;
		RefreshClipMode();
	}

	public void PopClip()
	{
		FlushCurrentCommand();

		if (mClipStack.IsEmpty)
		{
			mCurrentState.ClipRect = .();
			mCurrentState.Scissored = false;
		}
		else
		{
			let saved = mClipStack.PopBack();
			mCurrentState.ClipRect = saved.Rect;
			mCurrentState.Scissored = saved.Scissored;
		}
		RefreshClipMode();
	}

	/// Whether a rectangle in CURRENT local coordinates could contribute any pixels.
	///
	/// A caller uses this to skip tessellating geometry the scissor would discard anyway: a
	/// scrolled list draws its viewport rather than its whole contents, which is the
	/// difference between a frame and a frame that exceeds the renderer's vertex ceiling.
	public bool IsRectVisible(Rectangle rect)
	{
		if (!mCurrentState.Scissored)
			return true;
		if (!HasClip(mCurrentState.ClipRect))
			return false;
		return TransformRect(rect).Intersects(mCurrentState.ClipRect);
	}

	// === path clipping ===

	/// Clips subsequent draws to a path, by the non zero rule, within any path clip already
	/// active.
	///
	/// Clips NEST, each the intersection of its path and the clips around it, so a rounded card
	/// can hold a list of rounded items; a rectangle clip (PushClipRect) inside or around one
	/// still applies. Requires stencil fills. WITHOUT them it degrades to a scissor of the path's
	/// transformed bounds, which is coarse but contained: too much is drawn rather than the
	/// wrong thing. Balance with PopClipPath before Clear or the frame's end.
	public void PushClipPath(Path path)
	{
		let level = new ClipPathLevel();
		PathFlattener.Flatten(path, GetScaledTolerance(), level.SubPaths);

		if (!mStencilFills)
		{
			PushClipPathAsScissor(level.SubPaths);
			delete level;
			return;
		}

		FlushCurrentCommand();
		level.Transform = mCurrentState.Transform;
		let outer = mClipPaths.IsEmpty ? Rectangle() : mClipPaths.Back.Bounds;
		level.Bounds = EmitClipLevel(level, !mClipPaths.IsEmpty, outer);
		mClipPaths.Add(level);
		RefreshClipMode();
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

		FlushCurrentCommand();
		// Saved, so the pop restores the clip around this one rather than dropping it.
		mClipPathScissors.Add(.(mCurrentState.ClipRect, mCurrentState.Scissored));
		// An empty path clips everything away.
		let deviceRect = ((max.X > min.X) && (max.Y > min.Y))
			? Rectangle(min.X, min.Y, max.X - min.X, max.Y - min.Y) : Rectangle();
		mCurrentState.ClipRect = mCurrentState.Scissored
			? Rectangle.Intersect(mCurrentState.ClipRect, deviceRect) : deviceRect;
		mCurrentState.Scissored = true;
		RefreshClipMode();
	}

	/// Ends the innermost path clip: the clip around it applies again.
	public void PopClipPath()
	{
		FlushCurrentCommand();
		if (!mClipPathScissors.IsEmpty && mClipPaths.IsEmpty)
		{
			let saved = mClipPathScissors.PopBack();
			mCurrentState.ClipRect = saved.Rect;
			mCurrentState.Scissored = saved.Scissored;
			RefreshClipMode();
			return;
		}
		if (mClipPaths.IsEmpty)
		{
			RefreshClipMode();
			return;
		}

		// Every mask bit lies inside the outermost clip's bounds: clear them, then rebuild the
		// clips that remain from the outermost in. Nesting is shallow, so the replay is cheap.
		let outermost = mClipPaths[0].Bounds;
		delete mClipPaths.PopBack();
		ClearClipMask(outermost);
		for (int i < mClipPaths.Count)
		{
			mClipPaths[i].Bounds = EmitClipLevel(mClipPaths[i], i > 0,
				(i > 0) ? mClipPaths[i - 1].Bounds : Rectangle());
		}
		RefreshClipMode();
	}

	/// The clip mode the state's clips call for: the stencil while path clips are active (with
	/// the scissor too when a rectangle clip is), the scissor alone, or none.
	private void RefreshClipMode()
	{
		mCurrentState.ClipMode = !mClipPaths.IsEmpty ? .Stencil
			: (mCurrentState.Scissored ? .Scissor : .None);
	}

	/// Writes one path clip into the stencil mask and returns its device bounds.
	///
	/// The outermost: its winding over the clear mask, then ClipApply over its bounds. A nested
	/// one: its winding only where the mask is already set (a clipped write), then ClipApply over
	/// the OUTER clip's bounds, which keeps the mask where the new winding is and zeroes it
	/// elsewhere: the intersection, with the pipelines fills already use.
	private Rectangle EmitClipLevel(ClipPathLevel level, bool nested, Rectangle outer)
	{
		let saved = mCurrentState;
		mCurrentState.Transform = level.Transform;
		// The clip's own geometry is never scissored.
		mCurrentState.Scissored = false;
		mCurrentState.ClipMode = nested ? .Stencil : .None;
		let bounds = EmitWindingFans(level.SubPaths, .NonZero);
		mCurrentState.ClipMode = .None;
		let apply = nested ? outer : bounds;
		if (HasClip(apply))
			EmitDeviceQuad(apply, .ClipApply);
		mCurrentState.Transform = saved.Transform;
		mCurrentState.ClipRect = saved.ClipRect;
		mCurrentState.Scissored = saved.Scissored;
		mCurrentState.ClipMode = saved.ClipMode;
		return nested ? Rectangle.Intersect(bounds, outer) : bounds;
	}

	/// Zeroes the clip mask, and any stray winding, over a device rectangle.
	private void ClearClipMask(Rectangle rect)
	{
		if (!HasClip(rect))
			return;
		let savedScissored = mCurrentState.Scissored;
		let savedMode = mCurrentState.ClipMode;
		mCurrentState.Scissored = false;
		mCurrentState.ClipMode = .None;
		EmitDeviceQuad(rect, .ClipClear);
		mCurrentState.Scissored = savedScissored;
		mCurrentState.ClipMode = savedMode;
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

	// === text effects ===

	/// Effects drawn under the text drawn from here (an outline, a shadow, a glow), until
	/// changed, cleared or a PopState; part of the state PushState saves.
	public void SetTextEffects(TextEffects effects) => mCurrentState.TextEffects = effects;
	public void ClearTextEffects() => mCurrentState.TextEffects = .();
	public TextEffects TextEffects => mCurrentState.TextEffects;
	/// Text draws only its effects, not its glyphs: a paragraph of runs draws every run's effects
	/// first and its glyphs after, so no run's outline or shadow covers a neighbour.
	public void SetTextEffectsOnly(bool only) => mCurrentState.TextEffectsOnly = only;
	public bool TextEffectsOnly => mCurrentState.TextEffectsOnly;

	// === layers ===

	/// Layers a batch holds before PushLayer falls back to an opacity push: each costs the
	/// renderer a pass and a uniform slot, of which it has 256 a frame, one per slice besides.
	public const int32 MaxLayers = 128;
	/// The widest layer blur, a sigma in device pixels: a pass costs six sigmas of taps a pixel.
	public const float MaxLayerBlur = 32.0f;

	/// Draws what follows into an offscreen layer, composited into what is under it once, at
	/// PopLayer, with `opacity` and `blendMode`: a group fades as one, its overlapping parts never
	/// showing through each other.
	///
	/// Inside, opacity starts again at one and no clip applies; the clips around the layer apply
	/// to its composite. The transform carries on. `blur` blurs the layer before its composite, a
	/// Gaussian of that sigma in device pixels, up to MaxLayerBlur. Without SetLayers, or past
	/// MaxLayers in a batch, an opacity push instead, and no blur.
	public void PushLayer(float opacity, VGBlendMode blendMode = .Normal, float blur = 0.0f)
	{
		if (!mLayersEnabled || (mBatch.Layers.Count >= MaxLayers))
		{
			PushOpacity(opacity);
			// Layer -1: PopLayer pops the opacity.
			mLayerStack.Add(new LayerSave());
			return;
		}

		FlushCurrentCommand();
		let save = new LayerSave();
		save.State = mCurrentState;
		Swap!(save.ClipPaths, mClipPaths);
		Swap!(save.ClipStack, mClipStack);
		Swap!(save.ClipPathScissors, mClipPathScissors);
		Swap!(save.OpacityStack, mOpacityStack);
		save.FirstCommand = (int32)mBatch.Commands.Count;
		mCurrentState.ClipRect = .();
		mCurrentState.Scissored = false;
		mCurrentState.ClipMode = .None;
		mCurrentState.Opacity = 1.0f;

		var layer = VGLayer();
		layer.Parent = mCurrentLayer;
		layer.Opacity = Clamp(opacity, 0.0f, 1.0f);
		layer.BlendMode = blendMode;
		layer.Blur = Clamp(blur, 0.0f, MaxLayerBlur);
		save.Layer = (int32)mBatch.Layers.Count;
		mBatch.Layers.Add(layer);
		mCurrentLayer = save.Layer;
		mLayerStack.Add(save);
	}

	/// Ends the innermost layer: its content's bounds are taken, the state around it comes back,
	/// and its composite is drawn there.
	public void PopLayer()
	{
		if (mLayerStack.IsEmpty)
			return;
		if (mLayerStack.Back.Layer < 0)
		{
			delete mLayerStack.PopBack();
			PopOpacity();
			return;
		}

		FlushCurrentCommand();
		let save = mLayerStack.PopBack();
		defer delete save;
		let index = save.Layer;
		let content = LayerContentBounds(index, save.FirstCommand);
		// A blur spreads three sigmas past what was drawn, and needs that margin transparent.
		let spread = Ceil(3.0f * mBatch.Layers[index].Blur);
		let bounds = HasClip(content)
			? Rectangle(content.X - spread, content.Y - spread, content.Width + 2.0f * spread,
				content.Height + 2.0f * spread)
			: content;
		mBatch.Layers[index].Bounds = bounds;
		mCurrentState = save.State;
		// The layer's own (balanced, so empty) stacks go with the save.
		Swap!(save.ClipPaths, mClipPaths);
		Swap!(save.ClipStack, mClipStack);
		Swap!(save.ClipPathScissors, mClipPathScissors);
		Swap!(save.OpacityStack, mOpacityStack);
		mCurrentLayer = mBatch.Layers[index].Parent;
		if (!HasClip(bounds))
			return; // nothing drawn: nothing to composite

		let layer = mBatch.Layers[index];
		EmitComposite(index, layer.Opacity * mCurrentState.Opacity, layer.BlendMode, true);
	}

	/// Blurs what is already drawn behind `rect` (rounded by `radii`) by a Gaussian of `sigma`
	/// device pixels, as CSS's backdrop-filter does; a panel's own translucent background then goes
	/// over it.
	///
	/// The backdrop is what this canvas drew before, in the target the call is in (a layer's, or
	/// the canvas's), not what lies under the canvas. Everything drawn there so far moves into a
	/// layer of its own, composited as before, whose blurred copy the shape shows. Without layers,
	/// past MaxLayers, or inside a clip path (whose stencil mask could not follow the move),
	/// nothing is drawn.
	public void DrawBackdropBlur(Rectangle rect, CornerRadii radii, float sigma)
	{
		if (!mLayersEnabled || (mBatch.Layers.Count >= MaxLayers) || !mClipPaths.IsEmpty || (sigma <= 0.0f)
			|| (rect.Width <= 0.0f) || (rect.Height <= 0.0f))
			return;

		FlushCurrentCommand();
		let first = mLayerStack.IsEmpty ? 0 : mLayerStack.Back.FirstCommand;
		let index = (int32)mBatch.Layers.Count;
		// The target's commands so far, and the layers composited into it, move into the new layer.
		for (int c = first; c < mBatch.Commands.Count; c++)
		{
			if (mBatch.Commands[c].Layer == mCurrentLayer)
				mBatch.Commands[c].Layer = index;
		}
		for (int l < mBatch.Layers.Count)
		{
			if ((mBatch.Layers[l].Parent == mCurrentLayer) && !IsOpenLayer((int32)l))
				mBatch.Layers[l].Parent = index;
		}
		var behind = VGLayer();
		behind.Parent = mCurrentLayer;
		behind.BackdropBlur = Clamp(sigma, 0.0f, MaxLayerBlur);
		mBatch.Layers.Add(behind);
		let bounds = LayerContentBounds(index, (int32)first);
		mBatch.Layers[index].Bounds = bounds;
		if (!HasClip(bounds))
			return; // nothing behind it: nothing to blur, and the empty layer is never drawn

		// As drawn: its opacities and clips are its own.
		EmitComposite(index, 1.0f, .Normal, false);
		// The shape, tessellated, sampling the blurred copy.
		let builder = scope PathBuilder();
		ShapeBuilder.BuildRoundedRect(rect, radii, builder);
		let shape = builder.ToPath();
		defer delete shape;
		let firstShape = mBatch.Commands.Count;
		FillPath(shape, .(1.0f, 1.0f, 1.0f, 1.0f), .NonZero, true);
		FlushCurrentCommand();
		for (int c = firstShape; c < mBatch.Commands.Count; c++)
		{
			mBatch.Commands[c].DrawMode = .Layer;
			mBatch.Commands[c].CompositeLayer = index;
			mBatch.Commands[c].Backdrop = true;
		}
	}

	/// Whether a layer is still being drawn, on the stack.
	private bool IsOpenLayer(int32 index)
	{
		for (let save in mLayerStack)
		{
			if (save.Layer == index)
				return true;
		}
		return false;
	}

	/// A layer's composite in the current target: a device quad over its bounds, `alpha` its
	/// opacity, sampling its target (the renderer maps positions to texels). `clipped`: the current
	/// clips apply, as a pushed layer's do; else none, since drawing moved aside keeps its own.
	private void EmitComposite(int32 index, float alpha, VGBlendMode blendMode, bool clipped)
	{
		let bounds = mBatch.Layers[index].Bounds;
		let tint = Color(1.0f, 1.0f, 1.0f, alpha);
		let start = (int32)mBatch.Indices.Count;
		let vertexBase = (uint32)mBatch.Vertices.Count;
		let x0 = bounds.X;
		let y0 = bounds.Y;
		let x1 = bounds.X + bounds.Width;
		let y1 = bounds.Y + bounds.Height;
		mBatch.Vertices.Add(.(.(x0, y0), .(0.0f, 0.0f), tint));
		mBatch.Vertices.Add(.(.(x1, y0), .(1.0f, 0.0f), tint));
		mBatch.Vertices.Add(.(.(x1, y1), .(1.0f, 1.0f), tint));
		mBatch.Vertices.Add(.(.(x0, y1), .(0.0f, 1.0f), tint));
		for (let i in scope uint32[](0, 1, 2, 0, 2, 3))
			mBatch.Indices.Add(vertexBase + i);

		var command = CurrentCommand(start, 6);
		if (!clipped)
		{
			command.ClipRect = .();
			command.ClipMode = .None;
			command.Scissored = false;
			command.StencilRef = 0;
		}
		command.BlendMode = blendMode;
		command.DrawMode = .Layer;
		command.GradientSpread = .Pad;
		command.CompositeLayer = index;
		mBatch.Commands.Add(command);
		mCommandStartIndex = (int32)mBatch.Indices.Count;
	}

	/// The device bounds of what a layer drew (its commands from `firstCommand` on that draw into
	/// it, a nested layer's composite among them), on whole pixels with a pixel of margin for the
	/// edges' antialiasing; empty when it drew nothing.
	private Rectangle LayerContentBounds(int32 layer, int32 firstCommand)
	{
		var min = Float2(FloatMax, FloatMax);
		var max = Float2(-FloatMax, -FloatMax);
		for (int c = firstCommand; c < mBatch.Commands.Count; c++)
		{
			let command = mBatch.Commands[c];
			// Only what draws colour counts: winding fans and masks do not.
			if ((command.Layer != layer) || (command.FillPhase == .StencilWrite)
				|| (command.FillPhase == .ClipApply) || (command.FillPhase == .ClipClear))
				continue;
			for (int i < command.IndexCount)
			{
				let at = command.StartIndex + i;
				let p = (command.DrawMode == .Box) ? mBatch.BoxVertices[at].Position
					: mBatch.Vertices[(int)mBatch.Indices[at]].Position;
				min = .(Min(min.X, p.X), Min(min.Y, p.Y));
				max = .(Max(max.X, p.X), Max(max.Y, p.Y));
			}
		}
		if ((max.X < min.X) || (max.Y < min.Y))
			return .();
		let x0 = Floor(min.X) - 1.0f;
		let y0 = Floor(min.Y) - 1.0f;
		let x1 = Ceil(max.X) + 1.0f;
		let y1 = Ceil(max.Y) + 1.0f;
		return .(x0, y0, x1 - x0, y1 - y0);
	}

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
		if (mAnalyticBoxes)
		{
			// Exact corners, no fringe.
			DrawBox(rect, radii, color);
			return;
		}

		let builder = scope PathBuilder();
		ShapeBuilder.BuildRoundedRect(rect, radii, builder);
		let path = builder.ToPath();
		defer delete path;
		FillPath(path, color);
	}

	/// A box: `rect` filled with `fill` and rounded by `radii`, with a border of `borders` widths
	/// (per side) in `borderColor` drawn over the fill inside its edge.
	///
	/// Analytic when the host enabled it (SetAnalyticBoxes): one quad whose fill and border come
	/// from one signed distance, so they cannot disagree, a thin border has no halo and small
	/// radii are exact; where neighbouring borders differ, the inner corner is a quarter ellipse.
	/// An axis aligned box snaps to device pixels as FillRect does.
	public void DrawBox(Rectangle rect, CornerRadii radii, Color fill, BorderWidths borders = .(),
		Color borderColor = .(0, 0, 0, 0))
	{
		DrawBox(rect, radii, fill, borders, BorderColors(borderColor));
	}

	/// DrawBox with a colour per side (CSS's border-top-color and the rest): where two sides meet,
	/// the corner splits along the line from its outer corner to its inner one.
	public void DrawBox(Rectangle rect, CornerRadii radii, Color fill, BorderWidths borders, BorderColors borderColors)
	{
		if ((rect.Width <= 0.0f) || (rect.Height <= 0.0f))
			return;
		if (!mAnalyticBoxes)
		{
			TessellateBox(rect, radii, fill, borders, borderColors);
			return;
		}

		// Radii no larger than the box allows, as BuildRoundedRect clamps them.
		let maxRadius = Min(rect.Width, rect.Height) * 0.5f;
		let clamped = CornerRadii(Min(radii.TopLeft, maxRadius), Min(radii.TopRight, maxRadius),
			Min(radii.BottomRight, maxRadius), Min(radii.BottomLeft, maxRadius));

		var boxVertex = VGBoxVertex();
		boxVertex.Fill = ApplyOpacity(fill);
		boxVertex.BorderTop = ApplyOpacity(borderColors.Top);
		boxVertex.BorderRight = ApplyOpacity(borderColors.Right);
		boxVertex.BorderBottom = ApplyOpacity(borderColors.Bottom);
		boxVertex.BorderLeft = ApplyOpacity(borderColors.Left);
		Float2[4] corner = default;
		Float2[4] local = default;
		if (mPixelSnap && TransformIsAxisAligned())
		{
			// Device units, the edges on whole pixels.
			let p0 = TransformPoint(.(rect.X, rect.Y));
			let p1 = TransformPoint(.(rect.X + rect.Width, rect.Y + rect.Height));
			let x0 = Round(Min(p0.X, p1.X));
			let y0 = Round(Min(p0.Y, p1.Y));
			let x1 = Round(Max(p0.X, p1.X));
			let y1 = Round(Max(p0.Y, p1.Y));
			if ((x1 <= x0) || (y1 <= y0))
				return;
			let scale = DeviceScale();
			let r = (scale.X + scale.Y) * 0.5f;
			boxVertex.HalfSize = .((x1 - x0) * 0.5f, (y1 - y0) * 0.5f);
			boxVertex.Radii = .(clamped.TopLeft * r, clamped.TopRight * r, clamped.BottomRight * r, clamped.BottomLeft * r);
			// Each border a whole number of device pixels, never thinner than one: a 2 px border
			// on a canvas scaled to 0.48 is one crisp pixel, not a 0.96 px blur.
			float SnapWidth(float w, float s) => (w > 0.0f) ? Max(1.0f, Round(w * s)) : 0.0f;
			boxVertex.Borders = .(SnapWidth(borders.Top, scale.Y), SnapWidth(borders.Right, scale.X),
				SnapWidth(borders.Bottom, scale.Y), SnapWidth(borders.Left, scale.X));
			let center = Float2((x0 + x1) * 0.5f, (y0 + y1) * 0.5f);
			// One device pixel for the antialiasing ramp.
			let h = Float2(boxVertex.HalfSize.X + 1.0f, boxVertex.HalfSize.Y + 1.0f);
			local = .(.(-h.X, -h.Y), .(h.X, -h.Y), .(h.X, h.Y), .(-h.X, h.Y));
			for (int i < 4)
				corner[i] = .(center.X + local[i].X, center.Y + local[i].Y);
			EmitBox(boxVertex, corner, local);
			return;
		}

		// Box units under the transform: grown by one device pixel's worth for the ramp.
		let m = mCurrentState.Transform;
		let sx = Length(Float2(m[0, 0], m[0, 1]));
		let sy = Length(Float2(m[1, 0], m[1, 1]));
		let margin = 1.0f / Max(Min(sx, sy), 1.0e-4f);
		boxVertex.HalfSize = .(rect.Width * 0.5f, rect.Height * 0.5f);
		boxVertex.Radii = .(clamped.TopLeft, clamped.TopRight, clamped.BottomRight, clamped.BottomLeft);
		boxVertex.Borders = .(borders.Top, borders.Right, borders.Bottom, borders.Left);
		let center = Float2(rect.X + boxVertex.HalfSize.X, rect.Y + boxVertex.HalfSize.Y);
		let h = Float2(boxVertex.HalfSize.X + margin, boxVertex.HalfSize.Y + margin);
		local = .(.(-h.X, -h.Y), .(h.X, -h.Y), .(h.X, h.Y), .(-h.X, h.Y));
		for (int i < 4)
			corner[i] = TransformPoint(.(center.X + local[i].X, center.Y + local[i].Y));
		EmitBox(boxVertex, corner, local);
	}

	/// One analytic box: two triangles over its quad, appended to the batch's box vertices and
	/// to the open Box command when it shares the state, so boxes batch with boxes.
	private void EmitBox(VGBoxVertex boxVertex, Float2[4] corner, Float2[4] local)
	{
		// Any indexed geometry closes first: draw order is kept.
		FlushCurrentCommand();
		var boxVertex;
		let start = (int32)mBatch.BoxVertices.Count;
		int[6] order = .(0, 1, 2, 0, 2, 3);
		for (let i in order)
		{
			boxVertex.Position = corner[i];
			boxVertex.Local = local[i];
			mBatch.BoxVertices.Add(boxVertex);
		}

		var command = CurrentCommand(start, 6);
		command.DrawMode = .Box;
		if (!mBatch.Commands.IsEmpty)
		{
			var last = ref mBatch.Commands.Back;
			if ((last.DrawMode == .Box) && (last.StartIndex + last.IndexCount == start)
				&& (last.BlendMode == command.BlendMode) && (last.ClipMode == command.ClipMode)
				&& (last.Scissored == command.Scissored) && SameRect(last.ClipRect, command.ClipRect)
				&& (last.StencilRef == command.StencilRef) && (last.Layer == command.Layer))
			{
				last.IndexCount += 6;
				return;
			}
		}
		mBatch.Commands.Add(command);
	}

	/// DrawBox without the box shader: the fill as FillRoundedRect, and the border as the ring
	/// between the box and its inset (even odd), each inner corner rounded by what is left of its
	/// radius past the wider neighbouring border.
	private void TessellateBox(Rectangle rect, CornerRadii radii, Color fill, BorderWidths borders,
		BorderColors colors)
	{
		if (fill.A > 0.0f)
			FillRoundedRect(rect, radii, fill);
		if (borders.IsZero || colors.IsTransparent)
			return;

		let inner = Rectangle(rect.X + borders.Left, rect.Y + borders.Top,
			rect.Width - borders.Left - borders.Right, rect.Height - borders.Top - borders.Bottom);
		let ring = scope PathBuilder();
		ShapeBuilder.BuildRoundedRect(rect, radii, ring);
		if ((inner.Width > 0.0f) && (inner.Height > 0.0f))
		{
			let innerRadii = CornerRadii(Max(0.0f, radii.TopLeft - Max(borders.Top, borders.Left)),
				Max(0.0f, radii.TopRight - Max(borders.Top, borders.Right)),
				Max(0.0f, radii.BottomRight - Max(borders.Bottom, borders.Right)),
				Max(0.0f, radii.BottomLeft - Max(borders.Bottom, borders.Left)));
			ShapeBuilder.BuildRoundedRect(inner, innerRadii, ring);
		}
		let path = ring.ToPath();
		defer delete path;
		if (colors.IsUniform)
		{
			FillPath(path, colors.Top, .EvenOdd);
			return;
		}

		// A colour per side: the ring clipped to each side's wedge, the region between the box's
		// edge and the inner box's on that side, its corners split along the line from the outer
		// corner to the inner one.
		let o0 = Float2(rect.X, rect.Y);
		let o1 = Float2(rect.X + rect.Width, rect.Y);
		let o2 = Float2(rect.X + rect.Width, rect.Y + rect.Height);
		let o3 = Float2(rect.X, rect.Y + rect.Height);
		let i0 = Float2(rect.X + borders.Left, rect.Y + borders.Top);
		let i1 = Float2(rect.X + rect.Width - borders.Right, rect.Y + borders.Top);
		let i2 = Float2(rect.X + rect.Width - borders.Right, rect.Y + rect.Height - borders.Bottom);
		let i3 = Float2(rect.X + borders.Left, rect.Y + rect.Height - borders.Bottom);
		void Side(Float2 a, Float2 b, Float2 c, Float2 d, Color color)
		{
			if (color.A <= 0.0f)
				return;
			let builder = scope PathBuilder();
			builder.MoveTo(a.X, a.Y);
			builder.LineTo(b.X, b.Y);
			builder.LineTo(c.X, c.Y);
			builder.LineTo(d.X, d.Y);
			builder.Close();
			let wedge = builder.ToPath();
			defer delete wedge;
			PushClipPath(wedge);
			FillPath(path, color, .EvenOdd);
			PopClipPath();
		}
		Side(o0, o1, i1, i0, colors.Top);
		Side(o1, o2, i2, i1, colors.Right);
		Side(o2, o3, i3, i2, colors.Bottom);
		Side(o3, o0, i0, i3, colors.Left);
	}

	/// A Gaussian blurred rounded rectangle, which is the UI's box shadow. `rect` and
	/// `radii` are the SHADOW's own box, the caller having already applied the offset and
	/// the spread; `blur` is the CSS blur radius, so sigma is half of it and the shadow
	/// fades over three sigma outside the box.
	///
	/// An OUTSET shadow paints outside the box and is fully opaque within it, the box's own
	/// background covering the inside; an INSET one paints only inside, fading inward from
	/// the edge. No blur degrades to a hard rounded rect when outset, and to nothing when
	/// inset.
	///
	/// Emitted as FOUR QUADRANT quads in the BoxShadow draw mode: within a single quadrant
	/// the rounded box distance operand `|p - c| - (halfSize - r)` is LINEAR in position, so
	/// it interpolates exactly from the four vertices, carried in sigma units in the texture
	/// coordinate, and the shader has only to finish
	/// `length(max(q, 0)) + min(max(q.x, q.y), 0) - r`. Non uniform radii come free, each
	/// quadrant carrying its own corner radius as coverage = r / sigma, negated for inset.
	/// Batches with every other shadow in the same command.
	public void FillBoxShadow(Rectangle rect, CornerRadii radii, float blur, Color color,
		bool inset = false)
	{
		if ((rect.Width <= 0.0f) || (rect.Height <= 0.0f) || (color.A <= 0.0f))
			return;

		if (blur <= 0.0f)
		{
			if (!inset)
				FillRoundedRect(rect, radii, color);
			return;
		}

		let sigma = blur * 0.5f;
		let extent = inset ? 0.0f : (sigma * 3.0f);
		let half = Float2(rect.Width * 0.5f, rect.Height * 0.5f);
		let center = Float2(rect.X + half.X, rect.Y + half.Y);
		let opColor = ApplyOpacity(color);

		SetDrawMode(.BoxShadow);
		SetupForSolidDraw();

		// The quadrant signs pick the corner; the outer reach runs three sigma past the box
		// so the tail has room to fade.
		float[4] corner = .(radii.TopLeft, radii.TopRight, radii.BottomRight, radii.BottomLeft);
		float[4][2] signs = .(.(-1.0f, -1.0f), .(1.0f, -1.0f), .(1.0f, 1.0f), .(-1.0f, 1.0f));
		for (int quadrant < 4)
		{
			let sx = signs[quadrant][0];
			let sy = signs[quadrant][1];
			let r = Min(corner[quadrant], Min(half.X, half.Y));
			let coverage = (inset ? -r : r) / sigma;
			let reachX = half.X + extent;
			let reachY = half.Y + extent;
			// q at a local offset (ax, ay) is |offset| - (half - r), in sigma units. Only two
			// values per axis appear, at the offsets 0 and the reach.
			let qxNear = (0.0f - (half.X - r)) / sigma;
			let qxFar = (reachX - (half.X - r)) / sigma;
			let qyNear = (0.0f - (half.Y - r)) / sigma;
			let qyFar = (reachY - (half.Y - r)) / sigma;

			let p0 = center;
			let p1 = Float2(center.X + sx * reachX, center.Y);
			let p2 = Float2(center.X + sx * reachX, center.Y + sy * reachY);
			let p3 = Float2(center.X, center.Y + sy * reachY);
			let baseIndex = (uint32)mBatch.Vertices.Count;
			mBatch.Vertices.Add(VGVertex(TransformPoint(p0), .(qxNear, qyNear), opColor, coverage));
			mBatch.Vertices.Add(VGVertex(TransformPoint(p1), .(qxFar, qyNear), opColor, coverage));
			mBatch.Vertices.Add(VGVertex(TransformPoint(p2), .(qxFar, qyFar), opColor, coverage));
			mBatch.Vertices.Add(VGVertex(TransformPoint(p3), .(qxNear, qyFar), opColor, coverage));
			mBatch.Indices.Add(baseIndex + 0);
			mBatch.Indices.Add(baseIndex + 1);
			mBatch.Indices.Add(baseIndex + 2);
			mBatch.Indices.Add(baseIndex + 0);
			mBatch.Indices.Add(baseIndex + 2);
			mBatch.Indices.Add(baseIndex + 3);
		}

		SetDrawMode(.Default);
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
		if (mAnalyticBoxes && (width > 0.0f))
		{
			// A stroke centred on the rect is a border of `width` inside the rect grown by half
			// of it, each rounded corner grown with it.
			let h = width * 0.5f;
			float Grow(float r) => (r > 0.0f) ? (r + h) : 0.0f;
			DrawBox(.(rect.X - h, rect.Y - h, rect.Width + width, rect.Height + width),
				.(Grow(radii.TopLeft), Grow(radii.TopRight), Grow(radii.BottomRight), Grow(radii.BottomLeft)),
				.(0, 0, 0, 0), .(width), color);
			return;
		}

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

	/// DrawImage clipped to a rounded rectangle: `srcRect` of the texture maps onto `destRect`,
	/// and only the part inside `destRect` rounded by `radii` is drawn, with an anti-aliased
	/// edge (a picture with rounded corners, such as a card's thumbnail).
	public void DrawImageRounded(ImageData texture, Rectangle destRect, Rectangle srcRect,
		CornerRadii radii, Color tint = .White)
	{
		if ((texture == null) || (destRect.Width <= 0.0f) || (destRect.Height <= 0.0f))
			return;
		if (radii.IsZero)
		{
			DrawImage(texture, destRect, srcRect, tint);
			return;
		}
		let builder = scope PathBuilder();
		ShapeBuilder.BuildRoundedRect(destRect, radii, builder);
		let path = builder.ToPath();
		defer delete path;
		FillConvexPathWithImage(path, texture, destRect, srcRect, tint);
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
		EmitGlyphPasses(atlas, ApplyOpacity(color), scope [&] (emit) =>
			{
				var cursorX = position.X;
				var index = 0;
				while (index < text.Length)
				{
					// Unshaped: each codepoint draws its atlas's glyph for it (none: nothing, no
					// advance).
					let glyph = atlas.GlyphFor((int32)DecodeCodepoint(text, ref index));
					if ((glyph >= 0) && atlas.GetGlyphQuad(glyph, ref cursorX, position.Y, let quad))
						emit(quad);
				}
			});

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
		case .Bottom: offsetY = bounds.Y + bounds.Height + metrics.Descent;
		// The caller has already worked out the baseline, so it is taken as given.
		case .Baseline: offsetY = bounds.Y;
		}

		DrawText(text, atlas, atlasTexture,
			.(HorizontalOffset(bounds, font.MeasureString(text), horizontal), offsetY), color);
	}

	/// Through a cached font, which needs a font service to resolve its atlas texture.
	/// Shaped by the font's shaper when it has one (ligatures, joined forms), at a baseline
	/// position.
	public void DrawText(StringView text, CachedFont font, Float2 position, Color color)
	{
		if ((font == null) || (mFontService == null))
			return;

		if (let shaped = ShapedText(text, font))
		{
			DrawPositionedGlyphs(shaped.Glyphs, font, position.X, position.Y, color);
			return;
		}

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

		if (let shaped = ShapedText(text, font))
		{
			// Shaped: aligned by the shaped width, as the unshaped path aligns by the measured one.
			let metrics = font.Font.Metrics;
			float y;
			switch (vertical)
			{
			case .Top: y = bounds.Y + metrics.Ascent;
			case .Middle: y = bounds.Y + ((bounds.Height - metrics.LineHeight) * 0.5f) + metrics.Ascent;
			case .Bottom: y = bounds.Y + bounds.Height + metrics.Descent;
			case .Baseline: y = bounds.Y;
			}
			DrawPositionedGlyphs(shaped.Glyphs, font, HorizontalOffset(bounds, shaped.Width, horizontal), y, color);
			return;
		}

		DrawText(text, font.Font, font.Atlas, atlasTexture, bounds, horizontal, vertical, color);
	}

	/// How many texts DrawText has shaped rather than found shaped already, for tests.
	public uint64 ShapedTextCount => mShapeCount;

	/// The glyphs of `text` shaped by `font`'s shaper on one line from 0 (the baseline at y 0),
	/// cached; null when the font has no shaper, to draw it unshaped. BORROWED: valid until the
	/// next call.
	private ShapedTextEntry ShapedText(StringView text, CachedFont font)
	{
		if ((font == null) || (font.Shaper == null) || (font.Font == null) || text.IsEmpty)
			return null;

		let key = HashBytes(text.Ptr, text.Length) ^ HashInteger((uint64)(uint)Internal.UnsafeCastToPtr(font));
		if (mShapedText.TryGetValue(key, let found))
		{
			if ((found.Cached === font) && (found.Font === font.Font) && (found.Atlas === font.Atlas)
				&& (found.Text == text))
				return found;
		}
		if (mShapedText.Count >= cShapedTextLimit)
		{
			for (let value in mShapedText.Values)
				delete value;
			mShapedText.Clear();
		}

		let entry = new ShapedTextEntry();
		entry.Text.Set(text);
		entry.Cached = font;
		entry.Font = font.Font;
		entry.Atlas = font.Atlas;
		if (font.Shaper.ShapeText(font.Font, text, 0, 0, entry.Glyphs) case .Ok(let width))
		{
			entry.Width = width;
		}
		else
		{
			delete entry;
			return null;
		}
		mShapeCount++;
		if (mShapedText.TryGetValue(key, let replaced))
			delete replaced; // a different text or font at this key
		mShapedText[key] = entry;
		return entry;
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
		EmitGlyphPasses(font.Atlas, ApplyOpacity(color), scope [&] (emit) =>
			{
				for (let position in positions)
				{
					if (font.Atlas.GetGlyphQuadAt(position.GlyphId, offsetX + position.X + position.XOffset,
						offsetY + position.Y + position.YOffset, let quad))
						emit(quad);
				}
			});

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

	/// The farthest an effect's ramp may reach past the edge, in field units: the field ends at
	/// 0.5.
	private const float cMaxEffectReach = 0.49f;

	/// Emits a run of glyphs under the current text effects: `forEachQuad(emit)` calls
	/// `emit(quad)` for each glyph's quad, once per pass (shadow, glow, outline, then the glyphs
	/// themselves in `color`). Effects in pixels become field units per glyph (a quad's atlas
	/// texels per pixel over the atlas's distance range), so they follow the text's size and the
	/// transform, and are scaled down to what the field holds (half its range).
	private void EmitGlyphPasses(IFontAtlas atlas, Color color, delegate void(delegate void(GlyphQuad)) forEachQuad)
	{
		let effects = mCurrentState.TextEffects;
		let distanceField = atlas.Mode == .DistanceField;
		if (effects.HasShadow)
			EmitGlyphPass(atlas, distanceField, effects.ShadowOffset, ApplyOpacity(effects.ShadowColor), 0.0f,
				distanceField ? effects.ShadowBlur : 0.0f, forEachQuad);
		if (distanceField && effects.HasGlow) // full at the edge, gone GlowRadius past it
			EmitGlyphPass(atlas, true, .Zero, ApplyOpacity(effects.GlowColor), effects.GlowRadius * 0.5f,
				effects.GlowRadius, forEachQuad);
		if (distanceField && effects.HasOutline)
			EmitGlyphPass(atlas, true, .Zero, ApplyOpacity(effects.OutlineColor), effects.OutlineWidth, 0.0f,
				forEachQuad);
		if (!mCurrentState.TextEffectsOnly)
			EmitGlyphPass(atlas, distanceField, .Zero, color, 0.0f, 0.0f, forEachQuad);
	}

	private void EmitGlyphPass(IFontAtlas atlas, bool distanceField, Float2 offset, Color color, float shiftPixels,
		float softPixels, delegate void(delegate void(GlyphQuad)) forEachQuad)
	{
		let range = atlas.DistanceFieldRange;
		let atlasWidth = (float)atlas.Width;
		forEachQuad(scope [&] (quad) =>
			{
				var quad;
				var effect = Float2.Zero;
				if (distanceField && (range > 0.0f) && (quad.X1 > quad.X0) && ((shiftPixels > 0.0f) || (softPixels > 0.0f)))
				{
					let unitsPerPixel = (quad.U1 - quad.U0) * atlasWidth / (quad.X1 - quad.X0) / range;
					effect = .(shiftPixels * unitsPerPixel, softPixels * unitsPerPixel);
					// The ramp's outer end past the edge, in field units.
					let reach = effect.X + effect.Y * 0.5f;
					if (reach > cMaxEffectReach)
						effect = effect * (cMaxEffectReach / reach);
				}
				quad.X0 += offset.X;
				quad.X1 += offset.X;
				quad.Y0 += offset.Y;
				quad.Y1 += offset.Y;
				EmitGlyphQuad(quad, color, effect);
			});
	}

	private void EmitGlyphQuad(GlyphQuad quad, Color color, Float2 effect = .Zero)
	{
		let baseIndex = (uint32)mBatch.Vertices.Count;

		var vertex = VGVertex(Float2(quad.X0, quad.Y0), .(quad.U0, quad.V0), color, 1.0f);
		vertex.Effect = effect;
		mBatch.Vertices.Add(vertex);
		vertex.Position = .(quad.X1, quad.Y0);
		vertex.TexCoord = .(quad.U1, quad.V0);
		mBatch.Vertices.Add(vertex);
		vertex.Position = .(quad.X1, quad.Y1);
		vertex.TexCoord = .(quad.U1, quad.V1);
		mBatch.Vertices.Add(vertex);
		vertex.Position = .(quad.X0, quad.Y1);
		vertex.TexCoord = .(quad.U0, quad.V1);
		mBatch.Vertices.Add(vertex);

		AddQuadIndices(baseIndex);
	}

	/// Fills a convex path with `srcRect` of a texture mapped onto `destRect`: the path is
	/// tessellated as a solid fill, its anti-aliased fringe included, and each vertex then takes
	/// the UV of its place in `destRect`. The UVs are clamped to `srcRect`, so the fringe, which
	/// reaches a little past the shape, samples the edge texels rather than the texture beyond.
	private void FillConvexPathWithImage(Path path, ImageData texture, Rectangle destRect,
		Rectangle srcRect, Color tint)
	{
		SetupForTextureDraw(GetOrAddTexture(texture));
		let startVertex = mBatch.Vertices.Count;
		FillTessellator.Tessellate(path, .NonZero, ApplyOpacity(tint), true, mBatch.Vertices,
			mBatch.Indices, GetScaledTolerance(), GetScaledFringe());
		let u0 = srcRect.X / (float)texture.Width;
		let v0 = srcRect.Y / (float)texture.Height;
		let u1 = (srcRect.X + srcRect.Width) / (float)texture.Width;
		let v1 = (srcRect.Y + srcRect.Height) / (float)texture.Height;
		for (int i = startVertex; i < mBatch.Vertices.Count; i++)
		{
			var vertex = mBatch.Vertices[i];
			let tx = (vertex.Position.X - destRect.X) / destRect.Width;
			let ty = (vertex.Position.Y - destRect.Y) / destRect.Height;
			vertex.TexCoord = .(Clamp(u0 + (u1 - u0) * tx, Min(u0, u1), Max(u0, u1)),
				Clamp(v0 + (v1 - v0) * ty, Min(v0, v1), Max(v0, v1)));
			mBatch.Vertices[i] = vertex;
		}
		TransformVertices(startVertex);
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
			pixels[(int)(i * 4) + 0] = color.R;
			pixels[(int)(i * 4) + 1] = color.G;
			pixels[(int)(i * 4) + 2] = color.B;
			pixels[(int)(i * 4) + 3] = color.A;
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
		command.Scissored = mCurrentState.Scissored && (mCurrentState.ClipMode == .Stencil);
		command.BlendMode = mCurrentBlendMode;
		command.StencilRef = mCurrentState.StencilRef;
		command.DrawMode = mCurrentDrawMode;
		command.GradientSpread = mCurrentGradientSpread;
		command.Layer = mCurrentLayer;
		return command;
	}

	// === transform helpers ===

	private static bool HasClip(Rectangle rect) => (rect.Width > 0.0f) && (rect.Height > 0.0f);

	private static bool SameRect(Rectangle a, Rectangle b)
		=> (a.X == b.X) && (a.Y == b.Y) && (a.Width == b.Width) && (a.Height == b.Height);

	/// A rectangle clip's state before it was pushed (PushClipRect, and a path clip's scissor
	/// fallback).
	private struct ClipRectSave : this(Rectangle Rect, bool Scissored);

	/// What a layer set aside (PushLayer) and gives back (PopLayer). With no layer (-1) it marks
	/// an opacity push, which is what a layer is with layers off.
	private class LayerSave
	{
		public VGState State = .();
		public List<ClipPathLevel> ClipPaths = new .() ~ DeleteContainerAndItems!(_);
		public List<ClipRectSave> ClipStack = new .() ~ delete _;
		public List<ClipRectSave> ClipPathScissors = new .() ~ delete _;
		public List<float> OpacityStack = new .() ~ delete _;
		public int32 FirstCommand = 0;
		public int32 Layer = -1;
	}

	/// One active path clip: its flattened path and the transform it was pushed under (a pop
	/// replays the clips that remain), and its DEVICE space bounds.
	private class ClipPathLevel
	{
		public List<FlattenedSubPath> SubPaths = new .() ~ DeleteContainerAndItems!(_);
		public Float4x4 Transform = .Identity();
		public Rectangle Bounds = .();
	}

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
