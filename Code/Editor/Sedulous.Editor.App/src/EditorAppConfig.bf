using System;
using Sedulous.Runtime.Client;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.App;

/// What the executable hands the editor application: the data root, the project to open, the
/// log capture, the smoke-test aids, and the assembly seams through which the executable
/// composes the engine and the per-subsystem editor plugins, since this library never links
/// them. The editor's own faces are its sheet's, through its resources (EditorWindow); the
/// splash's are the executable's.
class EditorAppConfig
{
	/// The data root, resolved by main; the editor mounts it once for the GUI's shaders and the
	/// editor's files, the embedded runtime and the export's shader cook. Required.
	public String DataRoot = new .() ~ delete _;
	/// Opened on startup; scaffolded if no manifest yet.
	public String ProjectDirectory = new .() ~ delete _;
	/// The name used when scaffolding.
	public String ProjectName = new .("Untitled") ~ delete _;

	/// The log capture registered on the global logger by main before anything else runs,
	/// so early startup logs reach the console. Borrowed; main owns it.
	public EditorLogBuffer LogBuffer = null;

	/// Start on the project manager screen instead of opening ProjectDirectory (main sets it
	/// when no project was given).
	public bool StartInProjectManager = false;
	/// CLI: when the project directory has no manifest and gets scaffolded, also seed the
	/// starter content the manager's New Project flow seeds.
	public bool SeedOnScaffold = false;
	/// --seed-primitives: that seed with every primitive, not just the three.
	public bool SeedAllPrimitives = false;
	/// --restamp: the project's manifest is saved once as it opens, stamping it with this engine.
	/// The project manager passes it for an older engine's project the user chose to upgrade.
	public bool Restamp = false;
	/// --manager <path>: the project manager that launched this editor (EditorApplication.ManagerPath);
	/// empty when none said so.
	public String ManagerPath = new .() ~ delete _;

	/// A smoke-test aid: a clean shutdown after this many seconds (0 never), exercising the
	/// real teardown path.
	public float AutoExitSeconds = 0.0f;
	/// A smoke-test aid: Build > Rebuild All after this many seconds (0 never).
	public float AutoRebuildSeconds = 0.0f;
	/// A smoke-test aid: the main window's backbuffer written as a PNG to this path (empty
	/// never), once ScreenshotAfterSeconds have run, so a run proves what it drew.
	public String ScreenshotPath = new .() ~ delete _;
	public float ScreenshotAfterSeconds = 0.0f;
	/// --screenshot-exit: request the clean shutdown once that capture is written (or has
	/// failed), the player's flag of the same name, so a capture run needs no --exit-after guess.
	public bool ScreenshotExit = false;
	/// The MCP host for THIS run: --mcp enables it regardless of the preference and
	/// --mcp-port <n> picks its port (0 is the preference's), so an agent that launches the
	/// editor itself needs no UI. EditorMcpSettings is the persisted preference.
	public bool McpEnabled = false;
	public uint32 McpPort = 0;
	/// --release-files <url or folder>: where the Samples tab reads this version's release files
	/// instead of GitHub: a base URL, or a folder Code/Tools/pack-samples.py wrote, served on
	/// loopback (to try the tab before a release carries samples). Empty: the release itself.
	public String ReleaseFiles = new .() ~ delete _;

	/// From Configure: registers the engine subsystems. Owned.
	public delegate void(IApplicationHost host) ConfigureEngine ~ delete _;
	/// During OnStartup: the per-subsystem editor registrations, plus wiring the app to the
	/// engine interfaces it drives (SetSceneRenderer). The host is the EMBEDDED one: every
	/// page's scenes live there. Owned.
	public delegate void(EditorApplication app, IApplicationHost embeddedHost) RegisterEditors ~ delete _;
	/// Seeds starter content into a project the manager just created, once, right after the
	/// fresh project opens; the exe composes it because only the exe links every asset type.
	/// Null means new projects start empty. Owned.
	public delegate void(EditorContext context, EditorProject project) SeedNewProject ~ delete _;

	/// Startup's progress, for the splash main shows until the editor is ready: what it is
	/// doing now and how far along (0 to 1). Null: no splash.
	public delegate void(StringView status, float progress) StartupProgress ~ delete _;
	/// Called once at the end of OnStartup, the editor ready: main closes the splash and shows
	/// the main window (created hidden while the splash is up). Null: nothing to do.
	public delegate void() StartupFinished ~ delete _;

	/// The command line's project and flags (EditorMain's usage) into this config: the positional
	/// project directory, then the flags. The data root and the GPU's flags are read by main.
	public void ReadCommandLine(Span<String> args)
	{
		if ((args.Length > 0) && !args[0].StartsWith("-"))
			ProjectDirectory.Set(args[0]);
		for (int i = 0; i < args.Length - 1; i++)
		{
			if (args[i] == "--project")
				ProjectDirectory.Set(args[i + 1]);
			else if (args[i] == "--exit-after")
				AutoExitSeconds = float.Parse(args[i + 1]).GetValueOrDefault();
			else if (args[i] == "--rebuild-after")
				AutoRebuildSeconds = float.Parse(args[i + 1]).GetValueOrDefault();
			else if (args[i] == "--screenshot")
				ScreenshotPath.Set(args[i + 1]);
			else if (args[i] == "--screenshot-after")
				ScreenshotAfterSeconds = float.Parse(args[i + 1]).GetValueOrDefault();
			else if (args[i] == "--release-files")
				ReleaseFiles.Set(args[i + 1]);
			else if (args[i] == "--manager")
				ManagerPath.Set(args[i + 1]);
			else if (args[i] == "--mcp-port")
			{
				McpPort = uint32.Parse(args[i + 1]).GetValueOrDefault();
				McpEnabled = true; // naming a port means serving on it
			}
		}
		for (let arg in args)
		{
			if (arg == "--seed")
				SeedOnScaffold = true; // a scaffolded project also gets the starter content
			else if (arg == "--screenshot-exit")
				ScreenshotExit = true;
			else if (arg == "--mcp")
				McpEnabled = true; // the MCP host for this run, whatever the preference says
			else if (arg == "--restamp")
				Restamp = true;
			else if (arg == "--seed-primitives")
			{
				SeedOnScaffold = true;
				SeedAllPrimitives = true; // plus every primitive, not just the three
			}
		}
	}
}
