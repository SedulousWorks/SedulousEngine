namespace Sedulous.Engine;

using System;
using System.Collections;
using Sedulous.Runtime;
using Sedulous.Scenes;

/// Manages scene lifecycle and updates.
/// Runs early (UpdateOrder -500) so scenes are updated before rendering.
///
/// When a scene is created, all ISceneAware subsystems are notified
/// so they can inject their component managers.
class SceneSubsystem : Subsystem
{
	private List<Scene> mScenes = new .() ~ delete _;
	private List<Scene> mActiveScenes = new .() ~ delete _;
	private List<Scene> mPendingRemoves = new .() ~ delete _;

	public override int32 UpdateOrder => -500;

	/// Gets all scenes.
	public Span<Scene> Scenes => mScenes;

	/// Gets all active scenes.
	public Span<Scene> ActiveScenes => mActiveScenes;

	/// Creates a new scene and notifies all ISceneAware subsystems.
	public Scene CreateScene(StringView name = "Scene")
	{
		let scene = new Scene();
		scene.Name.Set(name);
		mScenes.Add(scene);
		mActiveScenes.Add(scene);

		// Notify all ISceneAware subsystems
		NotifySceneCreated(scene);

		return scene;
	}

	/// Removes and destroys a scene.
	/// If called during an update, destruction is deferred.
	public void DestroyScene(Scene scene)
	{
		if (!mScenes.Contains(scene))
			return;

		mPendingRemoves.Add(scene);
	}

	/// Gets a scene by name. Returns null if not found.
	public Scene GetScene(StringView name)
	{
		for (let scene in mScenes)
		{
			if (StringView(scene.Name) == name)
				return scene;
		}
		return null;
	}

	// ==================== Subsystem Lifecycle ====================

	protected override void OnInit()
	{
	}

	protected override void OnShutdown()
	{
		// Destroy all scenes in reverse order
		for (int i = mScenes.Count - 1; i >= 0; i--)
			DestroySceneImmediate(mScenes[i]);

		mScenes.Clear();
		mActiveScenes.Clear();
		mPendingRemoves.Clear();
	}

	// ==================== Update Loop ====================

	/// Fixed update — delegates to all active scenes at fixed timestep.
	public override void FixedUpdate(float fixedDeltaTime)
	{
		// Lockstep: all scenes run the same phase before moving to the next
		for (let scene in mActiveScenes)
			scene.FixedUpdate(fixedDeltaTime);
	}

	/// Main update — runs all scene phases in lockstep across active scenes.
	public override void Update(float deltaTime)
	{
		for (let scene in mActiveScenes)
			scene.Update(deltaTime);

		// Process deferred destroys after all scenes have updated
		ProcessPendingRemoves();
	}

	// ==================== Internal ====================

	private void NotifySceneCreated(Scene scene)
	{
		if (Context == null)
			return;

		for (let subsystem in Context.Subsystems)
		{
			if (let aware = subsystem as ISceneAware)
				aware.OnSceneCreated(scene);
		}
	}

	private void NotifySceneDestroyed(Scene scene)
	{
		if (Context == null)
			return;

		for (let subsystem in Context.Subsystems)
		{
			if (let aware = subsystem as ISceneAware)
				aware.OnSceneDestroyed(scene);
		}
	}

	private void DestroySceneImmediate(Scene scene)
	{
		NotifySceneDestroyed(scene);
		mActiveScenes.Remove(scene);
		mScenes.Remove(scene);
		scene.Dispose();
		delete scene;
	}

	private void ProcessPendingRemoves()
	{
		if (mPendingRemoves.Count == 0)
			return;

		for (let scene in mPendingRemoves)
			DestroySceneImmediate(scene);

		mPendingRemoves.Clear();
	}
}
