using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Settings;
using Sedulous.Xml.Serialization;
using Sedulous.Graphics;
using Sedulous.RHI.Capture;
using Sedulous.Runtime.Client;
using Sedulous.GUI;
using Sedulous.Http.Client;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Editor.Projects;
using Sedulous.Editor.Look;
using Sedulous.Editor.App;
using internal Sedulous.Editor.Project;

namespace Sedulous.Editor.ProjectManager;

/// What the project manager program runs with: the command line's choices and the files it
/// keeps. Every path left empty is the user's own.
class ProjectManagerConfig
{
	/// The data root the manager's look is read from, whose parent is the SDK it sits in.
	public String DataRoot = new .() ~ delete _;
	/// The recent list (ProjectsStore.DefaultPath).
	public String ProjectsPath = new .() ~ delete _;
	/// The editor's store, read for the appearance preferences and, once, the recent list
	/// (ProjectsStore.DefaultEditorSettingsPath).
	public String EditorSettingsPath = new .() ~ delete _;
	/// The SDK registry (SdkRegistry.DefaultPath).
	public String SdksPath = new .() ~ delete _;
	/// Where the Engines page installs engines (SdkRegistry.ManagedDirectory).
	public String SdksDirectory = new .() ~ delete _;
	/// Where the Toolchain page installs toolchains (<user-data>/Sedulous/Toolchains).
	public String ToolchainsDirectory = new .() ~ delete _;
	/// Where the Engines page reads the list of releases; empty: GitHub's (or, with --release-files,
	/// its releases.json).
	public String ReleasesUrl = new .() ~ delete _;
	/// Where a file of a release is fetched from, given its tag, its name and the URL the releases
	/// list published (empty: none); null: that URL, else the release's (or --release-files'). Owned.
	public delegate void(StringView tag, StringView file, StringView published, String outUrl) AssetUrl ~ delete _;
	/// The HTTP client the releases are fetched with, BORROWED; null: one over TLS made on first use.
	public IHttpClient Http = null;
	/// The user's theme overrides' folder (<user-data>/theme).
	public String ThemeFolder = new .() ~ delete _;
	/// This program's executable, recorded in the SDK registry for an editor to start the manager
	/// again; empty: nothing recorded.
	public String ExecutablePath = new .() ~ delete _;
	/// --release-files: where the Samples tab reads the release's files; empty: the release.
	public String ReleaseFiles = new .() ~ delete _;
	/// --screenshot: the main window as a PNG once it has drawn; empty: none.
	public String ScreenshotPath = new .() ~ delete _;
	/// --screenshot-exit: quit once the screenshot is written (or failed).
	public bool ScreenshotExit = false;
	/// --exit-after: quit after this many seconds; 0: never.
	public float ExitAfterSeconds = 0.0f;
	/// --open: a project folder opened as though picked, once the window is up; empty: none.
	/// What a check (or a script) uses to open a project without clicking.
	public String OpenPath = new .() ~ delete _;
	/// --page: the tab the manager starts on; null: Projects (Samples with --release-files, which a
	/// run is pointed at to try them). What a check or a screenshot of one page uses.
	public ManagerPage? StartPage = null;
	/// Starts an editor: its executable and arguments, true when it started. Null: a process of its
	/// own (Process.Start). Owned.
	public delegate bool(StringView executable, Span<StringView> arguments) Launch ~ delete _;
	/// Finds the SDK a project opens with, from the data root and the project's folder. Null:
	/// ProjectBuild.FindSdkFrom over SEDULOUS_SDK, the SDK registry (SdksPath), the data root and
	/// the folders above the project. Owned.
	public SdkFinder FindSdk ~ delete _;
	/// What the toolchain check reads of its surroundings. Null: this process's. Owned.
	public ToolchainProbe Probe ~ delete _;
	/// Runs BeefBuild for a project's editor, on the build's own thread. Null: Process.RunStreaming.
	/// Owned.
	public BuildRunner Runner ~ delete _;

	/// The command line's flags (ProjectManagerMain's usage) into this config. A --page that names no
	/// tab is said in the log and left out.
	public void ReadCommandLine(Span<String> args)
	{
		for (int i = 0; i < args.Length - 1; i++)
		{
			if (args[i] == "--release-files")
				ReleaseFiles.Set(args[i + 1]);
			else if (args[i] == "--screenshot")
				ScreenshotPath.Set(args[i + 1]);
			else if (args[i] == "--open")
				OpenPath.Set(args[i + 1]);
			else if (args[i] == "--exit-after")
				ExitAfterSeconds = float.Parse(args[i + 1]).GetValueOrDefault();
			else if (args[i] == "--page")
			{
				ManagerPage page;
				if (ParsePage(args[i + 1], out page))
					StartPage = page;
				else
					GlobalLog(.Warning, "Projects: --page {} is no tab (projects, samples, engines or toolchain)", args[i + 1]);
			}
		}
		for (let arg in args)
		{
			if (arg == "--screenshot-exit")
				ScreenshotExit = true;
		}
	}

	/// The tab `name` names (projects, samples, engines, toolchain; any case); false for none.
	public static bool ParsePage(StringView name, out ManagerPage outPage)
	{
		outPage = .Projects;
		if (name.Equals("projects", true))
			outPage = .Projects;
		else if (name.Equals("samples", true))
			outPage = .Samples;
		else if (name.Equals("engines", true))
			outPage = .Engines;
		else if (name.Equals("toolchain", true))
			outPage = .Toolchain;
		else
			return false;
		return true;
	}

	/// Each path left empty set to the user's own.
	public void ResolveUserPaths()
	{
		if (ProjectsPath.IsEmpty)
			ProjectsStore.DefaultPath(ProjectsPath);
		if (EditorSettingsPath.IsEmpty)
			ProjectsStore.DefaultEditorSettingsPath(EditorSettingsPath);
		if (SdksPath.IsEmpty)
			SdkRegistry.DefaultPath(SdksPath);
		if (SdksDirectory.IsEmpty)
			SdkRegistry.ManagedDirectory(SdksDirectory);
		if (ToolchainsDirectory.IsEmpty)
			PathJoin(GetUserDataDirectory(.. scope .()), ProjectBuild.cToolchainsDir, ToolchainsDirectory);
		if (ThemeFolder.IsEmpty)
			PathJoin(GetUserDataDirectory(.. scope .()), EditorLookHost.cThemeFolder, ThemeFolder);
	}
}

/// The project manager as a program of its own: its window with the editor's look, the recent
/// list in projects.xml (taken once from the editor's store), the SDK it sits in registered and
/// this executable recorded, and the manager (ProjectManagerApp) over them.
///
/// Every project opens in its own editor, <Game>Editor, which Open builds and launches:
/// 1. its header read (a folder with no project is refused);
/// 2. the SDK it opens with picked (FindSdk: SEDULOUS_SDK, the project's pin or an SDK of its
///    version in the registry, the SDK this program sits in, a checkout above the project); with
///    none, it says which engine the project needs;
/// 3. the gate against that SDK's version (an older engine's project asks about a backup and is
///    stamped by the editor; a newer one's warns);
/// 4. the toolchain checked (Toolchain.Check): a missing BeefBuild, linker or archiver stops it,
///    said with the fix;
/// 5. the editor built in Debug on a thread of its own when it is stale over that SDK (always over
///    a checkout, where BeefBuild rebuilds what changed), shown on a panel over the projects with
///    its output, its diagnostics and Cancel; a failure stays there and launches nothing;
/// 6. the editor launched with --project, --data-root <sdk>/Data, --manager <this executable> and,
///    for an older engine's project, --restamp; the open recorded, and this program exits, as the
///    editor owns the project from there.
/// New Project makes the project from a template of the engine picked (the newest installed at
/// first), pins it to that engine, then opens it the same way. One build runs at a time.
///
/// The engines side by side (EngineManager) are the Engines and Toolchain tabs: the engines listed
/// and offered by the releases, installed, added and removed, and the toolchain each needs. A
/// project's menu picks the engine it opens with: one of its version only pins it, another
/// upgrades it (its manifest backed up when asked, the editor built over that engine and told to
/// stamp it) or opens it with an older engine after the warning.
///
/// Start is the headless half (the stores, the registry, the manager), which a test drives with
/// no window, calling Pump for what a frame does; OnStartup adds the window.
class ProjectManagerProgram : IApplication
{
	/// The config a project's editor is built in.
	public const String cEditorConfig = "Debug";

	private ProjectManagerConfig mConfig ~ delete _;
	private Settings mStore = new .() ~ delete _;
	private ProjectsStore mProjects ~ delete _;
	/// False when projects.xml did not read: the list then is never saved over it.
	private bool mStoreWritable = true;
	private ProjectManagerController mController ~ delete _;
	private SdkRegistry mSdks ~ delete _;
	/// The SDK this program sits in (the data root's parent); empty when that is no SDK.
	private String mSdk = new .() ~ delete _;
	private EditorLookHost mGui = new .() ~ delete _;
	private ReleaseAccess mRelease ~ delete _;
	/// The engines and toolchains for the Engines and Toolchain tabs; made by Start, and let go
	/// after the manager (its pages read it) and before the client its downloads run on.
	private EngineManager mEngines = null;
	/// The editor being built for an open, or the last one built, until another open or its
	/// panel's close; null for none.
	private EditorBuildRun mBuild = null;
	/// The build's panel while it shows (with a window); null with none.
	private EditorBuildPanel mPanel = null;
	/// The panel's window went (Close, or its own close button): the panel and an ended build are
	/// let go at the next frame, not inside the GUI's event.
	private bool mPanelClosed = false;
	/// The build's end has been seen to (its editor launched, or why not said).
	private bool mBuildSettled = false;
	private String mStatus = new .() ~ delete _;
	/// After the network and the GUI it reaches, so it goes first.
	private ProjectManagerApp mApp = null;
	/// Whether --open's folder was opened.
	private bool mOpenFired = false;
	/// The manager's screen over the window: a reference of ours, the tree holding its own.
	private Node mScreen = null;
	/// Borrowed; null when run headless.
	private IApplicationHost mHost = null;
	private ScreenshotCapture mCapture = new .() ~ delete _;
	private float mElapsed = 0.0f;
	private bool mShotFired = false;
	private bool mExitRequested = false;

	/// TAKES OWNERSHIP of the config; its empty paths become the user's.
	public this(ProjectManagerConfig config)
	{
		mConfig = config;
		mConfig.ResolveUserPaths();
		mProjects = new ProjectsStore(mConfig.ProjectsPath, mConfig.EditorSettingsPath);
		mController = new ProjectManagerController(mStore);
		mSdks = new SdkRegistry(mConfig.SdksPath);
		mRelease = new ReleaseAccess(mConfig.ReleaseFiles);
	}

	public ~this()
	{
		// A build first: cancelled, its thread waited for. Then the manager: its view's downloads
		// cancel through the client, its screen in the GUI.
		DeleteAndNullify!(mPanel);
		DeleteAndNullify!(mBuild);
		DeleteAndNullify!(mApp);
		DeleteAndNullify!(mEngines);
		ShowScreen(null);
	}

	/// The manager; null until Start.
	public ProjectManagerApp App => mApp;
	/// The build of a project's editor running, or the last one, until another open or its panel
	/// closes; null for none.
	public BuildJob Build => (mBuild != null) ? mBuild.Job : null;
	/// A project's editor is being built.
	public bool Building => (mBuild != null) && !mBuild.Ended;
	/// The recent list the manager shows.
	public ProjectManagerController Projects => mController;
	/// The SDK this program sits in; empty when its data root's parent is no SDK.
	public StringView Sdk => mSdk;
	/// The engines and toolchains side by side; null until Start.
	public EngineManager Engines => mEngines;
	/// The last Start took the recent list from the editor's store.
	public bool Migrated => mProjects.Migrated;
	/// It has asked to exit (a project launched, or the command line's time is up).
	public bool ExitRequested => mExitRequested;

	/// The headless half: the section types registered, the recent list read (taken from the
	/// editor's store the first time), the SDK this program sits in registered and this executable
	/// recorded, and the manager made. Once.
	public void Start()
	{
		if (mApp != null)
			return;
		EditorProjectsSerializables.RegisterAll();
		EditorLookSerializables.RegisterAll();
		ProjectsStore.RegisterFormerNames();
		EditorUiSettings.RegisterFormerName();
		if (mProjects.Load(mStore) case .Err(let error))
		{
			mStoreWritable = false;
			GlobalLog(.Error, "Projects: {} did not read ({}); the list is not saved over it", mConfig.ProjectsPath, error);
		}
		else if (mProjects.Migrated)
			GlobalLog(.Information, "Projects: the recent projects were taken from {} into {}", mConfig.EditorSettingsPath, mConfig.ProjectsPath);
		RegisterSdk();
		mEngines = new EngineManager(EnginesConfig(), mSdks, mController);
		mApp = new ProjectManagerApp(AppServices());
	}

	/// What the engine manager works over: this program's client and release files, the folders
	/// engines and toolchains are installed in, the SDK it sits in and the toolchain probe.
	private EngineManagerConfig EnginesConfig()
	{
		let config = new EngineManagerConfig();
		config.Http = new () => Client();
		if (!mConfig.ReleasesUrl.IsEmpty)
		{
			let url = new String(mConfig.ReleasesUrl);
			config.ReleasesUrl = new [=url] (outUrl) => { outUrl.Set(url); } ~ delete url;
		}
		else if (mRelease.Overridden)
			config.ReleasesUrl = new (outUrl) => { mRelease.FileUrl("releases.json", outUrl); };
		if (mConfig.AssetUrl != null)
			config.AssetUrl = new (tag, file, published, outUrl) => { mConfig.AssetUrl(tag, file, published, outUrl); };
		else if (mRelease.Overridden)
			config.AssetUrl = new (tag, file, published, outUrl) => { mRelease.FileUrl(file, outUrl); };
		config.SdksDirectory.Set(mConfig.SdksDirectory);
		config.ToolchainsDirectory.Set(mConfig.ToolchainsDirectory);
		config.OwnSdk.Set(mSdk);
		config.Probe = mConfig.Probe;
		return config;
	}

	/// The client releases are fetched with: the config's, else one over TLS made on first use.
	private IHttpClient Client() => (mConfig.Http != null) ? mConfig.Http : mRelease.Client();

	/// The SDK this program sits in, listed unless it is (a checkout, an unpacked SDK, or one the
	/// manager installed), and this executable recorded as the manager that ran last.
	private void RegisterSdk()
	{
		mSdk.Clear();
		if (!mConfig.DataRoot.IsEmpty)
		{
			let parent = PathParent(mConfig.DataRoot, .. scope .());
			if (ProjectBuild.IsSdk(parent))
			{
				if (mSdks.Adopt(parent) case .Err(let error))
					GlobalLog(.Error, "Projects: the SDK {} could not be registered in {} ({})", parent, mConfig.SdksPath, error);
				mSdk.Set(parent);
			}
			else
				GlobalLog(.Warning, "Projects: {} is not an SDK: no editor to open projects with", parent);
		}
		if (!mConfig.ExecutablePath.IsEmpty && (mSdks.RecordManager(mConfig.ExecutablePath) case .Err(let recordError)))
			GlobalLog(.Error, "Projects: this manager could not be recorded in {} ({})", mConfig.SdksPath, recordError);
	}

	private ProjectManagerAppServices AppServices()
	{
		let services = new ProjectManagerAppServices();
		services.Projects = mController;
		services.Root = new () => mGui.Root;
		services.Dialogs = new () => ((mHost != null) && (mHost.Shell != null)) ? mHost.Shell.Dialogs : null;
		services.ShowScreen = new (screen) => { ShowScreen(screen); };
		services.LoadMarkup = new (path) => mGui.LoadMarkup(path);
		services.StoreChanged = new () => { SaveStore(); };
		services.Http = new () => Client();
		if (mRelease.Overridden)
		{
			services.ReleaseFile = new (version, file, outUrl) => { mRelease.FileUrl(version, file, outUrl); };
			services.StartPage = .Samples;
		}
		if (mConfig.StartPage.HasValue)
			services.StartPage = mConfig.StartPage.Value;
		services.EngineFor = new (directory, outVersion, outWhy) => EngineFor(directory, outVersion, outWhy);
		services.OpenProject = new (directory, restamp, outWhy) => OpenInEditor(directory, restamp, outWhy);
		services.CreateProject = new (directory, name, template, sdk, outWhy) => CreateFromTemplate(directory, name, template, sdk, outWhy);
		services.Engines = new (outEngines) => { ListEngines(outEngines); };
		services.Templates = new (sdk, outTemplates) => { ListTemplates(sdk, outTemplates); };
		services.PinEngine = new (directory, sdk, outWhy) => PinEngine(directory, sdk, outWhy);
		services.EngineOf = new (directory, outSdk) => PickSdk(directory, outSdk);
		services.EngineManager = mEngines;
		return services;
	}

	/// The engines New Project and a project's menu offer, into `outEngines` (each new, the
	/// caller's): the registered SDKs that read, the newest version first (NewerSdk), else the SDK
	/// this program sits in; each with its version and how it is listed.
	public void ListEngines(List<NewProjectEngine> outEngines)
	{
		let listed = scope List<ListedSdk>();
		defer { ClearAndDeleteItems!(listed); }
		mSdks.ReadListed(listed);
		for (int i = listed.Count - 1; i >= 0; i--)
		{
			let candidate = listed[i];
			if (candidate.Info != null)
				continue;
			listed.RemoveAt(i); // missing: nothing to make or open a project with
			delete candidate;
		}
		if (listed.IsEmpty && !mSdk.IsEmpty)
		{
			let own = new ListedSdk();
			own.Root.Set(mSdk);
			own.Info = new SdkInfo();
			if (SdkInfo.Read(mSdk, own.Info) case .Ok)
				listed.Add(own);
			else
				delete own;
		}
		listed.Sort(scope (a, b) => NewerSdk(a.Info, b.Info) ? -1 : (NewerSdk(b.Info, a.Info) ? 1 : 0));
		for (let entry in listed)
		{
			let sdk = entry.Info;
			let engine = new NewProjectEngine();
			engine.Sdk.Set(sdk.Root);
			engine.Label.AppendF("{}{} at {}", sdk.Display, sdk.IsCheckout ? " (checkout)" : "", sdk.Root);
			engine.Version.Set(sdk.Version);
			engine.Display.Set(sdk.Display);
			if (sdk.IsCheckout)
				engine.Kind.Set(InstalledEngine.KindName(.Checkout));
			else
				engine.Kind.Set(InstalledEngine.KindName(entry.Managed ? EngineKind.Installed : EngineKind.Folder));
			outEngines.Add(engine);
		}
	}

	/// The project in `directory` pinned to the SDK at `sdk`: the engine it opens with from now on.
	/// False, with why in `outWhy`, when the registry cannot be written.
	private bool PinEngine(StringView directory, StringView sdk, String outWhy)
	{
		if (mSdks.Pin(directory, sdk) case .Err(let error))
		{
			outWhy.AppendF("The project could not be pinned to the engine at {} in {} ({}).", sdk, mConfig.SdksPath, error);
			GlobalLog(.Error, "Projects: {}", outWhy);
			return false;
		}
		return true;
	}

	/// Whether `a` is listed before `b` among the engines New Project offers: a version that reads
	/// before one that does not, then the higher version, then, of one version, the SDK
	/// SdkRegistry.Prefer prefers.
	public static bool NewerSdk(SdkInfo a, SdkInfo b)
	{
		uint32[3] versionA;
		uint32[3] versionB;
		let readsA = ProjectRegistry.ParseEngineVersion(a.Version, out versionA);
		let readsB = ProjectRegistry.ParseEngineVersion(b.Version, out versionB);
		if (readsA != readsB)
			return readsA;
		for (int i < 3)
		{
			if (versionA[i] != versionB[i])
				return versionA[i] > versionB[i];
		}
		return SdkRegistry.Prefer(a, b);
	}

	/// The project templates of the SDK at `sdk` (its Data/Templates), in their order, into
	/// `outTemplates` (each new, the caller's).
	public static void ListTemplates(StringView sdk, List<ProjectTemplate> outTemplates)
	{
		if (!sdk.IsEmpty)
			ProjectTemplates.ListTemplates(PathJoin(sdk, "Data", .. scope .()), outTemplates);
	}

	/// New Project's project made at `directory` from the template in the folder `template` (none:
	/// the bare manifest and folders), pinned to the SDK at `sdk` when one was picked, then opened
	/// in its editor as any other. False, with why in `outWhy`, when it is not made or does not open.
	private bool CreateFromTemplate(StringView directory, StringView name, StringView template, StringView sdk, String outWhy)
	{
		if (template.IsEmpty)
		{
			if (ProjectScaffold.Create(directory, name) case .Err)
				return false;
		}
		else if (ProjectTemplates.Instantiate(template, directory, name) case .Err(let error))
		{
			if (error == .AlreadyExists)
				outWhy.Set("That folder is not empty: a project is made in a new or empty folder.");
			else
				outWhy.AppendF("The project could not be made from the template in {} ({}).", template, error);
			GlobalLog(.Error, "Projects: {}", outWhy);
			mStatus.Set(outWhy);
			return false;
		}
		if (!sdk.IsEmpty && (mSdks.Pin(directory, sdk) case .Err(let pinError)))
			GlobalLog(.Warning, "Projects: {} could not be pinned to the SDK at {} in {} ({})", directory, sdk, mConfig.SdksPath, pinError);
		return OpenInEditor(directory, false, outWhy);
	}

	/// The recent list written to projects.xml, unless that did not read.
	private void SaveStore()
	{
		if (mStoreWritable && (mProjects.Save(mStore) case .Err(let error)))
			GlobalLog(.Error, "Projects: {} could not be written ({})", mConfig.ProjectsPath, error);
	}

	/// What the manager said last of an open: why it did not open, or how its editor's build
	/// ended. The status line shows it.
	public StringView Status => mStatus;

	/// `text` on the status line, and kept as Status.
	private void Say(StringView text)
	{
		mStatus.Set(text);
		if (mApp != null)
			mApp.SetStatus(text);
	}

	/// The SDK the project in `directory` opens with, absolute, into `outSdk`: the config's finder,
	/// else ProjectBuild.FindSdkFrom over SEDULOUS_SDK, the SDK registry, the data root and the
	/// folders above the project. False when none is found.
	public bool PickSdk(StringView directory, String outSdk)
	{
		outSdk.Clear();
		if (mConfig.FindSdk != null)
			return mConfig.FindSdk(mConfig.DataRoot, directory, outSdk);
		let variable = scope String();
		if (Environment.GetEnvironmentVariable(ProjectBuild.cSdkVariable, variable) case .Err)
			variable.Clear();
		return ProjectBuild.FindSdkFrom(variable, mSdks, mConfig.DataRoot, directory, outSdk);
	}

	/// The version of the SDK the project in `directory` opens with, for the gate; false, with the
	/// engine the project needs in `outWhy`, when there is none.
	private bool EngineFor(StringView directory, String outVersion, String outWhy)
	{
		let sdk = scope String();
		let info = scope SdkInfo();
		if (PickSdk(directory, sdk) && (SdkInfo.Read(sdk, info) case .Ok))
		{
			outVersion.Set(info.Version);
			return true;
		}
		NeedsEngine(directory, outWhy);
		mStatus.Set(outWhy);
		return false;
	}

	/// What an open with no SDK to build the project's editor over says: the engine its stamp names.
	private static void NeedsEngine(StringView directory, String outWhy)
	{
		let header = scope ProjectHeader();
		ProjectHeader.Read(directory, header).IgnoreError();
		if (header.EngineVersion.IsEmpty)
			outWhy.Set("This project names no engine, and there is none here to open it with: install one, or open it from an engine's folder.");
		else
			outWhy.Set(scope $"This project needs engine {header.EngineVersion}: Install it, or choose another engine (it will be upgraded).");
	}

	/// Opens the project in `directory` in its own editor, the gate passed: the SDK picked, the
	/// toolchain checked, then the editor built on a thread of its own when it is stale over that
	/// SDK (Pump launches it once built), else launched at once. False, with why in `outWhy`, when
	/// it cannot start: a build running already, no SDK, a toolchain that cannot build, settings
	/// this manager does not read, or an editor that does not start.
	private bool OpenInEditor(StringView directory, bool restamp, String outWhy)
	{
		let opened = TryOpenInEditor(directory, restamp, outWhy);
		if (!opened)
		{
			GlobalLog(.Error, "Projects: {} did not open: {}", directory, outWhy);
			mStatus.Set(outWhy);
		}
		return opened;
	}

	private bool TryOpenInEditor(StringView directory, bool restamp, String outWhy)
	{
		if (Building)
		{
			outWhy.Set("A project's editor is being built: one build at a time.");
			return false;
		}
		DropBuild();
		let projectDir = ProjectBuild.Absolute(directory, .. scope .());
		let sdk = scope String();
		let info = scope SdkInfo();
		if (!PickSdk(projectDir, sdk) || (SdkInfo.Read(sdk, info) case .Err))
		{
			NeedsEngine(projectDir, outWhy);
			return false;
		}

		let report = scope ToolchainReport();
		Toolchain.Check(info, report, mConfig.Probe);
		if (!report.CanBuild)
		{
			let missing = scope String();
			for (let line in report.Lines)
			{
				if ((line.Need == .Emscripten) || (line.State != .Missing))
					continue; // a web export's alone: an editor is a desktop build
				GlobalLog(.Error, "Projects: the toolchain: {}", line.Detail);
				if (missing.IsEmpty)
					missing.Set(line.Detail);
			}
			outWhy.AppendF("This project's editor cannot be built: {}", missing);
			return false;
		}

		// The settings the build generates the workspace from, read at this manager's data versions.
		let settings = new ProjectSettings();
		if (ProjectRegistry.ProbeProject(projectDir, settings) case .Err)
		{
			delete settings;
			outWhy.AppendF("This project's settings do not read with this manager (engine {}): open it with its own engine's manager.", EngineVersion.Display);
			return false;
		}
		if (!ProjectBuild.IsStale(projectDir, settings, cEditorConfig, sdk))
		{
			let game = ProjectBuild.GameName(settings.Name, .. scope .());
			delete settings;
			return Launch(ProjectBuild.ExecutablePath(projectDir, game, true, cEditorConfig, .. scope .()), projectDir, sdk, restamp, outWhy);
		}

		let name = scope String(settings.Name);
		let job = new BuildJob(.Editor, projectDir, PathJoin(sdk, "Data", .. scope .()), settings);
		let configRunner = mConfig.Runner; // the config's, which outlives the build
		BuildRunner runner = null;
		if (configRunner != null)
			runner = new [=configRunner] (executable, arguments, onLine, cancelled) => configRunner(executable, arguments, onLine, cancelled);
		let picked = new String(sdk);
		let service = new ProjectBuildService(runner, report.BeefBuild, default,
			new [=picked] (dataRoot, project, outSdk) =>
			{
				outSdk.Set(picked); // the SDK the gate and the toolchain were checked against
				return true;
			} ~ delete picked);
		mBuild = new EditorBuildRun(service, job, projectDir, sdk, restamp);
		mBuildSettled = false;
		mBuild.Start();
		GlobalLog(.Information, "Projects: building the editor of {} over the SDK at {}", projectDir, sdk);
		Say(scope $"Building {name}'s editor (a project's first build compiles the engine too, which takes minutes)...");
		ShowPanel(name);
		return true;
	}

	/// The editor at `editor` started on the project in `projectDir`, with the SDK's data, this
	/// program as its manager and, when asked, --restamp; then the open recorded and this program
	/// asked to exit: the editor has the project from here. False, with why in `outWhy`, when it
	/// does not start.
	private bool Launch(StringView editor, StringView projectDir, StringView sdk, bool restamp, String outWhy)
	{
		let data = PathJoin(sdk, "Data", .. scope .());
		let manager = !mConfig.ExecutablePath.IsEmpty;
		let arguments = scope StringView[4 + (manager ? 2 : 0) + (restamp ? 1 : 0)];
		arguments[0] = "--project";
		arguments[1] = projectDir;
		arguments[2] = "--data-root";
		arguments[3] = data;
		int next = 4;
		if (manager)
		{
			arguments[next++] = "--manager";
			arguments[next++] = mConfig.ExecutablePath;
		}
		if (restamp)
			arguments[next++] = "--restamp";
		let started = (mConfig.Launch != null) ? mConfig.Launch(editor, arguments) : Sedulous.Core.Process.Start(editor, arguments);
		if (!started)
		{
			outWhy.AppendF("The project's editor '{}' did not start.", editor);
			return false;
		}
		GlobalLog(.Information, "Projects: {} opened in {}", projectDir, editor);
		let header = scope ProjectHeader();
		if (ProjectHeader.Read(projectDir, header) case .Ok)
		{
			// Restamped, it carries the SDK's version once the editor has opened it.
			let stamp = scope String(header.EngineVersion);
			let info = scope SdkInfo();
			if (restamp && (SdkInfo.Read(sdk, info) case .Ok))
				stamp.Set(info.Version);
			mController.NoteOpened(projectDir, header.Name, stamp);
			SaveStore();
		}
		RequestExit();
		return true;
	}

	/// What a frame does besides the GUI: the build of a project's editor followed (its panel
	/// filled; once it has ended, its editor launched, or why not said), and a panel that closed
	/// let go. OnUpdate calls it; a headless test calls it in its place.
	public void Pump()
	{
		if (mEngines != null)
			mEngines.Tick();
		if (mBuild != null)
		{
			let ended = mBuild.Ended;
			if ((mPanel != null) && !mBuildSettled) // while it runs, and once as it ends
				mPanel.Fill(mBuild.Job);
			if (ended && !mBuildSettled)
			{
				mBuildSettled = true;
				BuildEnded();
			}
		}
		if (mPanelClosed)
		{
			mPanelClosed = false;
			DeleteAndNullify!(mPanel);
			if ((mBuild != null) && mBuild.Ended)
				DeleteAndNullify!(mBuild);
		}
	}

	/// The build has ended: built, its editor launched; failed or cancelled, said, and nothing
	/// launched (a failure's diagnostics stay on the panel).
	private void BuildEnded()
	{
		let job = mBuild.Job;
		let state = job.State;
		let why = scope String();
		if (state == .Succeeded)
		{
			let made = scope List<String>();
			defer { ClearAndDeleteItems!(made); }
			job.GetExecutables(made);
			if (!made.IsEmpty && Launch(made[0], mBuild.ProjectDirectory, mBuild.Sdk, mBuild.Restamp, why))
				return;
			if (why.IsEmpty)
				why.Set("The project's editor was built, and is not there.");
		}
		else if (state == .Cancelled)
			why.Set("The build was cancelled: the project did not open.");
		else
			why.AppendF("The project's editor did not build: {}", job.GetError(.. scope .()));
		GlobalLog(.Error, "Projects: {}", why);
		Say(why);
	}

	/// Cancels the build running, from the panel or a test: it ends Cancelled, and nothing launches.
	public void CancelBuild()
	{
		if (mBuild != null)
			mBuild.Cancel();
	}

	/// The build's panel over the projects, when there is a window: the build shown on it, Cancel
	/// stopping it, and its close (once the build has ended, or a close mid-build, which cancels)
	/// letting both go at the next frame.
	private void ShowPanel(StringView name)
	{
		let root = mGui.Root;
		if ((root == null) || (mBuild == null))
			return;
		let body = mGui.LoadMarkup(EditorBuildPanel.cMarkupPath);
		if (body == null)
			return;
		mPanel = new EditorBuildPanel(body);
		mPanel.Open(root, scope $"Building {name}'s editor", new () => { CancelBuild(); }, new () =>
			{
				mPanelClosed = true;
				CancelBuild(); // closed mid-build: nothing is to open
			});
		mPanel.Fill(mBuild.Job);
	}

	/// The last build and its panel let go, before another open: a build that has not ended stays.
	private void DropBuild()
	{
		if ((mBuild == null) || !mBuild.Ended)
			return;
		DeleteAndNullify!(mPanel);
		DeleteAndNullify!(mBuild);
		mPanelClosed = false; // the panel's close as it went: nothing left to let go
	}

	private void RequestExit()
	{
		mExitRequested = true;
		if (mHost != null)
			mHost.RequestExit();
	}

	/// The manager's screen over the window's root; null takes it away.
	private void ShowScreen(Node screen)
	{
		if (screen != null)
			screen.AddRef(); // first: the screen shown again is not let go below
		if (mScreen != null)
		{
			mScreen.RemoveFromParent();
			mScreen.ReleaseRef();
		}
		mScreen = screen;
		if ((mScreen != null) && (mGui.Root != null))
			mGui.Root.AddChild(mScreen);
	}

	/// The appearance preferences the editor's store holds, into `outLook`: the editor's defaults
	/// when it has none or does not read.
	public static void ReadLook(StringView editorSettingsPath, EditorLook outLook)
	{
		let store = scope Settings();
		if (FileExists(editorSettingsPath))
		{
			let stream = scope FileStream(editorSettingsPath, .Read);
			let factory = XmlSerializerFactory();
			defer delete factory;
			let types = scope SerializableRegistry();
			EditorLookSerializables.RegisterAll(types);
			if (stream.IsValid && (store.Load(stream, factory, types) case .Err))
				GlobalLog(.Warning, "Projects: {} did not read; the editor's default look", editorSettingsPath);
		}
		outLook.ReadFrom(store.Find<EditorUiSettings>());
	}

	// ---- IApplication ----

	public RenderWindowDesc MainRenderWindow => EditorLookHost.WindowDesc();

	public void OnStartup(IApplicationHost host)
	{
		mHost = host;
		Start();
		let look = scope EditorLook();
		ReadLook(mConfig.EditorSettingsPath, look);
		if (mGui.Open(host.Graphics, host.Shell, mConfig.DataRoot, look, mConfig.ThemeFolder))
			mGui.Attach(host.MainRenderWindow);
		else
			GlobalLog(.Error, "Projects: the window has no interface");
		mApp.Enter();
	}

	public void OnUpdate(IApplicationHost host, float deltaTime)
	{
		// Recorded last frame: written once the GPU has run the copy.
		if (mCapture.Recorded && (host.Graphics != null) && (host.Graphics.Raw != null))
		{
			host.Graphics.Raw.WaitIdle();
			let written = scope Sedulous.Image.Image();
			if (mCapture.Complete(host.Graphics.Raw, written) case .Ok)
				GlobalLog(.Information, "Projects: the screenshot is at {}", mConfig.ScreenshotPath);
			else
				GlobalLog(.Error, "Projects: the screenshot {} failed", mConfig.ScreenshotPath);
			if (mConfig.ScreenshotExit)
				RequestExit();
		}
		mRelease.Pump(); // --release-files <folder>: before the client asks again
		if (!mConfig.OpenPath.IsEmpty && !mOpenFired)
		{
			mOpenFired = true; // --open: once, as a pick of that folder
			mApp.OpenFrom(mConfig.OpenPath);
		}
		mApp.Tick();
		Pump();
		mGui.Update(deltaTime);
		mElapsed += deltaTime;
		if ((mConfig.ExitAfterSeconds > 0.0f) && (mElapsed >= mConfig.ExitAfterSeconds))
			RequestExit();
		if (!mConfig.ScreenshotPath.IsEmpty && !mShotFired)
		{
			mShotFired = true; // one shot: the next frame records it
			mCapture.Request(mConfig.ScreenshotPath);
		}
	}

	public void OnRenderWindow(IApplicationHost host, ref FrameContext frame)
	{
		mGui.Render(ref frame);
		// The finished backbuffer, the GUI included, when a screenshot is armed.
		if (mCapture.Armed && frame.Valid && (frame.Window === host.MainRenderWindow) && (frame.Encoder != null)
			&& (host.Graphics != null) && (host.Graphics.Raw != null))
		{
			if (!mCapture.Record(host.Graphics.Raw, frame.Encoder, frame.Backbuffer, frame.Window.Swap.Format, frame.Width, frame.Height)
				&& mConfig.ScreenshotExit)
				RequestExit(); // it cannot be taken: said by the capture
		}
	}

	public void OnShutdown(IApplicationHost host)
	{
		if ((host.Graphics != null) && (host.Graphics.Raw != null))
			mCapture.Release(host.Graphics.Raw); // the readback buffer, while the device lives
		DeleteAndNullify!(mPanel); // its window, while the GUI is there
		DeleteAndNullify!(mBuild); // a build running is cancelled, its thread waited for
		DeleteAndNullify!(mApp); // its dialogs closed and its downloads cancelled, while the window is there
		DeleteAndNullify!(mEngines); // its installs cancelled, while their client is there
		ShowScreen(null);
		mRelease.Close();
		mGui.Close();
		mHost = null;
	}
}
