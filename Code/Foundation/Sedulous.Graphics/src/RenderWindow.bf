using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.Shell;

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

	/// One per frame in flight, all owned.
	private List<ICommandPool> mPools = new .() ~ delete _;
	private List<IFence> mFences = new .() ~ delete _;
	private List<uint64> mFenceValues = new .() ~ delete _;

	private uint32 mWidth;
	private uint32 mHeight;
	private IRenderWindowData mData;

	/// Takes ownership of the RHI objects handed in. Built only by
	/// GraphicsDevice.CreateRenderWindow, which is what sizes the rings.
	public this(GraphicsDevice device, IWindow window, ISurface surface, ISwapChain swapChain,
		List<ICommandPool> pools, List<IFence> fences)
	{
		mDevice = device;
		mWindow = window;
		mSurface = surface;
		mSwapChain = swapChain;
		mPools.AddRange(pools);
		mFences.AddRange(fences);
		for (int i < mFences.Count)
			mFenceValues.Add(0);
		mWidth = window.Width;
		mHeight = window.Height;
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
	public ISwapChain Swap => mSwapChain;

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
		let width = mWindow.Width;
		let height = mWindow.Height;
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

		// After device loss, stop. Continuing spins through failing acquires and submits,
		// floods the log and stalls the machine. Loss is STICKY, so the window stays dark
		// until the host builds a new device.
		let device = mDevice.Raw;
		if ((device == null) || device.IsLost())
			return .();

		let frameIndex = mDevice.CurrentFrame;

		// Guard reuse of this slot: its pool and its back buffer are still the GPU's until
		// the fence this window signalled at this slot has been reached.
		if (mFenceValues[frameIndex] > 0)
			mFences[frameIndex].Wait(mFenceValues[frameIndex]);

		if (mSwapChain.AcquireNextImage() case .Err)
			return .();

		mPools[frameIndex].Reset();
		if (!(mPools[frameIndex].CreateEncoder() case .Ok(let encoder)))
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
		frame.Pool = mPools[frameIndex];
		frame.Backbuffer = mSwapChain.CurrentTexture;
		frame.BackbufferView = mSwapChain.CurrentTextureView;
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
		mFenceValues[frameIndex]++;
		var buffers = ICommandBuffer[1](commandBuffer);
		mDevice.GraphicsQueue.Submit(buffers, mFences[frameIndex], mFenceValues[frameIndex]);
		mSwapChain.Present(mDevice.GraphicsQueue).IgnoreError();

		var encoder = frame.Encoder;
		mPools[frameIndex].DestroyEncoder(ref encoder);
		frame.Encoder = null;
	}
}
