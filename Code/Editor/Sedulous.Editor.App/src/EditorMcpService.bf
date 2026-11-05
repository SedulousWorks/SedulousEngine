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
	/// What the editor shows, for host_info: "projectManager" or "editor"; null: from whether a
	/// project is open. Owned.
	public delegate void(String outScreen) Screen ~ delete _;
}

/// The editor's MCP host over the open project, out of the application. It starts when a
/// project opens (when the user enabled it, or --mcp asked for it), minting the token the first
/// time, with the shared engine tools over the application's own services (an agent's cook,
/// import or export takes the paths the menus do) and the editor host's live additions: the
/// pages, the windows' screenshots, the profiler. The application adds the tools that need its
/// other parts through AddTools. It stops before the project's services go, and its calls are
/// answered from Pump, once a frame. The user starts and stops it from the MCP panel too: their
/// Start runs it whatever the preference says, and their Stop holds until they start it again or
/// change the MCP preferences, across the projects opened between. What agents did is kept in its
/// activity (McpActivity), which outlives the host's restarts.
class EditorMcpService
{
	private EditorMcpServiceServices mServices ~ delete _;
	/// The open project, as the engine tools see it; the host only borrows it.
	private ProjectSession mSession = new .() ~ delete _;
	private EditorProjectOperations mOperations = null;
	/// Gone before the operations it runs through (Stop).
	private EditorMcpHost mHost = null;
	/// What agents did through the host in this run.
	private McpActivity mActivity = new .() ~ delete _;
	/// The client that last connected, as it named itself.
	private String mClientName = new .() ~ delete _;
	private String mClientVersion = new .() ~ delete _;
	/// The user's Start runs the host whatever the preference says.
	private bool mUserStarted = false;
	/// The user's Stop holds until their Start or a preference change.
	private bool mStopHeld = false;

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

	/// The host for the project manager, with no project: started when enabled and none runs,
	/// so showing the manager again never restarts one. False when it is not enabled, or could
	/// not listen.
	public bool EnsureRunning()
	{
		if (IsRunning)
			return true;
		return Start(null);
	}

	/// Starts the host over `project` when the preference, the command line or the user's own
	/// Start asks for it and the user's Stop does not hold, stopping a running one first: false
	/// when none asks, or it could not listen (logged: another editor may hold the port). With no
	/// project (the project manager's), the editor's own tools serve and the project's refuse.
	public bool Start(EditorProject project)
	{
		Stop();
		Runtime.Assert(mServices.UserSettings != null, "EditorMcpService: the user settings are required");
		let settings = mServices.UserSettings.Section<EditorMcpSettings>();
		if (mStopHeld || !(settings.Enabled || mServices.ForceEnabled || mUserStarted))
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
		mSession.Plugins = mServices.Context.Plugins; // the project's plugins, enabled with it

		// The operations run on the application's services, so an agent's cook, import or export
		// takes the same background paths the menus do and the editor stays live. The hooks are
		// forwarded, not moved: the host starts again for every project.
		let operations = new EditorProjectOperationsSeams();
		operations.Project = project;
		operations.Context = mServices.Context;
		operations.Cook = mServices.Cook;
		operations.Tasks = mServices.Context.Tasks; // each step on the build lane
		operations.Lane = mServices.Context.BuildLane;
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
		mHost.OnCall = new [=] (report) =>
			{
				mActivity.Record(report, LocalNow());
				if (report.Phase == .Finished)
					context.SetStatus(scope $"MCP: {report.Tool} {report.IsError ? "failed" : "done"}");
			};
		if (mServices.Screen != null)
		{
			mHost.Screen = new (outScreen) =>
				{
					if (mServices.Screen != null)
						mServices.Screen(outScreen);
				};
		}

		// This host's live additions: the pages, over the same open and close paths the tabs take.
		let pages = new PageToolSeams();
		pages.Context = mServices.Context;
		pages.OpenPage = new (id) => (mServices.OpenPage != null) ? mServices.OpenPage(id) : null;
		pages.ClosePage = new (page) =>
			{
				if (mServices.ClosePage != null)
					mServices.ClosePage(page);
			};
		pages.HasProject = new () => mSession.Project != null;
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
		mActivity.RecordEvent(scope $"Listening on 127.0.0.1:{mHost.BoundPort}", LocalNow());
		mClientName.Clear();
		mClientVersion.Clear();
		return true;
	}

	/// The user's Start (the MCP panel's): runs the host over `project` whatever the preference
	/// says, until the user stops it. False when it could not listen.
	public bool StartByUser(EditorProject project)
	{
		mStopHeld = false;
		mUserStarted = true;
		return Start(project);
	}

	/// The user's Stop: the host stops and stays stopped, over every project opened, until the
	/// user starts it again or changes the MCP preferences.
	public void StopByUser()
	{
		mUserStarted = false;
		mStopHeld = true;
		Stop();
	}

	/// The MCP preferences changed: the user's own Start or Stop no longer holds, and the host
	/// follows the preferences again over `project`.
	public void Restart(EditorProject project)
	{
		mUserStarted = false;
		mStopHeld = false;
		Start(project);
	}

	/// Whether the user's Stop holds the host stopped.
	public bool IsStopHeld => mStopHeld;
	/// What agents did through the host in this run. BORROWED.
	public McpActivity Activity => mActivity;
	/// The client that last connected (empty before any did).
	public StringView ClientName => mClientName;
	public StringView ClientVersion => mClientVersion;
	/// The port the host listens on (0: stopped), and the one it starts on.
	public uint16 Port => (mHost != null) ? mHost.BoundPort : 0;
	public uint32 ConfiguredPort => (mServices.Port != 0) ? mServices.Port : mServices.UserSettings.Section<EditorMcpSettings>().Port;

	/// The command that wires an agent (Claude Code) to the running host, with its token,
	/// appended; nothing while stopped.
	public void ConnectCommand(String outCommand)
	{
		if (mHost == null)
			return;
		outCommand.AppendF("claude mcp add --transport http engine-editor http://127.0.0.1:{}/mcp --header \"Authorization: Bearer {}\"",
			mHost.BoundPort, mServices.UserSettings.Section<EditorMcpSettings>().Token);
	}

	/// Stops and releases the host, before the project's services go: a waiting agent sees its
	/// connection close. Nothing when none runs.
	public void Stop()
	{
		if ((mHost != null) && mHost.IsRunning)
			mActivity.HostStopped(LocalNow()); // a host that never listened has nothing to stop
		DeleteAndNullify!(mHost);
		DeleteAndNullify!(mOperations);
		mSession.Project = null;
		mSession.Plugins = null;
	}

	/// Each frame, on the main thread: the calls that arrived are answered here, so a tool may
	/// touch anything the editor owns.
	public void Pump()
	{
		if (mHost == null)
			return;
		mHost.Pump();
		// A client that initialized since: recorded once per change of who it is.
		let server = mHost.Server;
		if (!server.ClientName.IsEmpty && ((server.ClientName != mClientName) || (server.ClientVersion != mClientVersion)))
		{
			mClientName.Set(server.ClientName);
			mClientVersion.Set(server.ClientVersion);
			let line = scope String(mClientName);
			if (!mClientVersion.IsEmpty)
				line.AppendF(" {}", mClientVersion);
			line.Append(" connected");
			mActivity.RecordEvent(line, LocalNow());
		}
	}

	/// The local time now, in seconds since 1970 (CivilTimeOf reads it).
	private static int64 LocalNow()
	{
		let now = GetUnixTime();
		return now + GetLocalTimeOffset(now);
	}

	/// The build identity host_info reports: the executable's write time (the About box shows
	/// the same).
	public static void BuildStamp(String outStamp) => Sedulous.Engine.Project.EngineVersion.ExecutableStamp(outStamp);

	/// The services' directory, or the user data directory when they name none.
	private void UserDataDirectory(String outPath)
	{
		if (mServices.UserDataDirectory.IsEmpty)
			GetUserDataDirectory(outPath);
		else
			outPath.Set(mServices.UserDataDirectory);
	}
}
