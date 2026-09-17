using System;
using Sedulous.Graphics;
using Sedulous.Graphics.Gpu;
using Sedulous.Runtime.Web;
using Sedulous.Shell;
using Sedulous.Shell.Web;
using Samples.WebScene;

namespace Samples.WebScene.Web;

/// The BROWSER entry for WebScene, over the same Samples.WebScene.App the desktop entry uses.
///
/// Three things differ from the desktop, and each for a reason: the shell, because a canvas
/// has no OS window; the backend, because a browser has WebGPU and nothing else; and the
/// runner, because a browser cannot be blocked and the loop belongs to requestAnimationFrame.
class Program
{
	public static int Main(String[] args)
	{
		// NOTHING here is scoped. The browser calls the frame after this returns, so anything
		// on this stack would already be freed by the time the first frame ran.
		let shell = new WebShell();
		if (shell.MainWindow == null)
		{
			Console.Error.WriteLine("WebScene: the page has no canvas");
			return 1;
		}

		GraphicsDeviceDesc deviceDesc = .();
		deviceDesc.Backend = .WebGPU; // the only backend a browser has
		// Off here: wgpu validates unconditionally in a browser, so the wrapper would only
		// duplicate what the console already reports.
		deviceDesc.EnableValidation = false;

		if (!(GpuGraphics.CreateDevice(deviceDesc) case .Ok(let graphics)))
		{
			Console.Error.WriteLine("WebScene: no WebGPU device. A recent Chrome or Edge is needed.");
			return 1;
		}

		let app = new WebSceneApp();
		return WebRunner.RunApplication(app, shell, graphics);
	}
}
