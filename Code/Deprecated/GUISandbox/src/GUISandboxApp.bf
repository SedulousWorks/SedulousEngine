namespace GUISandbox;

using System;
using System.Collections;
using System.IO;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Runtime.Client;
using Sedulous.Runtime;
using Sedulous.Drawing;
using Sedulous.Fonts;
using Sedulous.GUI;
using Sedulous.Fonts.TTF;
using Sedulous.Drawing.Renderer;
using Sedulous.Shell.Input;
using Sedulous.GUI.Shell;
using Sedulous.Shaders;
using Sedulous.Images;
using Sedulous.Fonts.TTF;

/// GUI Sandbox sample demonstrating the Sedulous.GUI framework.
/// Features a professional header with theme/scale switching and demo navigation.
class GUISandboxApp : Application
{
	// GUI System
	private GUIContext mGUIContext ~ delete _;

	// Main shell with header and navigation
	private MainShell mMainShell ~ delete _;

	// Font service
	private FontService mFontService ~ delete _;

	// Drawing context
	private DrawContext mDrawContext ~ delete _;

	// Drawing renderer
	private DrawingRenderer mDrawingRenderer;

	// Shader system
	private ShaderSystem mShaderSystem;

	// FPS tracking
	private int mFrameCount = 0;
	private float mFpsTimer = 0;
	private int mCurrentFps = 0;

	// Demo images for Image control demo
	private OwnedImageData mDemoCheckerboard ~ delete _;
	private OwnedImageData mDemoGradient ~ delete _;

	// Clipboard adapter
	private ShellClipboardAdapter mClipboard ~ delete _;

	// Cursor tracking
	private Sedulous.GUI.CursorType mLastCursor = .Default;

	// Input helper for polling-based keyboard/mouse routing
	private GUIInputHelper mInputHelper = new .() ~ delete _;
	private float mFrameDelta = 0;

	public this() : base()
	{
	}

	protected override void OnInitialize(Context context)
	{
		// Initialize image loader (must be before any image loading)
		Sedulous.Images.SDL.SDLImageLoader.Initialize();

		// Initialize fonts
		mFontService = new FontService();

		String fontPath = scope .();
		GetAssetPath("fonts/roboto/Roboto-Regular.ttf", fontPath);

		FontLoadOptions options = .ExtendedLatin;
		options.PixelHeight = 16;

		if (mFontService.LoadFont("Roboto", fontPath, options) case .Err)
		{
			Console.WriteLine(scope $"Failed to load font: {fontPath}");
			return;
		}

		// Initialize shader system
		mShaderSystem = new ShaderSystem();
		String shaderPath = scope .();
		GetAssetPath("shaders", shaderPath);
		if (mShaderSystem.Initialize(Device, scope StringView[](shaderPath)) case .Err)
		{
			Console.WriteLine("Failed to initialize shader system");
			return;
		}

		// Create draw context
		mDrawContext = new DrawContext(mFontService);

		// Initialize drawing renderer
		mDrawingRenderer = new DrawingRenderer();
		if (mDrawingRenderer.Initialize(Device, SwapChain.Format, (int32)SwapChain.BufferCount, mShaderSystem) case .Err)
		{
			Console.WriteLine("Failed to initialize drawing renderer");
			return;
		}

		// Create demo images for Image control demo
		CreateDemoImages();

		// Initialize GUI
		InitializeGUI();

		Console.WriteLine("Sedulous.GUI Sandbox initialized.");
		Console.WriteLine("  Use the header controls to switch demos, themes, and scale.");
		Console.WriteLine("  F2: Toggle debug overlay | ESC: Exit");
	}

	private void CreateDemoImages()
	{
		// Create a checkerboard pattern image (64x64)
		let checkerboard = Sedulous.Images.Image.CreateSolidColor(64, 64, Color.Red);
		mDemoCheckerboard = new OwnedImageData(checkerboard.Width, checkerboard.Height, .RGBA8, checkerboard.Data);
		delete checkerboard;

		// Create a gradient image (80x60)
		let gradient = Sedulous.Images.Image.CreateGradient(80, 60, Color(100, 200, 100, 255), Color(100, 100, 200, 255), .RGBA8);
		mDemoGradient = new OwnedImageData(gradient.Width, gradient.Height, .RGBA8, gradient.Data);
		delete gradient;
	}

	private void InitializeGUI()
	{
		mGUIContext = new GUIContext();
		mGUIContext.SetViewportSize((float)SwapChain.Width, (float)SwapChain.Height);

		// Register clipboard adapter
		mClipboard = new ShellClipboardAdapter(mShell.Clipboard);
		mGUIContext.RegisterClipboard(mClipboard);

		// Register font service for text rendering
		mGUIContext.RegisterService<IFontService>(mFontService);

		// Create main shell
		mMainShell = new MainShell(mGUIContext, mDemoCheckerboard, mDemoGradient, AssetDirectory);
		mMainShell.Create();
		mGUIContext.RootElement = mMainShell.Root;
	}

	protected override void OnInput(FrameContext frame)
	{
		let keyboard = mShell.InputManager.Keyboard;
		let mouse = mShell.InputManager.Mouse;

		// Toggle debug overlay with F2
		if (keyboard.IsKeyPressed(.F2))
			mMainShell.ToggleDebugMode();

		// Handle Escape - let GUI handle it first, then exit
		if (keyboard.IsKeyPressed(.Escape))
		{
			if (!mGUIContext.ProcessKeyDown(.Escape, .None))
				Exit();
		}

		// Route mouse and keyboard input to GUI via shared helper
		GUIInputHelper.ProcessMouseInput(mouse, keyboard, mGUIContext);
		mInputHelper.ProcessKeyboardInput(keyboard, mGUIContext, mFrameDelta);

		// Update cursor
		UpdateCursor(mouse);
	}

	/// Updates the mouse cursor based on the hovered UI element.
	private void UpdateCursor(Sedulous.Shell.Input.IMouse mouse)
	{
		let guiCursor = mGUIContext.CurrentCursor;
		if (guiCursor != mLastCursor)
		{
			mLastCursor = guiCursor;
			mouse.Cursor = InputMapping.MapCursor(guiCursor);
		}
	}

	protected override void OnUpdate(FrameContext frame)
	{
		mFrameDelta = frame.DeltaTime;

		// FPS calculation
		mFrameCount++;
		mFpsTimer += frame.DeltaTime;
		if (mFpsTimer >= 1.0f)
		{
			mCurrentFps = mFrameCount;
			mFrameCount = 0;
			mFpsTimer -= 1.0f;

			// Update FPS display in shell
			mMainShell.UpdateFps(mCurrentFps);
		}

		// Update GUI
		mGUIContext.Update(frame.DeltaTime, (double)frame.TotalTime);
	}

	protected override void OnPrepareFrame(FrameContext frame)
	{
		BuildDrawCommands();

		// Update renderer
		mDrawingRenderer.UpdateProjection(SwapChain.Width, SwapChain.Height, frame.FrameIndex);
		mDrawingRenderer.Prepare(mDrawContext.GetBatch(), frame.FrameIndex);
	}

	private void BuildDrawCommands()
	{
		mDrawContext.Clear();

		// Render GUI (includes debug overlay if enabled)
		mGUIContext.Render(mDrawContext);

		// Debug indicator (top-right corner)
		if (mGUIContext.DebugSettings.ShowLayoutBounds)
		{
			let cachedFont = mFontService.GetFont(16);
			let atlasTexture = mFontService.GetAtlasTexture(cachedFont);
			float screenWidth = (float)SwapChain.Width;
			mDrawContext.DrawText("[DEBUG]", cachedFont.Atlas, atlasTexture, .(screenWidth - 70, 60 + cachedFont.Font.Metrics.Ascent), Color.Yellow);
		}
	}

	protected override void OnRender(IRenderPassEncoder renderPass, FrameContext frame)
	{
		mDrawingRenderer.Render(renderPass, SwapChain.Width, SwapChain.Height, frame.FrameIndex, useMsaa: false);
	}

	protected override void OnResize(int32 width, int32 height)
	{
		mGUIContext?.SetViewportSize((float)width, (float)height);
	}

	protected override void OnShutdown()
	{
		// Clean up drawing renderer
		if (mDrawingRenderer != null)
		{
			mDrawingRenderer.Dispose();
			delete mDrawingRenderer;
			mDrawingRenderer = null;
		}

		// Clean up shader system
		if (mShaderSystem != null)
		{
			mShaderSystem.Dispose();
			delete mShaderSystem;
		}
	}
}
