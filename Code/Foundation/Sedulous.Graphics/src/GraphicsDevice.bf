using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Sedulous.Shell;

namespace Sedulous.Graphics;

/// The SHARED GPU: a backend, a logical device, a graphics queue, and the CPU's frame
/// ring index.
///
/// Created once for the whole application and handed out to every window. Backend
/// agnostic: a GPU backend is built by GraphicsBackends and passed to FromBackend, which
/// is what keeps this free of any one backend's types.
class GraphicsDevice
{
	private IBackend mBackend;
	/// The unwrapped backend, which is what has to be destroyed: the validation wrapper
	/// borrows its inner, so both are kept.
	private IBackend mInnerBackend;
	private IDevice mDevice;
	private IQueue mQueue;
	private uint32 mFramesInFlight;
	private uint32 mCurrentFrame = 0;

	/// Takes ownership of `backend` and `innerBackend`; the queue is borrowed from the
	/// device. Built through FromBackend, which is what checks any of it.
	public this(IBackend backend, IBackend innerBackend, IDevice device, IQueue queue,
		uint32 framesInFlight)
	{
		mBackend = backend;
		mInnerBackend = innerBackend;
		mDevice = device;
		mQueue = queue;
		mFramesInFlight = framesInFlight;
	}

	public ~this()
	{
		if (mDevice != null)
		{
			mDevice.WaitIdle();
			mDevice.Destroy();
			mDevice = null;
		}
		// The wrapper borrowed the real backend, so the wrapper goes and the real one is
		// destroyed.
		if ((mBackend != null) && (mBackend !== mInnerBackend))
			delete mBackend;
		mBackend = null;
		if (mInnerBackend != null)
		{
			// Destroy tears the native state down and frees what the backend owns; the
			// OBJECT is the owner's to free.
			mInnerBackend.Destroy();
			delete mInnerBackend;
			mInnerBackend = null;
		}
	}

	/// Brings a device up on a backend that already exists: pick the adapter, create the
	/// logical device, take the graphics queue.
	///
	/// `backend` is what everything is reached through, and may be a validation wrapper;
	/// `innerBackend` is the real one underneath, which is the same object when nothing
	/// wrapped it. On failure BOTH are destroyed, so a caller never has to unwind a half
	/// built device.
	public static Result<GraphicsDevice> FromBackend(IBackend backend, IBackend innerBackend,
		uint32 framesInFlight, DeviceFeatures features = .())
	{
		if (backend == null)
		{
			GlobalLog(.Error, "GraphicsDevice.FromBackend: the backend is null");
			DestroyBackends(backend, innerBackend);
			return .Err;
		}

		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
		{
			GlobalLog(.Error, "GraphicsDevice.FromBackend: no adapters");
			DestroyBackends(backend, innerBackend);
			return .Err;
		}

		var desc = DeviceDesc();
		desc.GraphicsQueueCount = 1;
		desc.RequiredFeatures = features;
		// The backend ranks them, so the first is the best available GPU.
		if (!(adapters[0].CreateDevice(desc) case .Ok(let device)))
		{
			GlobalLog(.Error, "GraphicsDevice.FromBackend: the device could not be created");
			DestroyBackends(backend, innerBackend);
			return .Err;
		}

		let queue = device.GetQueue(.Graphics);
		if (queue == null)
		{
			GlobalLog(.Error, "GraphicsDevice.FromBackend: the device has no graphics queue");
			device.Destroy();
			DestroyBackends(backend, innerBackend);
			return .Err;
		}

#if BF_PLATFORM_WASM
		// ONE frame in flight on the web, whatever was asked for. A browser surface hands
		// out a SINGLE current texture that is reused every frame, and wgpuQueueSubmit
		// validates ASYNCHRONOUSLY. With more than one frame in flight the next frame's
		// AcquireNextImage releases that shared surface texture while the previous frame's
		// still pending submit references it: "Destroyed texture used in a submit", and the
		// submit is dropped. That is what silently kills the one shot IBL env bake and
		// leaves the sky black in a reflection probe.
		//
		// Serialised, BeginFrame's fence wait guarantees a frame's submit has completed
		// before the next acquire releases the surface texture.
		let frames = (uint32)1;
#else
		let frames = (framesInFlight == 0) ? (uint32)1 : framesInFlight;
#endif
		return .Ok(new GraphicsDevice(backend, innerBackend, device, queue, frames));
	}

	private static void DestroyBackends(IBackend backend, IBackend innerBackend)
	{
		if ((backend != null) && (backend !== innerBackend))
			delete backend;
		if (innerBackend != null)
		{
			innerBackend.Destroy();
			delete innerBackend;
		}
	}

	public IDevice Raw => mDevice;
	public IQueue GraphicsQueue => mQueue;
	public uint32 FramesInFlight => mFramesInFlight;
	public uint32 CurrentFrame => mCurrentFrame;

	/// Steps the CPU frame ring, ONCE per application frame after every window has been
	/// rendered. A consumer keys its per frame resources on CurrentFrame.
	public void AdvanceFrame() => mCurrentFrame = (mCurrentFrame + 1) % mFramesInFlight;

	/// A presentation target for a window: surface, swap chain, and the per frame pools
	/// and fences. The window must outlive what comes back.
	public Result<RenderWindow> CreateRenderWindow(IWindow window, RenderWindowDesc desc)
	{
		let native = window.Native;
		if (!(mBackend.CreateSurface(native.Window, native.Display, ToSurfacePlatform(native.System))
			case .Ok(var surface)))
			return .Err;

		var swapDesc = SwapChainDesc();
		swapDesc.Width = window.Width;
		swapDesc.Height = window.Height;
		swapDesc.Format = desc.Format;
		swapDesc.PresentMode = desc.PresentMode;
		swapDesc.BufferCount = desc.BufferCount;
		swapDesc.Label = "renderwindow";
		if (!(mDevice.CreateSwapChain(surface, swapDesc) case .Ok(var swapChain)))
		{
			mDevice.DestroySurface(ref surface);
			return .Err;
		}

		let pools = scope List<ICommandPool>();
		let fences = scope List<IFence>();
		for (uint32 i < mFramesInFlight)
		{
			if (!(mDevice.CreateCommandPool(.Graphics) case .Ok(let pool)))
			{
				UnwindRings(pools, fences, ref swapChain, ref surface);
				return .Err;
			}
			pools.Add(pool);

			if (!(mDevice.CreateFence(0) case .Ok(let fence)))
			{
				UnwindRings(pools, fences, ref swapChain, ref surface);
				return .Err;
			}
			fences.Add(fence);
		}

		return .Ok(new RenderWindow(this, window, surface, swapChain, pools, fences));
	}

	/// Frees a half built window. The lists are the caller's scratch, so what is in them
	/// is exactly what was created before the failure.
	private void UnwindRings(List<ICommandPool> pools, List<IFence> fences,
		ref ISwapChain swapChain, ref ISurface surface)
	{
		for (var pool in ref pools)
			mDevice.DestroyCommandPool(ref pool);
		for (var fence in ref fences)
			mDevice.DestroyFence(ref fence);
		mDevice.DestroySwapChain(ref swapChain);
		mDevice.DestroySurface(ref surface);
	}

	/// Which windowing system the shell ACTUALLY used, so the backend builds the matching
	/// surface rather than guessing: handing X11 handles to the Wayland entry point is the
	/// classic crash on a session that has both.
	private static SurfacePlatform ToSurfacePlatform(WindowSystem system)
	{
		switch (system)
		{
		case .Win32: return .Win32;
		case .X11: return .X11;
		case .Wayland: return .Wayland;
		case .Cocoa: return .Cocoa;
		// The browser. WITHOUT this the canvas fell through to Unknown, the backend was
		// handed a selector it was not told to read as one, the surface failed, and the
		// host registered no RenderWindow at all: every frame ticked and nothing ever
		// acquired a back buffer, which presents as a wholly black page and not one error.
		case .Web: return .Web;
		default: return .Unknown;
		}
	}
}
