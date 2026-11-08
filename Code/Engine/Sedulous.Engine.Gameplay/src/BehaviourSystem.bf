using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Physics;
using Sedulous.Scene;
using Sedulous.Engine.Physics;
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
///   3. the end of the tick, where what was queued before it drains: the contacts, then the
///      queued calls (Post), each in the order queued.
/// OnFixedUpdate runs on the scene's fixed step, which runs before the frame's Update, and
/// OnLateUpdate in PostUpdate, after every system's Update.
///
/// Contacts come from the scene's physics, which it listens to as a scene listener (the
/// physics step pushes them, on the main thread, from inside the fixed step). Each is queued,
/// one entry per side, and delivered at the end of the next tick, so a contact callback has
/// the footing of an update and never runs inside the physics step. Each side's behaviours
/// hear it, the far side as `other`: OnContactBegin and OnContactEnd for a collision, with its
/// point, normal and speed; OnTriggerEnter and OnTriggerExit when either body is a trigger
/// (physics decides the kind). A side that no longer maps to an entity is not queued; at
/// delivery an entity destroyed since, and a behaviour not ticking (not started, disabled or
/// inactive), hears nothing.
///
/// An instance added during a pass is not visited by it: it starts with the next frame's
/// edges. One removed during a pass is not visited after its removal, the rest are visited
/// once each, and it is deleted only as the pass ends. An entity destroyed during Update or
/// during the fixed step is destroyed by the scene at the end of the frame's Update, so its
/// behaviours still hear the rest of the frame (the remaining fixed steps, the update and the
/// late tick) and are released there.
///
/// A queued call is a direct call deferred: it runs at the drain with an update's footing,
/// whatever queued it. One bound to a behaviour (Behaviour.Post) is dropped when the
/// behaviour is released before the drain, and one bound to a level (Level.Post) when the
/// level stops. What a drain's deliveries queue, contacts or
/// calls, waits for the next drain, so a call that queues itself cannot keep one going.
///
/// A behaviour of an inactive entity freezes: OnDisable on the edge, then nothing until the
/// entity is active again, when OnEnable follows (OnStart only if it never started).
class BehaviourSystem : SceneSystem, IContactListener
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
	/// BORROWED: the managers whose class overrides a contact callback.
	private List<BehaviourManagerBase> mContactManagers = new .() ~ delete _;

	/// One side of a contact, waiting for the end of the tick.
	private struct PendingContact
	{
		public EntityHandle Self;
		public EntityHandle Other;
		public ContactKind Kind;
		public Float3 Point;
		public Float3 Normal;
		public float Speed;
	}

	/// The contacts queued since the last drain, and the ones the drain in progress delivers:
	/// what a delivery queues waits for the next drain.
	private List<PendingContact> mContacts = new .() ~ delete _;
	private List<PendingContact> mDrainingContacts = new .() ~ delete _;

	/// A call waiting for the drain. The call is OWNED; the owner, BORROWED, is the behaviour
	/// or level it is bound to, or null. A dropped call (its owner released) is nulled in place.
	private struct QueuedCall
	{
		public Object Owner;
		public delegate void() Call;
	}

	/// The calls queued since the last drain, and the ones the drain in progress runs.
	private List<QueuedCall> mCalls = new .() ~ { DeleteCalls(_); delete _; };
	private List<QueuedCall> mDrainingCalls = new .() ~ { DeleteCalls(_); delete _; };

	public override int32 UpdateOrder => cUpdateOrder;
	public override bool IsSimulationOnly => true;

	/// Finds the managers added before it; the ones added after find it. The same with the
	/// scene's physics: one there already takes it as a listener, one added after finds it.
	public override void OnSceneCreate(Scene scene)
	{
		for (let system in scene.Systems)
		{
			if (let manager = system as BehaviourManagerBase)
				Register(manager);
		}
		if (let physics = scene.GetSystem<PhysicsSceneSystem>())
			physics.AddSceneContactListener(this);
	}

	/// Lets go of the managers it drives, which may outlive it, and of the scene's physics. The
	/// scene takes a system out of its lookups before deleting it, so a physics system found
	/// here is still alive.
	public ~this()
	{
		for (let manager in mManagers)
			manager.mSystem = null;
		if (Scene != null)
		{
			if (let physics = Scene.GetSystem<PhysicsSceneSystem>())
				physics.RemoveSceneContactListener(this);
		}
	}

	/// The registered managers, and how many are on each tick list.
	public int ManagerCount => mManagers.Count;
	public int UpdateCount => mUpdates.Count;
	public int FixedUpdateCount => mFixedUpdates.Count;
	public int LateUpdateCount => mLateUpdates.Count;
	public int ContactCount => mContactManagers.Count;
	/// The contact sides waiting for the end of the tick.
	public int PendingContactCount => mContacts.Count;
	/// The calls waiting for the end of the tick, dropped ones included.
	public int PendingCallCount => mCalls.Count;

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
		if (manager.Contacts != .None)
			mContactManagers.Add(manager);
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
		mContactManagers.Remove(manager);
	}

	/// A contact of the scene's physics: queued, one entry per side that maps to an entity,
	/// each seeing the other. Only queues, as the physics step it is called from asks; nothing
	/// is queued while no class here hears contacts.
	public void OnContact(EntityContact contact)
	{
		if ((contact.Scene !== Scene) || mContactManagers.IsEmpty)
			return;
		QueueContactSide(contact.A, contact.B, contact);
		QueueContactSide(contact.B, contact.A, contact);
	}

	private void QueueContactSide(EntityHandle self, EntityHandle other, EntityContact contact)
	{
		// A side whose body no longer maps to a live entity, an end after a destroy, has
		// nobody to tell.
		if (!self.IsAssigned)
			return;
		PendingContact pending;
		pending.Self = self;
		pending.Other = other;
		pending.Kind = contact.Kind;
		pending.Point = contact.Point;
		pending.Normal = contact.Normal;
		pending.Speed = contact.Speed;
		mContacts.Add(pending);
	}

	/// Queues `call` for the end of the next tick's Update, where the scene's queued work
	/// drains. TAKES OWNERSHIP: deleted once it has run, or unrun if the scene stops first.
	public void Post(delegate void() call)
	{
		Post(null, call);
	}

	/// As Post, bound to `owner`, a behaviour or a level: dropped (deleted unrun) if the
	/// behaviour is released, or the level stops, first.
	internal void Post(Object owner, delegate void() call)
	{
		if (call == null)
			return;
		QueuedCall queued;
		queued.Owner = owner;
		queued.Call = call;
		mCalls.Add(queued);
		if (let behaviour = owner as Behaviour)
			behaviour.mQueuedCalls++;
	}

	/// Drops `owner`'s queued calls, those of the drain in progress included: its release, or
	/// a level's stop.
	internal void DropCalls(Object owner)
	{
		DropCalls(mCalls, owner);
		DropCalls(mDrainingCalls, owner);
	}

	private static void DropCalls(List<QueuedCall> calls, Object owner)
	{
		for (var queued in ref calls)
		{
			if ((queued.Owner === owner) && (queued.Call != null))
			{
				delete queued.Call;
				queued.Call = null;
				queued.Owner = null;
			}
		}
	}

	/// A stopped scene's queues go with it: nothing queued in one play reaches the next.
	public override void OnSceneStopped()
	{
		mContacts.Clear();
		for (let queued in mCalls)
		{
			if (let behaviour = queued.Owner as Behaviour)
				behaviour.mQueuedCalls = 0;
		}
		DeleteCalls(mCalls);
	}

	/// Deletes what is still queued, leaving the list empty.
	private static void DeleteCalls(List<QueuedCall> calls)
	{
		for (let queued in calls)
		{
			if (queued.Call != null)
				delete queued.Call;
		}
		calls.Clear();
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
		Drain();

		Run(mManagers, .End, 0.0f);
	}

	/// Delivers what was queued before the drain began, the contacts and then the calls;
	/// what it queues waits for the next.
	private void Drain()
	{
		if (mContacts.IsEmpty && mCalls.IsEmpty)
			return;

		Swap(ref mContacts, ref mDrainingContacts);
		Swap(ref mCalls, ref mDrainingCalls);

		for (let contact in mDrainingContacts)
			DeliverContact(contact);
		mDrainingContacts.Clear();

		for (int i < mDrainingCalls.Count)
		{
			let queued = mDrainingCalls[i];
			if (queued.Call == null)
				continue;
			// Taken out first: the owner's release during its own call finds nothing to drop,
			// and the call is deleted only once it has returned.
			mDrainingCalls[i].Call = null;
			mDrainingCalls[i].Owner = null;
			if (let behaviour = queued.Owner as Behaviour)
				behaviour.mQueuedCalls--;
			queued.Call();
			delete queued.Call;
		}
		mDrainingCalls.Clear();
	}

	/// One side to every behaviour of its entity whose class hears contacts, in registration
	/// order. An entity destroyed since is not looked at.
	private void DeliverContact(PendingContact contact)
	{
		if (!Scene.IsValid(contact.Self))
			return;
		let count = mContactManagers.Count;
		for (int i = 0; (i < count) && (i < mContactManagers.Count); i++)
		{
			mContactManagers[i].DeliverContact(contact.Self, contact.Other, contact.Kind, contact.Point,
				contact.Normal, contact.Speed);
		}
	}

	private static void Swap<L>(ref L a, ref L b) where L : class
	{
		let held = a;
		a = b;
		b = held;
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
