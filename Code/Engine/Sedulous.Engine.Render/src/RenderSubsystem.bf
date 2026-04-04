namespace Sedulous.Engine.Render;

using Sedulous.Runtime;
using Sedulous.Scenes;
using Sedulous.Engine;
using Sedulous.RHI;
using Sedulous.Shell;

/// Owns the renderer, swapchain, command pools, and GPU frame pacing.
/// Runs late (UpdateOrder 500) — all scene updates and extraction are complete by this point.
/// Injects render component managers (Mesh, Light, Camera, etc.) into scenes via ISceneAware.
///
/// The app creates the device, window, and surface, then sets them on this subsystem
/// before context startup. This subsystem owns all other GPU resources.
class RenderSubsystem : Subsystem, ISceneAware, IWindowAware
{
	private const int MAX_FRAMES_IN_FLIGHT = 2;

	// Set by EngineApplication before context startup
	private IDevice mDevice;
	private IWindow mWindow;
	private ISurface mSurface;
	private TextureFormat mSwapChainFormat = .BGRA8UnormSrgb;
	private PresentMode mPresentMode = .Fifo;

	// Owned by this subsystem
	private ISwapChain mSwapChain;
	private IQueue mGraphicsQueue;
	private ICommandPool[MAX_FRAMES_IN_FLIGHT] mCommandPools;
	private IFence mFrameFence;
	private uint64 mNextFenceValue = 1;
	private uint64[MAX_FRAMES_IN_FLIGHT] mFrameFenceValues;

	// Frame state
	private int32 mFrameIndex = 0;
	private bool mWindowMinimized = false;

	public override int32 UpdateOrder => 500;

	// ==================== Properties (set by app before startup) ====================

	/// The RHI device.
	public IDevice Device { get => mDevice; set => mDevice = value; }

	/// The main window.
	public IWindow Window { get => mWindow; set => mWindow = value; }

	/// The surface for swapchain creation.
	public ISurface Surface { get => mSurface; set => mSurface = value; }

	/// Swap chain format.
	public TextureFormat SwapChainFormat { get => mSwapChainFormat; set => mSwapChainFormat = value; }

	/// Presentation mode.
	public PresentMode PresentMode { get => mPresentMode; set => mPresentMode = value; }

	/// The swapchain.
	public ISwapChain SwapChain => mSwapChain;

	/// The graphics queue.
	public IQueue GraphicsQueue => mGraphicsQueue;

	/// Current frame index (for multi-buffering).
	public int32 FrameIndex => mFrameIndex;

	// ==================== Lifecycle ====================

	protected override void OnInit()
	{
		if (mDevice == null || mSurface == null || mWindow == null)
			return;

		// Create swapchain
		SwapChainDesc desc = .()
		{
			Width = (uint32)mWindow.Width,
			Height = (uint32)mWindow.Height,
			Format = mSwapChainFormat,
			PresentMode = mPresentMode
		};

		if (mDevice.CreateSwapChain(mSurface, desc) case .Ok(let swapChain))
			mSwapChain = swapChain;

		// Graphics queue
		mGraphicsQueue = mDevice.GetQueue(.Graphics);

		// Per-frame command pools
		for (int i = 0; i < MAX_FRAMES_IN_FLIGHT; i++)
		{
			if (mDevice.CreateCommandPool(.Graphics) case .Ok(let pool))
				mCommandPools[i] = pool;
		}

		// Frame fence
		if (mDevice.CreateFence(0) case .Ok(let fence))
			mFrameFence = fence;

		// TODO: initialize renderer pipeline, depth buffer, shared resources
	}

	protected override void OnShutdown()
	{
		if (mDevice == null)
			return;

		mDevice.WaitIdle();

		for (int i = 0; i < MAX_FRAMES_IN_FLIGHT; i++)
		{
			if (mCommandPools[i] != null)
				mDevice.DestroyCommandPool(ref mCommandPools[i]);
		}

		if (mFrameFence != null)
			mDevice.DestroyFence(ref mFrameFence);

		if (mSwapChain != null)
			mDevice.DestroySwapChain(ref mSwapChain);
	}

	// ==================== Frame ====================

	public override void EndFrame()
	{
		if (mDevice == null || mSwapChain == null)
			return;

		// Skip when minimized
		if (mWindow.State == .Minimized)
			return;

		mFrameIndex = (int32)mSwapChain.CurrentImageIndex;

		// Wait for this frame's previous GPU work to complete
		if (mFrameFenceValues[mFrameIndex] > 0)
			mFrameFence.Wait(mFrameFenceValues[mFrameIndex]);

		// Reset command pool for this frame
		mCommandPools[mFrameIndex].Reset();

		// Acquire next swapchain image
		if (mSwapChain.AcquireNextImage() case .Err)
		{
			OnWindowResized(mWindow, mWindow.Width, mWindow.Height);
			return;
		}

		// Create encoder
		let pool = mCommandPools[mFrameIndex];
		var encoder = pool.CreateEncoder().Value;

		// TODO: collect extracted RenderData from all scenes
		// TODO: execute render graph / pipeline passes
		// For now: just clear to dark blue
		ColorAttachment[1] colorAttachments = .(.()
		{
			View = mSwapChain.CurrentTextureView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = ClearColor(0.1f, 0.1f, 0.2f, 1.0f)
		});

		RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };
		let renderPass = encoder.BeginRenderPass(passDesc);
		renderPass.SetViewport(0, 0, mSwapChain.Width, mSwapChain.Height, 0, 1);
		renderPass.SetScissor(0, 0, mSwapChain.Width, mSwapChain.Height);
		renderPass.End();

		// Transition to present
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = encoder.Finish();

		// Submit with fence
		mFrameFenceValues[mFrameIndex] = mNextFenceValue++;
		ICommandBuffer[1] bufs = .(commandBuffer);
		mGraphicsQueue.Submit(bufs, mFrameFence, mFrameFenceValues[mFrameIndex]);

		// Present
		if (mSwapChain.Present(mGraphicsQueue) case .Err)
			OnWindowResized(mWindow, mWindow.Width, mWindow.Height);

		pool.DestroyEncoder(ref encoder);
	}

	// ==================== Scene Injection ====================

	public void OnSceneCreated(Scene scene)
	{
		// TODO: inject MeshComponentManager, LightComponentManager, CameraComponentManager, etc.
	}

	public void OnSceneDestroyed(Scene scene)
	{
	}

	// ==================== IWindowAware ====================

	public void OnWindowResized(IWindow window, int32 width, int32 height)
	{
		if (width == 0 || height == 0 || mDevice == null || mSwapChain == null)
			return;

		mDevice.WaitIdle();
		mSwapChain.Resize((uint32)width, (uint32)height);

		// TODO: resize depth buffer, render targets
	}
}
