using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Messaging;

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

	/// BORROWED, and injected into every scene this manager creates.
	private EventBus mSceneEventBus = null;

	/// The group term of the chain.
	private float mTimeScale = 1.0f;
	private Scene mCurrent = null;

	private List<Scene> mScenes = new .() ~ DeleteContainerAndItems!(_);
	/// Non owning.
	private List<Scene> mActive = new .() ~ delete _;
	private List<Scene> mPendingRemove = new .() ~ delete _;
	private bool mUpdating = false;

	/// Sets the assembler. While one is set it is the ONLY assembly path: there is no
	/// fallback that quietly builds something else.
	public void SetSceneInstaller(delegate void(Scene) installer) => mInstaller = installer;
	public void ClearSceneInstaller() => mInstaller = null;

	public void SetSceneUninstaller(delegate void(Scene) uninstaller) => mUninstaller = uninstaller;
	public void ClearSceneUninstaller() => mUninstaller = null;

	/// The scope bus every scene created here BORROWS, so a scene's emits and the run's bus
	/// are one object. Applied BEFORE assembly, so a system binding at creation sees it.
	/// Null leaves scenes with no bus.
	public void SetSceneEventBus(EventBus bus) => mSceneEventBus = bus;

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

		// Before assembly, so a system binding at OnSceneCreate sees the same bus its emits
		// land on.
		scene.SetEventBus(mSceneEventBus);

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

	/// Destroys a scene, DEFERRED to the end of the update when called during one.
	public void DestroyScene(Scene scene)
	{
		if (scene == null)
			return;
		if (mUpdating)
		{
			mPendingRemove.Add(scene);
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
		for (let scene in mActive)
		{
			if ((time.FixedStep > 0.0f) && (scene.FixedTimeStep != time.FixedStep))
				scene.SetFixedTiming(time.FixedStep, 4);
			scene.AdvanceTime(time.ContextDelta * mTimeScale * scene.TimeScale);
		}
	}

	/// The variable lane: the same chain, composed the same one place.
	public void Update(FrameTime time)
	{
		mUpdating = true;
		for (let scene in mActive)
			scene.Update(time.ContextDelta * mTimeScale * scene.TimeScale);
		mUpdating = false;

		ProcessPendingRemoves();
	}

	/// Destroys every scene in the group, notifying for each: the group's teardown.
	public void Clear()
	{
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
		// A snapshot is not needed: DestroyImmediate touches the owned and active lists,
		// never this one.
		for (let scene in mPendingRemove)
			DestroyImmediate(scene);
		mPendingRemove.Clear();
	}
}
