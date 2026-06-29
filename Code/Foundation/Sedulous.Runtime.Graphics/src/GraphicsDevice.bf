using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RHI.Validation;
using Sedulous.Shell;

namespace Sedulous.RuntimeGraphics;

/// The shared GPU: backend (optionally validation-wrapped) + adapter + logical
/// device + graphics queue, plus the CPU frame-in-flight ring index.
/// Created once for the whole app. Hands out RenderWindows.
class GraphicsDevice
{
	private IBackend mBackend;     // owned
	private IDevice mDevice;       // owned
	private IQueue mQueue;         // borrowed from device
	private uint32 mFramesInFlight;
	private uint32 mCurrentFrame = 0;

	/// The raw RHI device.
	public IDevice Raw => mDevice;

	/// The graphics queue.
	public IQueue GfxQueue => mQueue;

	/// Number of CPU-ahead frames in the ring buffer.
	public uint32 FramesInFlight => mFramesInFlight;

	/// Current CPU frame ring index (0..FramesInFlight-1).
	public uint32 CurrentFrame => mCurrentFrame;

	private this(IBackend backend, IDevice device, IQueue queue, uint32 framesInFlight)
	{
		mBackend = backend;
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
			if (let validated = mDevice as ValidatedDevice)
			{
				delete validated.Inner;
				delete validated;
			}
			else
				delete mDevice;
			mDevice = null;
		}
		if (mBackend != null)
		{
			mBackend.Destroy();
			if (let validated = mBackend as ValidatedBackend)
			{
				delete validated.Inner;
				delete validated;
			}
			else
				delete mBackend;
			mBackend = null;
		}
	}

	/// Create a GraphicsDevice: backend + adapter + logical device + queue.
	/// On failure, all partially created objects are cleaned up.
	public static Result<GraphicsDevice> Create(GraphicsDeviceDesc desc)
	{
		// 1. Create the backend
		IBackend rawBackend = null;
		switch (desc.Backend)
		{
		case .Vulkan:
			if (Sedulous.RHI.Vulkan.VulkanBackend.Create(desc.EnableValidation) case .Ok(let vkBackend))
				rawBackend = vkBackend;
		case .DX12:
			if (Sedulous.RHI.DX12.DX12Backend.Create(desc.EnableValidation) case .Ok(let dxBackend))
				rawBackend = dxBackend;
		default:
		}
		if (rawBackend == null)
			return .Err;

		// 2. Optionally wrap with validation
		IBackend backend = desc.EnableValidation
			? new ValidatedBackend(rawBackend)
			: rawBackend;

		// 3. Enumerate adapters (use the inner/unwrapped backend)
		IBackend innerBackend = backend;
		if (let validated = backend as ValidatedBackend)
			innerBackend = validated.Inner;

		List<IAdapter> adapters = scope .();
		innerBackend.EnumerateAdapters(adapters);
		if (adapters.IsEmpty)
		{
			Console.WriteLine("ERROR: No GPU adapters found");
			backend.Destroy();
			if (let validated = backend as ValidatedBackend)
			{
				delete validated.Inner;
				delete validated;
			}
			else
				delete backend;
			return .Err;
		}

		let adapterInfo = adapters[0].GetInfo();
		Console.WriteLine("Using adapter: {0}", adapterInfo.Name);
		delete adapterInfo;

		// 4. Create device
		DeviceDesc deviceDesc = .();
		deviceDesc.RequiredFeatures = desc.RequiredFeatures;

		IDevice rawDevice;
		if (adapters[0].CreateDevice(deviceDesc) case .Ok(let dev))
			rawDevice = dev;
		else
		{
			Console.WriteLine("ERROR: Failed to create device");
			backend.Destroy();
			if (let validated = backend as ValidatedBackend)
			{
				delete validated.Inner;
				delete validated;
			}
			else
				delete backend;
			return .Err;
		}

		IDevice device = desc.EnableValidation
			? new ValidatedDevice(rawDevice)
			: rawDevice;

		// 5. Get graphics queue
		let queue = device.GetQueue(.Graphics);
		if (queue == null)
		{
			device.Destroy();
			if (let vd = device as ValidatedDevice) { delete vd.Inner; delete vd; } else delete device;
			backend.Destroy();
			if (let vb = backend as ValidatedBackend) { delete vb.Inner; delete vb; } else delete backend;
			return .Err;
		}

		uint32 frames = (desc.FramesInFlight == 0) ? 1 : desc.FramesInFlight;
		return .Ok(new GraphicsDevice(backend, device, queue, frames));
	}

	/// Create a presentation target (surface + swapchain + per-frame pools/
	/// fences) for a window. The window must outlive the returned RenderWindow.
	public Result<RenderWindow> CreateRenderWindow(IWindow window, RenderWindowDesc desc)
	{
		// Create surface
		ISurface surface;
		if (mBackend.CreateSurface(window.NativeHandle) case .Ok(let s))
			surface = s;
		else
			return .Err;

		// Create swapchain
		SwapChainDesc sd = .()
		{
			Width = (uint32)window.Width,
			Height = (uint32)window.Height,
			Format = desc.Format,
			PresentMode = desc.PresentMode,
			BufferCount = desc.BufferCount
		};

		ISwapChain swapChain;
		if (mDevice.CreateSwapChain(surface, sd) case .Ok(let sc))
			swapChain = sc;
		else
		{
			var sf = surface;
			mDevice.DestroySurface(ref sf);
			return .Err;
		}

		// Create per-frame pools and fences
		ICommandPool[] pools = new ICommandPool[mFramesInFlight];
		IFence[] fences = new IFence[mFramesInFlight];

		for (uint32 i = 0; i < mFramesInFlight; i++)
		{
			ICommandPool pool;
			if (mDevice.CreateCommandPool(.Graphics) case .Ok(let p))
				pool = p;
			else
			{
				// Cleanup already created
				for (uint32 j = 0; j < i; j++)
				{
					var p2 = pools[j];
					mDevice.DestroyCommandPool(ref p2);
					var f2 = fences[j];
					if (f2 != null) mDevice.DestroyFence(ref f2);
				}
				delete pools;
				delete fences;
				var sc2 = swapChain;
				mDevice.DestroySwapChain(ref sc2);
				var sf2 = surface;
				mDevice.DestroySurface(ref sf2);
				return .Err;
			}
			pools[i] = pool;

			IFence fence;
			if (mDevice.CreateFence(0) case .Ok(let f))
				fence = f;
			else
			{
				// Cleanup: destroy the pool we just created + prior ones
				var p3 = pool;
				mDevice.DestroyCommandPool(ref p3);
				for (uint32 j = 0; j < i; j++)
				{
					var p2 = pools[j];
					mDevice.DestroyCommandPool(ref p2);
					var f2 = fences[j];
					mDevice.DestroyFence(ref f2);
				}
				delete pools;
				delete fences;
				var sc2 = swapChain;
				mDevice.DestroySwapChain(ref sc2);
				var sf2 = surface;
				mDevice.DestroySurface(ref sf2);
				return .Err;
			}
			fences[i] = fence;
		}

		return .Ok(new RenderWindow(this, window, surface, swapChain, pools, fences));
	}

	/// Advance the CPU frame ring once per app frame (after all windows are
	/// rendered). Consumers key per-frame GPU resources on CurrentFrame.
	public void AdvanceFrame()
	{
		mCurrentFrame = (mCurrentFrame + 1) % mFramesInFlight;
	}
}
