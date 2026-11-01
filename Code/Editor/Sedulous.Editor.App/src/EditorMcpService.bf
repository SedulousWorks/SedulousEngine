using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.VFS;
using Sedulous.Settings;
using Sedulous.Mcp;
using Sedulous.GUI; // the input tools' root
using Sedulous.Profiler;
using Sedulous.Profiler.Capture;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;
using Sedulous.Editor.Mcp;

namespace Sedulous.Editor.App;

/// What an EditorMcpService works over. The services are borrowed for its life; the strings and
/// delegates are its own. The delegates are read at each call, not at Start, so the application
/// may set them at any time.
class EditorMcpServiceServices
{
	public EditorContext Context = null;
	public EditorCookService Cook = null;
	public EditorJobService Jobs = null;
	public BuilderRegistry Builders = null;
	/// The per-user editor settings: their EditorMcpSettings section (enabled, port, token) is
	/// the preference, and a minted token is saved with them. Required.
	public Settings UserSettings = null;
	/// The log capture log_read serves; without one the host is not started.
	public EditorLogBuffer Log = null;
	/// The engine data root; shader_validate and the shader cook read <DataRoot>/Shaders.
	public String DataRoot = new .() ~ delete _;
	/// The command line's (--mcp, --mcp-port): on whatever the preference says, and a port of
	/// its own (0: the preference's).
	public bool ForceEnabled = false;
	public uint32 Port = 0;
	/// Where the token file, the settings a minted token is saved with and the profiler's
	/// captures go. Empty: the user data directory, as the editor runs; a test points it at a
	/// scratch folder so a run leaves the user's own token alone.
	public String UserDataDirectory = new .() ~ delete _;
	/// The templates folder the export operations use (it reads settings: main thread). Unset:
	/// none. Owned.
	public delegate void(String outPath) TemplatesRoot ~ delete _;
	/// What an agent's create, delete and import do beside the store (the assets list, the
	/// default scene, the cook). An unset delete falls back to the database's own. Owned, all.
	public delegate void(AssetCreator creator, Instance instance) OnCreated ~ delete _;
	public delegate bool(Guid id) DeleteAsset ~ delete _;
	public delegate void(Instance primary, ImportOptions options) OnImported ~ delete _;
	/// The pages, over the paths the tabs take. Owned, both.
	public delegate EditorPage(Guid id) OpenPage ~ delete _;
	public delegate void(EditorPage page) ClosePage ~ delete _;
	/// The windows' screenshots, over the application's capture (WindowToolSeams). Owned, all.
	public delegate void(List<uint32> outWindows) Windows ~ delete _;
	public delegate void(Span<WindowShotRequest> requests) RequestShots ~ delete _;
	public delegate void(List<WindowShot> outShots) Shots ~ delete _;
	/// The tools the application adds over its other parts (the dock's layout tools, the action
	/// bridge), called on every start. Owned.
	/// The main window's GUI, which the input tools drive; null: none now.
	public delegate SceneRoot() GuiRoot ~ delete _;
	/// What a file dropped on the main window does (editor_drop); false with `error` when it
	/// cannot. Owned.
	public delegate bool(Span<StringView> paths, String error) DropFiles ~ delete _;
	public delegate void(McpServer server) AddTools ~ delete _;
}

/// The editor's MCP host over the open project, out of the application (Raptor's editor-gui
/// spec, 5.1, layer 3). It starts when a project opens (when the user enabled it, or --mcp
/// asked for it), minting the token the first time, with the shared engine tools over the
/// application's own services (an agent's cook, import or export takes the paths the menus do)
/// and the editor host's live additions: the pages, the windows' screenshots, the profiler. The
/// application adds the tools that need its other parts through AddTools. It stops before the
/// project's services go, and its calls are answered from Pump, once a frame.
class EditorMcpService
{
	private EditorMcpServiceServices mServices ~ delete _;
	/// The open project, as the engine tools see it; the host only borrows it.
	private ProjectSession mSession = new .() ~ delete _;
	private EditorProjectOperations mOperations = null;
	/// Gone before the operations it runs through (Stop).
	private EditorMcpHost mHost = null;

	/// TAKES OWNERSHIP of the services.
	public this(EditorMcpServiceServices services)
	{
		mServices = services;
	}

	/// The host goes with the service; the fields then have nothing left to free.
	public ~this()
	{
		Stop();
	}

	public bool IsRunning => mHost != null;
	/// The running host, or null.
	public EditorMcpHost Host => mHost;

	/// Starts the host over `project` when enabled, stopping a running one first: false when it
	/// is not enabled, or it could not listen (logged: another editor may hold the port).
	public bool Start(EditorProject project)
	{
		Stop();
		Runtime.Assert(mServices.UserSettings != null, "EditorMcpService: the user settings are required");
		let settings = mServices.UserSettings.Section<EditorMcpSettings>();
		if (!(settings.Enabled || mServices.ForceEnabled) || (project == null))
			return false;
		if (mServices.Log == null)
		{
			GlobalLog(.Warning, "MCP: no log capture was installed, the host is not started");
			return false;
		}
		let userData = UserDataDirectory(.. scope .());
		if (settings.Token.IsEmpty)
		{
			// The first enable mints the secret once and keeps it: the token file and the
			// Preferences display stay valid across runs.
			EditorMcpSettings.GenerateToken(settings.Token);
			CreateDirectory(userData);
			if (EditorSettingsStore.Save(scope NativeFileSystem(userData), mServices.UserSettings) case .Err)
				GlobalLog(.Warning, "MCP: the minted token could not be saved to the editor settings; it changes on the next run");
		}
		let paths = scope EngineToolPaths();
		paths.LocateShippingDocs(scope StringView[](GetExecutableDirectory(.. scope .()), GetCurrentDirectory(.. scope .())));
		// shader_validate compiles against the engine's shader library under the data root.
		DataPath(mServices.DataRoot, "Engine/Shaders", paths.ShaderLibrary);
		mSession.Project = project;

		// The operations run on the application's services, so an agent's cook, import or export
		// takes the same background paths the menus do and the editor stays live. The hooks are
		// forwarded, not moved: the host starts again for every project.
		let operations = new EditorProjectOperationsSeams();
		operations.Project = project;
		operations.Context = mServices.Context;
		operations.Cook = mServices.Cook;
		operations.Jobs = mServices.Jobs;
		operations.Builders = mServices.Builders;
		BuildLayout.PlayerDirectoryBeside(GetExecutableDirectory(.. scope .()), operations.PlayerDir);
		if (mServices.TemplatesRoot != null)
			mServices.TemplatesRoot(operations.TemplatesRoot);
		operations.DataRoot.Set(mServices.DataRoot);
		operations.OnCreated = new (creator, instance) =>
			{
				if (mServices.OnCreated != null)
					mServices.OnCreated(creator, instance);
			};
		// Sedulous's operations fall back to the database's delete when no hook is set: only an
		// application that has its own delete is asked.
		if (mServices.DeleteAsset != null)
			operations.OnDelete = new (id) => (mServices.DeleteAsset != null) && mServices.DeleteAsset(id);
		operations.OnImported = new (primary, options) =>
			{
				if (mServices.OnImported != null)
					mServices.OnImported(primary, options);
			};
		mOperations = new EditorProjectOperations(operations);
		mHost = new EditorMcpHost(mServices.Context, mSession, mServices.Log, mServices.Builders, mServices.Context.Importers,
			paths, mOperations, BuildStamp(.. scope .()));
		let context = mServices.Context;
		mHost.OnToolFinished = new (tool, isError) =>
			{
				context.SetStatus(scope $"MCP: {tool} {isError ? "failed" : "done"}");
			};

		// This host's live additions: the pages, over the same open and close paths the tabs take.
		let pages = new PageToolSeams();
		pages.Context = mServices.Context;
		pages.OpenPage = new (id) => (mServices.OpenPage != null) ? mServices.OpenPage(id) : null;
		pages.ClosePage = new (page) =>
			{
				if (mServices.ClosePage != null)
					mServices.ClosePage(page);
			};
		EditorPageTools.Register(mHost.Server, pages);
		// editor_screenshot, over the same capture as View > Screenshot.
		let windows = new WindowToolSeams();
		windows.Windows = new (outWindows) =>
			{
				if (mServices.Windows != null)
					mServices.Windows(outWindows);
			};
		windows.Request = new (requests) =>
			{
				if (mServices.RequestShots != null)
					mServices.RequestShots(requests);
			};
		windows.Shots = new (outShots) =>
			{
				if (mServices.Shots != null)
					mServices.Shots(outShots);
			};
		EditorWindowTools.Register(mHost.Server, windows);
		// editor_find, editor_click and the other hands: the main window's GUI, driven as a user would.
		let input = new InputToolSeams();
		input.Root = new [=this] () => (mServices.GuiRoot != null) ? mServices.GuiRoot() : null;
		input.Drop = new [=this] (paths, error) => (mServices.DropFiles != null) && mServices.DropFiles(paths, error);
		EditorInputTools.Register(mHost.Server, input);
		// profiler_capture: the process's recorder, which the host advances after each frame.
		let profiler = new ProfilerToolSeams();
		profiler.Profiler = GlobalProfiler();
		profiler.Recorder = CaptureRecorder.Process;
		CaptureRecorder.Process.SetApplication("Editor"); // its captures' names and header
		PathJoin(userData, "profiles", profiler.Folder);
		EditorProfilerTools.Register(mHost.Server, profiler);
		if (mServices.AddTools != null)
			mServices.AddTools(mHost.Server);

		EditorMcpHostConfig config = .();
		config.Port = (uint16)((mServices.Port != 0) ? mServices.Port : settings.Port);
		config.Token = settings.Token;
		config.TokenFileDirectory = userData;
		if (!mHost.Start(config))
		{
			GlobalLog(.Warning, scope $"MCP: could not listen on 127.0.0.1:{config.Port}, another editor may hold the port; pass --mcp-port <n> or change it in Preferences");
			Stop();
			return false;
		}
		GlobalLog(.Information, scope $"MCP: listening on 127.0.0.1:{mHost.BoundPort} (the token is in <user-data>/{EditorMcpHost.cTokenFileName})");
		context.SetStatus(scope $"MCP host on 127.0.0.1:{mHost.BoundPort}");
		return true;
	}

	/// Stops and releases the host, before the project's services go: a waiting agent sees its
	/// connection close. Nothing when none runs.
	public void Stop()
	{
		DeleteAndNullify!(mHost);
		DeleteAndNullify!(mOperations);
		mSession.Project = null;
	}

	/// Each frame, on the main thread: the calls that arrived are answered here, so a tool may
	/// touch anything the editor owns.
	public void Pump()
	{
		if (mHost != null)
			mHost.Pump();
	}

	/// The build identity host_info reports: the executable's write time (the About box shows
	/// the same).
	public static void BuildStamp(String outStamp)
	{
		let exe = Environment.GetExecutableFilePath(.. scope .());
		if (System.IO.File.GetLastWriteTimeUtc(exe) case .Ok(let time))
			time.ToString(outStamp, "yyyy-MM-ddTHH:mm:ssZ");
		else
			outStamp.Set("unknown");
	}

	/// The services' directory, or the user data directory when they name none.
	private void UserDataDirectory(String outPath)
	{
		if (mServices.UserDataDirectory.IsEmpty)
			GetUserDataDirectory(outPath);
		else
			outPath.Set(mServices.UserDataDirectory);
	}
}
