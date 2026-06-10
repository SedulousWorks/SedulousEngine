namespace Sedulous.Engine.UI;

using System;
using Sedulous.UI;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.RHI;
using Sedulous.Renderer;
using Sedulous.Engine.Core;
using Sedulous.Fonts;
using Sedulous.Shaders;

/// Per-scene singleton owning the scene's screen-space UI.
///
/// One instance per `Scene`, attached as a `SceneModule`. Not entity-
/// attached - modeled on `RenderSceneModule` (per-scene singleton for
/// render settings) rather than a `ComponentManager`.
///
/// Draws into the scene's pipeline output via the per-pipeline overlay
/// hook (`IPipelineOverlay`, see `Sedulous.Renderer.IPipelineOverlay`).
/// `EngineUISubsystem` constructs + initializes this module per scene,
/// adds it to the scene, and registers it with the scene's pipeline.
///
/// Game code accesses the HUD's root view via:
/// ```
/// scene.GetModule<UISceneModule>().Root.AddView(myHud)
/// ```
///
/// Resource lifecycle is two-stage: construction sets nothing up;
/// `Initialize(...)` (sub-phase B) builds the `UIContext`, `RootView`,
/// `VGContext`, and `VGRenderer`. This mirrors `UIComponentManager`'s
/// pattern of field-injection before `scene.AddModule(...)`.
public class UISceneModule : SceneModule, IPipelineOverlay
{
	// === Owned UI resources (constructed by Initialize in sub-phase B) ===
	private UIContext mUIContext;
	private RootView mRoot;
	private VGContext mVGContext;
	private VGRenderer mVGRenderer;

	// === Public accessors ===

	/// The scene HUD's root view. Game code adds layout / widgets here.
	public RootView Root => mRoot;

	/// The scene's UI input scope. Distinct from the engine's window-level
	/// `UIContext`. Input routing dispatches into this context when the
	/// window-level context doesn't consume the event (see input chain in
	/// `EngineUISubsystem`).
	public UIContext UIContext => mUIContext;

	// === IPipelineOverlay ===

	/// Scene HUD draws above billboards (~50) and below editor gizmos.
	/// See UI_SCENE.md for the convention.
	public int32 Order => 100;

	/// Per-frame layout + draw. Called once per pipeline per frame by
	/// `OverlayPass`. The render pass is already open with `LoadOp.Load`
	/// on the pipeline output; this method only records draw commands.
	public void Render(IRenderPassEncoder encoder, RenderView view, Pipeline pipeline)
	{
		if (mRoot == null || mUIContext == null || mVGContext == null || mVGRenderer == null)
			return;

		let width = view.Width;
		let height = view.Height;
		let frameIndex = view.FrameIndex;

		// Layout the scene HUD against the active pipeline's output size.
		mRoot.ViewportSize = .((float)width, (float)height);
		mUIContext.UpdateRootView(mRoot);

		// Build VG geometry from the view tree.
		mVGContext.Clear();
		mUIContext.DrawRootView(mRoot, mVGContext);

		let batch = mVGContext.GetBatch();
		if (batch == null || batch.Commands.Count == 0)
			return;

		// Upload and emit draw commands into the active overlay encoder.
		mVGRenderer.BeginFrame(frameIndex);
		let slice = mVGRenderer.Prepare(batch, frameIndex, width, height);
		mVGRenderer.Render(encoder, width, height, frameIndex, slice);
	}

	// === Initialization / teardown ===

	/// Constructs the owned UI + VG resources. Call before
	/// `scene.AddModule(this)` (matches `UIComponentManager`'s
	/// field-injection-then-add pattern).
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
