using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Run;

namespace Sedulous.Scene;

/// A GROUP of scenes, as a first class object.
///
/// It owns its scenes, a current scene and the group's time scale; it ticks its own
/// variable and fixed lanes; and it assembles and tears down each scene through hooks a
/// driver wires. It stays composition agnostic and runtime agnostic itself.
///
/// That agnosticism is the point. A game instance, up in the runtime layer, OWNS a scene
/// manager, so the dependency points DOWN and the scene library never learns about the
/// runtime. A manager reads only its own group's configuration and never reaches up to its
/// owner; the context's time scale and fixed step are handed IN.
class SceneManager
{
	/// Assembles a scene's systems. Set by the driver; the caller owns whatever the
	/// delegate closes over.
	private delegate void(Scene) mInstaller = null;
	/// The teardown notification, run on destroy and on clear.
	private delegate void(Scene) mUninstaller = null;

	/// BORROWED: the run every created scene belongs to.
	private IRun mSceneRun = null;

	/// The group term of the chain.
	private float mTimeScale = 1.0f;
	private Scene mCurrent = null;

	private List<Scene> mScenes = new .() ~ DeleteContainerAndItems!(_);
	/// Non owning.
	private List<Scene> mActive = new .() ~ delete _;
	private List<Scene> mPendingRemove = new .() ~ delete _;
	private bool mUpdating = false;
	/// Scene destroys waiting in the run's mutations.
	private int32 mRunDestroysQueued = 0;

	public ~this()
	{
		// A scene destroy it queued goes with it. Only then is the run asked: a manager may
		// outlive the run it was given, and has nothing queued on it by then.
		if ((mRunDestroysQueued > 0) && (mSceneRun != null))
			mSceneRun.Mutations.Cancel(this);
	}

	/// Sets the assembler. While one is set it is the ONLY assembly path: there is no
	/// fallback that quietly builds something else.
	public void SetSceneInstaller(delegate void(Scene) installer) => mInstaller = installer;
	public void ClearSceneInstaller() => mInstaller = null;

	public void SetSceneUninstaller(delegate void(Scene) uninstaller) => mUninstaller = uninstaller;
	public void ClearSceneUninstaller() => mUninstaller = null;

	/// The run every scene created here belongs to (Scene.SetRun), set by the owning run: its
	/// bus is the scenes' bus. Applied BEFORE assembly, so a system binding at creation sees it.
	/// Null leaves scenes outside every run, with no bus.
	public void SetSceneRun(IRun run)
	{
		if ((mRunDestroysQueued > 0) && (mSceneRun != null) && ((Object)mSceneRun !== (Object)run))
		{
			mSceneRun.Mutations.Cancel(this);
			mRunDestroysQueued = 0;
		}
		mSceneRun = run;
	}

	/// The GROUP term of host by context by GROUP by scene.
	///
	/// Clamped at zero like every other term: a negative delta would run time backwards,
	/// which nothing downstream is written to survive.
	public float TimeScale
	{
		get => mTimeScale;
		set => mTimeScale = Math.Max(value, 0.0f);
	}

	/// The group's current scene: what a transition repoints and what a spawn targets. The
	/// first scene created becomes current.
	public Scene CurrentScene
	{
		get => mCurrent;
		set => mCurrent = value;
	}

	// ---- scene lifecycle ----

	/// Creates a scene.
	///
	/// `activate` false leaves it OWNED but inactive: not ticked, not rendered, not a spawn
	/// target. An asynchronous level load creates it that way and activates it only once
	/// its resources have finalised, so a half resolved scene never ticks. Assembly happens
	/// either way, so an inactive scene can be populated before it goes live.
	public Scene CreateScene(StringView name = "Scene", bool activate = true)
	{
		let scene = new Scene(name);
		mScenes.Add(scene);

		if (activate)
		{
			mActive.Add(scene);
			if (mCurrent == null)
				mCurrent = scene;
		}

		// The run before assembly, so a system binding at OnSceneCreate sees its run and the
		// bus its emits land on (the run's).
		scene.SetRun(mSceneRun);

		if (mInstaller != null)
			mInstaller(scene);
		return scene;
	}

	/// Adds an owned but inactive scene to the active set. A no op when it is already
	/// active, or not this manager's.
	public void ActivateScene(Scene scene)
	{
		if ((scene == null) || !Owns(scene) || IsActive(scene))
			return;

		mActive.Add(scene);
		if (mCurrent == null)
			mCurrent = scene;
	}

	/// Stops ticking and rendering a scene WITHOUT destroying it.
	public void DeactivateScene(Scene scene)
	{
		if (mCurrent === scene)
			mCurrent = null;
		RemoveFromActive(scene);
	}

	public bool IsActive(Scene scene) => mActive.Contains(scene);

	/// Destroys a scene, DEFERRED to the end of the tick (either lane) when called during one, and
	/// to the run's flush while the run defers (a script asked from a handler or the fixed step:
	/// the scene may be the one it runs in). Asked twice, it is destroyed once.
	public void DestroyScene(Scene scene)
	{
		if (scene == null)
			return;
		if (mUpdating)
		{
			mPendingRemove.Add(scene);
			return;
		}
		if ((mSceneRun != null) && mSceneRun.Mutations.IsDeferring)
		{
			mRunDestroysQueued++;
			mSceneRun.Mutations.Enqueue(this, new () =>
				{
					mRunDestroysQueued--;
					if (Owns(scene)) // destroyed meanwhile: nothing
						DestroyImmediate(scene);
				});
			return;
		}
		DestroyImmediate(scene);
	}

	/// The first ACTIVE scene with this name, or null.
	public Scene GetScene(StringView name)
	{
		for (let scene in mActive)
		{
			if (scene.Name == name)
				return scene;
		}
		return null;
	}

	public Span<Scene> ActiveScenes => mActive;
	public int SceneCount => mScenes.Count;

	/// Every scene, active or not.
	public void ForEachScene(delegate void(Scene) fn)
	{
		for (let scene in mScenes)
			fn(scene);
	}

	// ---- ticking ----

	/// The fixed lane: seed each active scene's step from the lane's configuration, then
	/// advance its fixed time on the FULL chain.
	///
	/// `time` carries host by context, built by the driver; this manager contributes the
	/// group term and each scene its own. THE one place the chain is composed, which is why
	/// the terms cannot drift apart.
	public void BeginFrame(FrameTime time)
	{
		// Scripts run in the fixed step: what they destroy waits for the end of the lane, and
		// what they ask of the run for its flush.
		let run = mSceneRun;
		run?.Mutations.Enter();
		mUpdating = true;
		for (let scene in mActive)
		{
			if ((time.FixedStep > 0.0f)
				&& ((scene.FixedTimeStep != time.FixedStep) || (scene.MaxFixedSteps != time.MaxFixedSteps)))
				scene.SetFixedTiming(time.FixedStep, time.MaxFixedSteps);
			scene.AdvanceTime(time.ContextDelta * mTimeScale * scene.TimeScale);
		}
		mUpdating = false;
		ProcessPendingRemoves();
		if (run != null)
		{
			run.Mutations.Leave();
			run.Mutations.Flush();
		}
	}

	/// The variable lane: the same chain, composed the same one place.
	public void Update(FrameTime time)
	{
		let run = mSceneRun;
		run?.Mutations.Enter();
		mUpdating = true;
		for (let scene in mActive)
			scene.Update(time.ContextDelta * mTimeScale * scene.TimeScale);
		mUpdating = false;

		ProcessPendingRemoves();
		if (run != null)
		{
			run.Mutations.Leave();
			run.Mutations.Flush();
		}
	}

	/// Destroys every scene in the group, notifying for each: the group's teardown.
	public void Clear()
	{
		// Running scenes stop first, as one destroyed alone does.
		for (int i = mScenes.Count - 1; i >= 0; i--)
			mScenes[i].Stop();
		for (int i = mScenes.Count - 1; i >= 0; i--)
			NotifyDestroyed(mScenes[i]);

		mActive.Clear();
		mPendingRemove.Clear();
		mCurrent = null;
		ClearAndDeleteItems!(mScenes);
	}

	// ---- internals ----

	private void NotifyDestroyed(Scene scene)
	{
		if (mUninstaller != null)
			mUninstaller(scene);
	}

	private void DestroyImmediate(Scene scene)
	{
		// A running scene stops before it goes: its systems' stop hooks are what unhook them from
		// whatever outlives the scene (a script system's handlers on a run's event bus, a Level's
		// onStop). A run loading the scene it is already in destroyed it unstopped, and the next
		// event drained into the freed system. A no-op for a scene that is not running.
		scene.Stop();
		NotifyDestroyed(scene);
		if (mCurrent === scene)
			mCurrent = null;
		RemoveFromActive(scene);

		if (mScenes.Remove(scene))
			delete scene;
	}

	private void RemoveFromActive(Scene scene) => mActive.Remove(scene);

	private bool Owns(Scene scene) => mScenes.Contains(scene);

	private void ProcessPendingRemoves()
	{
		if (mPendingRemove.IsEmpty)
			return;
		// A snapshot: a destroy's stop hooks may ask again.
		let batch = scope List<Scene>();
		batch.AddRange(mPendingRemove);
		mPendingRemove.Clear();
		for (let scene in batch)
		{
			if (Owns(scene)) // asked twice: destroyed once
				DestroyImmediate(scene);
		}
	}
}
