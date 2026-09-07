using System;
using System.Diagnostics;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Validation;
using Sedulous.RHI.Vulkan;
using Sedulous.Shaders;
using Sedulous.Shell;
using Sedulous.Shell.SDL3;

namespace Samples.Framework;

/// The base every RHI sample derives from.
///
/// Brings up a window, a backend, a device, a queue and a swap chain; pumps events, tracks
/// timing, and calls OnRender. A sample supplies only what it actually draws.
///
/// Validation is ON by default. These are development samples, and a sample that renders
/// something wrong is far more useful when the layer says why.
abstract class SampleApp
{
	protected SDL3Shell mShell = null;
	protected IWindow mWindow = null;
	protected IBackend mBackend = null;
	/// The unwrapped backend, which is what has to be destroyed: the validation wrapper
	/// borrows it rather than owning it.
	private IBackend mInnerBackend = null;
	protected IDevice mDevice = null;
	protected IQueue mGraphicsQueue = null;
	protected ISurface mSurface = null;
	protected ISwapChain mSwapChain = null;

	protected uint32 mWidth = 1280;
	protected uint32 mHeight = 720;
	protected bool mRunning = false;
	protected float mDeltaTime = 0.0f;
	protected float mTotalTime = 0.0f;

	private BackendType mBackendType;
	private bool mValidationEnabled;

	public this(BackendType backend = .Vulkan, bool validation = true)
	{
		mBackendType = backend;
		mValidationEnabled = validation;
	}

	// ---- what a sample overrides ----

	protected virtual StringView Title => "RHI Sample";
	protected virtual DeviceFeatures RequiredFeatures => .();
	protected virtual TextureFormat SwapChainFormat => .RGBA8UnormSrgb;
	protected virtual PresentMode PresentMode => .Fifo;
	protected virtual uint32 BufferCount => 2;

	protected abstract Result<void> OnInit();
	protected abstract void OnRender();
	protected virtual void OnResize(uint32 width, uint32 height) {}
	protected abstract void OnShutdown();

	protected void Exit() => mRunning = false;

	/// Runs the sample to completion, returning a process exit code.
	public int Run(String[] args = null)
	{
		ParseArguments(args);

		if (Initialize() case .Err)
		{
			Shutdown();
			return 1;
		}
		MainLoop();
		Shutdown();
		return 0;
	}

	/// The backend and validation flags.
	///
	/// One built sample can then be pointed at whichever backend a machine has, rather than
	/// needing a build per backend.
	private void ParseArguments(String[] args)
	{
		if (args == null)
			return;

		for (let argument in args)
		{
			switch (argument)
			{
			case "--dx12", "--d3d12": mBackendType = .DX12;
			case "--webgpu", "--wgpu": mBackendType = .WebGPU;
			case "--vk", "--vulkan": mBackendType = .Vulkan;
			case "--novalidation": mValidationEnabled = false;
			default:
			}
		}
	}

	private Result<void> Initialize()
	{
		var settings = WindowSettings();
		settings.Title = Title;
		settings.Width = mWidth;
		settings.Height = mHeight;

		mShell = new SDL3Shell(settings);
		mWindow = mShell.MainWindow;
		if (mWindow == null)
		{
			Console.Error.WriteLine("SampleApp: the shell produced no window");
			return .Err;
		}
		// The shell may not have honoured the requested size, so the real one is taken back.
		mWidth = mWindow.Width;
		mHeight = mWindow.Height;

		if (CreateBackend() case .Err)
			return .Err;
		if (CreateSurface() case .Err)
			return .Err;
		if (CreateDevice() case .Err)
			return .Err;
		if (CreateSwapChain() case .Err)
			return .Err;

		return OnInit();
	}

	private Result<void> CreateBackend()
	{
		switch (mBackendType)
		{
		case .Vulkan:
			if (!(VulkanRhi.CreateBackend(mValidationEnabled) case .Ok(let backend)))
			{
				Console.Error.WriteLine("SampleApp: the Vulkan backend could not be created");
				return .Err;
			}
			mInnerBackend = backend;
		case .DX12:
			Console.Error.WriteLine("SampleApp: the DX12 backend is not ported yet");
			return .Err;
		case .WebGPU:
			Console.Error.WriteLine("SampleApp: the WebGPU backend is not ported yet");
			return .Err;
		}

		// The wrapper BORROWS the real backend, so both are kept: one to use, one to destroy.
		mBackend = mValidationEnabled ? ValidationRhi.Wrap(mInnerBackend) : mInnerBackend;
		return .Ok;
	}

	/// Builds the surface against the windowing system the shell ACTUALLY used.
	///
	/// Not the one the platform might suggest: handing X11 handles to the Wayland entry
	/// point is the classic crash on a session that has both.
	private Result<void> CreateSurface()
	{
		let native = mWindow.Native;
		SurfacePlatform platform = .Unknown;
		switch (native.System)
		{
		case .Win32: platform = .Win32;
		case .X11: platform = .X11;
		case .Wayland: platform = .Wayland;
		case .Cocoa: platform = .Cocoa;
		default:
		}

		if (!(mBackend.CreateSurface(native.Window, native.Display, platform)
			case .Ok(let surface)))
		{
			Console.Error.WriteLine("SampleApp: the surface could not be created");
			return .Err;
		}
		mSurface = surface;
		return .Ok;
	}

	private Result<void> CreateDevice()
	{
		let adapters = mBackend.EnumerateAdapters();
		if (adapters.IsEmpty)
		{
			Console.Error.WriteLine("SampleApp: no adapters");
			return .Err;
		}
		// The backend ranks them, so the first is the best available GPU.
		let adapter = adapters[0];

		let info = scope AdapterInfo();
		adapter.GetInfo(info);
		Console.WriteLine(scope $"SampleApp: backend={mBackendType} adapter={info.Name}");

		var desc = DeviceDesc();
		desc.GraphicsQueueCount = 1;
		desc.RequiredFeatures = RequiredFeatures;
		if (!(adapter.CreateDevice(desc) case .Ok(let device)))
		{
			Console.Error.WriteLine("SampleApp: the device could not be created");
			return .Err;
		}
		mDevice = device;

		mGraphicsQueue = mDevice.GetQueue(.Graphics);
		if (mGraphicsQueue == null)
		{
			Console.Error.WriteLine("SampleApp: the device has no graphics queue");
			return .Err;
		}
		return .Ok;
	}

	private Result<void> CreateSwapChain()
	{
		var desc = SwapChainDesc();
		desc.Width = mWidth;
		desc.Height = mHeight;
		desc.Format = SwapChainFormat;
		desc.PresentMode = PresentMode;
		desc.BufferCount = BufferCount;
		desc.Label = "main";

		if (!(mDevice.CreateSwapChain(mSurface, desc) case .Ok(let swapChain)))
		{
			Console.Error.WriteLine("SampleApp: the swap chain could not be created");
			return .Err;
		}
		mSwapChain = swapChain;
		return .Ok;
	}

	private void MainLoop()
	{
		mRunning = true;

		let clock = scope Stopwatch(true);
		var lastSeconds = 0.0;

		while (mRunning && mShell.IsRunning)
		{
			mShell.ProcessEvents();

			let nowSeconds = clock.Elapsed.TotalSeconds;
			mDeltaTime = (float)(nowSeconds - lastSeconds);
			lastSeconds = nowSeconds;
			mTotalTime += mDeltaTime;

			// A minimised window has no extent, so there is nothing to render into and a
			// swap chain cannot even be rebuilt for it.
			if (!mWindow.IsMinimized)
			{
				CheckAndResize();
				OnRender();
			}
		}
	}

	/// Resize is POLLED rather than driven by an event, so a sample needs no event handler
	/// of its own and a window manager that resizes without telling us still works.
	private void CheckAndResize()
	{
		let width = mWindow.Width;
		let height = mWindow.Height;
		if ((width == 0) || (height == 0))
			return;
		if ((width == mWidth) && (height == mHeight))
			return;

		mWidth = width;
		mHeight = height;
		// The old back buffers may still be in flight, and resizing frees them.
		mDevice.WaitIdle();
		mSwapChain.Resize(mWidth, mHeight).IgnoreError();
		OnResize(mWidth, mHeight);
	}

	private void Shutdown()
	{
		// Everything below is destroyed while the GPU may still be using it, so the device
		// is drained first.
		if (mDevice != null)
			mDevice.WaitIdle();

		OnShutdown();

		if (mSwapChain != null)
			mDevice.DestroySwapChain(ref mSwapChain);
		if (mSurface != null)
			mDevice.DestroySurface(ref mSurface);
		if (mDevice != null)
		{
			mDevice.Destroy();
			mDevice = null;
		}
		// The validation wrapper borrowed the real backend, so the wrapper goes and the
		// real one is destroyed.
		if ((mBackend != null) && (mBackend !== mInnerBackend))
			delete mBackend;
		mBackend = null;
		if (mInnerBackend != null)
		{
			mInnerBackend.Destroy();
			mInnerBackend = null;
		}

		if (mShell != null)
		{
			delete mShell;
			mShell = null;
			mWindow = null;
		}
	}
}
