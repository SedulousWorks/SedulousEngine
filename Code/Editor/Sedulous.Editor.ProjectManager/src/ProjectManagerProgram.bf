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
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Editor.Projects;
using Sedulous.Editor.Look;
using Sedulous.Editor.App;

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
	/// Starts an editor: its executable and arguments, true when it started. Null: a process of its
	/// own (Process.Start). Owned.
	public delegate bool(StringView executable, Span<StringView> arguments) Launch ~ delete _;

	/// Each path left empty set to the user's own.
	public void ResolveUserPaths()
	{
		if (ProjectsPath.IsEmpty)
			ProjectsStore.DefaultPath(ProjectsPath);
		if (EditorSettingsPath.IsEmpty)
			ProjectsStore.DefaultEditorSettingsPath(EditorSettingsPath);
		if (SdksPath.IsEmpty)
			SdkRegistry.DefaultPath(SdksPath);
		if (ThemeFolder.IsEmpty)
			PathJoin(GetUserDataDirectory(.. scope .()), EditorLookHost.cThemeFolder, ThemeFolder);
	}
}

/// The project manager as a program of its own: its window with the editor's look, the recent
/// list in projects.xml (taken once from the editor's store), the SDK it sits in registered and
/// this executable recorded, and the manager (ProjectManagerApp) over them. Opening a project
/// launches the editor built in that SDK with the project and the SDK's data, records the open and
/// exits, as the editor then owns the project. New Project makes the project's folder and manifest,
/// then opens it the same way.
///
/// Start is the headless half (the stores, the registry, the manager), which a test drives with
/// no window; OnStartup adds the window.
class ProjectManagerProgram : IApplication
{
	/// The editor every SDK builds, which opens a project until the project's own is built.
	public const String cStockEditor = "Sedulous.Tools.Editor";
	/// The configurations looked in for it, in this order.
	public static readonly StringView[3] EditorConfigs = .("Debug", "Release", "ShippingRelease");

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
	/// After the network and the GUI it reaches, so it goes first.
	private ProjectManagerApp mApp = null;
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
		// The manager first: its view's downloads cancel through the client, its screen in the GUI.
		DeleteAndNullify!(mApp);
		ShowScreen(null);
	}

	/// The manager; null until Start.
	public ProjectManagerApp App => mApp;
	/// The recent list the manager shows.
	public ProjectManagerController Projects => mController;
	/// The SDK this program sits in; empty when its data root's parent is no SDK.
	public StringView Sdk => mSdk;
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
		mApp = new ProjectManagerApp(AppServices());
	}

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
		services.Http = new () => mRelease.Client();
		if (mRelease.Overridden)
		{
			services.ReleaseFile = new (file, outUrl) => { mRelease.FileUrl(file, outUrl); };
			services.OpenOnSamples = true;
		}
		services.OpenProject = new (directory, restamp) => LaunchEditor(directory);
		services.CreateProject = new (directory, name) => (ProjectScaffold.Create(directory, name) case .Ok) && LaunchEditor(directory);
		return services;
	}

	/// The recent list written to projects.xml, unless that did not read.
	private void SaveStore()
	{
		if (mStoreWritable && (mProjects.Save(mStore) case .Err(let error)))
			GlobalLog(.Error, "Projects: {} could not be written ({})", mConfig.ProjectsPath, error);
	}

	/// The editor built in `sdk` into `outPath`: the stock editor of the first configuration
	/// (EditorConfigs) that has one under Code/build for this host. False when none is built.
	public static bool StockEditor(StringView sdk, String outPath)
	{
		outPath.Clear();
		let file = BuildLayout.ExecutableName(cStockEditor, .. scope .());
		for (let config in EditorConfigs)
		{
			let candidate = scope String();
			PathJoin(sdk, scope $"Code/build/{config}_{BuildLayout.HostPlatformName}/{cStockEditor}/{file}", candidate);
			if (FileExists(candidate))
			{
				outPath.Set(candidate);
				return true;
			}
		}
		return false;
	}

	/// Opens the project in `directory` in the SDK's editor, with the SDK's data, then records the
	/// open and asks to exit: the editor has the project from here. False (said in the log) when
	/// there is no SDK or no editor built in it, or it does not start.
	private bool LaunchEditor(StringView directory)
	{
		let editor = scope String();
		if (mSdk.IsEmpty || !StockEditor(mSdk, editor))
		{
			GlobalLog(.Error, "Projects: no editor is built in the SDK '{}' (build {}) to open {}", mSdk, cStockEditor, directory);
			return false;
		}
		let data = PathJoin(mSdk, "Data", .. scope .());
		let arguments = scope StringView[]("--project", directory, "--data-root", data);
		let started = (mConfig.Launch != null) ? mConfig.Launch(editor, arguments) : Sedulous.Core.Process.Start(editor, arguments);
		if (!started)
		{
			GlobalLog(.Error, "Projects: '{}' did not start", editor);
			return false;
		}
		GlobalLog(.Information, "Projects: {} opened in {}", directory, editor);
		let header = scope ProjectHeader();
		if (ProjectHeader.Read(directory, header) case .Ok)
		{
			mController.NoteOpened(directory, header.Name, header.EngineVersion);
			SaveStore();
		}
		RequestExit();
		return true;
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
		mApp.Tick();
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
		DeleteAndNullify!(mApp); // its dialogs closed and its downloads cancelled, while the window is there
		ShowScreen(null);
		mRelease.Close();
		mGui.Close();
		mHost = null;
	}
}
