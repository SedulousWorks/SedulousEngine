using System;
using Sedulous.RHI;
using Sedulous.RHI.WebGPU;
using Sedulous.Shell;
using Sedulous.Shell.Web;

namespace Samples.WebTriangle;

/// The smallest thing that proves the browser stack is wired: a canvas shell, a WebGPU
/// device on it, and a swap chain cleared every frame.
///
/// Deliberately NOT a raw wgpu sample. The point is the chain the port added, shell to
/// surface to backend, which is what the rest of the web tier stands on; a triangle through
/// the RHI directly would skip exactly that.
class Program
{
	private static WebShell sShell;
	private static IBackend sBackend;
	private static IDevice sDevice;
	private static ISurface sSurface;
	private static ISwapChain sSwapChain;
	private static ICommandPool sPool;
	private static uint32 sFrame;

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

		// The browser owns the cadence; see WebRunner for why this cannot be a loop.
		EmscriptenHtml5.emscripten_set_main_loop_arg(=> Frame, null, 0, 0);
		return 0;
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
