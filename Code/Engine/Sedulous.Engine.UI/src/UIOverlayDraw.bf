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

	/// The SCREEN tier, from the host's overlay call per window target, after the scene has
	/// composed.
	public void Render(IRenderPassEncoder encoder, ScreenOverlayView view)
	{
		if ((mRenderState == null) || (mRenderState.Device == null))
			return;
		if ((mScreenRoot == null) || (view.Width == 0) || (view.Height == 0))
			return;

		DrawRootInPass(mScreenRoot, encoder, view.TargetFormat, 0, 0, view.Width, view.Height,
			(int32)view.FrameIndex, StencilAgrees(view.DepthStencilFormat));
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
		bool stencilCapable = false, uint32 sampleCount = 1)
	{
		root.ViewportSize = .((float)width, (float)height);
		mContext.UpdateRootView(root);

		// What is EMITTED has to match the pass it will be rendered into: stencil fill
		// commands only where the target pass carries the attachment, which the canvas
		// targets do and the renderer's own overlay passes advertise.
		let stencil = stencilCapable && (mRenderState.CanvasStencilFormat != .Undefined);

		mRenderState.Context.SetStencilFills(stencil);
		mRenderState.Context.Clear();
		mContext.DrawRootView(root, mRenderState.Context);

		let batch = mRenderState.Context.GetBatch();
		// Reset, because each tier opts in per batch rather than once.
		mRenderState.Context.SetStencilFills(false);

		if (batch.Commands.IsEmpty)
			return;

		let renderer = mRenderState.RendererFor(format, mFrameSerial, frameIndex, stencil,
			sampleCount);
		if (renderer == null)
			return;

		let slice = renderer.Prepare(batch, frameIndex, width, height);
		renderer.Render(encoder, viewportX, viewportY, width, height, frameIndex, slice);
	}
}
