namespace Sedulous.Engine.UI;

using System;
using Sedulous.Runtime;
using Sedulous.Shell;
using Sedulous.Engine;
using Sedulous.Engine.Render;
using Sedulous.Scenes;
using Sedulous.RHI;
using Sedulous.UI;
using Sedulous.UI.Shell;
using Sedulous.Fonts;
using Sedulous.Fonts.TTF;
using Sedulous.Shaders;
using Sedulous.Core.Mathematics;

/// Unified engine UI subsystem handling screen-space and world-space UI.
/// Screen-space: ScreenUIView renders as IRenderOverlay after 3D scene blit.
/// World-space: UIComponentManager per scene, renders to textures displayed as sprites.
class EngineUISubsystem : Subsystem, ISceneAware, IWindowAware
{
	public override int32 UpdateOrder => 400;

	// Set by EngineApplication before Startup.
	public IDevice Device;
	public IWindow Window;
	public IShell Shell;
	public ShaderSystem ShaderSystem;
	public String AssetDirectory ~ delete _;

	// Owned.
	private UIContext mUIContext;
	private FontService mFontService;
	private ScreenUIView mScreenView;
	private UIInputHelper mInputHelper;
	private ShellClipboardAdapter mClipboardAdapter;

	// Public access.
	public UIContext UIContext => mUIContext;
	public FontService FontService => mFontService;
	public ScreenUIView ScreenView => mScreenView;

	/// Returns true if the mouse is over a UI element (not just the root).
	/// Use to block scene input when UI is handling the mouse.
	public bool IsMouseOverUI
	{
		get
		{
			if (mUIContext == null || mScreenView?.Root == null) return false;
			let hit = mUIContext.HitTest(.(mUIContext.InputManager.MouseX, mUIContext.InputManager.MouseY));
			return hit != null && hit !== mScreenView.Root;
		}
	}

	protected override void OnInit()
	{
		// Font service.
		mFontService = new FontService();

		// UIContext (shared across screen + world views).
		mUIContext = new UIContext();
		mUIContext.FontService = mFontService;
		mUIContext.Theme = DarkTheme.Create();

		// Clipboard bridge.
		if (Shell?.Clipboard != null)
		{
			mClipboardAdapter = new ShellClipboardAdapter(Shell.Clipboard);
			mUIContext.Clipboard = mClipboardAdapter;
		}

		// Input bridge.
		if (Shell?.InputManager != null)
			mInputHelper = new UIInputHelper();

		// Screen UI view — needs Device + SwapChain format.
		if (Device != null)
		{
			// Get swap chain format from RenderSubsystem.
			let renderSub = Context.GetSubsystem<Sedulous.Engine.Render.RenderSubsystem>();
			if (renderSub != null)
			{
				let swapFormat = renderSub.SwapChainFormat;
				let frameCount = renderSub.FrameCount;

				mScreenView = new ScreenUIView(mUIContext, Device, swapFormat,
					frameCount, mFontService, ShaderSystem);

				// Register as render overlay.
				renderSub.RegisterOverlay(mScreenView);
			}
		}

		// Load default font if asset directory is available.
		if (AssetDirectory != null && AssetDirectory.Length > 0)
		{
			let fontPath = scope String();
			System.IO.Path.InternalCombine(fontPath, AssetDirectory, "fonts/roboto/Roboto-Regular.ttf");
			if (System.IO.File.Exists(fontPath))
			{
				mFontService.LoadFont("Roboto", fontPath, .() { PixelHeight = 16 });
				mFontService.LoadFont("Roboto", fontPath, .() { PixelHeight = 24 });
			}
		}
	}

	public override void Update(float deltaTime)
	{
		if (mUIContext == null) return;

		// Sync DPI scale from window.
		if (Window != null && mScreenView != null)
			mScreenView.Root.DpiScale = Window.ContentScale;

		// Route input.
		if (mInputHelper != null && Shell?.InputManager != null)
			mInputHelper.Update(Shell.InputManager, mUIContext, deltaTime);

		// Drain mutations, tick animations/tooltips.
		mUIContext.BeginFrame(deltaTime);

		// Layout screen view.
		if (mScreenView != null)
			mUIContext.UpdateRootView(mScreenView.Root);
	}

	// === IWindowAware ===

	public void OnWindowResized(IWindow window, int32 width, int32 height)
	{
		// ScreenUIView gets its viewport from RenderOverlay parameters,
		// so no explicit handling needed here.
	}

	// === ISceneAware ===

	public void OnSceneCreated(Scene scene)
	{
		let uiMgr = new UIComponentManager();
		uiMgr.Device = Device;
		uiMgr.UIContext = mUIContext;
		uiMgr.FontService = mFontService;
		uiMgr.ShaderSystem = ShaderSystem;
		scene.AddModule(uiMgr);
	}

	public void OnSceneDestroyed(Scene scene)
	{
	}

	// === Shutdown ===

	protected override void OnPrepareShutdown()
	{
		// Unregister overlay while other subsystems are still alive.
		if (mScreenView != null)
		{
			let renderSub = Context?.GetSubsystem<RenderSubsystem>();
			renderSub?.UnregisterOverlay(mScreenView);
		}
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

		if (mScreenView != null)
		{
			delete mScreenView;
			mScreenView = null;
		}

		if (mFontService != null)
		{
			delete mFontService;
			mFontService = null;
		}

		if (mUIContext != null)
		{
			delete mUIContext;
			mUIContext = null;
		}
	}
}
