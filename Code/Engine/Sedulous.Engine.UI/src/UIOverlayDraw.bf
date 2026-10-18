using System;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.Scene;
using Sedulous.UI;
using Sedulous.VG;
using Sedulous.VG.Renderer;

namespace Sedulous.Engine.UI;

/// The two overlay roles, and the recording they share.
///
/// The scene tier draws each scene's canvases and billboards INSIDE the compose, wherever
/// that scene renders and with that view's REAL camera, so a split screen's halves each
/// project their own nameplates. The screen tier draws the scene less overlays once per
/// window target, after everything else.
extension UISubsystem : ISceneOverlay, IScreenOverlay
{
	/// Both roles sit at the same place in the draw order.
	public int32 OverlayOrder => 0;

	/// The per view sync, split out and free of any encoder so a headless test can drive it
	/// with a synthetic view: canvas visibility from the authored flag, then the billboards
	/// projected through the view's camera into its pixels.
	public void UpdateSceneView(Scene scene, SceneOverlayView view)
	{
		if (let canvases = scene.GetSystem<UICanvasComponentManager>())
		{
			canvases.ForEach(scope [&] (component, owner) =>
				{
					if (component.Root != null)
					{
						// Gone takes it out of hit testing as well as out of the drawing.
						component.Root.Visibility = (component.Visible
							&& scene.IsEffectivelyActive(owner)) ? .Visible : .Gone;
					}
				});
		}

		if (let billboards = scene.GetSystem<UIBillboardComponentManager>())
		{
			billboards.ForEach(scope [&] (component, owner) =>
				{
					ProjectBillboard(scene, view, component, owner);
				});
		}
	}

	private static void ProjectBillboard(Scene scene, SceneOverlayView view,
		UIBillboardComponent* component, EntityHandle owner)
	{
		if (component.Root == null)
			return;

		if (!component.Visible || !scene.IsEffectivelyActive(owner))
		{
			component.Root.Visibility = .Gone;
			return;
		}

		component.Root.Visibility = .Visible;

		let entity = scene.GetWorldMatrix(owner);
		Float3 worldPos;
		if (component.Orientation == .Cylindrical)
		{
			// The offset is a fixed lift in WORLD space, so the plate stays above the
			// anchor however the entity turns.
			let anchor = TransformPoint(Float3(0, 0, 0), entity);
			worldPos = anchor + component.Offset;
		}
		else
		{
			// ENTITY LOCAL, so the offset rides the entity's rotation.
			worldPos = TransformPoint(component.Offset, entity);
		}

		let clip = Float4(worldPos.X, worldPos.Y, worldPos.Z, 1.0f) * view.ViewProjection;
		var placement = component.Root.Layout;

		if (clip.W <= 0.0f)
		{
			// Behind the camera: parked off screen, so it is clipped and unhit without the
			// tree churning as an entity turns away.
			placement.Left = -10000.0f;
			placement.Top = -10000.0f;
		}
		else
		{
			// Pixels in VIEWPORT space: the scene root lays out at the viewport's size and
			// the vector renderer places it at the view's rectangle.
			//
			// The plate hangs BOTTOM CENTRED on the projected point, and scales toward it,
			// so it hovers over its anchor instead of sliding away to one side as the
			// distance changes. The first frame uses an unlaid out size of nothing, and it
			// converges on the next one.
			let ndcX = clip.X / clip.W;
			let ndcY = clip.Y / clip.W;
			let px = (ndcX * 0.5f + 0.5f) * (float)view.ViewportWidth;
			let py = (1.0f - (ndcY * 0.5f + 0.5f)) * (float)view.ViewportHeight;

			placement.Left = px - component.Root.Width * 0.5f;
			placement.Top = py - component.Root.Height;
		}

		component.Root.SetLayout(placement);

		var scale = 1.0f;
		if (component.ScaleMode == .Distance)
		{
			let toCamera = worldPos - view.CameraPosition;
			let distance = Math.Max(Length(toCamera), 0.001f);
			scale = Math.Clamp(component.ReferenceDistance / distance, component.MinScale,
				component.MaxScale);
		}

		component.Root.Transform.Scale = .(scale, scale);
		// Shrinking and growing toward the ANCHOR, which is where the placement put it.
		component.Root.Transform.Origin = .(0.5f, 1.0f);
	}

	/// The SCENE tier, inside the compose's shared overlay pass, once per view.
	public void Render(IRenderPassEncoder encoder, SceneOverlayView view)
	{
		if ((mRenderState == null) || (mRenderState.Device == null))
			return;
		if ((view.ViewportWidth == 0) || (view.ViewportHeight == 0))
			return;

		UISceneUI sceneUI = null;
		for (let ui in mSceneUIs)
		{
			if ((void*)Internal.UnsafeCastToPtr(ui.Scene) == view.SceneKey)
			{
				sceneUI = ui;
				break;
			}
		}

		if ((sceneUI == null) || (sceneUI.Root == null))
			return;

		// The scene root lays out at the VIEWPORT's size and draws at the view's rectangle,
		// so a split screen's halves each lay out their own interface, clipped to their half.
		UpdateSceneView(sceneUI.Scene, view);

		DrawRootInPass(sceneUI.Root, encoder, view.TargetFormat, view.ViewportX, view.ViewportY,
			view.ViewportWidth, view.ViewportHeight, (int32)view.FrameIndex,
			StencilAgrees(view.DepthStencilFormat));
	}

	/// The SCREEN tier, before the host's overlay pass: records the screens and draws their
	/// offscreen layers (VGContext.PushLayer) on the host's encoder, for Render to composite.
	public void PrepareOverlay(ICommandEncoder encoder, ScreenOverlayView view)
	{
		if ((mRenderState == null) || (mRenderState.Device == null))
			return;
		mRenderState.ScreensPrepared = false;
		mRenderState.PreparedScreens.Clear();
		if ((mScreen.Root == null) || (view.Width == 0) || (view.Height == 0))
			return;

		let layers = mRenderState.LayerShader != null;
		// The same tiers in the same order as Render draws them.
		if (let runTier = mRunScreens ? FindRunTier(mRenderRun) : null)
			PrepareScreen(runTier, encoder, view, layers);
		PrepareScreen(mScreen, encoder, view, layers);
		mRenderState.PreparedView = view;
		mRenderState.ScreensPrepared = true;
	}

	private void PrepareScreen(UIScreenTier tier, ICommandEncoder encoder, ScreenOverlayView view, bool layers)
	{
		let root = PrepareTier(tier, view, layers);
		if (root.Renderer != null)
			root.Renderer.RenderLayers(encoder, root.FrameIndex, root.Slice);
		mRenderState.PreparedScreens.Add(root);
	}

	/// The SCREEN tier, from the host's overlay call per window target, after the scene has
	/// composed: the render run's own screens (its Game tab), then the shared tier's global
	/// overlays above them. What PrepareOverlay recorded for this very view is drawn as it is;
	/// otherwise (another host, a changed view) the screens are recorded now, inside the pass,
	/// and their layers are opacity pushes.
	public void Render(IRenderPassEncoder encoder, ScreenOverlayView view)
	{
		if ((mRenderState == null) || (mRenderState.Device == null))
			return;
		if ((mScreen.Root == null) || (view.Width == 0) || (view.Height == 0))
			return;

		let prepared = mRenderState.ScreensPrepared && SameView(mRenderState.PreparedView, view);
		mRenderState.ScreensPrepared = false;
		if (prepared)
		{
			for (let root in mRenderState.PreparedScreens)
				DrawPrepared(root, encoder);
			mRenderState.PreparedScreens.Clear();
			return;
		}
		mRenderState.PreparedScreens.Clear();

		if (let runTier = mRunScreens ? FindRunTier(mRenderRun) : null)
			DrawPrepared(PrepareTier(runTier, view, false), encoder);
		DrawPrepared(PrepareTier(mScreen, view, false), encoder);
	}

	private static bool SameView(ScreenOverlayView a, ScreenOverlayView b)
		=> (a.Width == b.Width) && (a.Height == b.Height) && (a.FrameIndex == b.FrameIndex)
			&& (a.TargetFormat == b.TargetFormat) && (a.EncodedTarget == b.EncodedTarget)
			&& (a.DepthStencilFormat == b.DepthStencilFormat);

	/// Records a tier for the view. `layers` lets its views draw offscreen layers, which the
	/// caller then draws before the pass (VGRenderer.RenderLayers).
	private UIPreparedRoot PrepareTier(UIScreenTier tier, ScreenOverlayView view, bool layers)
	{
		tier.TargetSize = .((float)view.Width, (float)view.Height);
		var place = PlaceScreen(tier.Resolution, tier.FitMode, tier.Orientation, tier.TargetSize);
		tier.Turn = place.Turn;
		if (place.Fitted)
		{
			// Laid out at the game's resolution (or shape), drawn crisp at the target's resolution
			// into the rectangle the game's image was fitted to, turned with it.
			tier.Root.DpiScale = place.DpiScale;
			return PrepareRoot(tier.Root, view.TargetFormat, (int32)place.Rect.X, (int32)place.Rect.Y,
				(uint32)Math.Max(place.Rect.Width, 1.0f), (uint32)Math.Max(place.Rect.Height, 1.0f),
				(int32)view.FrameIndex, StencilAgrees(view.DepthStencilFormat), 1, &place, view.EncodedTarget,
				layers);
		}
		return PrepareRoot(tier.Root, view.TargetFormat, 0, 0, view.Width, view.Height,
			(int32)view.FrameIndex, StencilAgrees(view.DepthStencilFormat), 1, null, view.EncodedTarget, layers);
	}

	/// Stencil fills only where the pass carries an attachment in the SAME format the
	/// stencil pipelines were built against. Both sides probe the device in the same order,
	/// so agreeing is the expected case rather than a lucky one.
	private bool StencilAgrees(TextureFormat passFormat)
	{
		return (passFormat != .Undefined) && (passFormat == mRenderState.CanvasStencilFormat);
	}

	/// Records one root into an ALREADY ACTIVE pass.
	///
	/// Laid out at the CONTENT size, batched through the shared context, uploaded as a
	/// slice, which is pure writes into mapped memory and so legal while a pass is
	/// recording, and drawn at the given origin through the renderer's viewport seam.
	///
	/// The per configuration renderer's ring rewinds once per UI frame, so draws recorded
	/// earlier in the same frame are never clobbered by a later one.
	private void DrawRootInPass(RootView root, IRenderPassEncoder encoder, TextureFormat format,
		int32 viewportX, int32 viewportY, uint32 width, uint32 height, int32 frameIndex,
		bool stencilCapable = false, uint32 sampleCount = 1, UIScreenPlacement* placement = null,
		bool encoded = false)
	{
		// Inside a pass there is no drawing a layer first: they stay opacity pushes.
		DrawPrepared(PrepareRoot(root, format, viewportX, viewportY, width, height, frameIndex,
			stencilCapable, sampleCount, placement, encoded, false), encoder);
	}

	/// DrawRootInPass's second half: draws what was prepared into the active pass.
	private static void DrawPrepared(UIPreparedRoot prepared, IRenderPassEncoder encoder)
	{
		if (prepared.Renderer != null)
		{
			prepared.Renderer.Render(encoder, prepared.ViewportX, prepared.ViewportY, prepared.Width,
				prepared.Height, prepared.FrameIndex, prepared.Slice);
		}
	}

	/// DrawRootInPass's first half: lays out, records and uploads, which needs no pass.
	private UIPreparedRoot PrepareRoot(RootView root, TextureFormat format, int32 viewportX, int32 viewportY,
		uint32 width, uint32 height, int32 frameIndex, bool stencilCapable, uint32 sampleCount,
		UIScreenPlacement* placement, bool encoded, bool layers)
	{
		// A turned tier lays out in its own frame (the rectangle turned back) and draws through the
		// turn; everything else at the rectangle's size.
		root.ViewportSize = (placement != null) ? placement.DrawSize : Float2((float)width, (float)height);
		mContext.UpdateRootView(root);

		// What is EMITTED has to match the pass it will be rendered into: stencil fill
		// commands only where the target pass carries the attachment, which the canvas
		// targets do and the renderer's own overlay passes advertise.
		let stencil = stencilCapable && (mRenderState.CanvasStencilFormat != .Undefined);

		mRenderState.Context.SetStencilFills(stencil);
		mRenderState.Context.SetLayers(layers);
		mRenderState.Context.Clear();
		if (placement != null)
			mRenderState.Context.SetTransform(placement.Transform); // under the root's own DpiScale
		mContext.DrawRootView(root, mRenderState.Context);

		let batch = mRenderState.Context.GetBatch();
		// Reset, because each tier opts in per batch rather than once.
		mRenderState.Context.SetStencilFills(false);
		mRenderState.Context.SetLayers(false);

		var prepared = UIPreparedRoot();
		if (batch.Commands.IsEmpty)
			return prepared;

		let renderer = mRenderState.RendererFor(format, mFrameSerial, frameIndex, stencil,
			sampleCount, encoded);
		if (renderer == null)
			return prepared;
		// The texture images the tree names (resolved as it drew) registered on this renderer.
		mImages.SyncOn(renderer, mFrameSerial);

		prepared.Renderer = renderer;
		prepared.Slice = renderer.Prepare(batch, frameIndex, width, height);
		prepared.ViewportX = viewportX;
		prepared.ViewportY = viewportY;
		prepared.Width = width;
		prepared.Height = height;
		prepared.FrameIndex = frameIndex;
		return prepared;
	}
}
