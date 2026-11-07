using System;
using Sedulous.Core;
using Sedulous.Physics;
using Sedulous.Scene;
using internal Sedulous.Engine.Gameplay;

namespace Sedulous.Engine.Gameplay;

/// The contact callbacks a behaviour class overrides.
enum ContactCallbacks : uint8
{
	None = 0,
	ContactBegin = 1,
	ContactEnd = 2,
	TriggerEnter = 4,
	TriggerExit = 8
}

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
	/// The contact callbacks its class overrides, found the same way: a class with none is not
	/// on the system's contact list, so a contact costs it nothing.
	protected internal abstract ContactCallbacks Contacts { get; }

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

	/// One side of a contact to `self`'s instance, when it ticks and its class overrides the
	/// callback `kind` reaches: `other` is the far side, as it was when the contact happened.
	protected internal abstract void DeliverContact(EntityHandle self, EntityHandle other, ContactKind kind,
		Float3 point, Float3 normal, float speed);
}
