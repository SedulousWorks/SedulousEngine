using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Shell;
using Sedulous.Profiler; // ProfileScope: a frame's two waits apart

namespace Sedulous.Graphics;

/// One window's presentation target: its surface, its swap chain, and a per frame ring
/// of command pools and fences.
///
/// Created and destroyed at runtime through the GraphicsDevice that made it, which is
/// what makes a detachable window possible. The main window is simply the first one.
class RenderWindow
{
	private GraphicsDevice mDevice;
	private IWindow mWindow;
	private ISurface mSurface;
	private ISwapChain mSwapChain;
	/// What the swap chain is made as, again after Suspend.
	private RenderWindowDesc mDesc;

	/// One per frame in flight, all owned.
	private List<ICommandPool> mPools = new .() ~ delete _;
	private List<IFence> mFences = new .() ~ delete _;
	private List<uint64> mFenceValues = new .() ~ delete _;

	private uint32 mWidth;
	private uint32 mHeight;
	private IRenderWindowData mData;

	/// Takes ownership of the RHI objects handed in. Built only by
	/// GraphicsDevice.CreateRenderWindow, which is what sizes the rings.
	public this(GraphicsDevice device, IWindow window, RenderWindowDesc desc, ISurface surface, ISwapChain swapChain,
		List<ICommandPool> pools, List<IFence> fences)
	{
		mDevice = device;
		mWindow = window;
		mDesc = desc;
		mSurface = surface;
		mSwapChain = swapChain;
		mPools.AddRange(pools);
		mFences.AddRange(fences);
		for (int i < mFences.Count)
			mFenceValues.Add(0);
		mWidth = window.PixelWidth;
		mHeight = window.PixelHeight;
	}

	public ~this()
	{
		let device = mDevice.Raw;
		if (device != null)
		{
			// Everything below is still referenced by whatever the GPU has in flight.
			device.WaitIdle();

			for (var pool in ref mPools)
			{
				if (pool != null)
					device.DestroyCommandPool(ref pool);
			}
			for (var fence in ref mFences)
			{
				if (fence != null)
					device.DestroyFence(ref fence);
			}
			if (mSwapChain != null)
				device.DestroySwapChain(ref mSwapChain);
			if (mSurface != null)
				device.DestroySurface(ref mSurface);
		}

		if (mData != null)
		{
			delete mData;
			mData = null;
		}
	}

	public IWindow Window => mWindow;
	/// Null while suspended.
	public ISwapChain Swap => mSwapChain;

	/// Lets go of the surface and swap chain, once the GPU is done with them: the app is going to
	/// the background, where a phone's platform takes the window's surface away. The next frame
	/// makes them again from the window's native handle as it is then, or, while the window has
	/// none, is skipped, and so on until it has one.
	public void Suspend()
	{
		let device = mDevice.Raw;
		if ((device == null) || (mSwapChain == null))
			return;
		device.WaitIdle();
		device.DestroySwapChain(ref mSwapChain);
		if (mSurface != null)
			device.DestroySurface(ref mSurface);
	}

	public bool IsSuspended => mSwapChain == null;

	/// The typed payload, OWNED: setting a second one deletes the first, and the window
	/// deletes what it holds.
	public IRenderWindowData Data
	{
		get => mData;
		set
		{
			if (mData === value)
				return;
			if (mData != null)
				delete mData;
			mData = value;
		}
	}

	/// Polls the window's size and rebuilds the swap chain when it changed, returning
	/// whether it did.
	///
	/// POLLED rather than event driven, so a host needs no event handler and a window
	/// manager that resizes without telling anyone still works.
	public bool SyncSize()
	{
		// Suspended: BeginFrame makes the swap chain at the window's size.
		if (mSwapChain == null)
			return false;
		let width = mWindow.PixelWidth;
		let height = mWindow.PixelHeight;
		if ((width == 0) || (height == 0))
			return false;
		if ((width == mWidth) && (height == mHeight))
			return false;

		mWidth = width;
		mHeight = height;
		// The old back buffers may still be in flight, and resizing frees them.
		mDevice.Raw.WaitIdle();
		mSwapChain.Resize(width, height).IgnoreError();
		return true;
	}

	/// Waits this ring slot free, acquires the back buffer, and opens an encoder on the
	/// slot's pool.
	///
	/// An INVALID frame comes back when there is nothing to render into, and the caller
	/// simply skips the window rather than treating it as a failure.
	public FrameContext BeginFrame()
	{
		if (mWindow.IsMinimized || (mWindow.Width == 0) || (mWindow.Height == 0))
			return .();

		// Suspended: make the surface and swap chain again once the window has a native handle. A
		// phone's window has none from when the platform takes its surface until it gives a new
		// one, around when the app comes back.
		if (mSwapChain == null)
		{
			let raw = mDevice.Raw;
			if ((raw == null) || raw.IsLost() || (mWindow.Native.Window == null) ||
				!mDevice.MakePresentation(mWindow, mDesc, out mSurface, out mSwapChain))
				return .();
			mWidth = mWindow.PixelWidth;
			mHeight = mWindow.PixelHeight;
		}

		// After device loss, stop. Continuing spins through failing acquires and submits,
		// floods the log and stalls the machine. Loss is STICKY, so the window stays dark
		// until the host builds a new device.
		let device = mDevice.Raw;
		if ((device == null) || device.IsLost())
			return .();

		let frameIndex = mDevice.CurrentFrame;

		// Timed apart, as their causes differ: the fence is the GPU still on the frame that last
		// used this slot (ours to fix); the image is the compositor not yet giving one back (vsync,
		// or the display stalled).
		using (ProfileScope("Render.Acquire.Fence"))
		{
			// Guard reuse of this slot: its pool and its back buffer are still the GPU's until
			// the fence this window signalled at this slot has been reached.
			if (mFenceValues[(int)frameIndex] > 0)
				mFences[(int)frameIndex].Wait(mFenceValues[(int)frameIndex]);
		}

		using (ProfileScope("Render.Acquire.Image"))
		{
			if (mSwapChain.AcquireNextImage() case .Err)
				return .();
		}

		mPools[(int)frameIndex].Reset();
		if (!(mPools[(int)frameIndex].CreateEncoder() case .Ok(let encoder)))
			return .();

		// The host owns the back buffer's state, so the transition into it happens here
		// rather than in whatever records the contents.
		encoder.TransitionTexture(mSwapChain.CurrentTexture, .Undefined, .RenderTarget);

		var frame = FrameContext();
		frame.Valid = true;
		frame.Window = this;
		frame.FrameIndex = frameIndex;
		frame.Width = mSwapChain.Width;
		frame.Height = mSwapChain.Height;
		frame.Encoder = encoder;
		frame.Pool = mPools[(int)frameIndex];
		frame.Backbuffer = mSwapChain.CurrentTexture;
		frame.BackbufferView = mSwapChain.CurrentTextureView;
		frame.BackbufferAlternateView = mSwapChain.CurrentAlternateTextureView;
		return frame;
	}

	/// Transitions the back buffer to Present, submits against this slot's fence, and
	/// presents. A no op for an invalid frame, so a caller need not branch.
	public void EndFrame(ref FrameContext frame)
	{
		if (!frame.Valid)
			return;

		let frameIndex = frame.FrameIndex;
		frame.Encoder.TransitionTexture(mSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commandBuffer = frame.Encoder.Finish();
		mFenceValues[(int)frameIndex]++;
		var buffers = ICommandBuffer[1](commandBuffer);
		mDevice.GraphicsQueue.Submit(buffers, mFences[(int)frameIndex], mFenceValues[(int)frameIndex]);
		mSwapChain.Present(mDevice.GraphicsQueue).IgnoreError();

		var encoder = frame.Encoder;
		mPools[(int)frameIndex].DestroyEncoder(ref encoder);
		frame.Encoder = null;
	}
}
