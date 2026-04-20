namespace Sedulous.Engine.Physics;

using System;
using System.Collections;
using Sedulous.Runtime;
using Sedulous.Scenes;
using Sedulous.Engine;
using Sedulous.Physics;
using Sedulous.Physics.Jolt;

/// Owns the physics engine backend and creates per-scene physics worlds.
/// Implements ISceneAware to automatically inject PhysicsComponentManager
/// into newly created scenes.
class PhysicsSubsystem : Subsystem, ISceneAware
{
	public override int32 UpdateOrder => -100;

	/// Default world descriptor for new scenes.
	public PhysicsWorldDescriptor WorldDescriptor = .Default;

	/// Per-scene physics worlds.
	private Dictionary<Scene, IPhysicsWorld> mSceneWorlds = new .() ~ {
		for (let kv in _)
		{
			kv.value.Dispose();
			delete kv.value;
		}
		delete _;
	};

	protected override void OnInit()
	{
	}

	/// Detach all component managers from their physics worlds before shutdown.
	/// This prevents use-after-free when component destructors try to call
	/// DestroyBody on an already-deleted world during scene teardown.
	protected override void OnPrepareShutdown()
	{
		for (let kv in mSceneWorlds)
		{
			let physicsMgr = kv.key.GetModule<PhysicsComponentManager>();
			if (physicsMgr != null)
				physicsMgr.PhysicsWorld = null;
		}
	}

	protected override void OnShutdown()
	{
		// Managers already detached by PrepareShutdown - safe to destroy worlds.
		for (let kv in mSceneWorlds)
		{
			kv.value.Dispose();
			delete kv.value;
		}
		mSceneWorlds.Clear();
	}

	public void OnSceneCreated(Scene scene)
	{
		// Create physics world for this scene
		if (JoltPhysicsWorld.Create(WorldDescriptor) case .Ok(let world))
		{
			mSceneWorlds[scene] = world;
			world.OptimizeBroadPhase();

			// Inject component manager
			let physicsMgr = new PhysicsComponentManager();
			physicsMgr.PhysicsWorld = world;
			scene.AddModule(physicsMgr);
		}
	}

	public void OnSceneDestroyed(Scene scene)
	{
		if (mSceneWorlds.TryGetValue(scene, let world))
		{
			// Null the manager's reference before destroying the world so
			// component cleanup in OnComponentDestroyed skips physics calls.
			let physicsMgr = scene.GetModule<PhysicsComponentManager>();
			if (physicsMgr != null)
				physicsMgr.PhysicsWorld = null;

			world.Dispose();
			delete world;
			mSceneWorlds.Remove(scene);
		}
	}

	/// Gets the physics world for a scene. Returns null if not found.
	public IPhysicsWorld GetPhysicsWorld(Scene scene)
	{
		if (mSceneWorlds.TryGetValue(scene, let world))
			return world;
		return null;
	}
}
