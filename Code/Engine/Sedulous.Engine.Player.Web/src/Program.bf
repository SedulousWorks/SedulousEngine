using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Engine.Player;
using Sedulous.Engine.Project;
using Sedulous.Graphics;
using Sedulous.Graphics.Gpu;
using Sedulous.Runtime.Web;
using Sedulous.Shell;
using Sedulous.Shell.Web;

namespace Sedulous.Engine.Player.Web;

/// The BROWSER entry for the player.
///
/// A separate project from the desktop entry, for the reason stated there: the dependencies
/// differ and a compile time branch cannot drop one. Three things differ in the body too, each
/// for a reason. The shell, because a canvas has no OS window. The backend, because a browser
/// has WebGPU and nothing else. The runner, because a browser cannot be blocked and the loop
/// belongs to requestAnimationFrame.
///
/// The fourth difference is the dist, and it is this file's real work: a desktop player is
/// launched inside a game's directory, while a browser starts with an empty filesystem and has
/// to pull the game in before the app boots.
class Program
{
	public static int Main(String[] args)
	{
		// NOTHING here is scoped. The browser calls the frame after this returns, so anything
		// on this stack would already be freed by the time the first frame ran.
		//
		// A console sink FIRST, because GlobalLog drops every record until a logger exists and
		// a failure in the browser otherwise looks like a blank canvas and a silent console.
		InitGlobalLogger(new ConsoleLogger(.Information, "Player"), true);
		GlobalLog(.Information, "Player {}", EngineVersion.String);

		StageDist();

		let shell = new WebShell();
		if (shell.MainWindow == null)
		{
			Console.Error.WriteLine("Player: the page has no canvas");
			return 1;
		}

		GraphicsDeviceDesc deviceDesc = .();
		deviceDesc.Backend = .WebGPU; // the only backend a browser has
		// Off: wgpu validates unconditionally in a browser, so the wrapper would only
		// duplicate what the console already reports.
		deviceDesc.EnableValidation = false;

		if (!(GpuGraphics.CreateDevice(deviceDesc) case .Ok(let graphics)))
		{
			Console.Error.WriteLine(
				"Player: no WebGPU device. A recent Chrome or Edge is needed.");
			return 1;
		}

		let options = new PlayerOptions();
		// The dist is fetched into the root of the browser's filesystem, so the game is
		// simply here.
		options.ProjectDir.Set(".");

		let app = new PlayerApplication(options);
		return WebRunner.RunApplication(app, shell, graphics);
	}

	/// Pulls the game in BEFORE the app boots.
	///
	/// The order is forced by what reads what: the project loader opens player.xml and
	/// Content.pak during Initialize, the app resolves its data root at Data/.dataroot in
	/// Configure, and the render subsystem opens the shader pack when the device comes up.
	/// All of that happens inside RunApplication, so every file has to be present before it
	/// is called.
	private static void StageDist()
	{
		WebDist.Fetch("player.xml");
		ContentVariant.SelectAndFetch();

		// The SAME layout a desktop dist stages beside the player, so the one discovery walk
		// finds Data/.dataroot in a browser exactly as it does on disk. See the data root
		// rule: one mechanism, never a baked or probed path.
		CreateDirectory("Data");
		CreateDirectory("Data/Shaders");
		WebDist.Fetch("Data/.dataroot");
		WebDist.Fetch("Data/Shaders/shaders.dpak");
	}
}
