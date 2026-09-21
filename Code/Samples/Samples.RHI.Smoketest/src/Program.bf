using System;
using Sedulous.Core;
using Sedulous.RHI;
using Sedulous.RHI.Null;
using Sedulous.RHI.Validation;
using Sedulous.RHI.Vulkan;
using Sedulous.RHI.WebGPU;
#if BF_PLATFORM_WINDOWS
// The namespace itself does not exist off Windows: every file in that backend is compiled out.
using Sedulous.RHI.DX12;
#endif
using Sedulous.Shell;
using Sedulous.Shell.SDL3;

namespace Samples.RHI.Smoketest;

/// Creates one of everything the RHI offers, prints what came back, and destroys it.
///
/// Not a rendering sample: nothing is drawn beyond a bare transition to Present, and the
/// point is that every create and destroy pair on every backend survives being called for
/// real. It is what gets run first on a new machine, or after a backend change, to say
/// whether the backend is alive at all before a sample is blamed for anything.
class Program
{
	/// A no-op SPIR-V fragment shader: a module has to be created from SOMETHING, and this
	/// is the smallest blob a driver will accept.
	private static uint32[32] cSpvNoop = .(
		0x07230203, 0x00010000, 0x00080001, 0x00000005, 0x00000000, 0x00020011, 0x00000001,
		0x0003000E, 0x00000000, 0x00000001, 0x0005000F, 0x00000004, 0x00000001, 0x6E69616D,
		0x00000000, 0x00030010, 0x00000001, 0x00000007, 0x00020013, 0x00000002, 0x00030021,
		0x00000003, 0x00000002, 0x00050036, 0x00000002, 0x00000001, 0x00000000, 0x00000003,
		0x000200F8, 0x00000004, 0x000100FD, 0x00010038);

	public static int Main(String[] args)
	{
		var settings = WindowSettings();
		settings.Title = "RHI Smoketest";
		settings.Width = 1280;
		settings.Height = 720;

		let shell = scope SDL3Shell(settings);
		let window = shell.MainWindow;
		if (window == null)
		{
			Console.Error.WriteLine("shell/window init failed");
			return 1;
		}

		let native = window.Native;
		if (native.Window == null)
		{
			Console.Error.WriteLine("no native handle on shell window");
			return 1;
		}

		if (RunVulkan(native) case .Err)
			return 1;

		Console.WriteLine("\n=== WebGPU Backend ===");
		RunWebGpu();

		Console.WriteLine("\n=== DX12 Backend ===");
		RunDx12();

		Console.WriteLine("\n=== Null Backend ===");
		RunNull();
		return 0;
	}

	private static Result<void> RunVulkan(NativeWindow native)
	{
		if (!(VulkanRhi.CreateBackend(true) case .Ok(let rawBackend)))
		{
			Console.Error.WriteLine("createBackend failed");
			return .Err;
		}
		// The wrapper BORROWS the real backend, so both are kept: one to use, one to
		// destroy.
		let backend = ValidationRhi.Wrap(rawBackend);
		defer
		{
			delete backend;
			rawBackend.Destroy();
			delete rawBackend;
		}

		let adapters = backend.EnumerateAdapters();
		if (adapters.IsEmpty)
			return .Err;

		let chosen = adapters[0];
		let adapterInfo = scope AdapterInfo();
		chosen.GetInfo(adapterInfo);
		Console.WriteLine(scope $"adapter: {adapterInfo.Name} ({AdapterTypeName(adapterInfo.Type)})");

		var deviceDesc = DeviceDesc();
		deviceDesc.GraphicsQueueCount = 1;
		deviceDesc.ComputeQueueCount = 1;
		deviceDesc.TransferQueueCount = 1;
		deviceDesc.RequiredFeatures.MeshShaders = adapterInfo.SupportedFeatures.MeshShaders;
		if (!(chosen.CreateDevice(deviceDesc) case .Ok(let device)))
		{
			Console.Error.WriteLine("createDevice failed");
			return .Err;
		}

		if (!(backend.CreateSurface(native.Window, native.Display, SurfacePlatformOf(native))
			case .Ok(var surface)))
		{
			Console.Error.WriteLine("createSurface failed");
			device.Destroy();
			return .Err;
		}
		Console.WriteLine("surface created");

		var swapDesc = SwapChainDesc();
		swapDesc.Width = 1280;
		swapDesc.Height = 720;
		swapDesc.Format = .BGRA8UnormSrgb;
		swapDesc.PresentMode = .Fifo;
		swapDesc.BufferCount = 2;
		swapDesc.Label = "main";
		if (!(device.CreateSwapChain(surface, swapDesc) case .Ok(var swapChain)))
		{
			Console.Error.WriteLine("createSwapChain failed");
			device.DestroySurface(ref surface);
			device.Destroy();
			return .Err;
		}
		Console.WriteLine(scope $"swap chain: {swapChain.Width}x{swapChain.Height}, bufferCount={swapChain.BufferCount}");

		CheckBuffer(device);
		CheckSampler(device);
		CheckShaderModule(device);
		CheckLayoutsAndCache(device);

		var pool = CheckCommandPool(device);
		var fence = CheckFence(device);
		var querySet = CheckQuerySet(device);

		RunFrames(device, swapChain, pool, fence);
		ReportFeatures(device);
		CheckShaderCompiler();

		if (querySet != null)
			device.DestroyQuerySet(ref querySet);
		if (fence != null)
			device.DestroyFence(ref fence);
		if (pool != null)
			device.DestroyCommandPool(ref pool);

		device.WaitIdle();
		device.DestroySwapChain(ref swapChain);
		device.DestroySurface(ref surface);
		device.Destroy();
		return .Ok;
	}

	/// A mapped uniform buffer: the create, the map, and a write through the pointer.
	private static void CheckBuffer(IDevice device)
	{
		var desc = BufferDesc();
		desc.Size = 1024;
		desc.Usage = .Uniform | .CopyDst;
		desc.Memory = .CpuToGpu;
		desc.Label = "smoketest_uniform";
		if (!(device.CreateBuffer(desc) case .Ok(var buffer)))
		{
			Console.Error.WriteLine("createBuffer failed");
			return;
		}

		let mapped = buffer.Map();
		Console.WriteLine(scope $"uniform buffer: size={buffer.Size} mapped=0x{(int)(void*)mapped:X}");
		if (mapped != null)
			Internal.MemSet(mapped, 0xAB, 16);
		buffer.Unmap();
		device.DestroyBuffer(ref buffer);
	}

	private static void CheckSampler(IDevice device)
	{
		var desc = SamplerDesc();
		desc.MaxAnisotropy = 16;
		desc.Label = "smoketest_sampler";
		if (!(device.CreateSampler(desc) case .Ok(var sampler)))
		{
			Console.Error.WriteLine("createSampler failed");
			return;
		}
		Console.WriteLine(scope $"sampler created (aniso={sampler.Desc.MaxAnisotropy})");
		device.DestroySampler(ref sampler);
	}

	private static void CheckShaderModule(IDevice device)
	{
		var desc = ShaderModuleDesc();
		desc.Code = .((uint8*)&cSpvNoop[0], cSpvNoop.Count * sizeof(uint32));
		desc.Label = "smoketest_noop_fs";
		if (!(device.CreateShaderModule(desc) case .Ok(var module)))
		{
			Console.Error.WriteLine("createShaderModule failed");
			return;
		}
		Console.WriteLine(scope $"shader module created ({desc.Code.Length} bytes)");
		device.DestroyShaderModule(ref module);
	}

	/// The bind group layout, the pipeline layout over it, and a cold pipeline cache.
	///
	/// Together rather than separately because the pipeline layout NAMES the bind group
	/// layout, so the three have to be destroyed in the reverse order they were made.
	private static void CheckLayoutsAndCache(IDevice device)
	{
		var entries = BindGroupLayoutEntry[2](
			BindGroupLayoutEntry.UniformBuffer(0, .Vertex),
			BindGroupLayoutEntry.SampledTexture(1, .Fragment));

		var bglDesc = BindGroupLayoutDesc();
		bglDesc.Entries = entries;
		bglDesc.Label = "smoketest_bgl";
		if (!(device.CreateBindGroupLayout(bglDesc) case .Ok(var bindGroupLayout)))
		{
			Console.Error.WriteLine("createBindGroupLayout failed");
			return;
		}
		Console.WriteLine(scope $"bind group layout: {bindGroupLayout.Entries.Length} entries");

		var sets = IBindGroupLayout[1](bindGroupLayout);
		var plDesc = PipelineLayoutDesc();
		plDesc.BindGroupLayouts = sets;
		plDesc.Label = "smoketest_pl";
		IPipelineLayout pipelineLayout = null;
		if (device.CreatePipelineLayout(plDesc) case .Ok(let created))
		{
			pipelineLayout = created;
			Console.WriteLine("pipeline layout created");
		}
		else
		{
			Console.Error.WriteLine("createPipelineLayout failed");
		}

		var pcDesc = PipelineCacheDesc();
		pcDesc.Label = "smoketest_pc";
		IPipelineCache pipelineCache = null;
		if (device.CreatePipelineCache(pcDesc) case .Ok(let cache))
		{
			pipelineCache = cache;
			Console.WriteLine(scope $"pipeline cache created (size={cache.GetDataSize()})");
		}
		else
		{
			Console.Error.WriteLine("createPipelineCache failed");
		}

		if (pipelineCache != null)
			device.DestroyPipelineCache(ref pipelineCache);
		if (pipelineLayout != null)
			device.DestroyPipelineLayout(ref pipelineLayout);
		device.DestroyBindGroupLayout(ref bindGroupLayout);
	}

	private static ICommandPool CheckCommandPool(IDevice device)
	{
		if (!(device.CreateCommandPool(.Graphics) case .Ok(let pool)))
		{
			Console.Error.WriteLine("createCommandPool failed");
			return null;
		}
		Console.WriteLine("command pool created");
		return pool;
	}

	private static IFence CheckFence(IDevice device)
	{
		if (!(device.CreateFence(0) case .Ok(let fence)))
		{
			Console.Error.WriteLine("createFence failed");
			return null;
		}
		Console.WriteLine(scope $"fence created (initial={fence.CompletedValue()})");
		return fence;
	}

	private static IQuerySet CheckQuerySet(IDevice device)
	{
		var desc = QuerySetDesc();
		desc.Type = .Timestamp;
		desc.Count = 16;
		desc.Label = "smoketest_qs";
		if (!(device.CreateQuerySet(desc) case .Ok(let querySet)))
		{
			Console.Error.WriteLine("createQuerySet failed");
			return null;
		}
		Console.WriteLine(scope $"query set created (type={(uint32)querySet.Type} count={querySet.Count})");
		return querySet;
	}

	/// Three frames of the smallest possible submission: acquire, transition to Present,
	/// submit, present, wait.
	///
	/// Nothing is drawn. What is being checked is that the acquire, submit, present and
	/// fence wait cycle turns over more than once, which is where a swap chain that hands
	/// back the same image twice or a fence that never signals shows up.
	private static void RunFrames(IDevice device, ISwapChain swapChain, ICommandPool pool,
		IFence fence)
	{
		let graphics = device.GetQueue(.Graphics);
		uint64 fenceValue = 0;

		for (int frame = 0; frame < 3; frame++)
		{
			if (swapChain.AcquireNextImage() case .Err)
			{
				Console.Error.WriteLine(scope $"acquireNextImage failed on frame {frame}");
				break;
			}

			if ((pool != null) && (pool.CreateEncoder() case .Ok(var encoder)))
			{
				encoder.TransitionTexture(swapChain.CurrentTexture, .Undefined, .Present);
				let commandBuffer = encoder.Finish();
				var buffers = ICommandBuffer[1](commandBuffer);
				fenceValue++;
				graphics.Submit(buffers, fence, fenceValue);
				pool.DestroyEncoder(ref encoder);
			}

			swapChain.Present(graphics).IgnoreError();
			if (fence != null)
				fence.Wait(fenceValue);
			if (pool != null)
				pool.Reset();
			Console.WriteLine(scope $"frame {frame} acquired image_index={swapChain.CurrentImageIndex} fence={fenceValue}");
		}
	}

	private static void ReportFeatures(IDevice device)
	{
		let features = device.Features;
		Console.WriteLine(features.MeshShaders
			? "mesh shaders: supported"
			: "mesh shaders: not available");

		if (features.RayTracing)
			Console.WriteLine(scope $"ray tracing: supported (handle_size={device.ShaderGroupHandleSize})");
		else
			Console.WriteLine("ray tracing: not available");
	}

	/// HLSL through the compiler, checked by the SPIR-V magic word rather than by running
	/// it: the point is that DXC is reachable and produces something of the right shape.
	private static void CheckShaderCompiler()
	{
		let compiler = scope Sedulous.Shaders.ShaderCompiler();
		if (compiler.Initialize() case .Err)
		{
			Console.Error.WriteLine("shaders: createCompiler failed");
			return;
		}

		let hlsl = """
			float4 main(float2 uv : TEXCOORD0) : SV_Target {
			    return float4(uv, 0.0, 1.0);
			}
			""";

		var options = Sedulous.Shaders.CompileOptions();
		options.ShaderModel = "6_0";
		options.OptimizationLevel = 3;

		var result = compiler.Compile(.((uint8*)hlsl.Ptr, hlsl.Length),
			Sedulous.Shaders.ShaderStage.Fragment, "main", .SPIRV, options);
		defer result.Dispose();

		if (!result.Success)
		{
			Console.Error.WriteLine(scope $"shaders: compile failed: {result.Messages}");
			return;
		}

		let magic = (result.Bytecode.Count >= 4) ? *(uint32*)&result.Bytecode[0] : 0;
		Console.WriteLine(scope $"HLSL->SPIR-V: {result.Bytecode.Count} bytes, magic=0x{magic:X8} {(magic == 0x07230203) ? "(SPIR-V OK)" : "(unexpected)"}");
	}

	/// One of everything on WebGPU, which is the second real backend.
	///
	/// No surface and no swap chain here: the window is already bound to the Vulkan
	/// surface the pass above made, and wgpu cannot take a second surface over the same
	/// one. The samples cover presenting; this covers that every object a device hands out
	/// can be made and unmade for real.
	/// DX12, which exists only on Windows. Elsewhere this says so and moves on, the way the
	/// other backends report themselves unavailable, so the smoketest reads the same on every
	/// platform.
	private static void RunDx12()
	{
#if BF_PLATFORM_WINDOWS
		if (!(DxRhi.CreateBackend(true) case .Ok(let backend)))
		{
			Console.WriteLine("DX12 backend: FAILED to create");
			return;
		}
		defer { backend.Destroy(); delete backend; }

		let adapters = backend.EnumerateAdapters();
		Console.WriteLine(scope $"DX12 adapters: {adapters.Length}");
		for (int i = 0; i < adapters.Length; i++)
		{
			let info = scope AdapterInfo();
			adapters[i].GetInfo(info);
			Console.WriteLine(scope $"  [{i}] {info.Name} ({info.Type})");
		}

		if (adapters.IsEmpty)
			return;

		if (!(adapters[0].CreateDevice(DeviceDesc()) case .Ok(var device)))
		{
			Console.Error.WriteLine("DX12 device: FAILED to create");
			return;
		}

		Console.WriteLine(scope $"DX12 device created (type={device.Type})");
		device.Destroy();
#else
		Console.WriteLine("DX12 backend: Windows only - skipped");
#endif
	}

	private static void RunWebGpu()
	{
		if (!(WebGpuRhi.CreateBackend() case .Ok(let backend)))
		{
			Console.WriteLine("WebGPU backend: unavailable - skipped");
			return;
		}
		defer { backend.Destroy(); delete backend; }

		let version = scope String();
		WebGpuBackendInfo.NativeVersionString(version);
		Console.WriteLine(scope $"wgpu-native {version}");

		// Which shader path this build actually takes. SPIR-V ingestion is a wgpu-native
		// instance feature that a browser never has, and the samples feed SPIR-V
		// unconditionally, so a "no" here means every one of them would fail to make a
		// module. Worth stating rather than inferring from whether they rendered.
		Console.WriteLine(scope $"SPIR-V ingestion: {(WebGpuApi.SpirvIngestion ? "yes" : "no (WGSL only)")}");

		let adapters = backend.EnumerateAdapters();
		Console.WriteLine(scope $"WebGPU adapters: {adapters.Length}");
		for (int i = 0; i < adapters.Length; i++)
		{
			let info = scope AdapterInfo();
			adapters[i].GetInfo(info);
			Console.WriteLine(scope $"  [{i}] {info.Name} ({info.Type})");
		}

		if (adapters.IsEmpty)
			return;

		if (!(adapters[0].CreateDevice(DeviceDesc()) case .Ok(var device)))
		{
			Console.Error.WriteLine("WebGPU device: FAILED to create");
			return;
		}

		Console.WriteLine(scope $"WebGPU device created (type={device.Type})");

		// The buffer is the Map EMULATION: a CPU shadow that flushes through WriteBuffer.
		var bufferDesc = BufferDesc();
		bufferDesc.Size = 256;
		bufferDesc.Usage = .Uniform;
		bufferDesc.Memory = .CpuToGpu;
		if (device.CreateBuffer(bufferDesc) case .Ok(var buffer))
		{
			let mapped = buffer.Map();
			Console.WriteLine(scope $"WebGPU buffer mapped: {(mapped != null) ? "OK" : "FAIL"}");
			if (mapped != null)
			{
				Internal.MemSet(mapped, 0x5A, 256);
				buffer.Unmap();
			}

			device.DestroyBuffer(ref buffer);
		}

		var texture = device.CreateTexture(TextureDesc.RenderTarget(.RGBA8Unorm, 64, 64))
			.GetValueOrDefault();
		ITextureView view = null;
		if (texture != null)
		{
			var viewDesc = TextureViewDesc();
			viewDesc.Format = .RGBA8Unorm;
			view = device.CreateTextureView(texture, viewDesc).GetValueOrDefault();
		}

		var sampler = device.CreateSampler(SamplerDesc()).GetValueOrDefault();
		Console.WriteLine(scope $"WebGPU texture/view/sampler: {Ok(texture)}/{Ok(view)}/{Ok(sampler)}");

		// WGSL rather than the SPIR-V blob above: which path a module takes is decided by
		// LOOKING at the code for the SPIR-V magic, so this exercises the other branch.
		let wgsl = "@vertex fn main() -> @builtin(position) vec4f { return vec4f(0.0); }";
		var moduleDesc = ShaderModuleDesc();
		moduleDesc.Code = .((uint8*)wgsl.Ptr, wgsl.Length);
		var module = device.CreateShaderModule(moduleDesc).GetValueOrDefault();
		Console.WriteLine(scope $"WebGPU WGSL shader module: {Ok(module)}");
		if (module != null)
			device.DestroyShaderModule(ref module);

		// The fence has no WebGPU object behind it, so an EMPTY submission carrying a
		// signal is the whole timeline emulation in one call.
		if (device.CreateFence(0) case .Ok(var fence))
		{
			device.GetQueue(.Graphics, 0).Submit(.(), fence, 1);
			let signaled = fence.Wait(1, uint64.MaxValue);
			Console.WriteLine(scope $"WebGPU fence signaled: {(signaled ? "OK" : "FAIL")} (value {fence.CompletedValue()})");
			device.DestroyFence(ref fence);
		}

		if (sampler != null)
			device.DestroySampler(ref sampler);
		if (view != null)
			device.DestroyTextureView(ref view);
		if (texture != null)
			device.DestroyTexture(ref texture);

		device.WaitIdle();
		Console.WriteLine(scope $"WebGPU device lost: {(device.IsLost() ? "YES (bad)" : "no")}");
		device.Destroy();
		Console.WriteLine("WebGPU backend: OK");
	}

	private static StringView Ok(Object value) => (value != null) ? "OK" : "FAIL";

	/// The same sequence again with no GPU behind it.
	///
	/// A backend that needs no hardware is the one place a create and destroy mismatch is
	/// unambiguous, so the null path is run every time rather than only when Vulkan is
	/// missing.
	private static void RunNull()
	{
		let backend = NullRhi.CreateBackend();
		// The backend OWNS its adapter, its devices and its surfaces, so deleting it frees
		// them and calling DestroySurface as well would be a double free.
		defer delete backend;

		let adapters = backend.EnumerateAdapters();
		Console.WriteLine(scope $"null adapters: {adapters.Length}");

		if (!(adapters[0].CreateDevice(DeviceDesc()) case .Ok(let device)))
			return;
		if (!(backend.CreateSurface(null) case .Ok(let surface)))
			return;

		var swapDesc = SwapChainDesc();
		swapDesc.Width = 800;
		swapDesc.Height = 600;
		swapDesc.BufferCount = 2;
		if (!(device.CreateSwapChain(surface, swapDesc) case .Ok(var swapChain)))
			return;
		Console.WriteLine(scope $"null swap chain: {swapChain.Width}x{swapChain.Height}");

		var bufferDesc = BufferDesc();
		bufferDesc.Size = 256;
		bufferDesc.Usage = .Uniform;
		bufferDesc.Memory = .CpuToGpu;
		if (!(device.CreateBuffer(bufferDesc) case .Ok(var buffer)))
			return;
		Console.WriteLine(scope $"null buffer mapped: {(buffer.Map() != null) ? "yes" : "no"}");
		buffer.Unmap();

		if (!(device.CreateCommandPool(.Graphics) case .Ok(var pool)))
			return;
		if (!(pool.CreateEncoder() case .Ok(var encoder)))
			return;

		swapChain.AcquireNextImage().IgnoreError();
		encoder.TransitionTexture(swapChain.CurrentTexture, .Undefined, .Present);
		let commandBuffer = encoder.Finish();

		if (!(device.CreateFence(0) case .Ok(var fence)))
			return;
		var buffers = ICommandBuffer[1](commandBuffer);
		let graphics = device.GetQueue(.Graphics);
		graphics.Submit(buffers, fence, 1);
		fence.Wait(1);
		swapChain.Present(graphics).IgnoreError();
		Console.WriteLine("null frame completed");

		pool.DestroyEncoder(ref encoder);
		device.DestroyFence(ref fence);
		device.DestroyCommandPool(ref pool);
		device.DestroyBuffer(ref buffer);
		device.DestroySwapChain(ref swapChain);
		Console.WriteLine("null backend: OK");
	}

	/// Which windowing system the shell ACTUALLY used, so the backend picks the matching
	/// surface type rather than guessing.
	private static SurfacePlatform SurfacePlatformOf(NativeWindow native)
	{
		switch (native.System)
		{
		case .Win32: return .Win32;
		case .X11: return .X11;
		case .Wayland: return .Wayland;
		case .Cocoa: return .Cocoa;
		default: return .Unknown;
		}
	}

	private static StringView AdapterTypeName(AdapterType type)
	{
		switch (type)
		{
		case .DiscreteGpu: return "DiscreteGpu";
		case .IntegratedGpu: return "IntegratedGpu";
		case .Cpu: return "Cpu";
		default: return "Unknown";
		}
	}
}
