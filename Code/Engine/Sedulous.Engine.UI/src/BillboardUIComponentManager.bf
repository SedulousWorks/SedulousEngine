namespace Sedulous.Engine.UI;

using System;
using Sedulous.Engine.Core;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.UI;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.Fonts;
using Sedulous.Shaders;
using Sedulous.Renderer;

/// Per-scene manager for `BillboardUIComponent`s.
///
/// Owns one shared `UIContext`, full-screen `RootView` (`AbsoluteLayout`),
/// `VGContext`, and `VGRenderer` for all billboards in the scene.
/// Implements `IPipelineOverlay` (Order = 50) so the renderer's
/// `OverlayPass` invokes `Render` once per frame per pipeline. Every
/// component's `Content` is added as a child of the shared root with
/// `AbsoluteLayout.LayoutParams` whose X/Y are recomputed each frame
/// from the projected screen position of the anchor entity.
///
/// Resources are initialized lazily by `EngineUISubsystem.OnSceneReady`
/// once the scene's pipeline (and its `OutputFormat`) is known. Until
/// `Initialize` succeeds, `Render` no-ops.
///
/// See `Documentation/Roadmap/UI_BILLBOARD.md` for the design.
class BillboardUIComponentManager : ComponentManager<BillboardUIComponent>, IPipelineOverlay
{
	// === Owned UI resources (constructed by Initialize) ===
	private UIContext mUIContext;
	private RootView mRoot;
	/// Full-screen `AbsoluteLayout` child of `mRoot`. Component `Content`
	/// views live as children of this layout with absolute X/Y matching
	/// their projected screen position. `IsHitTestVisible = false` so
	/// empty space between billboards falls through to lower-priority
	/// chain contexts (the layout doesn't count as an interactive view).
	private AbsoluteLayout mLayer;
	private VGContext mVGContext;
	private VGRenderer mVGRenderer;

	// === Public accessors ===

	/// The manager's top-level `RootView`. The full-screen
	/// `AbsoluteLayout` inside it (where component contents actually
	/// live) is internal; component lifecycle hooks manage child
	/// add/remove against it.
	public RootView Root => mRoot;

	/// The manager's UI input scope (joined to the engine's per-frame
	/// input chain after the scene's `UISceneModule.UIContext`).
	public UIContext UIContext => mUIContext;

	// === IPipelineOverlay ===

	/// Billboards draw below the Scene HUD (Order = 100, Track 2).
	public int32 Order => 50;

	/// Per-pipeline render entry point. Called once per frame per pipeline
	/// by `OverlayPass`. Projects each active component's anchor point to
	/// screen, updates the corresponding child's AbsoluteLayout X/Y, lays
	/// out the shared root, then emits the unified VG batch into the
	/// active overlay encoder.
	///
	/// Behind-camera anchors (clip.w <= 0) are positioned off-screen so
	/// the GPU clips them and HitTest naturally returns null. No
	/// Visibility / tree-membership manipulation - see UI_BILLBOARD.md
	/// for the rationale.
	public void Render(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline)
	{
		if (mRoot == null || mUIContext == null || mLayer == null || mVGContext == null || mVGRenderer == null)
			return;
		if (Scene == null) return;

		let width = view.Width;
		let height = view.Height;
		let frameIndex = view.FrameIndex;
		let vp = view.ViewProjectionMatrix;

		// Project every active component and write its screen position
		// into the child's AbsoluteLayout LayoutParams.
		for (let comp in ActiveComponents)
		{
			if (comp.Content == null) continue;

			// Lazy attach: components whose Content was assigned after
			// initialization get added the first time we see them in
			// Render.
			if (comp.Content.Parent == null)
			{
				mLayer.AddView(comp.Content, new AbsoluteLayout.LayoutParams() {
					Width = .Wrap,
					Height = .Wrap,
					X = 0,
					Y = 0
				});
			}

			let entityMat = Scene.GetWorldMatrix(comp.Owner);

			Vector3 worldPos;
			switch (comp.Orientation)
			{
			case .Cylindrical:
				// Offset in world space - position is entity translation
				// plus offset; entity rotation/scale ignored.
				worldPos = entityMat.Translation + comp.Offset;
			case .ScreenBillboard:
				// Offset in entity local space - full transform applies,
				// so offset follows the entity's rotation/scale.
				worldPos = Vector3.Transform(comp.Offset, entityMat);
			}

			// Project to clip space.
			let world4 = Vector4(worldPos.X, worldPos.Y, worldPos.Z, 1);
			let clip = Vector4.Transform(world4, vp);

			float screenX;
			float screenY;
			if (clip.W <= 0)
			{
				// Behind camera - off-screen position. GPU clips; HitTest
				// returns null. See UI_BILLBOARD.md "Culling" section.
				screenX = -10000;
				screenY = -10000;
			}
			else
			{
				let ndcX = clip.X / clip.W;
				let ndcY = clip.Y / clip.W;
				screenX = (ndcX * 0.5f + 0.5f) * (float)width;
				screenY = (1.0f - (ndcY * 0.5f + 0.5f)) * (float)height;
			}

			if (let absLP = comp.Content.LayoutParams as AbsoluteLayout.LayoutParams)
			{
				absLP.X = screenX;
				absLP.Y = screenY;
			}

			// Distance scaling - applied as a 2D ViewTransform.Scale on the
			// Content so it shows + hit-tests at the scaled size. Origin
			// stays at the default (center) so scaling pivots around the
			// content's middle.
			float scale = 1.0f;
			if (comp.ScaleMode == .Distance)
			{
				let toCamera = worldPos - view.CameraPosition;
				let distance = Math.Max(toCamera.Length(), 0.001f);
				let raw = comp.ReferenceDistance / distance;
				scale = Math.Clamp(raw, comp.MinScale, comp.MaxScale);
			}
			comp.Content.Transform.Scale = .(scale, scale);
		}

		// Layout the shared root against the active pipeline output size.
		mRoot.ViewportSize = .((float)width, (float)height);
		mUIContext.UpdateRootView(mRoot);

		// Build the unified VG batch (one batch covers every billboard).
		mVGContext.Clear();
		mUIContext.DrawRootView(mRoot, mVGContext);

		let batch = mVGContext.GetBatch();
		if (batch == null || batch.Commands.Count == 0)
			return;

		// One draw call per frame for all billboards.
		mVGRenderer.BeginFrame(frameIndex);
		let slice = mVGRenderer.Prepare(batch, frameIndex, width, height);
		mVGRenderer.Render(encoder, width, height, frameIndex, slice);
	}

	// === Component lifecycle ===

	/// Removes the component's Content from the shared layer (without
	/// deleting it - the component owns the view). The component itself
	/// is freed by the base ComponentManager.
	protected override void OnComponentDestroyed(BillboardUIComponent comp)
	{
		if (mLayer == null || comp.Content == null) return;
		if (comp.Content.Parent === mLayer)
			mLayer.RemoveView(comp.Content, false);
	}

	// === Initialization / teardown ===

	/// Constructs the shared `UIContext` + `RootView` (with a full-screen
	/// `AbsoluteLayout` child) + `VGContext` + `VGRenderer`. Call after
	/// `scene.AddModule(this)` once the pipeline's `OutputFormat` is
	/// known (e.g. from `EngineUISubsystem.OnSceneReady`).
	///
	/// `sharedStyleSheet` is borrowed (RefCounted, AddRef on assign,
	/// Release on destruction). `fontService` and `shaderSystem` are
	/// borrowed - the host application owns their lifetime.
	public Result<void> Initialize(IDevice device, TextureFormat targetFormat,
		int32 frameCount, IFontService fontService, ShaderSystem shaderSystem,
		StyleSheet sharedStyleSheet)
	{
		if (device == null || fontService == null || shaderSystem == null)
			return .Err;

		mUIContext = new UIContext();
		mUIContext.FontService = fontService;
		if (sharedStyleSheet != null)
			mUIContext.StyleSheet = sharedStyleSheet;

		mRoot = new RootView();
		mUIContext.AddRootView(mRoot);

		mLayer = new AbsoluteLayout();
		// Empty regions of the billboard layer must pass clicks through to
		// the next chain context (world UI / camera) rather than swallowing
		// them. Component `Content` views are the actual hit-test targets.
		mLayer.IsHitTestVisible = false;
		mRoot.AddView(mLayer, new LayoutParams() { Width = .Match, Height = .Match });

		mVGContext = new VGContext(fontService);

		mVGRenderer = new VGRenderer();
		if (mVGRenderer.Initialize(device, targetFormat, frameCount, shaderSystem) case .Err)
			return .Err;

		return .Ok;
	}

	public override void Dispose()
	{
		base.Dispose();

		if (mVGRenderer != null)
		{
			mVGRenderer.Dispose();
			delete mVGRenderer;
			mVGRenderer = null;
		}

		if (mVGContext != null)
		{
			delete mVGContext;
			mVGContext = null;
		}

		// mLayer is a child of mRoot; RootView/ViewGroup teardown deletes
		// children. Component `Content` views are owned by the components
		// (not by the layer), so the manager only nulls its reference.
		mLayer = null;

		if (mUIContext != null && mRoot != null)
			mUIContext.RemoveRootView(mRoot);

		if (mRoot != null)
		{
			delete mRoot;
			mRoot = null;
		}

		if (mUIContext != null)
		{
			delete mUIContext;
			mUIContext = null;
		}
	}
}
