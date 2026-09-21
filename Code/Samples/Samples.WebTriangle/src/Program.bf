using System;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;
using Sedulous.Shell;
using Sedulous.Shell.Web;

namespace Samples.WebTriangle;

/// The smallest thing that proves the browser stack is wired: a canvas shell, a WebGPU
/// device on it, a swap chain, and one WGSL triangle recorded into it every frame.
///
/// Deliberately NOT a raw wgpu sample. The point is the chain the engine adds, shell to
/// surface to backend, which is what the rest of the web tier stands on; a triangle through
/// wgpu directly would skip exactly that.
///
/// The triangle carries its own weight as a DIAGNOSTIC: it is the only sample that creates a
/// shader module without the content pipeline in the way, so it separates "WGSL does not
/// reach the browser" from "the shader pack does not load".
///
/// Position and colour are selected by vertex index out of arrays baked into the shader, so
/// there is no vertex buffer and no bind group to get wrong.
class Program
{
	private static WebShell sShell;
	private static IBackend sBackend;
	private static IDevice sDevice;
	private static ISurface sSurface;
	private static ISwapChain sSwapChain;
	private static ICommandPool sPool;
	private static uint32 sFrame;
	private static IShaderModule sShader;
	private static IBindGroupLayout sBindGroupLayout;
	private static IPipelineLayout sPipelineLayout;
	private static IRenderPipeline sPipeline;

	/// Browsers ingest WGSL directly and there is no runtime HLSL compiler on the web, so the
	/// source is the shader: nothing here is cooked.
	private const String TriangleWgsl = """
		struct VSOut {
			@builtin(position) position : vec4f,
			@location(0) color : vec3f,
		};
		@vertex fn vs(@builtin(vertex_index) index : u32) -> VSOut {
			var positions = array<vec2f, 3>(
				vec2f( 0.0,  0.5),
				vec2f( 0.5, -0.5),
				vec2f(-0.5, -0.5));
			var colors = array<vec3f, 3>(
				vec3f(1.0, 0.0, 0.0),
				vec3f(0.0, 1.0, 0.0),
				vec3f(0.0, 0.0, 1.0));
			var out : VSOut;
			out.position = vec4f(positions[index], 0.0, 1.0);
			out.color = colors[index];
			return out;
		}
		@fragment fn fs(in : VSOut) -> @location(0) vec4f {
			return vec4f(in.color, 1.0);
		}
		""";

	public static int Main(String[] args)
	{
		sShell = new WebShell();
		let window = sShell.MainWindow;
		if (window == null)
		{
			Console.Error.WriteLine("WebTriangle: the shell produced no canvas");
			return 1;
		}

		if (!(WebGpuRhi.CreateBackend() case .Ok(let backend)))
		{
			Console.Error.WriteLine("WebTriangle: no WebGPU. A recent Chrome or Edge is needed.");
			return 1;
		}
		sBackend = backend;

		// The canvas selector IS the native handle on web: see WebWindow.Native.
		let native = window.Native;
		if (!(sBackend.CreateSurface(native.Window, native.Display, .Web) case .Ok(let surface)))
		{
			Console.Error.WriteLine("WebTriangle: the canvas surface could not be created");
			return 1;
		}
		sSurface = surface;

		let adapters = sBackend.EnumerateAdapters();
		if (adapters.IsEmpty)
		{
			Console.Error.WriteLine("WebTriangle: no adapters");
			return 1;
		}

		if (!(adapters[0].CreateDevice(.()) case .Ok(let device)))
		{
			Console.Error.WriteLine("WebTriangle: the device could not be created");
			return 1;
		}
		sDevice = device;

		var desc = SwapChainDesc();
		desc.Width = window.Width;
		desc.Height = window.Height;
		desc.Format = .BGRA8Unorm;
		desc.PresentMode = .Fifo;
		desc.BufferCount = 2;
		desc.Label = "canvas";
		if (!(sDevice.CreateSwapChain(sSurface, desc) case .Ok(let swapChain)))
		{
			Console.Error.WriteLine("WebTriangle: the swap chain could not be created");
			return 1;
		}
		sSwapChain = swapChain;

		if (!(sDevice.CreateCommandPool(.Graphics) case .Ok(let pool)))
			return 1;
		sPool = pool;

		Console.WriteLine("WebTriangle: WebGPU is up on the canvas");

		// A failure here leaves sPipeline null and the frame falls back to the clear alone,
		// which is the signal that the device came up but shaders did not.
		if (CreatePipeline() case .Err)
			Console.Error.WriteLine("WebTriangle: no pipeline, clearing only");

		// The browser owns the cadence; see WebRunner for why this cannot be a loop.
		EmscriptenHtml5.emscripten_set_main_loop_arg(=> Frame, null, 0, 0);
		return 0;
	}

	private static Result<void> CreatePipeline()
	{
		var moduleDesc = ShaderModuleDesc();
		// The WGSL TEXT is the blob: ShaderModuleDesc.Code is bytes for SPIR-V and DXIL, and
		// source for WGSL. No terminator, the length carries it.
		moduleDesc.Code = .((uint8*)TriangleWgsl.Ptr, TriangleWgsl.Length);
		moduleDesc.Label = "TriangleWGSL";
		if (!(sDevice.CreateShaderModule(moduleDesc) case .Ok(let shader)))
		{
			Console.Error.WriteLine("WebTriangle: the shader module could not be created");
			return .Err;
		}
		sShader = shader;

		// EMPTY, but not absent: the shader declares no bindings, and a pipeline layout with
		// no groups at all is a different thing from one group that happens to be empty.
		var bglDesc = BindGroupLayoutDesc();
		bglDesc.Label = "EmptyBGL";
		if (!(sDevice.CreateBindGroupLayout(bglDesc) case .Ok(let bgl)))
			return .Err;
		sBindGroupLayout = bgl;

		var layouts = IBindGroupLayout[1](sBindGroupLayout);
		var plDesc = PipelineLayoutDesc();
		plDesc.BindGroupLayouts = layouts;
		plDesc.Label = "TrianglePL";
		if (!(sDevice.CreatePipelineLayout(plDesc) case .Ok(let pipelineLayout)))
			return .Err;
		sPipelineLayout = pipelineLayout;

		var colorTarget = ColorTargetState();
		// The swap chain's ACTUAL format, not the one the desc asked for. On a canvas the
		// browser negotiates its own and hands back what it chose, so a hard coded format is
		// a pipeline/pass incompatibility at the first draw rather than a wrong colour.
		colorTarget.Format = sSwapChain.Format;
		colorTarget.WriteMask = .All;
		var targets = ColorTargetState[1](colorTarget);

		var fragment = FragmentState();
		fragment.Shader = .(sShader, "fs", .Fragment);
		fragment.Targets = targets;

		var pipelineDesc = RenderPipelineDesc();
		pipelineDesc.Layout = sPipelineLayout;
		pipelineDesc.Vertex.Shader = .(sShader, "vs", .Vertex);
		pipelineDesc.Fragment = fragment;
		pipelineDesc.Primitive.Topology = .TriangleList;
		pipelineDesc.Label = "TrianglePipeline";
		if (!(sDevice.CreateRenderPipeline(pipelineDesc) case .Ok(let pipeline)))
		{
			Console.Error.WriteLine("WebTriangle: the render pipeline could not be created");
			return .Err;
		}
		sPipeline = pipeline;
		return .Ok;
	}

	private static void Frame(void* userData)
	{
		sShell.ProcessEvents();
		if (!sShell.IsRunning)
		{
			EmscriptenHtml5.emscripten_cancel_main_loop();
			return;
		}

		if (!(sSwapChain.AcquireNextImage() case .Ok))
			return;

		if (!(sPool.CreateEncoder() case .Ok(var encoder)))
			return;

		// A colour that walks, so a still frame is visibly distinguishable from a stalled one.
		let t = (float)sFrame * 0.01f;

		var colorAttachment = ColorAttachment();
		colorAttachment.View = sSwapChain.CurrentTextureView;
		colorAttachment.LoadOp = .Clear;
		colorAttachment.StoreOp = .Store;
		colorAttachment.ClearValue = .((float)Math.Abs(Math.Sin(t)), 0.2f, 0.6f, 1.0f);

		var passDesc = RenderPassDesc();
		passDesc.ColorAttachments.Add(colorAttachment);

		let pass = encoder.BeginRenderPass(passDesc);
		if (sPipeline != null)
		{
			pass.SetPipeline(sPipeline);
			pass.SetViewport(0, 0, sSwapChain.Width, sSwapChain.Height);
			pass.SetScissor(0, 0, sSwapChain.Width, sSwapChain.Height);
			pass.Draw(3);
		}
		pass.End();

		encoder.TransitionTexture(sSwapChain.CurrentTexture, .RenderTarget, .Present);

		let commands = encoder.Finish();
		if (commands != null)
		{
			let queue = sDevice.GetQueue(.Graphics);
			var buffers = ICommandBuffer[1](commands);
			queue.Submit(buffers);
			sSwapChain.Present(queue).IgnoreError();
		}
		sPool.DestroyEncoder(ref encoder);
		sFrame++;
	}
}
