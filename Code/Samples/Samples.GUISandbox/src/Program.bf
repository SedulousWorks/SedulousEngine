using System;
using Sedulous.Graphics;
using Sedulous.Graphics.Gpu;
using Sedulous.RHI.Capture;
using Sedulous.Runtime.SDL3;
using Sedulous.Shell;
using Sedulous.Shell.SDL3;

namespace Samples.GUISandbox;

/// The sandbox's composition root: its flags, the shell, the graphics device and the desktop
/// runner. What Main returns is the run's code, or a check's verdict: 0 passed, 1 failed, 77
/// skipped (no device to test on), as the image tests, the sweep and the mirror audit report it.
///
/// --page <id>: open on that page (controls, text, layout, data-views, menus, viewport, docking,
/// toolkit, code, styling, effects, pictures, motion, themes, binding, input, navigation,
/// language, stress, game-menu). --showcase: open the game menu at once. --light: the light
/// scheme from the start. --menu-call <function>: call one of the game menu's script functions
/// once it is up (onSettings, onPlay, onQuit). --keys "<keys>": type keystrokes into what is
/// shown, one every 15 frames ("down down return", "pad-east"; pointer steps too, in logical
/// units: click:x,y rclick:x,y move:x,y down:x,y up:x,y pinch:x,y turn:x,y pan2:x,y, or at what a
/// selector or a text finds: click:#ok, click:text=Show, move:text~=Sett). --always-redraw: draw
/// every frame. --frame-stats: print, each second, how many frames drew. --sweep: hover, click
/// and right-click every widget of every page, walk each by keys and the pad, then open the game
/// menu, printing each step, and exit, failing when anything warned. --soak <minutes>
/// [--soak-csv <path>]: the sweep over and over, a CSV row every ten seconds. --mirror-audit:
/// every page laid out both ways, each widget where the mirror of its place puts it.
/// --scroll <px>: scroll the page down that far once it is up. --layout-overlay (F9),
/// --input-overlay (F8): start with that half of the debug overlay on. --inspector: start with
/// the inspector's pane open (Ctrl+Shift+I toggles it). --inspect <selector>: open it with the
/// first widget the selector matches selected. --image-tests: draw each page offscreen at 960x720
/// on a fixed clock and compare it with its reference in Data/Tests/GUI/Images (the pictures go
/// to --image-out <dir>, build/gui-images by default). --approve-images [backend]: write them as
/// the references instead (the backends' shared one, or with "backend" this backend's own),
/// after looking at them. --bench <page> [frames]: a page's frame cost by stage. --lang <locale>:
/// start in that language (en, ar, or pseudo: English pseudolocalized). --narrate: print what a
/// screen reader would say. --stress <n>: start on the Stress page, built at load n (1 to 20;
/// measure in Release). The backend: --vulkan (the default), --webgpu, --dx12. With the
/// framework's --screenshot flags, a picture of any of it.
class Program
{
	public static int Main(String[] args)
	{
		let app = scope GUISandboxApp();
		for (int i = 0; i < args.Count; i++)
		{
			let arg = args[i];
			let hasNext = i + 1 < args.Count;
			if ((arg == "--page") && hasNext)
				app.SetStartPage(args[++i]);
			else if (arg == "--showcase")
				app.SetOpenMenu(true);
			else if (arg == "--light")
				app.SetLightAtStart(true);
			else if ((arg == "--menu-call") && hasNext)
				app.SetMenuCall(args[++i]);
			else if ((arg == "--keys") && hasNext)
				app.SetKeys(args[++i]);
			else if (arg == "--always-redraw")
				app.SetAlwaysRedraw(true);
			else if (arg == "--frame-stats")
				app.SetFrameStats(true);
			else if (arg == "--sweep")
				app.SetSweep(true);
			else if (arg == "--mirror-audit")
				app.SetMirrorAudit(true);
			else if ((arg == "--soak") && hasNext)
				app.SetSoak(float.Parse(args[++i]).GetValueOrDefault());
			else if ((arg == "--soak-csv") && hasNext)
				app.SetSoakCsv(args[++i]);
			else if (arg == "--layout-overlay")
				app.SetLayoutOverlay(true);
			else if (arg == "--input-overlay")
				app.SetInputOverlay(true);
			else if (arg == "--inspector")
				app.SetOpenInspector(true);
			else if (arg == "--image-tests")
				app.SetImageTests(true);
			else if ((arg == "--bench") && hasNext)
			{
				let page = args[++i];
				uint32 frames = 300;
				// A count after the page is the bench's; anything else is the next flag.
				if ((i + 1 < args.Count) && (uint32.Parse(args[i + 1]) case .Ok(let count)))
				{
					frames = count;
					i++;
				}
				app.SetBench(page, frames);
			}
			else if (arg == "--approve-images")
			{
				if (hasNext && (args[i + 1] == "backend"))
					app.SetApproveImages(args[++i]);
				else
					app.SetApproveImages("shared");
			}
			else if ((arg == "--image-out") && hasNext)
				app.SetImageOut(args[++i]);
			else if ((arg == "--inspect") && hasNext)
				app.SetInspectSelector(args[++i]);
			else if ((arg == "--lang") && hasNext)
				app.SetStartLanguage(args[++i]);
			else if (arg == "--narrate")
				app.SetNarrate(true);
			else if ((arg == "--stress") && hasNext)
			{
				int32 load = 1; // a load that does not parse builds the first
				if (int32.Parse(args[++i]) case .Ok(let parsed))
					load = parsed;
				app.SetStress(load);
			}
			else if ((arg == "--scroll") && hasNext)
				app.SetScroll(float.Parse(args[++i]).GetValueOrDefault());
		}
		// The backend the device is made on names the image tests' pictures and references
		// (--vulkan, --webgpu, --dx12, read where the device's are).
		switch (BackendSelection.FromArguments(args))
		{
		case .WebGPU: app.SetBackendName("webgpu");
		case .DX12: app.SetBackendName("dx12");
		case .Null: app.SetBackendName("null");
		default: app.SetBackendName("vulkan");
		}
		app.SetScreenshots(ScreenshotOptions.FromArguments(args));

		WindowSettings windowSettings = .();
		windowSettings.Title = "GUI Sandbox";
		windowSettings.Width = 960;
		windowSettings.Height = 820;
		windowSettings.DrawsTextComposition = true; // its fields show an IME's composition in place
		let shell = scope SDL3Shell(windowSettings);
		if (shell.MainWindow == null)
		{
			Console.Error.WriteLine("GUISandbox: the shell has no main window");
			return app.ImageExitCode(1);
		}
		if (!(GpuGraphics.CreateDevice(GraphicsDeviceDesc.FromArguments(args)) case .Ok(let graphics)))
		{
			Console.Error.WriteLine("GUISandbox: the graphics device could not be created");
			return app.ImageExitCode(1); // 77 for the checks: no device to test on
		}
		defer delete graphics;
		return app.ImageExitCode(DesktopRunner.RunApplication(app, shell, graphics));
	}
}
