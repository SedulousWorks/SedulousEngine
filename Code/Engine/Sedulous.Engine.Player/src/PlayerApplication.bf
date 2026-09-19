using System;
using Sedulous.Audio;
using Sedulous.Audio.Resource;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Audio;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.GameInstance;
using Sedulous.Engine.Project;
using Sedulous.Engine.Render;
using Sedulous.Engine.Scene;
using Sedulous.Engine.UI;
using Sedulous.Fonts.Resource;
using Sedulous.Input.Resource;
using Sedulous.Runtime;
using Sedulous.Runtime.Client;
using Sedulous.Scene;
using Sedulous.Settings;
using Sedulous.UI;
using Sedulous.UI.Resource;
using Sedulous.Script.Resource;
using Sedulous.VFS;
using Sedulous.VFS.Pak;
using Sedulous.Xml.Serialization;

namespace Sedulous.Engine.Player;

/// The generic game runner: a project with NO native game code at all.
///
/// The engine's subsystems, the project's content, and its default scene. Two layouts are
/// understood, and a staged distribution WINS where both are present, because a distribution
/// can sit inside the project tree it was built from.
///
/// PARTIAL PORT. Raptor launches the project's game script before the scene and lets a script
/// own boot entirely. The script projects are out of scope, so the startup script is not
/// loaded and a project with no default scene simply has nothing to run.
class PlayerApplication : DefaultApplication
{
	private PlayerOptions mOptions;

	private ProjectSettings mSettings = new .() ~ delete _;
	/// The native game, static or loaded.
	private PluginHost mPlugins = null ~ delete _;

	private NativeFileSystem mRoot = null ~ delete _;
	/// Distribution only.
	private PakFileSystem mPak = null ~ delete _;
	// Project mode only.
	private NativeFileSystem mContentMount = null ~ delete _;
	private NativeFileSystem mCookedMount = null ~ delete _;

	/// Project mode: the authored scenes.
	private ContentDatabase mSourceDb = null ~ delete _;
	/// The products, and a distribution's scenes too.
	private ContentDatabase mContentDb = null ~ delete _;
	/// BORROWED: whichever of the two above scenes come from.
	private ContentDatabase mSceneDb = null;

	/// BORROWED: the scene subsystem owns it.
	private Scene mScene = null;

	// The boot splash and the asynchronous load behind it.
	private SceneLoadHandle mBootLoad = .();
	private View mSplashView = null;
	private String mBootScenePath = new .() ~ delete _;
	private bool mBooting = false;

	/// The serializer factories the databases and the settings store hold. OWNED here,
	/// because a database keeps the one it was given for as long as it lives.
	private SerializerFactory mBinaryFactory
		= (new (stream, mode) => new BinarySerializerContext(stream, mode)) ~ delete _;
	private SerializerFactory mXmlFactory
		= (new (stream, mode) => new XmlSerializerContext(stream, mode)) ~ delete _;

	public this(PlayerOptions options)
	{
		mOptions = options;
		// The base owns the exit timer, so a smoke run and a --screenshot-exit run share one.
		SetExitAfterSeconds(options.ExitAfterSeconds);
	}

	private SerializerFactory MakeBinaryFactory() => mBinaryFactory;
	private SerializerFactory MakeXmlFactory() => mXmlFactory;

	// ==================== startup ====================

	public override void OnStartup(IApplicationHost host)
	{
		if (!OpenProject(host))
			return;

		// The base builds the resource manager and the standard factories over this
		// database, and registers the product types with them.
		SetContentDatabase(mContentDb);
		base.OnStartup(host);

		// The player owns its window, so the UI drives the platform's text input on it as
		// game focus moves. An editor leaves this null, its own bridge owning that there.
		if ((UI != null) && (host.Shell != null))
			UI.SetTextInputTarget(host.Shell.MainWindow);

		LoadNativeGame(host);
	}

	/// Opens whichever layout the project directory actually is. False means the run cannot
	/// continue, and it has already asked to exit.
	private bool OpenProject(IApplicationHost host)
	{
		mRoot = new NativeFileSystem(mOptions.ProjectDir);

		// A distribution WINS when present: a staged one can sit inside a project tree.
		if (mRoot.Exists(ProjectLayout.DistContentPak))
			return OpenDistribution(host);

		if (mRoot.Exists(ProjectLayout.ManifestFile))
			return OpenProjectTree(host);

		GlobalLog(.Error,
			"Player: '{}' is neither a project nor a distribution: it has no manifest and no content pak",
			mOptions.ProjectDir);
		host.RequestExit(1);
		return false;
	}

	private bool OpenDistribution(IApplicationHost host)
	{
		let pakPath = scope String();
		PathJoin(mOptions.ProjectDir, ProjectLayout.DistContentPak, pakPath);

		mPak = new PakFileSystem(pakPath);
		if (!mPak.IsValid
			|| (ProjectManifest.Load(mRoot, mSettings, ProjectLayout.DistManifestFile) case .Err))
		{
			GlobalLog(.Error, "Player: the distribution at '{}' is unreadable",
				mOptions.ProjectDir);
			host.RequestExit(1);
			return false;
		}

		mContentDb = new ContentDatabase(mPak, MakeBinaryFactory(),
			ProjectLayout.CookedAssetExtension);
		// The scenes live IN the pak, binary like every other product.
		mSceneDb = mContentDb;
		SetSceneDatabase(mSceneDb);

		GlobalLog(.Information, "Player: distribution mode, {} pak entries", mPak.EntryCount);
		return true;
	}

	private bool OpenProjectTree(IApplicationHost host)
	{
		if (ProjectManifest.Load(mRoot, mSettings) case .Err)
		{
			GlobalLog(.Error, "Player: the project manifest at '{}' is unreadable",
				mOptions.ProjectDir);
			host.RequestExit(1);
			return false;
		}

		let contentPath = scope String();
		PathJoin(mOptions.ProjectDir, ProjectLayout.ContentDir, contentPath);
		mContentMount = new NativeFileSystem(contentPath);

		let cookedPath = scope String();
		PathJoin(mOptions.ProjectDir, ProjectLayout.CookedDir, cookedPath);
		mCookedMount = new NativeFileSystem(cookedPath);

		mSourceDb = new ContentDatabase(mContentMount, MakeXmlFactory(),
			ProjectLayout.SourceAssetExtension);
		mContentDb = new ContentDatabase(mCookedMount, MakeBinaryFactory(),
			ProjectLayout.CookedAssetExtension);
		// The authored scenes, with the products coming from the cooked database.
		mSceneDb = mSourceDb;
		SetSceneDatabase(mSceneDb);
		return true;
	}

	/// The project's native game.
	///
	/// AFTER the base startup, so its load can resolve the engine's subsystems, and BEFORE
	/// the first scene resolves, so the types it registers can deserialize. A missing or
	/// unloadable module is reported and the run CONTINUES.
	private void LoadNativeGame(IApplicationHost host)
	{
		mPlugins = new PluginHost(host.Context);
		// Record what the game contributes to scenes, so unloading reverses it.
		mPlugins.AddRecorder(SceneContributionRecorder.Global);

		if (mOptions.NativeGame != null)
		{
			mPlugins.Add(mOptions.NativeGame);
			GlobalLog(.Information, "Player: native game plugin '{}', statically linked",
				mOptions.NativeGame.Name);
			return;
		}

		if (mSettings.NativeModule.IsEmpty)
			return;

		let modulePath = scope String();
		PathJoin(mOptions.ProjectDir, mSettings.NativeModule, modulePath);

		if (mPlugins.Load(modulePath) case .Ok)
			GlobalLog(.Information, "Player: native game module '{}' loaded",
				mSettings.NativeModule);
		else
			GlobalLog(.Error,
				"Player: the native game module '{}' failed to load, so the run continues without it",
				modulePath);
	}

	// ==================== launch ====================

	public override void OnLaunch(IApplicationHost host)
	{
		if (mSceneDb == null)
			return;
		if (host.Context.GetSubsystem<SceneSubsystem>() == null)
			return;

		let instance = ResolveStartupScene(host);
		if ((instance == null) && !mOptions.SceneOverride.IsEmpty)
			return;

		ApplyProjectBindings(host);

		// The game script launches FIRST: its launch() may load the first level itself, and
		// a startup scene, when the manifest names one, loads behind it.
		LoadAndStartGameScript();

		if (instance != null)
			BeginBootScene(host, instance);
		else if (GameScriptRunning)
			GlobalLog(.Information, "Player: no startup scene; the game script owns boot");
		else
			GlobalLog(.Information,
				"Player: no startup scene resolved, and no game script to own boot, so nothing is running");
	}

	/// The manifest's startup script is a cooked ScriptClass, bound from the content
	/// database by id. None is fine; one that does not resolve is an error the run survives.
	private void LoadAndStartGameScript()
	{
		let scriptId = mSettings.StartupScriptId;
		if ((scriptId == Guid()) || (Resources == null))
			return;
		let scriptClass = Resources.Bind<ScriptClass>(scriptId).Get;
		if (scriptClass == null)
		{
			GlobalLog(.Error, "Player: the startup script asset did not resolve");
			return;
		}
		StartGameScript(scriptClass);
	}

	/// A script loaded level gets the player's full activation: a camera, then the base's
	/// start and simulation. The load's scene is the run's current one from here.
	protected override void ApplyLoadedSceneActivation(Scene scene)
	{
		EnsureCameraOn(scene);
		base.ApplyLoadedSceneActivation(scene);
		mScene = scene;
	}

	/// The override first, then the manifest's identifier, which survives a rename, then its
	/// path mirror.
	private Instance ResolveStartupScene(IApplicationHost host)
	{
		if (!mOptions.SceneOverride.IsEmpty)
		{
			let instance = mSceneDb.GetInstanceByPath(mOptions.SceneOverride);
			// An EXPLICIT scene that did not resolve is a user error, unlike an absent
			// default, which simply means there is none.
			if (instance == null)
			{
				GlobalLog(.Error, "Player: the requested scene '{}' did not resolve",
					mOptions.SceneOverride);
				host.RequestExit(1);
			}
			return instance;
		}

		if (mSettings.DefaultSceneId != Guid())
		{
			if (let instance = mSceneDb.GetInstance(mSettings.DefaultSceneId))
				return instance;
		}

		if (!mSettings.DefaultScene.IsEmpty)
			return mSceneDb.GetInstanceByPath(mSettings.DefaultScene);

		return null;
	}

	/// Everything the project asked the engine for: the input map, the multisampling, the
	/// mixer, the per user volumes, and the interface's font and theme.
	private void ApplyProjectBindings(IApplicationHost host)
	{
		BindInputMap();
		ApplyMsaa(host);
		BindAudio();
		BindUserAudioSettings();
		BindUIFont();
		BindUITheme();
	}

	/// The project's default map, onto the PRIMARY instance's own runtime. Unset or
	/// unresolved binds no actions at all.
	private void BindInputMap()
	{
		if ((Input == null) || (mSettings.DefaultInputMapId == Guid()) || (Resources == null))
			return;

		let map = Resources.Bind<InputMapResource>(mSettings.DefaultInputMapId).Get;
		if (map == null)
		{
			GlobalLog(.Warning, "Player: the default input map did not resolve");
			return;
		}

		Instance.SetInputMap(map.Map);
		GlobalLog(.Information, "Player: input map bound, {} set(s)", map.Map.Sets.Count);
	}

	/// The scene pass's sample count. The subsystem clamps per view against what the device
	/// can do, so the authored value goes straight through. Only above one, since one is off
	/// and setting it would force the global post path on for nothing.
	private void ApplyMsaa(IApplicationHost host)
	{
		if (mSettings.RenderMsaaSamples <= 1)
			return;

		if (let render = host.Context.GetSubsystem<RenderSubsystem>())
		{
			render.MsaaSamples = mSettings.RenderMsaaSamples;
			GlobalLog(.Information, "Player: scene pass multisampling requested at {}x",
				mSettings.RenderMsaaSamples);
		}
	}

	/// The project's mixer. Unset or unresolved leaves the built in neutral layout.
	private void BindAudio()
	{
		if ((Audio == null) || (Audio.Engine == null) || (mSettings.DefaultBusLayoutId == Guid())
			|| (Resources == null))
			return;

		let layout = Resources.Bind<AudioBusLayoutResource>(mSettings.DefaultBusLayoutId).Get;
		if (layout == null)
		{
			GlobalLog(.Warning, "Player: the default bus layout did not resolve");
			return;
		}

		Audio.Engine.ApplyBusLayout(layout.Layout);
		GlobalLog(.Information, "Player: audio bus layout applied");
	}

	/// The per user volumes, applied ON TOP of the layout: a user's slider is absolute.
	/// Absent on a first run, and captured back at shutdown so a change made in game
	/// persists without anything asking it to.
	private void BindUserAudioSettings()
	{
		if ((Audio == null) || (Audio.Engine == null))
			return;

		AudioSettings.RegisterAll();

		let dataDir = scope String();
		GetUserDataDirectory(dataDir);
		let userFs = scope NativeFileSystem(dataDir);

		let fileName = scope String();
		UserSettingsFileName(fileName);

		let stream = userFs.Open(fileName, .Read);
		if (stream == null)
			return;
		defer delete stream;

		let store = scope Settings();
		if (store.Load(stream, MakeXmlFactory()) case .Err)
			return;

		if (let audio = store.Find<AudioUserSettings>())
		{
			audio.ApplyTo(Audio.Engine);
			GlobalLog(.Information, "Player: user audio settings applied");
		}
	}

	/// The project's font. Unset or unresolved leaves the development fallback, WHICH A
	/// DISTRIBUTION DOES NOT HAVE: a distributed game needs this bound for any text at all.
	private void BindUIFont()
	{
		if (UI == null)
			return;

		if ((mSettings.DefaultUiFontId == Guid()) || (Resources == null))
		{
			GlobalLog(.Warning,
				"Player: no default UI font is set in the project, so game UI text will not render in a distribution");
			return;
		}

		let font = Resources.Bind<Font>(mSettings.DefaultUiFontId).Get;
		if (font == null)
		{
			GlobalLog(.Warning, "Player: the default UI font did not resolve");
			return;
		}

		UI.SetDefaultFont(font);
		GlobalLog(.Information, "Player: default UI font bound");
	}

	/// The project's theme. Unset or unresolved leaves the built in one.
	private void BindUITheme()
	{
		if ((UI == null) || (mSettings.DefaultUiThemeId == Guid()) || (Resources == null))
			return;

		let theme = Resources.Bind<UITheme>(mSettings.DefaultUiThemeId).Get;
		if (theme == null)
		{
			GlobalLog(.Warning, "Player: the default UI theme did not resolve");
			return;
		}

		UI.SetDefaultTheme(theme);
		GlobalLog(.Information, "Player: default UI theme bound");
	}

	/// Pushes the splash, then loads the scene BEHIND it, with the update driving both.
	private void BeginBootScene(IApplicationHost host, Instance instance)
	{
		mBootScenePath.Clear();
		instance.GetPath(mBootScenePath);

		mSplashView = PushSplash();

		let sceneDb = mSceneDb;
		mBootLoad = Instance.LoadSceneAsync(instance, Resources, scope (prefabId) =>
			{
				let prefab = (sceneDb != null) ? sceneDb.GetInstance(prefabId) : null;
				return (prefab != null) ? prefab.ReadData("scene") : null;
			});

		if (mBootLoad.Failed)
		{
			PopSplash();
			GlobalLog(.Error, "Player: the scene '{}' failed to load", mBootScenePath);
			host.RequestExit(1);
			return;
		}

		mBooting = true;
		// Painted once before the first pump, so the splash is on screen immediately.
		DriveSplash(0.0f);
	}

	// ==================== the frame ====================

	public override void OnUpdate(IApplicationHost host, float deltaTime)
	{
		base.OnUpdate(host, deltaTime);

		if (mBooting)
			DriveBoot(host);
	}

	private void DriveBoot(IApplicationHost host)
	{
		DriveSplash(mBootLoad.Progress);
		if (!mBootLoad.IsComplete)
			return;

		mBooting = false;
		let activated = Instance.ActivateLoadedScene(ref mBootLoad);
		PopSplash();

		if (activated == null)
		{
			GlobalLog(.Error, "Player: the scene '{}' failed to activate", mBootScenePath);
			host.RequestExit(1);
			return;
		}

		mScene = activated;
		EnsureCameraOn(mScene);
		mScene.Start();
		mScene.SetSimulationEnabled(true);
		SetPrimaryScene(mScene);

		GlobalLog(.Information, "Player: running the scene '{}'", mBootScenePath);
	}

	public override void OnExit(IApplicationHost host)
	{
		StopGameScript();
		SetPrimaryScene(null);
		if (mScene != null)
			mScene.Stop();
	}

	public override void OnShutdown(IApplicationHost host)
	{
		if (mPlugins != null)
		{
			mPlugins.UnloadAll();
			delete mPlugins;
			mPlugins = null;
		}

		CaptureUserAudioSettings();

		// Releases the products while the device is still alive.
		base.OnShutdown(host);
	}

	/// Writes the volumes back, so a change made in game survives the run.
	private void CaptureUserAudioSettings()
	{
		if ((Audio == null) || (Audio.Engine == null))
			return;

		let store = scope Settings();
		store.Section<AudioUserSettings>().CaptureFrom(Audio.Engine);

		let dataDir = scope String();
		GetUserDataDirectory(dataDir);
		CreateDirectory(dataDir);

		let userFs = scope NativeFileSystem(dataDir);
		let buffer = scope MemoryStream();
		if (store.Save(buffer, MakeXmlFactory()) case .Err)
			return;

		let fileName = scope String();
		UserSettingsFileName(fileName);
		userFs.Save(fileName, buffer.Bytes).IgnoreError();
	}

	private void UserSettingsFileName(String outName)
	{
		outName.Set(mSettings.Name.IsEmpty ? "project" : mSettings.Name);
		outName.Append(".user.settings.xml");
	}

	// ==================== scene helpers ====================

	/// A scene with no camera renders nothing at all, which looks like a broken build rather
	/// than an unfinished one, so one is added and the omission is said out loud.
	private void EnsureCameraOn(Scene scene)
	{
		if (scene == null)
			return;

		let cameras = scene.GetSystem<CameraComponentManager>();
		if (cameras == null)
			return;

		var hasCamera = false;
		cameras.ForEach(scope [&] (component, owner) => { hasCamera = true; });
		if (hasCamera)
			return;

		GlobalLog(.Warning, "Player: the scene has no camera, so a default one is added");

		let entity = scene.CreateEntity("PlayerCamera");
		var transform = Transform();
		transform.Position = .(8.0f, 6.0f, 10.0f);
		transform.Rotation = Quaternion.FromAxisAngle(.(0, 1, 0), 0.675f)
			* Quaternion.FromAxisAngle(.(1, 0, 0), -0.42f);
		scene.SetLocalTransform(entity, transform);
		cameras.Add(entity);
	}

	// ==================== the boot splash ====================

	private View PushSplash()
	{
		if (UI == null)
			return null;

		UIDocument document = null;
		if ((mSettings.LoadingDocumentId != Guid()) && (Resources != null))
			document = Resources.Bind<UIDocument>(mSettings.LoadingDocumentId).Get;

		if (document != null)
			return UI.PushScreenOverlay(document);

		let fallback = scope UIDocument();
		DefaultSplashMarkup(fallback.Markup);
		return UI.PushScreenOverlay(fallback);
	}

	private void PopSplash()
	{
		if ((mSplashView != null) && (UI != null))
			UI.RemoveScreenOverlay(mSplashView);

		mSplashView = null;
	}

	private void DriveSplash(float progress)
	{
		let root = mSplashView as ViewGroup;
		if (root == null)
			return;

		if (let bar = root.FindByName<ProgressBar>("progress"))
			bar.Value.Value = progress;
	}

	/// The built in splash, deliberately bare: a status line and a bar.
	///
	/// A distributed game authors its own and names it in the project; this only proves the
	/// flow works with nothing authored at all. The two identifiers are the contract between
	/// the application and whatever document is used.
	private static void DefaultSplashMarkup(String outMarkup)
	{
		outMarkup.Set("""
			<FlexLayout>
			<Label id="status" text="Loading..."/>
			<ProgressBar id="progress"/>
			</FlexLayout>
			""");
	}
}
