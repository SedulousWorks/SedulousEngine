namespace Sedulous.Engine.Navigation;

using System;
using System.Collections;
using Sedulous.Runtime;
using Sedulous.Scenes;
using Sedulous.Engine;

/// Owns per-scene NavWorlds and injects navigation component managers.
/// NavMesh building and crowd simulation are managed through the NavWorld.
class NavigationSubsystem : Subsystem, ISceneAware
{
	public override int32 UpdateOrder => 300;

	/// Per-scene navigation worlds.
	private Dictionary<Scene, NavWorld> mSceneWorlds = new .() ~ {
		for (let kv in _)
			delete kv.value;
		delete _;
	};

	protected override void OnInit()
	{
	}

	protected override void OnPrepareShutdown()
	{
		// Detach managers from their worlds before scene teardown
		for (let kv in mSceneWorlds)
		{
			let navMgr = kv.key.GetModule<NavigationComponentManager>();
			if (navMgr != null)
				navMgr.NavWorld = null;

			let obsMgr = kv.key.GetModule<NavObstacleComponentManager>();
			if (obsMgr != null)
				obsMgr.NavWorld = null;
		}
	}

	protected override void OnShutdown()
	{
		// Managers already detached by PrepareShutdown - safe to destroy worlds.
		for (let kv in mSceneWorlds)
			delete kv.value;
		mSceneWorlds.Clear();
	}

	public void OnSceneCreated(Scene scene)
	{
		// Create NavWorld for this scene
		let navWorld = new NavWorld();
		mSceneWorlds[scene] = navWorld;

		// Inject navigation component manager
		let navMgr = new NavigationComponentManager();
		navMgr.NavWorld = navWorld;
		scene.AddModule(navMgr);

		// Inject obstacle component manager
		let obsMgr = new NavObstacleComponentManager();
		obsMgr.NavWorld = navWorld;
		scene.AddModule(obsMgr);
	}

	public void OnSceneReady(Scene scene) { }

	public void OnSceneDestroyed(Scene scene)
	{
		// Detach managers before destroying world
		let navMgr = scene.GetModule<NavigationComponentManager>();
		if (navMgr != null)
			navMgr.NavWorld = null;

		let obsMgr = scene.GetModule<NavObstacleComponentManager>();
		if (obsMgr != null)
			obsMgr.NavWorld = null;

		if (mSceneWorlds.TryGetValue(scene, let world))
		{
			delete world;
			mSceneWorlds.Remove(scene);
		}
	}

	/// Gets the NavWorld for a scene. Returns null if not found.
	public NavWorld GetNavWorld(Scene scene)
	{
		if (mSceneWorlds.TryGetValue(scene, let world))
			return world;
		return null;
	}
}
