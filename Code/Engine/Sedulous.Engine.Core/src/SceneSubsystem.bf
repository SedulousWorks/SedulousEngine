namespace Sedulous.Engine;

using System;
using System.Collections;
using Sedulous.Runtime;
using Sedulous.Engine.Core;
using Sedulous.Engine.Core.Resources;
using Sedulous.Resources;
using Sedulous.Serialization;

/// Manages scene lifecycle and updates.
/// Runs early (UpdateOrder -500) so scenes are updated before rendering.
///
/// When a scene is created, all ISceneAware subsystems are notified
/// so they can inject their component managers. Owns SceneResourceManager
/// and PrefabResourceManager (registered with ResourceSystem).
class SceneSubsystem : Subsystem, ISceneAware
{
	private List<Scene> mScenes = new .() ~ delete _;
	private List<Scene> mActiveScenes = new .() ~ delete _;
	private List<Scene> mPendingRemoves = new .() ~ delete _;

	// Resource managers (owned, registered with ResourceSystem)
	private SceneResourceManager mSceneResourceManager ~ delete _;
	private PrefabResourceManager mPrefabResourceManager ~ delete _;
	private ResourceSystem mResourceSystem;
	private ComponentTypeRegistry mTypeRegistry;

	public override int32 UpdateOrder => -500;

	public this(ResourceSystem resourceSystem, ComponentTypeRegistry typeRegistry = null)
	{
		mResourceSystem = resourceSystem;
		mTypeRegistry = typeRegistry;
	}

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

	/// The scene resource manager (for loading/saving .scene files).
	public SceneResourceManager SceneResourceManager => mSceneResourceManager;

	/// The prefab resource manager (for loading/saving .prefab files).
	public PrefabResourceManager PrefabResourceManager => mPrefabResourceManager;

	/// The component type registry.
	public ComponentTypeRegistry TypeRegistry => mTypeRegistry;

	protected override void OnInit()
	{
		let serializerProvider = mResourceSystem?.SerializerProvider;

		if (serializerProvider != null)
		{
			mSceneResourceManager = new SceneResourceManager(mTypeRegistry, serializerProvider);
			mSceneResourceManager.ResourceSystem = mResourceSystem;
			mResourceSystem.AddResourceManager(mSceneResourceManager);

			mPrefabResourceManager = new PrefabResourceManager(mTypeRegistry, serializerProvider);
			mResourceSystem.AddResourceManager(mPrefabResourceManager);
		}
	}

	protected override void OnShutdown()
	{
		// Destroy all scenes in reverse order
		for (int i = mScenes.Count - 1; i >= 0; i--)
			DestroySceneImmediate(mScenes[i]);

		mScenes.Clear();
		mActiveScenes.Clear();
		mPendingRemoves.Clear();

		// Unregister resource managers from ResourceSystem before deleting them
		if (mResourceSystem != null)
		{
			if (mSceneResourceManager != null)
				mResourceSystem.RemoveResourceManager(mSceneResourceManager);
			if (mPrefabResourceManager != null)
				mResourceSystem.RemoveResourceManager(mPrefabResourceManager);
		}
	}

	// ==================== Update Loop ====================

	/// Called at start of each frame - initializes any components created last frame.
	/// Runs before FixedUpdate so new physics bodies, audio sources, etc.
	/// are ready before their first simulation step.
	public override void BeginFrame(float deltaTime)
	{
		for (let scene in mActiveScenes)
			scene.InitializePendingComponents();
	}

	/// Fixed update - delegates to all active scenes at fixed timestep.
	/// Lockstep: all scenes run the same phase before moving to the next.
	public override void FixedUpdate(float fixedDeltaTime)
	{
		for (let scene in mActiveScenes)
			scene.FixedUpdate(fixedDeltaTime);
	}

	/// Main update - runs all scene phases in lockstep across active scenes.
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

		// First pass: let all subsystems inject their scene modules.
		for (let subsystem in Context.Subsystems)
		{
			if (let aware = subsystem as ISceneAware)
				aware.OnSceneCreated(scene);
		}

		// Second pass: all modules/pipelines are created - safe for cross-subsystem access.
		for (let subsystem in Context.Subsystems)
		{
			if (let aware = subsystem as ISceneAware)
				aware.OnSceneReady(scene);
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

	// ==================== ISceneAware ====================

	public void OnSceneCreated(Scene scene)
	{
	}

	public void OnSceneReady(Scene scene) { }
	public void OnSceneDestroyed(Scene scene) { }

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
