using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// The WebGPU instance, the adapters on it, and the surfaces made from native windows.
class WebGpuBackend : IBackend
{
	private WGPUInstance mInstance;
	private bool mInitialized = false;

	private List<WebGpuAdapter> mAdapters = new .() ~ DeleteContainerAndItems!(_);
	private List<IAdapter> mAdapterHandles = new .() ~ delete _;
	private List<WebGpuSurface> mSurfaces = new .() ~ DeleteContainerAndItems!(_);

	public bool IsInitialized => mInitialized;
	public WGPUInstance Instance => mInstance;

	public Result<void> Initialize()
	{
		// Keep GL OUT of the instance. Left unset, wgpu-native enables every backend
		// including GL, whose WGL instance thread on Windows dies with a fatal callback
		// exception when an instance is created and torn down without the event loop
		// being pumped in between. Adapter choice is Vulkan or DX12, so nothing is lost.
		//
		// The extension STypes are a separate enum that extends the standard range, and
		// the chain field is typed as the standard one, so the value is cast across.
		WGPUInstanceExtras extras = .();
		extras.chain.sType = (WGPUSType)WGPUNativeSType.WGPUSType_InstanceExtras;
		extras.backends = WGPUInstanceBackend_Primary;

		// SPIRV ingestion is a STANDARD instance feature and the desktop DXC loop rides
		// on it. There is no way to ask whether it is available first, because
		// wgpuGetInstanceFeatures panics "not implemented" in wgpu-native v29 exactly as
		// WaitAny does, so it is requested optimistically and refused politely.
		WGPUInstanceFeatureName spirv = .WGPUInstanceFeatureName_ShaderSourceSPIRV;

		WGPUInstanceDescriptor desc = .();
		desc.nextInChain = &extras.chain;
		desc.requiredFeatureCount = 1;
		desc.requiredFeatures = &spirv;

		mInstance = wgpuCreateInstance(&desc);
		WebGpuApi.SpirvIngestion = mInstance != null;

		if (mInstance == null)
		{
			// Refused. A plain instance, with GL still kept out of it.
			desc = .();
			desc.nextInChain = &extras.chain;
			mInstance = wgpuCreateInstance(&desc);
		}

		if (mInstance == null)
		{
			GlobalLog(.Error, "WebGpuBackend: wgpuCreateInstance returned null");
			return .Err;
		}

		EnumerateNow();
		mInitialized = true;
		return .Ok;
	}

	public Span<IAdapter> EnumerateAdapters()
	{
		return mAdapterHandles;
	}

	public Result<ISurface> CreateSurface(void* windowHandle, void* displayHandle,
		SurfacePlatform platform = .Unknown)
	{
		if (mInstance == null)
			return .Err;

		WGPUSurfaceDescriptor desc = .();

		// EXACTLY ONE platform source chains in. Each is declared out here so the one
		// that gets chained outlives the call that reads it.
		WGPUSurfaceSourceXlibWindow xlib = .();
		WGPUSurfaceSourceWaylandSurface wayland = .();
		WGPUSurfaceSourceWindowsHWND win32 = .();

		switch (platform)
		{
		case .X11:
			xlib.chain.sType = .WGPUSType_SurfaceSourceXlibWindow;
			xlib.display = displayHandle;
			xlib.window = (uint64)(int)windowHandle; // the XID, carried as a pointer
			desc.nextInChain = &xlib.chain;

		case .Wayland:
			wayland.chain.sType = .WGPUSType_SurfaceSourceWaylandSurface;
			wayland.display = displayHandle;
			wayland.surface = windowHandle;
			desc.nextInChain = &wayland.chain;

		case .Win32:
			win32.chain.sType = .WGPUSType_SurfaceSourceWindowsHWND;
			win32.hwnd = windowHandle;
			desc.nextInChain = &win32.chain;

		default:
			// Unknown is a best guess: X11 when a display came with it, else there is
			// nothing to guess from.
			if (displayHandle == null)
				return .Err;

			xlib.chain.sType = .WGPUSType_SurfaceSourceXlibWindow;
			xlib.display = displayHandle;
			xlib.window = (uint64)(int)windowHandle;
			desc.nextInChain = &xlib.chain;
		}

		let handle = wgpuInstanceCreateSurface(mInstance, &desc);
		if (handle == null)
			return .Err;

		let surface = new WebGpuSurface(handle);
		mSurfaces.Add(surface);
		return .Ok(surface);
	}

	public void Destroy()
	{
		ClearAndDeleteItems!(mSurfaces);

		ClearAndDeleteItems!(mAdapters);
		mAdapterHandles.Clear();

		if (mInstance != null)
		{
			wgpuInstanceRelease(mInstance);
			mInstance = null;
		}

		mInitialized = false;
	}

	/// The adapters, read once at bring up.
	///
	/// Enumeration is a wgpu-native EXTENSION: the standard header can only request one
	/// adapter asynchronously by power preference, so a browser build will have to take
	/// that path instead. Count with a null array first, then fill.
	private void EnumerateNow()
	{
		let count = WebGpuApi.NativeOnly.EnumerateAdapters(mInstance, null);
		if (count == 0)
			return;

		let handles = scope WGPUAdapter[count];
		WebGpuApi.NativeOnly.EnumerateAdapters(mInstance, handles.Ptr);

		for (let handle in handles)
		{
			if (handle == null)
				continue;

			let adapter = new WebGpuAdapter(this, handle);
			mAdapters.Add(adapter);
			mAdapterHandles.Add(adapter);
		}
	}
}
