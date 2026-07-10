namespace Sedulous.UI.Runtime;

using System;
using Sedulous.Runtime;
using Sedulous.RHI;
using Sedulous.VG;
using Sedulous.VG.Renderer;
using Sedulous.Shaders;
using Sedulous.Fonts;
using Sedulous.Core.Mathematics;
using Sedulous.Shell;
using Sedulous.Profiler;
using Sedulous.UI;
using Sedulous.UI.Shell;
using Sedulous.Fonts.TTF;
using Sedulous.VFS;

/// Subsystem that provides UI rendering and lifecycle management.
/// Owns rendering pipeline (VGContext, VGRenderer, ShaderSystem, FontService).
/// Owns input bridge (UIInputHelper, ShellClipboardAdapter).
/// Does NOT own UIContext or RootView - the application creates and owns those.
/// All cleanup happens in OnShutdown in reverse creation order.
public class UISubsystem : Subsystem
{
	public override int32 UpdateOrder => 400;

	// Rendering pipeline (owned, created in InitializeRendering)
	private VGContext mVGContext;
	private VGRenderer mVGRenderer;
	private ShaderSystem mShaderSystem;
	private TrueTypeFontService mFontService;

	// Input bridge (owned)
	private UIInputHelper mInputHelper;
	private ShellClipboardAdapter mClipboardAdapter;

	// Platform references (not owned)
	private IDevice mDevice;
	private IWindow mWindow;
	private IShell mShell;

	// UI references (not owned - app creates and owns these)
	private UIContext mUIContext;
	private RootView mRoot;

	// State
	private bool mRenderingInitialized;
	private int32 mFrameCount;

	/// When true, the application handles all input routing via InputHelper.
	/// UI2Subsystem skips its automatic shell input processing.
	/// Set when the app needs multi-window input control.
	public bool ManualInputRouting;

	/// The UI context (not owned - app creates and passes it).
	public UIContext UIContext => mUIContext;

	/// The root view (not owned - app creates and passes it).
	public RootView Root => mRoot;

	/// The input helper for manual input routing (when ManualInputRouting is true).
	public UIInputHelper InputHelper => mInputHelper;

	/// The font service for loading/caching fonts.
	public TrueTypeFontService FontService => mFontService;

	/// The shader system.
	public ShaderSystem ShaderSystem => mShaderSystem;

	/// Whether rendering has been initialized.
	public bool IsRenderingInitialized => mRenderingInitialized;

	/// Initialize rendering resources. Call after the device is ready.
	/// uiContext and root are created and owned by the application.
	/// Pass `fontMount` to route font loading through a VFS mount (e.g.,
	/// the host application's `BuiltinMount`); when null, the font service
	/// reads fonts via raw disk paths (back-compat).
	public Result<void> InitializeRendering(
		UIContext uiContext,
		RootView root,
		IDevice device,
		TextureFormat targetFormat,
		int32 frameCount,
		Span<StringView> shaderPaths,
		IShell shell = null,
		IWindow window = null,
		IMount fontMount = null)
	{
		mUIContext = uiContext;
		mRoot = root;
		mDevice = device;
		mShell = shell;
		mWindow = window;
		mFrameCount = frameCount;

		// Font service - VFS-routed if a mount was supplied, disk-path
		// fallback otherwise.
		mFontService = new TrueTypeFontService(fontMount);

		// Shader system (for VG rendering)
		mShaderSystem = new ShaderSystem();
		if (mShaderSystem.Initialize(device, shaderPaths) case .Err)
			return .Err;

		// Set up root view from window
		if (window != null)
		{
			root.ViewportSize = .((float)window.Width, (float)window.Height);
			root.DpiScale = window.ContentScale;
		}

		// Register root with context (attaches subtree, sets active input root)
		uiContext.AddRootView(root);

		// Provide font service to UIContext so it can create draw contexts
		uiContext.FontService = mFontService;

		// Input bridge (Shell -> UI2)
		if (shell?.InputManager != null)
			mInputHelper = new UIInputHelper();

		// Clipboard bridge (Shell -> UI2)
		if (shell?.Clipboard != null)
		{
			mClipboardAdapter = new ShellClipboardAdapter(shell.Clipboard);
			uiContext.Clipboard = mClipboardAdapter;
		}

		// VG context (with font service for text rendering)
		mVGContext = new VGContext(mFontService);

		// VG renderer (GPU upload + drawing)
		mVGRenderer = new VGRenderer();
		if (mVGRenderer.Initialize(device, targetFormat, frameCount, mShaderSystem) case .Err)
			return .Err;

		mRenderingInitialized = true;
		return .Ok;
	}

	/// Load a font into the font service.
	public Result<void> LoadFont(StringView familyName, StringView filePath, FontLoadOptions options = .ExtendedLatin)
	{
		return mFontService.LoadFont(familyName, filePath, options);
	}

	/// Called each frame. Syncs DPI, routes input, runs layout.
	public override void Update(float deltaTime)
	{
		if (!mRenderingInitialized || mUIContext == null || mRoot == null)
			return;

		// Route shell input -> UI2 events (unless app handles routing manually)
		if (!ManualInputRouting && mInputHelper != null && mShell?.InputManager != null)
			mInputHelper.Update(mShell.InputManager, mUIContext, deltaTime);

		// Drain deferred mutations / tick animations. Layout is NOT run here --
		// it happens in Render(), after the app's OnUpdate has routed input, so
		// input-driven tree changes (e.g. switching to a TabView tab, which
		// makes previously-Gone content Visible) are laid out before they are
		// first drawn. Laying out here (before input) would draw the newly
		// visible subtree at its stale 0x0 bounds for one frame; controls that
		// cache layout-dependent state (multiline EditText glyph wrapping) would
		// bake in that zero-width result permanently. Order matches Raptor's
		// input -> layout -> draw.
		mUIContext.BeginFrame(deltaTime);

		// Sync cursor from UI2 -> Shell
		SyncCursor();
	}

	/// Render UI overlay. Call after 3D scene rendering, before present.
	/// Creates a render pass with LoadOp=Load to preserve existing content.
	public void Render(ICommandEncoder encoder, ITextureView targetView,
		uint32 width, uint32 height, int32 frameIndex)
	{
		if (!mRenderingInitialized || mUIContext == null || mRoot == null)
			return;

		// Never draw at zero size -- the tree hasn't been laid out at a real
		// size yet, and drawing here would cache layout-dependent state at 0.
		if (width == 0 || height == 0)
			return;

		using (SProfiler.Begin("UI2Subsystem.Render"))
		{
			// Sync DPI + viewport to the swapchain size (authoritative) and lay
			// out the tree immediately before drawing. Running layout here --
			// after the app's OnUpdate has routed input -- guarantees the draw
			// reflects the post-input tree, so a subtree that just became
			// visible this frame (e.g. a newly selected TabView tab) is arranged
			// at its real size before its first draw. Matches Raptor's
			// input -> layout -> draw ordering.
			if (mWindow != null)
				mRoot.DpiScale = mWindow.ContentScale;
			mRoot.ViewportSize = .((float)width, (float)height);
			mUIContext.UpdateRootView(mRoot);

			// Build VG geometry from UI tree
			mVGContext.Clear();
			mUIContext.DrawRootView(mRoot, mVGContext);

			let batch = mVGContext.GetBatch();
			if (batch == null || batch.Commands.Count == 0)
				return;

			// Upload to GPU
			mVGRenderer.BeginFrame(frameIndex);
			let slice = mVGRenderer.Prepare(batch, frameIndex, width, height);

			// Create overlay render pass (Load = preserve 3D scene / background)
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
				mVGRenderer.Render(renderPass, width, height, frameIndex, slice);
				renderPass.End();
			}
		}
	}

	/// Sync UI2 cursor type to Shell cursor.
	private void SyncCursor()
	{
		if (mShell?.InputManager?.Mouse == null || mUIContext.InputManager == null)
			return;

		let uiCursor = mUIContext.InputManager.CurrentCursor;
		mShell.InputManager.Mouse.Cursor = MapCursorToShell(uiCursor);
	}

	/// Map UI2 CursorType to Shell CursorType.
	private static Sedulous.Shell.Input.CursorType MapCursorToShell(Sedulous.UI.CursorType cursor)
	{
		switch (cursor)
		{
		case .Default, .Arrow: return .Default;
		case .Hand:            return .Pointer;
		case .IBeam:           return .Text;
		case .Crosshair:       return .Crosshair;
		case .SizeNS:          return .ResizeNS;
		case .SizeWE:          return .ResizeEW;
		case .SizeNWSE:        return .ResizeNWSE;
		case .SizeNESW:        return .ResizeNESW;
		case .Move:            return .Move;
		case .NotAllowed:      return .NotAllowed;
		case .Wait:            return .Wait;
		}
	}

	/// Explicit cleanup in reverse creation order.
	protected override void OnShutdown()
	{
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

		if (mFontService != null)
		{
			delete mFontService;
			mFontService = null;
		}

		if (mClipboardAdapter != null)
		{
			delete mClipboardAdapter;
			mClipboardAdapter = null;
		}

		if (mInputHelper != null)
		{
			delete mInputHelper;
			mInputHelper = null;
		}

		// UIContext and RootView are NOT owned - app deletes them.
		mUIContext = null;
		mRoot = null;

		mRenderingInitialized = false;
	}
}
