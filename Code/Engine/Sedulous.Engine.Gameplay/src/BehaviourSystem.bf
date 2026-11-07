using System;
using System.Collections;
using Sedulous.Scene;
using internal Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay;

/// Runs the scene's behaviours: one per scene, beside the BehaviourManagers it drives.
///
/// SIMULATION ONLY: nothing runs while the scene does not simulate, as in edit mode. Each
/// frame's Update runs, type by type in the order the managers registered, each type's
/// instances in pool order:
///   1. the edges, for every instance: OnEnable when it became active, OnStart the first
///      time, OnDisable when it stopped being;
///   2. OnUpdate, for the started and active instances of the types that override it;
///   3. the end of the tick, where what was queued during it drains.
/// OnFixedUpdate runs on the scene's fixed step, which runs before the frame's Update, and
/// OnLateUpdate in PostUpdate, after every system's Update.
///
/// An instance added during a pass is not visited by it: it starts with the next frame's
/// edges. One removed during a pass is not visited after its removal, the rest are visited
/// once each, and it is deleted only as the pass ends. An entity destroyed during Update is
/// destroyed by the scene at the end of the frame; one destroyed during the fixed step goes at
/// once (the scene defers only during Update), its behaviours released then and deleted as
/// the pass ends.
///
/// A behaviour of an inactive entity freezes: OnDisable on the edge, then nothing until the
/// entity is active again, when OnEnable follows (OnStart only if it never started).
class BehaviourSystem : SceneSystem
{
	/// The script tier's slot: before what acts on what game code writes (the navigation crowd
	/// at -100, animation at -2 and -1). The scene script system shares it; the two keep the
	/// order they were added in, and the engine's modules are added before a plugin's
	/// contributions, so scripts run first while both exist.
	public const int32 cUpdateOrder = -110;

	/// BORROWED: every registered manager, in registration order, and the tick lists, those of
	/// them whose class overrides that tick.
	private List<BehaviourManagerBase> mManagers = new .() ~ delete _;
	private List<BehaviourManagerBase> mUpdates = new .() ~ delete _;
	private List<BehaviourManagerBase> mFixedUpdates = new .() ~ delete _;
	private List<BehaviourManagerBase> mLateUpdates = new .() ~ delete _;

	public override int32 UpdateOrder => cUpdateOrder;
	public override bool IsSimulationOnly => true;

	/// Finds the managers added before it; the ones added after find it.
	public override void OnSceneCreate(Scene scene)
	{
		for (let system in scene.Systems)
		{
			if (let manager = system as BehaviourManagerBase)
				Register(manager);
		}
	}

	/// Lets go of the managers it drives, which may outlive it.
	public ~this()
	{
		for (let manager in mManagers)
			manager.mSystem = null;
	}

	/// The registered managers, and how many are on each tick list.
	public int ManagerCount => mManagers.Count;
	public int UpdateCount => mUpdates.Count;
	public int FixedUpdateCount => mFixedUpdates.Count;
	public int LateUpdateCount => mLateUpdates.Count;

	internal void Register(BehaviourManagerBase manager)
	{
		if (manager.mSystem == this)
			return;
		manager.mSystem = this;
		mManagers.Add(manager);
		if (manager.TicksUpdate)
			mUpdates.Add(manager);
		if (manager.TicksFixedUpdate)
			mFixedUpdates.Add(manager);
		if (manager.TicksLateUpdate)
			mLateUpdates.Add(manager);
	}

	internal void Unregister(BehaviourManagerBase manager)
	{
		if (manager.mSystem != this)
			return;
		manager.mSystem = null;
		mManagers.Remove(manager);
		mUpdates.Remove(manager);
		mFixedUpdates.Remove(manager);
		mLateUpdates.Remove(manager);
	}

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		switch (phase)
		{
		case .Update:
			Tick(deltaTime);
		case .PostUpdate:
			Run(mLateUpdates, .Begin, 0.0f);
			Run(mLateUpdates, .LateUpdate, deltaTime);
			Run(mLateUpdates, .End, 0.0f);
		default:
		}
	}

	public override void OnFixedUpdate(float fixedDeltaTime)
	{
		Run(mFixedUpdates, .Begin, 0.0f);
		Run(mFixedUpdates, .FixedUpdate, fixedDeltaTime);
		Run(mFixedUpdates, .End, 0.0f);
	}

	/// The frame's tick, one pass over every manager: each holds the instances it has as the
	/// tick begins, so one added by any callback (an OnStart included) waits for the next.
	private void Tick(float deltaTime)
	{
		Run(mManagers, .Begin, 0.0f);
		Run(mManagers, .Edges, 0.0f);
		Run(mUpdates, .Update, deltaTime);

		// The end of the tick drains here, inside the pass, so what it calls has the same
		// footing as an update.

		Run(mManagers, .End, 0.0f);
	}

	private enum Step
	{
		Begin,
		Edges,
		Update,
		FixedUpdate,
		LateUpdate,
		End
	}

	/// One step over `managers`, by index over the count they had as it began: a manager the
	/// scene gains during a callback is not visited until the next step that starts after it
	/// arrived, and its empty pass makes the steps it does meet do nothing.
	private static void Run(List<BehaviourManagerBase> managers, Step step, float deltaTime)
	{
		let count = managers.Count;
		for (int i = 0; (i < count) && (i < managers.Count); i++)
		{
			let manager = managers[i];
			switch (step)
			{
			case .Begin: manager.BeginPass();
			case .Edges: manager.DeliverEdges();
			case .Update: manager.RunUpdate(deltaTime);
			case .FixedUpdate: manager.RunFixedUpdate(deltaTime);
			case .LateUpdate: manager.RunLateUpdate(deltaTime);
			case .End: manager.EndPass();
			}
		}
	}
}
