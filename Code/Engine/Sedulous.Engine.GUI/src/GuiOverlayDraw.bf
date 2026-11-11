using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.GUI;
using Sedulous.Render;
using Sedulous.RHI;

namespace Sedulous.Engine.GUI;

/// The two overlay roles through GUI.Hosting's GuiPassRenderer, the GPU bring-up, and an
/// editor's preview.
///
/// The scene tier draws each scene's root inside the compose, wherever that scene renders, laid
/// out at the view's viewport (a split screen's half lays out its own). The screen tier draws once
/// per window target after everything else: recorded before the host's pass (PrepareOverlay, its
/// offscreen layers on the host's encoder), then drawn in it.
extension GuiSubsystem : ISceneOverlay, IScreenOverlay
{
	/// Above the engine's own overlays (0).
	public int32 OverlayOrder => 10;

	/// Whether the overlays draw: the renderer is up and its shaders resolved.
	public bool IsRenderReady => (mRenderState != null) && (mRenderState.Renderer != null) && mRenderState.Renderer.IsUsable;

	/// The GPU side, by whoever owns graphics (the application's startup): the VG shaders from the
	/// data mount, the renderer. IDEMPOTENT; without it the overlays draw nothing. The device is
	/// BORROWED and outlives the subsystem's shutdown, which waits for it.
	public void EnsureRenderReady(IDevice device, int32 frameCount)
	{
		if ((mRenderState != null) && (mRenderState.Device != null))
			return;
		delete mRenderState;
		mRenderState = new GuiRenderState();
		mRenderState.Device = device;
		if ((mDataFileSystem == null) || !mRenderState.Shaders.Load(device, mDataFileSystem))
		{
			GlobalLog(.Error, "GUI: no shader compiler and no shader pack: the GUI will not draw");
			return;
		}
		mRenderState.Renderer = new GuiPassRenderer(device, (uint32)Math.Max(frameCount, 1), Fonts, mRenderState.Shaders.Set);
		mContext.PictureBaker = mRenderState.Renderer.Baker;
		let renderer = mRenderState.Renderer;
		// OWNED by the provider from here; told at once of every key a texture backs now.
		mResources.SetTextureSink(new (key, view) =>
			{
				if (view != null)
					renderer.RegisterTexture(key, view);
				else
					renderer.UnregisterTexture(key);
			});
	}

	/// The scene tier: the view's scene root, laid out at the view's viewport and drawn there.
	public void Render(IRenderPassEncoder encoder, SceneOverlayView view)
	{
		if (!IsRenderReady || (view.ViewportWidth == 0) || (view.ViewportHeight == 0))
			return;
		GuiSceneTier tier = null;
		for (let known in mSceneTiers)
		{
			if ((void*)Internal.UnsafeCastToPtr(known.Scene) == view.SceneKey)
				tier = known;
		}
		// A scene's GUI draws while it shows a canvas or a billboard; its billboards placed
		// through this view's camera before the layout.
		if ((tier == null) || !HasContent(tier))
			return;
		PlaceBillboards(tier, view);
		// Laid out at the viewport's size (a split screen's half lays out its own) and drawn there.
		StyleAndLayOut(tier.Root, .((float)view.ViewportWidth, (float)view.ViewportHeight));
		var pass = GuiPassView();
		pass.X = view.ViewportX;
		pass.Y = view.ViewportY;
		pass.Width = view.ViewportWidth;
		pass.Height = view.ViewportHeight;
		pass.Format = view.TargetFormat;
		pass.DepthStencilFormat = view.DepthStencilFormat;
		pass.FrameIndex = view.FrameIndex;
		mRenderState.Renderer.DrawInPass(tier.Root, encoder, pass);
	}

	/// The screen tier, before the pass: the frame's bakes, then the drawn run's tier and the
	/// shared one recorded, their offscreen layers on the host's encoder.
	public void PrepareOverlay(ICommandEncoder encoder, ScreenOverlayView view)
	{
		if (!IsRenderReady)
			return;
		mRenderState.ScreenPrepared = false;
		// The bakes before any pass samples them, once a frame.
		mRenderState.Renderer.RecordBakes(encoder, view.FrameIndex);
		if ((mScreen.Root == null) || (view.Width == 0) || (view.Height == 0))
			return;
		// The drawn run's own screens (its Game tab), then the shared tier above them.
		let run = mRunScreens ? FindRunTier(mRenderRun) : null;
		mRenderState.HasRunScreen = run != null;
		if (run != null)
			mRenderState.RunScreen = PrepareScreenTier(run, view, encoder);
		mRenderState.Screen = PrepareScreenTier(mScreen, view, encoder);
		mRenderState.ScreenView = view;
		mRenderState.ScreenPrepared = true;
	}

	/// The screen tier: what PrepareOverlay recorded for this view, else recorded now, its layers
	/// drawn in place.
	public void Render(IRenderPassEncoder encoder, ScreenOverlayView view)
	{
		if (!IsRenderReady || (mScreen.Root == null) || (view.Width == 0) || (view.Height == 0))
			return;
		let prepared = mRenderState.ScreenPrepared && SameView(mRenderState.ScreenView, view);
		mRenderState.ScreenPrepared = false;
		let renderer = mRenderState.Renderer;
		if (prepared)
		{
			if (mRenderState.HasRunScreen)
				renderer.Draw(encoder, mRenderState.RunScreen);
			renderer.Draw(encoder, mRenderState.Screen);
			return;
		}
		if (let run = mRunScreens ? FindRunTier(mRenderRun) : null)
			renderer.Draw(encoder, PrepareScreenTier(run, view, null));
		renderer.Draw(encoder, PrepareScreenTier(mScreen, view, null));
	}

	private static GuiPassView ScreenPass(ScreenOverlayView view)
	{
		var pass = GuiPassView();
		pass.Width = view.Width;
		pass.Height = view.Height;
		pass.Format = view.TargetFormat;
		pass.DepthStencilFormat = view.DepthStencilFormat;
		pass.Encoded = view.EncodedTarget;
		pass.FrameIndex = view.FrameIndex;
		return pass;
	}

	private static bool SameView(ScreenOverlayView a, ScreenOverlayView b)
		=> (a.Width == b.Width) && (a.Height == b.Height) && (a.TargetFormat == b.TargetFormat)
			&& (a.DepthStencilFormat == b.DepthStencilFormat) && (a.FrameIndex == b.FrameIndex)
			&& (a.EncodedTarget == b.EncodedTarget)
			&& (a.SafeArea.X == b.SafeArea.X) && (a.SafeArea.Y == b.SafeArea.Y)
			&& (a.SafeArea.Width == b.SafeArea.Width) && (a.SafeArea.Height == b.SafeArea.Height);

	/// A screen tier placed on `view`'s target and recorded (its layers on `encoder` when given,
	/// else drawn in place): laid out at the game's resolution over its scale and drawn into the
	/// fitted rectangle, turned with the game's image, or at the target's own size over all of it.
	private GuiPassRenderer.Prepared PrepareScreenTier(GuiScreenTier tier, ScreenOverlayView view, ICommandEncoder encoder)
	{
		let target = Float2((float)view.Width, (float)view.Height);
		tier.TargetSize = target;
		tier.Area = view.SafeArea;
		let place = PlaceScreen(tier.Resolution, tier.Fit, tier.Orientation, target, view.SafeArea);
		tier.Turn = place.Turn;
		var pass = ScreenPass(view);
		var size = target;
		var scale = 1.0f;
		if (place.Fitted)
		{
			pass.X = (int32)place.Rect.X;
			pass.Y = (int32)place.Rect.Y;
			pass.Width = (uint32)Math.Max(place.Rect.Width, 1.0f);
			pass.Height = (uint32)Math.Max(place.Rect.Height, 1.0f);
			pass.Transform = place.Transform;
			size = place.DrawSize;
			scale = place.DpiScale;
		}
		if (tier.Root.DisplayScale != scale)
			tier.Root.DisplayScale = scale;
		StyleAndLayOut(tier.Root, size);
		return mRenderState.Renderer.Prepare(tier.Root, pass, encoder);
	}

	// ==================== an editor's preview ====================

	/// `markup` built for an editor's page in the GUI's own context (the game's fonts, theme and
	/// sheets), in a root of its own that is never in a tier and takes no input; `css`, when given,
	/// a sheet over it alone (a sheet's page). What the loader dropped goes to `diagnostics`, which
	/// owns what is added. The root comes with a reference the CALLER releases; null when the
	/// markup does not build.
	public SceneRoot CreatePreview(StringView markup, StringView css = "", List<GuiDiagnostic> diagnostics = null)
	{
		if (markup.IsEmpty)
			return null;
		let loader = scope MarkupLoader(mContext.ElementSet, mResources, Fonts);
		loader.SetDataModel(mContext.Data);
		loader.SetDiagnostics(diagnostics);
		let tree = loader.LoadFromString(markup);
		if (tree == null)
			return null;
		let root = new SceneRoot(mContext);
		using (Node.StyleWriteScope(root))
		{
			root.EditLayoutStyle(scope (s) => { s.Kind = .Stack; }); // the document fills it
		}
		root.AddChild(tree);
		tree.ReleaseRef(); // the root holds it
		if (!css.IsEmpty)
		{
			// In a GUI by now (the root's): the sheet holds it weakly through its element table.
			let sheet = scope StyleSheet();
			CSSParser.Parse(css, "preview", sheet);
			mStyles.SetSubtreeSheet(tree, sheet);
		}
		return root;
	}

	/// `root` laid out at `width` x `height` and drawn into `target` (in RenderTarget state, and
	/// left so) in a pass of its own on `encoder`, over what is there.
	public void RenderPreview(SceneRoot root, ICommandEncoder encoder, ITextureView target, TextureFormat format,
		uint32 width, uint32 height, uint32 frameIndex)
	{
		if (!IsRenderReady || (root == null) || (target == null) || (width == 0) || (height == 0))
			return;
		let renderer = mRenderState.Renderer;
		renderer.RecordBakes(encoder, frameIndex); // before the pass samples them, once a frame
		StyleAndLayOut(root, .((float)width, (float)height));
		var view = GuiPassView();
		view.Width = width;
		view.Height = height;
		view.Format = format;
		view.FrameIndex = frameIndex;
		let prepared = renderer.Prepare(root, view, encoder);
		var color = ColorAttachment();
		color.View = target;
		color.LoadOp = .Load;
		color.StoreOp = .Store;
		var pass = RenderPassDesc();
		pass.ColorAttachments.Add(color);
		if (let passEncoder = encoder.BeginRenderPass(pass))
		{
			renderer.Draw(passEncoder, prepared);
			passEncoder.End();
		}
	}
}
