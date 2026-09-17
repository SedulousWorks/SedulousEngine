using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// The WebGPU instance, the adapters on it, and the surfaces made from native windows.
sealed class WebGpuBackend : IBackend
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
#if BF_PLATFORM_WASM
		// A browser has neither piece of the desktop descriptor. InstanceExtras is a
		// wgpu-native extension whose sType means nothing to emdawnwebgpu, and SPIR-V
		// ingestion does not exist there at all: requesting it logs "ShaderSourceSPIRV
		// requested, but not supported in Wasm" and then hands back a WORKING instance
		// anyway, so the null check below would read that refusal as an acceptance.
		// Believing it makes PreferredShaderFormat answer SpirV, and the shader system then
		// asks a WGSL only pack for a format it does not carry.
		mInstance = wgpuCreateInstance(null);
		WebGpuApi.SpirvIngestion = false;
#else
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
#endif

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
		WebGpuCanvasSurfaceSource canvas = .();

		switch (platform)
		{
		case .Web:
			// The handle IS the selector, a null terminated CSS string the shell owns, not an
			// opaque pointer. WGPU_STRLEN tells wgpu to measure it rather than be given a
			// length, which is what keeps this from having to copy the string.
			canvas.Chain.sType = WebGpuCanvasSurfaceSource.SType;
			canvas.Selector = .() { data = (char8*)windowHandle, length = WGPU_STRLEN };
			desc.nextInChain = &canvas.Chain;

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

	/// The adapters, read once at bring up, and ORDERED.
	///
	/// Enumeration is a wgpu-native EXTENSION: the standard header can only request one
	/// adapter asynchronously by power preference, so a browser build will have to take
	/// that path instead. Count with a null array first, then fill.
	private void EnumerateNow()
	{
#if BF_PLATFORM_WASM
		// A browser cannot enumerate: navigator.gpu hands out ONE adapter, asynchronously,
		// chosen from a power preference. So there is nothing to rank or order, and the
		// environment pick has nothing to pick between.
		RequestAdapterNow();
		return;
#else
		let count = WebGpuApi.NativeOnly.EnumerateAdapters(mInstance, null);
		if (count == 0)
			return;

		let handles = scope WGPUAdapter[count];
		WebGpuApi.NativeOnly.EnumerateAdapters(mInstance, handles.Ptr);

		for (let handle in handles)
		{
			if (handle == null)
				continue;

			mAdapters.Add(new WebGpuAdapter(this, handle));
		}

		LogAdapters();
		if (!TakeEnvironmentPick())
			OrderByRank();

		for (let adapter in mAdapters)
			mAdapterHandles.Add(adapter);
#endif
	}

#if BF_PLATFORM_WASM
	/// The browser's single adapter, requested asynchronously and pumped until it lands.
	///
	/// HighPerformance is asked for rather than left default: a laptop otherwise gets the
	/// integrated GPU for a renderer that wants the discrete one, and the browser treats the
	/// preference as a hint it is free to ignore, so this is a request and not a demand.
	private void RequestAdapterNow()
	{
		WGPUAdapter handle = null;
		var done = false;

		WGPURequestAdapterOptions options = .();
		options.powerPreference = .WGPUPowerPreference_HighPerformance;

		WGPURequestAdapterCallbackInfo callback = .();
		callback.mode = WebGpuApi.cCallbackMode;
		callback.callback = (status, adapter, message, userdata1, userdata2) =>
			{
				*(WGPUAdapter*)userdata1 =
					(status == .WGPURequestAdapterStatus_Success) ? adapter : null;
				*(bool*)userdata2 = true;
			};
		callback.userdata1 = &handle;
		callback.userdata2 = &done;

		wgpuInstanceRequestAdapter(mInstance, &options, callback);
		WebGpuApi.PumpUntil(mInstance, ref done);

		if (handle == null)
		{
			GlobalLog(.Error, "[webgpu] no adapter. WebGPU may be unavailable in this browser.");
			return;
		}

		let adapter = new WebGpuAdapter(this, handle);
		mAdapters.Add(adapter);
		mAdapterHandles.Add(adapter);
		LogAdapters();
	}
#endif

	/// The host takes adapters[0], and wgpu's enumeration order is ARBITRARY. On Windows
	/// it routinely leads with an adapter that cannot PRESENT - a layered, software or
	/// non display GPU entry - and the swapchain then dies at configure with "Surface
	/// does not support the adapter's queue family".
	///
	/// So real GPUs go first: discrete, then integrated, then the rest, stable within a
	/// class because the insertion walks in enumeration order.
	private void OrderByRank()
	{
		let ordered = scope List<WebGpuAdapter>(mAdapters.Count);

		for (uint32 backend = 0; backend < 3; backend++)
		{
			for (uint32 rank = 0; rank < 4; rank++)
			{
				for (let adapter in mAdapters)
				{
					if ((BackendRank(adapter) == backend) && (ClassRank(adapter) == rank))
						ordered.Add(adapter);
				}
			}
		}

		mAdapters.Clear();
		mAdapters.AddRange(ordered);
	}

	/// One physical GPU appears once per wgpu backend. On WINDOWS prefer the D3D12 entry:
	/// DXGI present works on every adapter, while a Vulkan entry's queue family often
	/// cannot present on a hybrid machine and wgpu-native PANICS at configure. Elsewhere
	/// Vulkan and Metal are the real ones.
	private static uint32 BackendRank(WebGpuAdapter adapter)
	{
		let type = adapter.WgpuBackendType();

#if BF_PLATFORM_WINDOWS
		if (type == .WGPUBackendType_D3D12)
			return 0;
		if (type == .WGPUBackendType_Vulkan)
			return 1;
		return 2;
#else
		if ((type == .WGPUBackendType_Vulkan) || (type == .WGPUBackendType_Metal))
			return 0;
		return 1;
#endif
	}

	/// Software last, because it is never present capable.
	private static uint32 ClassRank(WebGpuAdapter adapter)
	{
		let info = scope AdapterInfo();
		adapter.GetInfo(info);

		switch (info.Type)
		{
		case .DiscreteGpu: return 0;
		case .IntegratedGpu: return 1;
		case .Unknown: return 2;
		default: return 3;
		}
	}

	/// Names every adapter, in enumeration order, because that order is what
	/// ENV_WEBGPU_ADAPTER indexes into.
	private void LogAdapters()
	{
		for (int i = 0; i < mAdapters.Count; i++)
		{
			let info = scope AdapterInfo();
			mAdapters[i].GetInfo(info);

			GlobalLog(.Information, "[webgpu] adapter {}: '{}' ({}, {})", i, info.Name,
				ClassName(info.Type), BackendName(mAdapters[i].WgpuBackendType()));
		}
	}

	/// The escape hatch for a hybrid GPU machine where the ranking still picks wrong:
	/// ENV_WEBGPU_ADAPTER is an index into the list just logged, and moves that one to
	/// the front INSTEAD of ranking. Returns whether it was honoured.
	private bool TakeEnvironmentPick()
	{
		let raw = scope String();
		if (Environment.GetEnvironmentVariable("ENV_WEBGPU_ADAPTER", raw) case .Err)
			return false;
		if (raw.IsEmpty)
			return false;

		if (int.Parse(raw) case .Ok(let index))
		{
			if ((index >= 0) && (index < mAdapters.Count))
			{
				let chosen = mAdapters[index];
				mAdapters.RemoveAt(index);
				mAdapters.Insert(0, chosen);
				GlobalLog(.Information, "[webgpu] ENV_WEBGPU_ADAPTER={}", index);
				return true;
			}
		}

		GlobalLog(.Error,
			"[webgpu] ENV_WEBGPU_ADAPTER is not a valid index into the list above - using the default order");
		return false;
	}

	private static StringView ClassName(AdapterType type)
	{
		switch (type)
		{
		case .DiscreteGpu: return "discrete";
		case .IntegratedGpu: return "integrated";
		case .Cpu: return "cpu";
		default: return "unknown";
		}
	}

	private static StringView BackendName(WGPUBackendType type)
	{
		switch (type)
		{
		case .WGPUBackendType_Vulkan: return "vulkan";
		case .WGPUBackendType_D3D12: return "d3d12";
		case .WGPUBackendType_Metal: return "metal";
		case .WGPUBackendType_OpenGL, .WGPUBackendType_OpenGLES: return "gl";
		default: return "?";
		}
	}
}

/// Bringing the WebGPU backend up.
static class WebGpuRhi
{
	/// A WebGPU backend, or an error when wgpu-native cannot make an instance. The CALLER
	/// owns what comes back.
	///
	/// No validation flag, unlike the Vulkan entry point: wgpu-native validates
	/// unconditionally and has no layer to switch on. ValidationRhi still wraps this the
	/// same way, and catches what it catches above the backend.
	public static Result<IBackend> CreateBackend()
	{
		let backend = new WebGpuBackend();
		if (backend.Initialize() case .Err)
		{
			delete backend;
			return .Err;
		}

		return .Ok(backend);
	}
}

