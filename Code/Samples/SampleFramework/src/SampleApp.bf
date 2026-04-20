namespace SampleFramework;

using System;
using SDL3;
using Sedulous.RHI;
using Sedulous.RHI.Validation;
using System.Collections;

/// Backend type selection.
enum BackendType
{
	Vulkan,
	DX12,
}

/// Abstract base class for all samples.
/// Handles window creation, event loop, backend/device/swap chain setup.
abstract class SampleApp
{
	protected SDL_Window* mWindow;
	protected IBackend mBackend;
	protected IDevice mDevice;
	protected IQueue mGraphicsQueue;
	protected ISurface mSurface;
	protected ISwapChain mSwapChain;

	protected uint32 mWidth = 1280;
	protected uint32 mHeight = 720;
	protected bool mRunning;
	protected bool mMinimized;
	protected float mDeltaTime;
	protected float mTotalTime;

	protected BackendType mBackendType;
	private bool mValidation;

	public this(BackendType backendType = .Vulkan, bool validation = true)
	{
		mBackendType = backendType;
		mValidation = validation;
	}

	/// Override to return the window title.
	protected virtual StringView Title => "Sedulous Sample";

	/// Override to initialize sample-specific resources.
	protected abstract Result<void> OnInit();

	/// Override to render a frame. Called every frame.
	protected abstract void OnRender();

	/// Override to handle resize.
	protected virtual void OnResize(uint32 width, uint32 height) { }

	/// Override to request device features (e.g. BindlessDescriptors).
	protected virtual DeviceFeatures RequiredFeatures => .();

	/// Override to clean up sample-specific resources.
	protected abstract void OnShutdown();

	/// Runs the application. Call from Main().
	public int Run()
	{
		if (Init() case .Err)
		{
			Shutdown();
			return 1;
		}

		MainLoop();
		Shutdown();
		return 0;
	}

	private Result<void> Init()
	{
		// Init SDL
		if (!SDL_Init(.SDL_INIT_VIDEO))
		{
			Console.WriteLine("ERROR: SDL_Init failed");
			return .Err;
		}

		// Create window
		let titleStr = scope String(Title);
		mWindow = SDL_CreateWindow(titleStr.CStr(), (.)mWidth, (.)mHeight,
			.SDL_WINDOW_RESIZABLE);
		if (mWindow == null)
		{
			Console.WriteLine("ERROR: SDL_CreateWindow failed");
			return .Err;
		}

		// Create backend
		if (CreateBackend() case .Err)
		{
			Console.WriteLine("ERROR: CreateBackend failed");
			return .Err;
		}

		// Create surface from native window handle
		let props = SDL_GetWindowProperties(mWindow);
		void* hwnd = SDL_GetPointerProperty(props, SDL_PROP_WINDOW_WIN32_HWND_POINTER, null);
		if (hwnd == null)
		{
			Console.WriteLine("ERROR: Failed to get HWND from SDL window");
			return .Err;
		}

		let surfaceResult = mBackend.CreateSurface(hwnd);
		if (surfaceResult case .Err)
		{
			Console.WriteLine("ERROR: CreateSurface failed");
			return .Err;
		}
		mSurface = surfaceResult.Value;

		// Pick first adapter and create device
		let adapters = scope List<IAdapter>();
		mBackend.EnumerateAdapters(adapters);
		if (adapters.IsEmpty)
		{
			Console.WriteLine("ERROR: No adapters found");
			return .Err;
		}

		let deviceResult = adapters[0].CreateDevice(DeviceDesc() { GraphicsQueueCount = 1, RequiredFeatures = RequiredFeatures });
		if (deviceResult case .Err)
		{
			Console.WriteLine("ERROR: CreateDevice failed");
			return .Err;
		}
		mDevice = deviceResult.Value;

		mGraphicsQueue = mDevice.GetQueue(.Graphics);
		if (mGraphicsQueue == null)
		{
			Console.WriteLine("ERROR: No graphics queue available");
			return .Err;
		}

		// Create swap chain
		if (CreateSwapChain() case .Err)
		{
			Console.WriteLine("ERROR: CreateSwapChain failed");
			return .Err;
		}

		// Sample-specific init
		return OnInit();
	}

	private Result<void> CreateBackend()
	{
		switch (mBackendType)
		{
		case .DX12:
			let result = Sedulous.RHI.DX12.DX12Backend.Create(mValidation);
			if (result case .Ok(let backend))
			{
				mBackend = mValidation ? CreateValidatedBackend(backend) : backend;
				return .Ok;
			}
			Console.WriteLine("ERROR: DX12Backend.Create failed");
			return .Err;

		case .Vulkan:
			let result = Sedulous.RHI.Vulkan.VulkanBackend.Create(mValidation);
			if (result case .Ok(let backend))
			{
				mBackend = mValidation ? CreateValidatedBackend(backend) : backend;
				return .Ok;
			}
			Console.WriteLine("ERROR: VulkanBackend.Create failed");
			return .Err;
		}
	}

	private Result<void> CreateSwapChain()
	{
		let desc = SwapChainDesc()
		{
			Width = mWidth,
			Height = mHeight,
			Format = .RGBA8UnormSrgb,
			PresentMode = .Fifo,
			BufferCount = 2,
		};

		let result = mDevice.CreateSwapChain(mSurface, desc);
		if (result case .Err)
		{
			Console.WriteLine("ERROR: Device.CreateSwapChain failed");
			return .Err;
		}
		mSwapChain = result.Value;
		return .Ok;
	}

	private void MainLoop()
	{
		mRunning = true;
		uint64 lastTime = SDL_GetPerformanceCounter();
		uint64 freq = SDL_GetPerformanceFrequency();

		while (mRunning)
		{
			// Poll events
			SDL_Event event = default;
			while (SDL_PollEvent(&event))
			{
				HandleEvent(ref event);
			}

			// Frame timing
			uint64 now = SDL_GetPerformanceCounter();
			mDeltaTime = (float)((double)(now - lastTime) / (double)freq);
			lastTime = now;
			mTotalTime += mDeltaTime;

			// Render (skip while minimized - no valid swapchain surface)
			if (!mMinimized)
			{
				CheckAndResize();
				OnRender();
			}
		}
	}

	private void HandleEvent(ref SDL_Event event)
	{
		switch ((SDL_EventType)event.type)
		{
		case .SDL_EVENT_QUIT:
			mRunning = false;

		case .SDL_EVENT_WINDOW_CLOSE_REQUESTED:
			mRunning = false;

		case .SDL_EVENT_WINDOW_MINIMIZED:
			mMinimized = true;

		case .SDL_EVENT_WINDOW_RESTORED:
			mMinimized = false;

		case .SDL_EVENT_WINDOW_RESIZED:
			CheckAndResize();

		default:
		}
	}

	private void CheckAndResize()
	{
		int32 w = 0, h = 0;
		SDL_GetWindowSizeInPixels(mWindow, &w, &h);
		let newWidth = (uint32)w;
		let newHeight = (uint32)h;
		if (newWidth > 0 && newHeight > 0 && (newWidth != mWidth || newHeight != mHeight))
		{
			mWidth = newWidth;
			mHeight = newHeight;
			mDevice.WaitIdle();
			mSwapChain.Resize(mWidth, mHeight);
			OnResize(mWidth, mHeight);
		}
	}

	private void Shutdown()
	{
		if (mDevice != null)
			mDevice.WaitIdle();

		OnShutdown();

		if (mSwapChain != null && mDevice != null)
			mDevice.DestroySwapChain(ref mSwapChain);

		if (mSurface != null && mDevice != null)
			mDevice.DestroySurface(ref mSurface);

		if (mDevice != null)
		{
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

		if (mWindow != null)
			SDL_DestroyWindow(mWindow);

		SDL_Quit();
	}
}
