using System;
using Sedulous.Runtime;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.Scene;

/// The Context level scene driver: it owns the registry and ticks every manager in it.
///
/// It owns NO scenes. There is no implicit default group: every owner of scenes, a game
/// instance or an editor page, creates its OWN manager and registers it here. The lifecycle
/// and the tick live in SceneManager; this only fans the Context's time scale and fixed step
/// down to them, which is what keeps Scene free of Runtime.
///
/// Assembly is declarative. Each registered manager gets an installer that builds new scenes
/// from the registry's composition, the single source of truth, and the observer stages are
/// the only injection path for cross subsystem per scene state.
///
/// A headless consumer that never ticks on this lane builds its scene from the full
/// composition directly rather than going through here.
class SceneSubsystem : Subsystem
{
	private SceneRegistry mScenes = new .() ~ delete _;
	/// Built in BeginFrame and reused by Update, so both lanes see one chain per frame.
	private FrameTime mFrameTime = .();

	/// Handed to the contribution registry, which BORROWS them, so they are ours to free.
	private delegate void(delegate void(Scene)) mLiveSceneSink ~ delete _;
	private delegate void(Scene) mLiveInstallHook ~ delete _;

	/// ONE pair serves every manager: the bodies close over this subsystem and nothing per
	/// manager. A manager BORROWS what it is given, so these stay ours to free.
	private delegate void(Scene) mInstaller ~ delete _;
	private delegate void(Scene) mUninstaller ~ delete _;

	public this()
	{
		// Composing fires BEFORE assembly and SystemsReady after every module installed.
		//
		// NO composition set is a scene with no modules, not a fault: the registry starts
		// null and says so by guarding its own RegisterReflection the same way. An empty
		// composition installs nothing either.
		mInstaller = new (scene) =>
			{
				mScenes.Notify(.Composing, scene);
				if (mScenes.Composition != null)
					mScenes.Composition.Instantiate(scene);
				mScenes.Notify(.SystemsReady, scene);
			};
		mUninstaller = new (scene) => mScenes.Notify(.Destroying, scene);
	}

	/// Scenes tick early, before anything that reads them draws.
	public override int32 UpdateOrder => -500;

	/// While registered, this is where a contribution reaches scenes that ALREADY exist: a
	/// manager a plugin adds after the fact is installed into every live scene, and the
	/// records preserved for it resolve into it there.
	public override void OnRegister(Context context)
	{
		base.OnRegister(context);

		mLiveSceneSink = new (visit) => mScenes.ForEachScene(visit);
		mLiveInstallHook = new (scene) => SceneResolve.ResolveAllUnresolvedRecords(scene);
		SceneModuleContributions.Global.SetLiveSceneSink(mLiveSceneSink);
		SceneModuleContributions.Global.SetLiveInstallHook(mLiveInstallHook);
	}

	public override void OnUnregister()
	{
		SceneModuleContributions.Global.SetLiveSceneSink(null);
		SceneModuleContributions.Global.SetLiveInstallHook(null);
		DeleteAndNullify!(mLiveSceneSink);
		DeleteAndNullify!(mLiveInstallHook);
		base.OnUnregister();
	}

	// ---- observers -------------------------------------------------------------------------

	public void RegisterObserver(ISceneObserver observer, SceneLifecycleStage stage) =>
		mScenes.AddObserver(observer, stage);

	public void UnregisterObserver(ISceneObserver observer) => mScenes.RemoveObserver(observer);

	// ---- composition -----------------------------------------------------------------------

	/// The declarative assignment every registered manager assembles a new scene from.
	///
	/// A manager registered BEFORE this reads the LIVE composition when it creates a scene, so
	/// the order of the two calls does not matter. Scenes created earlier are NOT rebuilt.
	public void SetComposition(SceneComposition composition) => mScenes.SetComposition(composition);

	public SceneComposition Composition => mScenes.Composition;

	// ---- managers --------------------------------------------------------------------------

	/// Registers a BORROWED manager so it ticks on this lane, and wires its install hooks.
	///
	/// The subsystem never learns who owns the manager, which is what keeps the dependency
	/// pointing down. The owner unregisters before destroying it.
	public void RegisterManager(SceneManager manager)
	{
		if (manager == null)
			return;

		mScenes.RegisterManager(manager);
		manager.SetSceneInstaller(mInstaller);
		manager.SetSceneUninstaller(mUninstaller);
	}

	/// Takes the hooks back off the manager as well: they belong to this subsystem, and an
	/// unregistered manager must not be left holding a pointer into it.
	public void UnregisterManager(SceneManager manager)
	{
		if (manager != null)
		{
			manager.ClearSceneInstaller();
			manager.ClearSceneUninstaller();
		}
		mScenes.UnregisterManager(manager);
	}

	/// The registry behind this subsystem, for an owner or a tool that needs the composition
	/// or the observer state.
	public SceneRegistry Registry => mScenes;

	/// Every registered manager. For a sweep that has to reach all of them.
	public void ForEachManager(delegate void(SceneManager) fn) => mScenes.ForEachManager(fn);

	/// Every live scene across every manager. A READ ONLY sweep, not ownership: a prefab
	/// rebuild after a template save, an export scan. Each owner still owns its own scenes.
	public void ForEachScene(delegate void(Scene) fn) => mScenes.ForEachScene(fn);

	// ---- frame -----------------------------------------------------------------------------

	/// Fixed stepping is PER SCENE, and it runs here so anything fixed rate is fresh before
	/// any subsystem's Update reads it.
	///
	/// THE bridge between the Context's plain floats and the scene's FrameTime: Runtime never
	/// sees a FrameTime, this builds one and hands it down.
	public override void BeginFrame(float deltaTime)
	{
		mFrameTime = FrameTime(deltaTime,
			(Context != null) ? Context.TimeScale : 1.0f,
			1.0f, 1.0f,
			(Context != null) ? Context.FixedTimeStep : 0.0f);
		mScenes.BeginFrame(mFrameTime);
	}

	/// The delta is ignored: the FrameTime captured in BeginFrame supersedes it, so both
	/// lanes run off one chain.
	public override void Update(float deltaTime) => mScenes.Update(mFrameTime);
}
