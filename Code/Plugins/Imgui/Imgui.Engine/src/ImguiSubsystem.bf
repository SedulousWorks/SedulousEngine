using System;
using Sedulous.Core;
using Sedulous.Engine.Render;
using Sedulous.Graphics;
using Sedulous.Render;
using Sedulous.RHI;
using Sedulous.VFS;
using Sedulous.Runtime;
using Sedulous.Shaders;
using Sedulous.Shell;
using cimgui_Beef;

namespace Imgui;

/// The debug interface as a SUBSYSTEM: the context owns it, and an application opens each frame
/// with NewFrame and builds its widgets.
///
/// Where the application has a render subsystem, the interface is one of its screen overlays,
/// drawn over the game's screens in the shared overlay pass and turned with the window when the
/// swapchain is pre-rotated. An application without one calls Render after its scene, which
/// draws onto the frame's target in a pass of its own.
///
/// Self contained on purpose, with its own shader host: a debug overlay that depended on the
/// renderer's shaders could not be used to debug the renderer.
class ImguiSubsystem : Subsystem, IScreenOverlay
{
	/// Above the game's screens (the GUI draws at 10): a debugging interface stays on top.
	public const int32 cOverlayOrder = 100;

	private IDevice mDevice = null;
	private uint32 mFramesInFlight = 2;

	private ShaderSystemHost mShaderHost = new .() ~ delete _;
	/// BORROWED, and where the overlay's shaders come from.
	private IFileSystem mDataFileSystem = null;
	private ImguiRenderer mRenderer = null ~ delete _;
	private ImGuiContext* mContext = null;

	/// The window's size at the last render or overlay, because the display size a frame is
	/// BUILT with has to be known before that frame is recorded.
	private uint32 mWidth = 1280;
	private uint32 mHeight = 720;

	private bool mReady = false;
	private bool mFrameOpen = false;
	/// The interface's frame was closed (rendered) since the last NewFrame.
	private bool mDrawReady = false;
	/// PrepareOverlay readied the view the overlay's Render draws.
	private bool mOverlayPrepared = false;
	/// The render subsystem drawing the interface as an overlay, BORROWED; null where the
	/// application calls Render itself.
	private RenderSubsystem mOverlayHost = null;

	/// The data mount is BORROWED: the application owns it and outlives this.
	public this(IDevice device, uint32 framesInFlight, IFileSystem dataFileSystem)
	{
		mDevice = device;
		mFramesInFlight = (framesInFlight < 1) ? 1 : framesInFlight;
		mDataFileSystem = dataFileSystem;
	}

	public bool IsReady => mReady;

	/// Whether a render subsystem draws the interface as one of its screen overlays.
	public bool IsOverlay => mOverlayHost != null;

	public int32 OverlayOrder => cOverlayOrder;

	/// Opens a frame: the display size, the step, the input, and then the frame itself. Call it
	/// at the top of the update, before building anything.
	public void NewFrame(IInputManager input, float deltaTime)
	{
		if (!mReady)
			return;

		// A frame opened last time and never rendered, which happens when the swapchain
		// handed back nothing and the render was skipped. Close it rather than open a second.
		if (mFrameOpen)
		{
			igEndFrame();
			mFrameOpen = false;
		}
		mDrawReady = false;

		let io = igGetIO_Nil();
		io.DisplaySize.x = (float)mWidth;
		io.DisplaySize.y = (float)mHeight;
		io.DeltaTime = (deltaTime > 0.0f) ? deltaTime : (1.0f / 60.0f);
		FeedInput(io, input);

		igNewFrame();
		mFrameOpen = true;
	}

	/// Closes the frame and draws it over what the application already rendered, for an
	/// application whose render subsystem does not draw it as an overlay. Does nothing where the
	/// overlay pass draws it.
	public void Render(ref FrameContext frame)
	{
		if (!mReady || (mOverlayHost != null))
			return;

		// Kept BALANCED even when the open was skipped, because the library asserts on a
		// render with no frame rather than ignoring it.
		if (!mFrameOpen)
			igNewFrame();
		mFrameOpen = false;

		igRender();

		mWidth = frame.Width;
		mHeight = frame.Height;

		if ((frame.Encoder == null) || (frame.BackbufferView == null) || (frame.Window == null))
			return;

		mRenderer.Render(frame.Encoder, frame.BackbufferView, frame.Window.Swap.Format,
			frame.Width, frame.Height, igGetDrawData(), frame.FrameIndex);
	}

	/// Closes the frame's interface (once, however many targets the overlay pass draws this
	/// frame) and readies it for the view, laying it out at the window's size from the next
	/// frame on.
	public void PrepareOverlay(ICommandEncoder encoder, ScreenOverlayView view)
	{
		mOverlayPrepared = false;
		if (!mReady)
			return;

		let window = view.WindowSize;
		mWidth = (uint32)window.X;
		mHeight = (uint32)window.Y;
		if (mFrameOpen)
		{
			igRender();
			mFrameOpen = false;
			mDrawReady = true;
		}
		if (!mDrawReady)
			return; // no NewFrame since the last frame drawn: nothing new to show

		let target = Float2((float)view.Width, (float)view.Height);
		mOverlayPrepared = mRenderer.Prepare(encoder, view.TargetFormat, view.DepthStencilFormat, target,
			view.WindowToTargetTransform, igGetDrawData(), view.FrameIndex);
	}

	public void Render(IRenderPassEncoder encoder, ScreenOverlayView view)
	{
		if (!mOverlayPrepared)
			return;
		mOverlayPrepared = false;
		mRenderer.Draw(encoder, igGetDrawData(), view.PreRotation, view.WindowSize, view.Width, view.Height);
	}

	protected override void OnInit()
	{
		// Cooked shaders from the pack where there is one, and the compiler over the shader
		// tree where there is not. With neither, the overlay stays INERT rather than failing
		// the application that registered it.
		if (mShaderHost.Initialize(mDevice, mDataFileSystem) case .Err)
			return;

		mContext = igCreateContext(null);

		let io = igGetIO_Nil();
		io.IniFilename = null; // no layout file unless an application asks for one
		// The renderer SERVICES texture requests, which is how this version of the library
		// hands its font atlas over: without the flag it would try to keep one itself.
		io.BackendFlags |= (int32)ImGuiBackendFlags.ImGuiBackendFlags_HasMouseCursors
			| (int32)ImGuiBackendFlags.ImGuiBackendFlags_RendererHasTextures;
		ImFontAtlas_AddFontDefault(io.Fonts, null);
		igStyleColorsDark(null);

		mRenderer = new ImguiRenderer(mDevice, mShaderHost.System, mFramesInFlight);
		if (mRenderer.Initialize() case .Err)
		{
			delete mRenderer;
			mRenderer = null;
			return;
		}
		mReady = true;
	}

	/// Draws as a screen overlay where there is a render subsystem; headless and plain
	/// applications have none, and call Render.
	protected override void OnReady()
	{
		if (!mReady || (Manager == null) || (mOverlayHost != null))
			return;
		mOverlayHost = Manager.GetSubsystem<RenderSubsystem>();
		if (mOverlayHost != null)
			mOverlayHost.RegisterOverlay((IScreenOverlay)this);
	}

	protected override void OnShutdown()
	{
		if (mOverlayHost != null)
		{
			mOverlayHost.UnregisterOverlay((IScreenOverlay)this);
			mOverlayHost = null;
		}

		// IDLE first: the renderer's buffers and textures are still referenced by frames the
		// device has not finished.
		if (mDevice != null)
			mDevice.WaitIdle();

		if (mRenderer != null)
		{
			delete mRenderer;
			mRenderer = null;
		}
		if (mContext != null)
		{
			igDestroyContext(mContext);
			mContext = null;
		}
		mShaderHost.Shutdown();
		mReady = false;
	}

	/// The pointer and the keys the interface needs, taken from the shell's own state rather
	/// than from an event queue: the overlay only cares what is held NOW.
	private void FeedInput(ImGuiIO* io, IInputManager input)
	{
		if (input == null)
			return;

		if (let mouse = input.Mouse)
		{
			ImGuiIO_AddMousePosEvent(io, mouse.X, mouse.Y);
			ImGuiIO_AddMouseButtonEvent(io, 0, mouse.IsButtonDown(.Left));
			ImGuiIO_AddMouseButtonEvent(io, 1, mouse.IsButtonDown(.Right));
			ImGuiIO_AddMouseButtonEvent(io, 2, mouse.IsButtonDown(.Middle));

			let scrollX = mouse.ScrollX;
			let scrollY = mouse.ScrollY;
			if ((scrollX != 0.0f) || (scrollY != 0.0f))
				ImGuiIO_AddMouseWheelEvent(io, scrollX, scrollY);
		}

		if (let keyboard = input.Keyboard)
		{
			ImGuiIO_AddKeyEvent(io, .ImGuiMod_Ctrl,
				keyboard.IsKeyDown(.LeftCtrl) || keyboard.IsKeyDown(.RightCtrl));
			ImGuiIO_AddKeyEvent(io, .ImGuiMod_Shift,
				keyboard.IsKeyDown(.LeftShift) || keyboard.IsKeyDown(.RightShift));
			ImGuiIO_AddKeyEvent(io, .ImGuiMod_Alt,
				keyboard.IsKeyDown(.LeftAlt) || keyboard.IsKeyDown(.RightAlt));

			ImGuiIO_AddKeyEvent(io, .ImGuiKey_Tab, keyboard.IsKeyDown(.Tab));
			ImGuiIO_AddKeyEvent(io, .ImGuiKey_LeftArrow, keyboard.IsKeyDown(.Left));
			ImGuiIO_AddKeyEvent(io, .ImGuiKey_RightArrow, keyboard.IsKeyDown(.Right));
			ImGuiIO_AddKeyEvent(io, .ImGuiKey_UpArrow, keyboard.IsKeyDown(.Up));
			ImGuiIO_AddKeyEvent(io, .ImGuiKey_DownArrow, keyboard.IsKeyDown(.Down));
			ImGuiIO_AddKeyEvent(io, .ImGuiKey_Enter, keyboard.IsKeyDown(.Return));
			ImGuiIO_AddKeyEvent(io, .ImGuiKey_Escape, keyboard.IsKeyDown(.Escape));
			ImGuiIO_AddKeyEvent(io, .ImGuiKey_Backspace, keyboard.IsKeyDown(.Backspace));
			ImGuiIO_AddKeyEvent(io, .ImGuiKey_Delete, keyboard.IsKeyDown(.Delete));
			ImGuiIO_AddKeyEvent(io, .ImGuiKey_Space, keyboard.IsKeyDown(.Space));
		}
	}
}
