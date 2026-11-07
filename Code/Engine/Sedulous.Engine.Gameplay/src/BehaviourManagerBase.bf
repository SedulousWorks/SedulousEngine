using System;
using Sedulous.Scene;
using internal Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay;

/// The non generic face of a BehaviourManager, which is what lets the scene's BehaviourSystem
/// hold the managers of every behaviour class together and drive each one's own typed loop.
///
/// A manager joins its scene's BehaviourSystem when either arrives (whichever comes second
/// finds the other) and leaves it when either goes, so the two may be added, removed and torn
/// down in any order.
abstract class BehaviourManagerBase : ComponentManagerBase
{
	/// BORROWED: the scene's BehaviourSystem this manager is registered with, null while it
	/// has none. Each side clears the other's hold on it as it goes.
	internal BehaviourSystem mSystem = null;

	/// Whether its class overrides OnUpdate, OnFixedUpdate or OnLateUpdate: the tick lists the
	/// system puts it on. Fixed for the class, found at compile time.
	protected internal abstract bool TicksUpdate { get; }
	protected internal abstract bool TicksFixedUpdate { get; }
	protected internal abstract bool TicksLateUpdate { get; }

	public override void OnSceneCreate(Scene scene)
	{
		if (let system = scene.GetSystem<BehaviourSystem>())
			system.Register(this);
	}

	public ~this()
	{
		if (mSystem != null)
			mSystem.Unregister(this);
	}

	// ---- the system's pass ----

	/// Opens a pass: the instances it visits are the ones held now, so one added during the
	/// pass waits for the next, and one removed during it is deleted only when it closes, so
	/// the instance whose callback removed it is never deleted under that callback.
	protected internal abstract void BeginPass();
	/// Closes the pass and deletes what was removed during it.
	protected internal abstract void EndPass();

	/// The enable and start edges for every instance of the pass (Behaviour.SettleEnabled).
	protected internal abstract void DeliverEdges();
	protected internal abstract void RunUpdate(float deltaTime);
	protected internal abstract void RunFixedUpdate(float fixedDeltaTime);
	protected internal abstract void RunLateUpdate(float deltaTime);
}
