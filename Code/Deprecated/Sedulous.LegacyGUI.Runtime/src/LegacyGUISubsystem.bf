namespace Sedulous.LegacyGUI.Runtime;

using System;
using Sedulous.Runtime;
using Sedulous.LegacyGUI;
using Sedulous.LegacyGUI.Shell;
using Sedulous.Drawing;
using Sedulous.Drawing.Renderer;
using Sedulous.Fonts;
using Sedulous.RHI;
using Sedulous.Shell;
using Sedulous.Shell.Input;
using Sedulous.Shaders;
using Sedulous.Profiler;

/// Foundation-layer subsystem for screen-space GUI overlays.
/// Owns GUIContext, DrawingRenderer, Theme, and ShaderSystem. The font
/// service is injected by the host application (non-owning).
/// Register with Context to get automatic Update() calls for input routing.
/// Call Render() explicitly after 3D scene rendering, before present.
public class GUISubsystem : Subsystem
{
	/// Updates after game logic but before rendering.
	public override int32 UpdateOrder => 400;

	// Core UI
	private LegacyGUIContext mGUIContext;
	private DrawContext mDrawContext;
	private DrawingRenderer mDrawingRenderer;
	private ShaderSystem mShaderSystem;

	/// IFontService used by this subsystem. Non-owning: the host
	/// application creates the concrete service, pre-loads fonts, and
	/// assigns it here before InitializeRendering runs.
	public IFontService FontService;

	// Services (owned)
	private ShellClipboardAdapter mClipboardAdapter;
	private ITheme mTheme;

	// Platform (not owned)
	private IDevice mDevice;
	private IShell mShell;
	private IWindow mWindow;

	// Input
	private LegacyGUIInputHelper mInputHelper = new .() ~ delete _;
	private bool mUIConsumedInput;

	// State
	private bool mRenderingInitialized;
	private float mTotalTime;
	private int32 mFrameCount;

	// Event delegates
	private delegate void(Sedulous.Shell.Input.KeyCode, bool) mKeyEventDelegate;
	private delegate void(StringView) mTextInputDelegate;
	private delegate void(IWindow, WindowEvent) mWindowEventDelegate;

	/// The global GUIContext for screen-space overlays.
	public LegacyGUIContext GUIContext => mGUIContext;

	/// The DrawingRenderer.
	public DrawingRenderer DrawingRenderer => mDrawingRenderer;

	/// The shader system (can be shared with WorldUISubsystem).
	public ShaderSystem ShaderSystem => mShaderSystem;

	/// The current theme.
	public ITheme Theme
	{
		get => mTheme;
		set
		{
			if (mTheme != null)
				delete mTheme;
			mTheme = value;
			if (mGUIContext != null)
				mGUIContext.RegisterService<ITheme>(mTheme);
		}
	}

	/// Whether screen-space UI consumed input this frame.
	public bool UIConsumedInput => mUIConsumedInput;

	/// The GPU device.
	public IDevice Device => mDevice;

	/// Number of in-flight frames.
	public int32 FrameCount => mFrameCount;

	/// Whether rendering has been initialized.
	public bool IsRenderingInitialized => mRenderingInitialized;

	public this()
	{
	}

	/// Initialize rendering resources. Call after the device is ready.
	/// Creates ShaderSystem, DrawingRenderer, DrawContext, GUIContext,
	/// Theme, Clipboard. FontService must already be assigned by the host.
	public Result<void> InitializeRendering(IDevice device, TextureFormat targetFormat, int32 frameCount, IShell shell, IWindow window, Span<StringView> shaderPaths)
	{
		mDevice = device;
		mFrameCount = frameCount;
		mShell = shell;
		mWindow = window;

		// Shader system (owned)
		mShaderSystem = new ShaderSystem();
		if (mShaderSystem.Initialize(device, shaderPaths) case .Err)
			return .Err;

		// GUIContext
		mGUIContext = new LegacyGUIContext();

		// DrawingRenderer
		mDrawingRenderer = new DrawingRenderer();
		if (mDrawingRenderer.Initialize(device, targetFormat, frameCount, mShaderSystem) case .Err)
		{
			delete mDrawingRenderer;
			mDrawingRenderer = null;
			return .Err;
		}

		// DrawContext
		mDrawContext = new DrawContext(FontService);
		mGUIContext.RegisterService<IFontService>(FontService);

		// Default theme
		mTheme = new DarkTheme();
		mGUIContext.RegisterService<ITheme>(mTheme);

		// Clipboard
		if (shell.Clipboard != null)
		{
			mClipboardAdapter = new ShellClipboardAdapter(shell.Clipboard);
			mGUIContext.RegisterClipboard(mClipboardAdapter);
		}

		// DPI scaling
		if (mWindow != null)
		{
			let scale = mWindow.ContentScale;
			if (scale > 0)
				mGUIContext.ScaleFactor = scale;
		}

		// Window events (DPI changes)
		mWindowEventDelegate = new => OnWindowEvent;
		shell.WindowManager.OnWindowEvent.Subscribe(mWindowEventDelegate);

		// Keyboard events (via shell directly, no InputSubsystem needed)
		SubscribeKeyboardEvents();

		mRenderingInitialized = true;
		return .Ok;
	}

	/// Called each frame. Routes input to GUIContext and checks consumption.
	public override void Update(float deltaTime)
	{
		if (!mRenderingInitialized)
			return;

		using (SProfiler.Begin("ScreenUI.Update"))
		{
			mTotalTime += deltaTime;
			mUIConsumedInput = false;

			// Route mouse input
			RouteMouseInput();

			// Update GUIContext
			mGUIContext.Update(deltaTime, (double)mTotalTime);

			// Check if screen-space UI consumed input
			bool consumed = mGUIContext.FocusManager?.FocusedElement != null;
			if (!consumed && mShell?.InputManager?.Mouse != null)
			{
				let mouse = mShell.InputManager.Mouse;
				let hitElement = mGUIContext.HitTest(mouse.X, mouse.Y);
				consumed = hitElement != null && hitElement != mGUIContext.RootElement;
			}
			mUIConsumedInput = consumed;

			// Update cursor
			UpdateCursor();
		}
	}

	/// Render UI overlay. Call after the 3D scene has been rendered, before present.
	/// Creates a render pass with LoadOp=Load to preserve existing content.
	public void Render(ICommandEncoder encoder, ITextureView targetView, uint32 width, uint32 height, int32 frameIndex)
	{
		if (!mRenderingInitialized || mGUIContext.RootElement == null)
			return;

		using (SProfiler.Begin("ScreenUI.Render"))
		{
			mGUIContext.SetViewportSize((float)width, (float)height);

			// Build geometry
			mDrawContext.Clear();
			mGUIContext.Render(mDrawContext);
			let batch = mDrawContext.GetBatch();
			if (batch == null || batch.Commands.Count == 0)
				return;

			// Upload to GPU
			mDrawingRenderer.BeginFrame(frameIndex);
			let slice = mDrawingRenderer.Prepare(batch, frameIndex, width, height);

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
				mDrawingRenderer.Render(renderPass, width, height, frameIndex, slice);
				renderPass.End();
			}
		}
	}

	protected override void OnInit()
	{
	}

	protected override void OnShutdown()
	{
		UnsubscribeKeyboardEvents();

		if (mDrawingRenderer != null)
		{
			mDrawingRenderer.Dispose();
			delete mDrawingRenderer;
			mDrawingRenderer = null;
		}

		if (mShaderSystem != null)
		{
			mShaderSystem.Dispose();
			delete mShaderSystem;
			mShaderSystem = null;
		}

		if (mDrawContext != null)
		{
			delete mDrawContext;
			mDrawContext = null;
		}

		if (mTheme != null)
		{
			delete mTheme;
			mTheme = null;
		}

		if (mClipboardAdapter != null)
		{
			delete mClipboardAdapter;
			mClipboardAdapter = null;
		}

		if (mGUIContext != null)
		{
			delete mGUIContext;
			mGUIContext = null;
		}

		// FontService is not owned - the host application created it and
		// is responsible for tearing it down.

		if (mKeyEventDelegate != null)
		{
			delete mKeyEventDelegate;
			mKeyEventDelegate = null;
		}

		if (mTextInputDelegate != null)
		{
			delete mTextInputDelegate;
			mTextInputDelegate = null;
		}

		if (mWindowEventDelegate != null)
		{
			mShell?.WindowManager?.OnWindowEvent.Unsubscribe(mWindowEventDelegate, false);
			delete mWindowEventDelegate;
			mWindowEventDelegate = null;
		}

		mShell = null;
		mWindow = null;
		mRenderingInitialized = false;
	}

	// ==================== Input Routing ====================

	private void RouteMouseInput()
	{
		if (mShell?.InputManager == null)
			return;

		let mouse = mShell.InputManager.Mouse;
		if (mouse == null)
			return;

		let keyboard = mShell.InputManager.Keyboard;
		LegacyGUIInputHelper.ProcessMouseInput(mouse, keyboard, mGUIContext);
	}

	private void UpdateCursor()
	{
		if (mShell?.InputManager == null)
			return;

		let mouse = mShell.InputManager.Mouse;
		if (mouse == null)
			return;

		let cursor = mGUIContext.CurrentCursor;
		let shellCursor = InputMapping.MapCursor(cursor);
		mouse.Cursor = shellCursor;
	}

	// ==================== Keyboard Events ====================

	private void SubscribeKeyboardEvents()
	{
		if (mShell?.InputManager == null)
			return;

		let keyboard = mShell.InputManager.Keyboard;
		if (keyboard == null)
			return;

		mKeyEventDelegate = new => OnKeyEvent;
		keyboard.OnKeyEvent.Subscribe(mKeyEventDelegate);

		mTextInputDelegate = new => OnTextInput;
		keyboard.OnTextInput.Subscribe(mTextInputDelegate);
	}

	private void UnsubscribeKeyboardEvents()
	{
		if (mShell?.InputManager == null)
			return;

		let keyboard = mShell.InputManager.Keyboard;
		if (keyboard == null)
			return;

		if (mKeyEventDelegate != null)
			keyboard.OnKeyEvent.Unsubscribe(mKeyEventDelegate, false);

		if (mTextInputDelegate != null)
			keyboard.OnTextInput.Unsubscribe(mTextInputDelegate, false);
	}

	private void OnKeyEvent(Sedulous.Shell.Input.KeyCode key, bool down)
	{
		if (!mRenderingInitialized)
			return;

		let uiKey = InputMapping.MapKey(key);
		let keyboard = mShell?.InputManager?.Keyboard;
		let mods = keyboard != null ? InputMapping.MapModifiers(keyboard.Modifiers) : Sedulous.LegacyGUI.KeyModifiers.None;

		if (down)
		{
			mGUIContext.ProcessKeyDown(uiKey, mods);
			InputMapping.ForwardKeyAsTextInput(key, mods, mGUIContext);
		}
		else
			mGUIContext.ProcessKeyUp(uiKey, mods);
	}

	private void OnTextInput(StringView text)
	{
		if (!mRenderingInitialized)
			return;

		for (let c in text.DecodedChars)
			mGUIContext.ProcessTextInput(c);
	}

	// ==================== DPI Scaling ====================

	private void OnWindowEvent(IWindow window, WindowEvent evt)
	{
		if (window != mWindow)
			return;

		if (evt.Type == .DisplayScaleChanged)
		{
			let scale = mWindow.ContentScale;
			if (scale > 0 && mGUIContext != null)
				mGUIContext.ScaleFactor = scale;
		}
	}
}
