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
}
