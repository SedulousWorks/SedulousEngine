using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Platform;

namespace Sedulous.RuntimeGraphics;

/// A window's presentation target. Owns its surface/swapchain and a per-frame
/// ring of command pools + fences (per-window present sync). Created via
/// GraphicsDevice.CreateRenderWindow() and destroyed by deleting.
class RenderWindow
{
	private GraphicsDevice mGraphicsDevice;  // borrowed
	private IWindow mWindow;                 // borrowed
	private ISurface mSurface;               // owned
	private ISwapChain mSwapChain;           // owned
	private ICommandPool[] mPools;           // owned, one per frame-in-flight
	private IFence[] mFences;                // owned, one per frame-in-flight
	private uint64[] mFenceValues;
	private uint32 mWidth;
	private uint32 mHeight;
	private IRenderWindowData mData;         // optional typed payload

	/// The platform window this render window targets.
	public IWindow Window => mWindow;

	/// The underlying swapchain.
	public ISwapChain Swap => mSwapChain;

	/// Optional typed per-window payload (e.g. UI context).
	public IRenderWindowData Data => mData;

	/// The fence for the current frame-in-flight slot. Useful for GPU
	/// readback tracking (e.g. thumbnail renderer waits on this fence
	/// to know when submitted work completes).
	public IFence CurrentFence => (mGraphicsDevice != null && mFences != null) ? mFences[mGraphicsDevice.CurrentFrame] : null;

	/// The fence value that EndFrame will signal for the current slot.
	/// Pass this to GPU readback tracking so it knows which value to
	/// wait for after the frame's submit completes.
	public uint64 NextFenceValue => (mGraphicsDevice != null && mFenceValues != null) ? mFenceValues[mGraphicsDevice.CurrentFrame] + 1 : 0;

	/// Attach a typed per-window payload. Disposes and deletes any previous data.
	public void SetData(IRenderWindowData data)
	{
		if (mData != null)
		{
			mData.Dispose();
			delete mData;
		}
		mData = data;
	}

	/// Built by GraphicsDevice.CreateRenderWindow; takes ownership of the RHI
	/// objects. Arrays are sized to framesInFlight.
	public this(GraphicsDevice device, IWindow window,
		ISurface surface, ISwapChain swapChain,
		ICommandPool[] pools, IFence[] fences)
	{
		mGraphicsDevice = device;
		mWindow = window;
		mSurface = surface;
		mSwapChain = swapChain;
		mPools = pools;
		mFences = fences;
		mWidth = (uint32)window.Width;
		mHeight = (uint32)window.Height;
		mFenceValues = new uint64[fences.Count];
	}

	public ~this()
	{
		let dev = mGraphicsDevice.Raw;
		if (dev != null) dev.WaitIdle();

		for (var pool in mPools)
		{
			if (pool != null)
				dev.DestroyCommandPool(ref pool);
		}
		for (var fence in mFences)
		{
			if (fence != null)
				dev.DestroyFence(ref fence);
		}
		if (mSwapChain != null)
		{
			var sc = mSwapChain;
			dev.DestroySwapChain(ref sc);
		}
		if (mSurface != null)
		{
			var sf = mSurface;
			dev.DestroySurface(ref sf);
		}

		if (mData != null)
		{
			mData.Dispose();
			delete mData;
		}

		delete mPools;
		delete mFences;
		delete mFenceValues;
	}

	/// Poll the window size; recreate the swapchain if it changed.
	/// Returns true when a resize happened.
	public bool SyncSize()
	{
		let nw = (uint32)mWindow.Width;
		let nh = (uint32)mWindow.Height;
		if (nw == 0 || nh == 0) return false;
		if (nw == mWidth && nh == mHeight) return false;
		mWidth = nw;
		mHeight = nh;
		mGraphicsDevice.Raw.WaitIdle();
		mSwapChain.Resize(nw, nh);
		return true;
	}

	/// Acquire this window's backbuffer and open a host-created encoder from
	/// the current frame's pool (after the per-window fence guards reuse).
	/// The returned FrameContext is invalid when the window is minimized/
	/// zero-sized or acquisition fails -- the caller skips rendering.
	public FrameContext BeginFrame()
	{
		if (mWindow.State == .Minimized || mWindow.Width == 0 || mWindow.Height == 0)
			return .();

		let fi = mGraphicsDevice.CurrentFrame;

		// Guard reuse of this slot's pool/backbuffer: wait the GPU's last
		// submission against this window's fence at this ring slot.
		if (mFenceValues[fi] > 0)
			mFences[fi].Wait(mFenceValues[fi]);

		if (mSwapChain.AcquireNextImage() case .Err)
			return .();

		mPools[fi].Reset();

		ICommandEncoder enc;
		if (mPools[fi].CreateEncoder() case .Ok(let e))
			enc = e;
		else
			return .();

		// Host-managed backbuffer transition (Undefined -> RenderTarget).
		enc.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);

		FrameContext f = .();
		f.Valid = true;
		f.Window = this;
		f.FrameIndex = fi;
		f.Width = (uint32)mWindow.Width;
		f.Height = (uint32)mWindow.Height;
		f.Encoder = enc;
		f.Pool = mPools[fi];
		f.Backbuffer = mSwapChain.CurrentTexture;
		f.BackbufferView = mSwapChain.CurrentTextureView;
		return f;
	}

	/// Transition the backbuffer to Present, submit (signalling the per-window
	/// fence), and present. No-op for an invalid frame.
	public void EndFrame(ref FrameContext frame)
	{
		if (!frame.Valid) return;
		let fi = frame.FrameIndex;

		frame.Encoder.TransitionTexture(mSwapChain.CurrentTexture,
			.RenderTarget, .Present);
		let cb = frame.Encoder.Finish();

		++mFenceValues[fi];
		ICommandBuffer[1] bufs = .(cb);
		mGraphicsDevice.GfxQueue.Submit(bufs, mFences[fi], mFenceValues[fi]);

		mSwapChain.Present(mGraphicsDevice.GfxQueue);

		var enc = frame.Encoder;
		mPools[fi].DestroyEncoder(ref enc);
		frame.Encoder = null;
	}
}
