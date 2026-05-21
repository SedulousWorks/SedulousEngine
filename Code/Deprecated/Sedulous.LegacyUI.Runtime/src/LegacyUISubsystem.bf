namespace Sedulous.LegacyUI.Runtime;

using System;
using Sedulous.Runtime;
using Sedulous.LegacyUI;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.RHI;
using Sedulous.Shaders;
using Sedulous.Fonts;
using Sedulous.Core.Mathematics;
using Sedulous.Profiler;

/// Foundation-layer subsystem for screen-space UI.
/// Owns UIContext, VGContext, VGRenderer, and ShaderSystem. The font
/// service is injected by the host application (non-owning).
/// Register with Context to get automatic Update() calls.
/// Call Render() explicitly after 3D scene rendering, before present.
public class LegacyUISubsystem : Subsystem
{
	public override int32 UpdateOrder => 400;

	/// IFontService used by this subsystem. Non-owning: the host
	/// application creates the concrete service and assigns it here
	/// before InitializeRendering runs.
	public IFontService FontService;

	// Core UI
	private UIContext mUIContext;
	private RootView mRoot;
	private VGContext mVGContext;
	private VGRenderer mVGRenderer;
	private ShaderSystem mShaderSystem;

	// Input bridge (Shell -> UI)
	private Sedulous.LegacyUI.Shell.UIInputHelper mInputHelper;
	private Sedulous.LegacyUI.Shell.ShellClipboardAdapter mClipboardAdapter;

	// Platform (not owned)
	private IDevice mDevice;
	private Sedulous.Shell.IShell mShell;
	private Sedulous.Shell.IWindow mWindow;

	// State
	private bool mRenderingInitialized;
	private int32 mFrameCount;
	private float mTotalTime;

	/// When true, the application handles all input routing via InputHelper.
	/// UISubsystem skips its automatic shell input processing.
	/// Set once at init when the app needs multi-window input control.
	public bool ManualInputRouting;

	/// The global UIContext for screen-space UI.
	public UIContext UIContext => mUIContext;

	/// The main root view (for the primary window).
	public RootView Root => mRoot;

	/// The input helper for manual input routing (when ManualInputRouting is true).
	public Sedulous.LegacyUI.Shell.UIInputHelper InputHelper => mInputHelper;

	/// The shader system.
	public ShaderSystem ShaderSystem => mShaderSystem;

	/// Whether rendering has been initialized.
	public bool IsRenderingInitialized => mRenderingInitialized;

	public this()
	{
	}

	/// Initialize rendering resources. Call after the device is ready.
	/// Pass shell for input bridging (optional - null disables input).
	public Result<void> InitializeRendering(
		IDevice device,
		TextureFormat targetFormat,
		int32 frameCount,
		Span<StringView> shaderPaths,
		Sedulous.Shell.IShell shell = null,
		Sedulous.Shell.IWindow window = null)
	{
		mDevice = device;
		mShell = shell;
		mWindow = window;
		mFrameCount = frameCount;

		// Shader system
		mShaderSystem = new ShaderSystem();
		if (mShaderSystem.Initialize(device, shaderPaths) case .Err)
			return .Err;

		// UIContext (connect font service + default theme). FontService
		// was assigned by the host before InitializeRendering was called.
		mUIContext = new UIContext();
		mUIContext.FontService = FontService;
		mUIContext.SetTheme(DarkTheme.Create(), true);

		// Create and register the main root view.
		mRoot = new RootView();
		mUIContext.AddRootView(mRoot);

		// Input bridge (Shell -> UI)
		if (shell?.InputManager != null)
			mInputHelper = new Sedulous.LegacyUI.Shell.UIInputHelper();

		// Clipboard bridge (Shell -> UI)
		if (shell?.Clipboard != null)
		{
			mClipboardAdapter = new Sedulous.LegacyUI.Shell.ShellClipboardAdapter(shell.Clipboard);
			mUIContext.Clipboard = mClipboardAdapter;
		}

		// VGContext (with font service so DrawText convenience overloads work)
		mVGContext = new VGContext(FontService);

		// VGRenderer
		mVGRenderer = new VGRenderer();
		if (mVGRenderer.Initialize(device, targetFormat, frameCount, mShaderSystem) case .Err)
			return .Err;

		mRenderingInitialized = true;
		return .Ok;
	}

	/// Called each frame by the Context. Routes input, runs mutation queue, layout.
	public override void Update(float deltaTime)
	{
		if (!mRenderingInitialized || mUIContext == null)
			return;

		using (SProfiler.Begin("UISubsystem.Update"))
		{
			mTotalTime += deltaTime;

			// Sync DPI scale from Shell window (handles monitor changes).
			if (mWindow != null)
				mRoot.DpiScale = mWindow.ContentScale;

			// Route shell input -> UI events (unless app handles routing manually).
			if (!ManualInputRouting && mInputHelper != null && mShell?.InputManager != null)
				mInputHelper.Update(mShell.InputManager, mUIContext, deltaTime);

			// Drain deferred mutations, then run layout.
			mUIContext.BeginFrame(deltaTime);
			mUIContext.UpdateRootView(mRoot);
		}
	}

	/// Render UI overlay. Call after 3D scene rendering, before present.
	/// Creates a render pass with LoadOp=Load to preserve existing content.
	public void Render(ICommandEncoder encoder, ITextureView targetView,
		uint32 width, uint32 height, int32 frameIndex)
	{
		if (!mRenderingInitialized || mUIContext == null)
			return;

		using (SProfiler.Begin("UISubsystem.Render"))
		{
			mRoot.ViewportSize = .((float)width, (float)height);

			// Build geometry
			mVGContext.Clear();
			mUIContext.DrawRootView(mRoot, mVGContext);
			let batch = mVGContext.GetBatch();
			if (batch == null || batch.Commands.Count == 0)
				return;

			// Upload to GPU
			mVGRenderer.UpdateProjection(width, height, frameIndex);
			mVGRenderer.Prepare(batch, frameIndex);

			// Create overlay render pass (Load = preserve 3D scene)
			ColorAttachment[1] colorAttachments = .(.()
			{
				View = targetView,
				ResolveTarget = null,
				LoadOp = .Load,
				StoreOp = .Store,
				ClearValue = .(0, 0, 0, 1)
			});
			RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };

			let renderPass = encoder.BeginRenderPass(passDesc);
			if (renderPass != null)
			{
				mVGRenderer.Render(renderPass, width, height, frameIndex);
				renderPass.End();
			}
		}
	}

	protected override void OnInit()
	{
	}

	protected override void OnShutdown()
	{
		if (mInputHelper != null)
		{
			delete mInputHelper;
			mInputHelper = null;
		}

		if (mClipboardAdapter != null)
		{
			if (mUIContext != null) mUIContext.Clipboard = null;
			delete mClipboardAdapter;
			mClipboardAdapter = null;
		}


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

		if (mShaderSystem != null)
		{
			mShaderSystem.Dispose();
			delete mShaderSystem;
			mShaderSystem = null;
		}

		// FontService is not owned - the host application created it and
		// is responsible for tearing it down.

		if (mUIContext != null)
		{
			if (mRoot != null)
			{
				mUIContext.RemoveRootView(mRoot);
				delete mRoot;
				mRoot = null;
			}
			delete mUIContext;
			mUIContext = null;
		}

		mRenderingInitialized = false;
	}
}
