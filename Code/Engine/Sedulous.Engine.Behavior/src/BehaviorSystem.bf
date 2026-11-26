using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Core.Serialization;
using Sedulous.Messaging;
using Sedulous.Profiler;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.Resource;

namespace Sedulous.Engine.Behavior;

/// Runs the scene's scripts: every entity's behaviours in order, and the scene's Level.
///
/// SIMULATION GATED: behaviours tick only while the scene simulates, so an editor's edit
/// mode runs nothing. An instance is built on the first simulated tick that has its class
/// (the deferred start), gets its defaults and overrides, then its lifecycle by declared
/// presence: onEnable, onStart once, onUpdate(dt) every tick or every UpdateInterval with
/// the accumulated dt, onDisable on the edge, onDestroy when the entity or the scene goes.
/// A behaviour of an inactive entity freezes: nothing fires and its coroutines are
/// cancelled once on the edge. A fault disables that one behaviour until a reload; its
/// siblings keep running. A reload, the resource swapping its product, rebuilds the
/// instance and re-applies the overrides.
///
/// Messages (`Send(target, "hit", payload)`) are DEFERRED: queued, and drained at the
/// tick's top level where no script call is active, so a send made inside a handler is
/// delivered later the same frame and never nested. Events (`Emit("OrbCollected", payload)`)
/// go through the scene's bus; a behaviour's `onOrbCollected` handler is its subscription.
///
/// Every instance a script holds carries its own scene in its entity, so a behaviour of
/// one scene reaching into another resolves there, never here.
class BehaviorSystem : SceneSystem, IEntityEventSink
{
	public const String cOnStart = "onStart";
	public const String cOnUpdate = "onUpdate";
	public const String cOnFixedUpdate = "onFixedUpdate";
	public const String cOnEnable = "onEnable";
	public const String cOnDisable = "onDisable";
	public const String cOnDestroy = "onDestroy";
	public const String cOnStop = "onStop";
	private const int cMaxMessagesPerDrain = 4096;

	/// BORROWED: the scene outlives its systems.
	private Scene mScene = null;
	/// BORROWED: the subsystem's, or a test's.
	private BehaviorRunHost mHost = null;
	private bool mStarted = false;
	private float mDeltaTime = 0.0f;
	private double mElapsed = 0.0;

	private List<EntityHandle> mTickOwners = new .() ~ delete _;
	/// The fixed step's snapshot of the owners, reused.
	private List<EntityHandle> mFixedOwners = new .() ~ delete _;
	private List<PendingScriptMessage> mMessages = new .() ~ DeleteContainerAndItems!(_);

	/// The bus subscriptions, one per event name any loaded class handles.
	private Dictionary<String, uint32> mSubscriptions = new .() ~ DeleteDictionaryAndKeys!(_);
	/// The callbacks subscribed, each owning its handler's name; handed to the bus as they
	/// unsubscribe (a handler may stop the scene, and so unsubscribe them, while it runs).
	private List<delegate void(Variant)> mSubscriptionCallbacks = new .() ~ DeleteContainerAndItems!(_);

	// ---- the Level tier ----
	private SceneBehaviorSettings mSettings = new .() ~ delete _;
	private BehaviorObject mLevel = null;
	private BehaviorClass mLevelClass = null;
	/// Keeps mLevelClass's resource loaded while the Level lives; null with none.
	private ResourceHold mLevelHold = null ~ _?.Release();
	private bool mLevelStarted = false;
	private bool mLevelFaulted = false;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
		if (let components = scene.GetSystem<BehaviorComponentManager>())
			components.SetScriptSystem(this);
		// What happens to an entity (a contact, an animation ending), posted by the domain to the
		// scene, reaches the entity's behaviors as on<Event>.
		scene.AddEntityEventSink(this);
	}

	/// Where the scene's scripts run in Update (the Level script, then the entity behaviours):
	/// before the systems that act on what a script writes (the navigation crowd at -100,
	/// animation at -2 and -1), so a destination or a graph parameter set in onUpdate takes
	/// effect that frame; a script reads the positions those systems left the frame before. An
	/// order of its own rather than a tie with the crowd, which only the composition's domain
	/// order used to break.
	public const int32 cUpdateOrder = -110;

	public override int32 UpdateOrder => cUpdateOrder;

	public override bool IsSimulationOnly => true;

	/// Called at the end of every stop, once the instances are gone: the subsystem asks
	/// there whether the run host can go. Owned.
	public delegate void() OnRunStopped = null ~ delete _;

	/// The subsystem, or a headless test, wires the run host in.
	public void SetRunHost(BehaviorRunHost host)
	{
		mHost = host;
	}

	/// The scene's facades go with its scripting, the scene being destroyed with its
	/// systems.
	public ~this()
	{
		if (mScene != null)
		{
			mScene.RemoveEntityEventSink(this);
			SceneFacades.Release(mScene);
		}
	}

	/// An entity event for this scene's behaviors: queued as `on<Name>` (the send rule:
	/// "contactBegin" calls onContactBegin) with its arguments, each entity among them made the
	/// Entity a behavior is given. Only queued, onto the same deferred queue as entity.send, drained
	/// at the tick's top level: the domain posts from its own step, and delivery is gated by
	/// HasHandler, as messages are.
	public void OnEntityEvent(Scene scene, EntityEvent entityEvent)
	{
		if (!entityEvent.Target.IsAssigned || entityEvent.Name.IsEmpty)
			return;
		let pending = new PendingScriptMessage();
		pending.Target = entityEvent.Target;
		HandlerNameOf(entityEvent.Name, pending.Handler);
		for (let arg in entityEvent.Args)
		{
			switch (arg.Kind)
			{
			case .Bool: pending.AddArg(.FromBool(arg.Bool));
			case .Int: pending.AddArg(.FromInt(arg.Int));
			case .Float: pending.AddArg(.FromFloat(arg.Float));
			case .String: pending.AddArg(.FromString(arg.String));
			case .Guid: pending.AddArg(.FromGuid(arg.Guid));
			case .Float3: pending.AddArg(.FromFloat3(arg.Float3));
			case .Entity: pending.AddArg(.FromEntity(arg.Entity, scene));
			}
		}
		mMessages.Add(pending);
	}

	public BehaviorRunHost Host => mHost;
	public Scene OwningScene => mScene;
	public SceneBehaviorSettings Settings => mSettings;
	public bool Started => mStarted;

	// ---- settings ----

	public override Type SettingsType => typeof(SceneBehaviorSettings);
	public override void* SettingsInstance => Internal.UnsafeCastToPtr(mSettings);
	public override StringView SettingsId => "sceneBehavior";
	public override void SerializeSettings(ISerializer ar) => mSettings.Serialize(ar);

	public override void ResolveResources(ResourceManager manager)
	{
		mSettings.BehaviorClass.Bind(manager);
	}

	/// The Level's asset-valued overrides, which the script binds itself.
	public override void CollectUnboundReferences(List<Guid> outIds)
	{
		BehaviorPropertyOverride.CollectAssetIds(mSettings.Overrides, outIds);
	}

	/// The Level's class (the settings' reference) and the assets its overrides name, which a
	/// script binds when it uses them: held while the scene is loaded.
	public override void CollectResourceIds(HashSet<Guid> outIds)
	{
		base.CollectResourceIds(outIds);
		let assets = scope List<Guid>();
		BehaviorPropertyOverride.CollectAssetIds(mSettings.Overrides, assets);
		for (let id in assets)
		{
			if (!id.IsNil)
				outIds.Add(id);
		}
	}

	// ---- the script surface ----

	/// The last delivered frame time.
	public float DeltaTime => mDeltaTime;

	/// Simulated seconds since the scene started.
	public double Elapsed => mElapsed;

	/// Queues `on<Message>()` for every enabled behaviour of `target` that declares it.
	/// Delivered at the tick's top level, never inside the caller. On the entity too, so a
	/// script writes `other.Send("hit", 5)`.
	public void Send(EntityHandle target, StringView message) => Queue(target, message, .Nil, false);
	public void Send(EntityHandle target, StringView message, float payload) => Queue(target, message, .FromFloat(payload), true);
	public void Send(EntityHandle target, StringView message, int32 payload) => Queue(target, message, .FromInt(payload), true);
	public void Send(EntityHandle target, StringView message, bool payload) => Queue(target, message, .FromBool(payload), true);
	public void Send(EntityHandle target, StringView message, StringView payload) => Queue(target, message, .FromString(payload), true);
	public void Send(EntityHandle target, StringView message, EntityHandle payload) => Queue(target, message, .FromEntity(payload, mScene), true);
	public void Send(EntityHandle target, StringView message, Float3 payload) => Queue(target, message, .FromFloat3(payload), true);
	public void Send(EntityHandle target, StringView message, Float4 payload) => Queue(target, message, .FromFloat4(payload), true);

	/// Publishes an event on the scene's bus: every behaviour and the Level declaring
	/// `on<Event>` hears it when the bus drains.
	public void Emit(StringView eventName) => Publish(eventName, Variant());
	public void Emit(StringView eventName, float payload) => Publish(eventName, Variant.Create(payload));
	public void Emit(StringView eventName, int32 payload) => Publish(eventName, Variant.Create(payload));
	public void Emit(StringView eventName, bool payload) => Publish(eventName, Variant.Create(payload));
	public void Emit(StringView eventName, StringView payload) => Publish(eventName, Variant.Create(new String(payload), true));
	public void Emit(StringView eventName, EntityHandle payload) => Publish(eventName, Variant.Create(payload));
	public void Emit(StringView eventName, Float3 payload) => Publish(eventName, Variant.Create(payload));
	public void Emit(StringView eventName, Float4 payload) => Publish(eventName, Variant.Create(payload));

	private void Publish(StringView eventName, Variant payload)
	{
		let bus = mScene.Events;
		if (bus == null)
		{
			var v = payload;
			v.Dispose();
			GlobalLog(.Warning, scope $"Script: Emit('{eventName}') on a scene with no event bus");
			return;
		}
		bus.Publish(StringHash(eventName), payload);
	}

	private void Queue(EntityHandle target, StringView message, ScriptValue payload, bool hasPayload)
	{
		let pending = new PendingScriptMessage();
		pending.Target = target;
		HandlerNameOf(message, pending.Handler);
		if (hasPayload)
			pending.AddArg(payload);
		mMessages.Add(pending);
	}

	/// "heal" -> "onHeal": the send convention. The first character uppercased.
	public static void HandlerNameOf(StringView message, String outHandler)
	{
		outHandler.Set("on");
		for (int i = 0; i < message.Length; i++)
		{
			let c = message[i];
			outHandler.Append((i == 0) ? c.ToUpper : c);
		}
	}

	/// The bus event a handler name subscribes to: "onOrbCollected" -> "OrbCollected".
	/// Empty for anything that is not an `on<Upper>` handler, or is a lifecycle handler.
	public static void EventNameOf(StringView handler, String outEvent)
	{
		outEvent.Clear();
		if (!handler.StartsWith("on") || (handler.Length < 3) || !handler[2].IsUpper)
			return;
		switch (handler)
		{
		case cOnStart, cOnUpdate, cOnFixedUpdate, cOnEnable, cOnDisable, cOnDestroy, cOnStop,
			"onContactBegin", "onContactEnd", "onTriggerEnter", "onTriggerExit", "onAnimationFinished",
			"onAnimationEvent":
			return;
		default:
			outEvent.Append(handler.Substring(2));
		}
	}

	// ---- the play lifecycle ----

	public override void OnSceneStarted()
	{
		mStarted = true;
		mElapsed = 0.0;
	}

	/// Every instance goes with onDestroy, the Level with onStop, and the bus subscriptions
	/// are dropped: a stopped scene's scripts hear nothing.
	public override void OnSceneStopped()
	{
		mStarted = false;
		DestroyAllInstances();
		StopLevel(true);
		ClearSubscriptions();
		ClearAndDeleteItems!(mMessages);
		if (OnRunStopped != null)
			OnRunStopped();
	}

	public override void OnEntityDestroyed(EntityHandle entity)
	{
		// The component's destruction routes here through the manager.
	}

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if ((phase != .Update) || (mScene == null) || (mHost == null))
			return;
		// Debug paused: a held call is mid update. Script time stands still with the sim.
		if (mHost.IsDebugPaused)
			return;

		mDeltaTime = deltaTime;
		mElapsed += deltaTime;
		using (ProfileScope("Script.Tick"))
		{
			TickLevel(deltaTime);
			if (mHost.IsDebugPaused)
				return;
			TickBehaviors(deltaTime);
			if (mHost.IsDebugPaused)
				return;
			// The top level: no script call is active, so the deferred work is safe here.
			DrainMessages();
		}
	}

	public override void OnFixedUpdate(float fixedDeltaTime)
	{
		if ((mScene == null) || (mHost == null) || mHost.IsDebugPaused)
			return;
		var dt = ScriptValue[1](.FromFloat(fixedDeltaTime));
		if ((mLevel != null) && !mLevelFaulted && mSettings.Enabled)
		{
			InvokeLevel(cOnFixedUpdate, dt);
			if (mHost.IsDebugPaused)
				return;
		}
		FixedTickBehaviors(dt);
	}

	/// Each fixed step, onFixedUpdate(dt) reaches every behaviour that has started and is running
	/// (enabled, not faulted, its entity active). Starting stays with the frame's tick, so a
	/// behaviour's first fixed step comes after its onStart.
	private void FixedTickBehaviors(Span<ScriptValue> dt)
	{
		if (!mStarted)
			return;
		let components = mScene.GetSystem<BehaviorComponentManager>();
		if ((components == null) || (components.ComponentCount == 0))
			return;
		using (ProfileScope("Script.FixedUpdate"))
		{
			// Snapshot the owners, as the frame's tick does: a script may destroy or spawn.
			mFixedOwners.Clear();
			components.ForEach(scope [&] (component, owner) => { mFixedOwners.Add(owner); });
			for (let entity in mFixedOwners)
			{
				if (!mScene.IsEffectivelyActive(entity))
					continue;
				// Re-resolve per behaviour: any dispatch can mutate the pool.
				for (int i = 0; ; i++)
				{
					let component = components.Get(entity);
					if ((component == null) || (i >= component.Behaviors.Count))
						break;
					let behavior = component.Behaviors[i];
					if (!behavior.Started || !behavior.Active || !behavior.Enabled || behavior.Faulted || (behavior.Instance == null))
						continue;
					Invoke(behavior, entity, cOnFixedUpdate, dt);
					if (mHost.IsDebugPaused)
						return;
				}
			}
		}
	}

	// ---- behaviours ----

	private void TickBehaviors(float deltaTime)
	{
		let components = mScene.GetSystem<BehaviorComponentManager>();
		if ((components == null) || (components.ComponentCount == 0))
			return;

		// Snapshot the owners: a script may destroy entities (a swap-remove moves pool
		// slots) or spawn new ones (picked up next tick, the deferred start).
		mTickOwners.Clear();
		components.ForEach(scope [&] (component, owner) => { mTickOwners.Add(owner); });

		for (let entity in mTickOwners)
		{
			// Re-resolve per behaviour: any dispatch can mutate the pool.
			for (int i = 0; ; i++)
			{
				let component = components.Get(entity);
				if ((component == null) || (i >= component.Behaviors.Count))
					break;
				TickBehavior(component.Behaviors[i], entity, deltaTime);
				// A breakpoint in this one holds the frame's tick here: the rest wait for
				// the continue, as they would behind a real pause.
				if (mHost.IsDebugPaused)
					return;
			}
		}
	}

	private void TickBehavior(AttachedBehavior behavior, EntityHandle entity, float deltaTime)
	{
		// An inactive entity's behaviours FREEZE: nothing fires, onStart waits for the first
		// active tick, and pending coroutines are cancelled once on the edge.
		if (!mScene.IsEffectivelyActive(entity))
		{
			if (!behavior.EntitySuspended)
			{
				behavior.EntitySuspended = true;
				CancelCoroutines(behavior);
			}
			return;
		}
		behavior.EntitySuspended = false;

		let scriptClass = behavior.BehaviorClass.Get;
		if (scriptClass == null)
		{
			if (behavior.Instance != null)
				StopBehavior(behavior, entity, true);
			return;
		}

		// A reload: the handle swapped its product. Rebuild, and re-apply below.
		if ((behavior.Instance != null) && (behavior.BoundClass !== scriptClass))
		{
			StopBehavior(behavior, entity, false);
			behavior.Faulted = false;
		}

		if (!behavior.Enabled)
		{
			if ((behavior.Instance != null) && behavior.Active)
			{
				// Set before the dispatch: no re-dispatch on a fault.
				behavior.Active = false;
				Invoke(behavior, entity, cOnDisable, default);
				CancelCoroutines(behavior);
			}
			return;
		}
		if (behavior.Faulted)
			return;

		if (behavior.Instance == null)
		{
			InstantiateBehavior(behavior, entity, scriptClass);
			if (behavior.Instance == null)
				return;
		}

		if (!behavior.Active)
		{
			behavior.Active = true;
			if (!Invoke(behavior, entity, cOnEnable, default))
				return;
		}
		if (!behavior.Started)
		{
			behavior.Started = true;
			if (!Invoke(behavior, entity, cOnStart, default))
				return;
		}

		// Throttled: bank time and deliver the ACCUMULATED dt once the interval elapses.
		if (behavior.UpdateInterval > 0.0f)
		{
			behavior.UpdateAccumulator += deltaTime;
			if (behavior.UpdateAccumulator + 1e-6f >= behavior.UpdateInterval)
			{
				var dt = ScriptValue[1](.FromFloat(behavior.UpdateAccumulator));
				behavior.UpdateAccumulator = 0.0f;
				Invoke(behavior, entity, cOnUpdate, dt);
			}
		}
		else
		{
			var dt = ScriptValue[1](.FromFloat(deltaTime));
			Invoke(behavior, entity, cOnUpdate, dt);
		}
	}

	private void InstantiateBehavior(AttachedBehavior behavior, EntityHandle entity, BehaviorClass scriptClass)
	{
		// The class stays loaded while what was built from it lives, whatever the reference
		// names meanwhile.
		HoldBound(behavior);
		if (scriptClass.IsModule)
		{
			// A utility module: nothing to instantiate, not an error.
			behavior.BoundClass = scriptClass;
			return;
		}

		using (ProfileScope(scriptClass.ProfileName))
		{
			behavior.Instance = mHost.Instantiate(scriptClass, .Entity);
		}
		behavior.BoundClass = scriptClass;
		behavior.Started = false;
		behavior.Active = false;
		behavior.UpdateAccumulator = 0.0f;
		if (behavior.Instance == null)
		{
			behavior.Faulted = true;
			GlobalLog(.Error, scope $"Script: '{mScene.GetEntityName(entity)}': behaviour '{scriptClass.ClassName}' failed to instantiate; disabled");
			return;
		}

		// What the instance knows of its place: its entity, scene included, and the scene.
		behavior.Instance.SetProperty("self", .FromEntity(entity, mScene));
		behavior.Instance.SetProperty("scene", .FromWeak(mScene));
		ScriptProperties.ApplyAll(behavior.Instance, scriptClass, behavior.Overrides, mScene, mScene.GetEntityName(entity));
		SubscribeHandlers(scriptClass);
	}

	/// One handler dispatch, gated by the class declaring it. A fault disables this
	/// behaviour and is logged; true when the behaviour may go on.
	private bool Invoke(AttachedBehavior behavior, EntityHandle entity, StringView handler, Span<ScriptValue> args)
	{
		let scriptClass = behavior.BoundClass;
		if ((behavior.Instance == null) || (scriptClass == null) || !scriptClass.HasHandler(handler))
			return true;
		if (!behavior.Instance.HasMethod(handler, args.Length))
			return true;

		var result = ScriptValue.Nil;
		bool ok;
		using (ProfileScope(scriptClass.ProfileName))
		{
			ok = behavior.Instance.Invoke(handler, args, ref result);
		}
		if (ok)
			return true;
		// A debugger suspension unwinds to here as a false too: paused is not a fault, and
		// the debugger completes the held call on its continue.
		if (mHost.IsDebugPaused)
			return true;

		behavior.Faulted = true;
		GlobalLog(.Error, scope $"Script: '{mScene.GetEntityName(entity)}': behaviour '{scriptClass.ClassName}' faulted in {handler}; disabled");
		mHost.Scripts.ReportProblems();
		return false;
	}

	/// Whether `bound` is no longer the product of the resource `hold` keeps: reloaded or released
	/// since. A class set directly, with no resource, is never stale.
	private static bool IsStale(ResourceHold hold, BehaviorClass bound)
	{
		let handle = (hold != null) ? hold.Handle : null;
		return (handle != null) && (bound != null) && (handle.Product !== bound);
	}

	/// A hold on the resource `behavior` names, replacing the one it had.
	private static void HoldBound(AttachedBehavior behavior)
	{
		ResourceHold.Replace(ref behavior.BoundHold, behavior.BehaviorClass.Handle);
	}

	private void CancelCoroutines(AttachedBehavior behavior)
	{
		if ((behavior.Instance == null) || (behavior.BoundClass == null) || !behavior.BoundClass.UsesCoroutines)
			return;
		behavior.Instance.CancelCoroutines();
	}

	private void StopBehavior(AttachedBehavior behavior, EntityHandle entity, bool invokeDestroy)
	{
		// A class its resource no longer has (reloaded since the instance was built, while the
		// entity was frozen or play paused) is no longer read: that product may be gone.
		if (IsStale(behavior.BoundHold, behavior.BoundClass))
			behavior.BoundClass = null;
		if ((behavior.Instance != null) && invokeDestroy && behavior.Started && (behavior.BoundClass != null) && !behavior.Faulted)
			Invoke(behavior, entity, cOnDestroy, default);
		if (behavior.Instance != null)
		{
			// Every coroutine of an instance whose class is not known any more.
			if ((behavior.BoundClass == null) || behavior.BoundClass.UsesCoroutines)
				behavior.Instance.CancelCoroutines();
			behavior.Instance.Release();
			behavior.Instance = null;
		}
		behavior.BoundClass = null;
		ResourceHold.Drop(ref behavior.BoundHold);
		behavior.Started = false;
		behavior.Active = false;
	}

	/// onDestroy and release for one component's behaviours: entity or component removal.
	public void ReleaseComponentInstances(BehaviorComponent* component, EntityHandle entity)
	{
		if (mHost == null)
			return;
		for (let behavior in component.Behaviors)
			StopBehavior(behavior, entity, true);
	}

	private void DestroyAllInstances()
	{
		let components = (mScene != null) ? mScene.GetSystem<BehaviorComponentManager>() : null;
		if (components == null)
			return;
		components.ForEach(scope [&] (component, entity) =>
			{
				ReleaseComponentInstances(component, entity);
			});
	}

	/// Live instances, for the subsystem's teardown accounting.
	public int InstanceCount
	{
		get
		{
			int count = (mLevel != null) ? 1 : 0;
			let components = (mScene != null) ? mScene.GetSystem<BehaviorComponentManager>() : null;
			if (components != null)
			{
				components.ForEach(scope [&] (component, entity) =>
					{
						for (let behavior in component.Behaviors)
						{
							if (behavior.Instance != null)
								count++;
						}
					});
			}
			return count;
		}
	}

	// ---- messages ----

	/// Drains at the tick's top level. A handler may send again; those go in the same pass,
	/// capped to break a runaway loop.
	private void DrainMessages()
	{
		int delivered = 0;
		while (!mMessages.IsEmpty && (delivered < cMaxMessagesPerDrain))
		{
			// A breakpoint in a handler holds the rest of the queue for the continue.
			if (mHost.IsDebugPaused)
				return;
			let pending = mMessages.PopFront();
			delivered++;
			DeliverMessage(pending);
			delete pending;
		}
		if (!mMessages.IsEmpty)
		{
			GlobalLog(.Warning, scope $"Script: {mMessages.Count} messages dropped after {cMaxMessagesPerDrain} in one drain; a send loop?");
			ClearAndDeleteItems!(mMessages);
		}
	}

	private void DeliverMessage(PendingScriptMessage pending)
	{
		let components = mScene.GetSystem<BehaviorComponentManager>();
		if ((components == null) || !mScene.IsValid(pending.Target))
			return;
		// An inactive entity receives nothing: neither messages nor contacts, which share
		// this queue.
		if (!mScene.IsEffectivelyActive(pending.Target))
			return;
		let span = pending.Arguments;
		for (int i = 0; ; i++)
		{
			let component = components.Get(pending.Target);
			if ((component == null) || (i >= component.Behaviors.Count))
				break;
			let behavior = component.Behaviors[i];
			if ((behavior.Instance == null) || !behavior.Enabled || behavior.Faulted || !behavior.Active)
				continue;
			Invoke(behavior, pending.Target, pending.Handler, span);
		}
	}

	// ---- events ----

	/// Subscribes this scene's bus to every event the class handles, once per event name.
	private void SubscribeHandlers(BehaviorClass scriptClass)
	{
		let bus = mScene.Events;
		if (bus == null)
			return;
		for (let handler in scriptClass.Handlers)
		{
			let eventName = EventNameOf(handler, .. scope .());
			if (eventName.IsEmpty || mSubscriptions.ContainsKey(eventName))
				continue;
			let name = new String(eventName);
			// The handler's name lives as long as the callback, which owns it.
			let handlerName = new String(handler);
			delegate void(Variant) callback = new (payload) => { BroadcastEvent(handlerName, payload); } ~ delete handlerName;
			mSubscriptionCallbacks.Add(callback);
			mSubscriptions[name] = bus.Subscribe(StringHash(eventName), callback);
		}
	}

	private void ClearSubscriptions()
	{
		let bus = (mScene != null) ? mScene.Events : null;
		if (bus != null)
		{
			// The bus deletes each callback once it is not running: this may be a handler
			// stopping its own scene.
			for (let entry in mSubscriptions)
				bus.Unsubscribe(entry.value, true);
			mSubscriptionCallbacks.Clear();
		}
		DeleteDictionaryAndKeys!(mSubscriptions);
		mSubscriptions = new .();
		ClearAndDeleteItems!(mSubscriptionCallbacks);
	}

	/// The bus drains at the scene tick's top level, so this dispatches directly: every
	/// enabled behaviour of this scene declaring the handler, and the Level. Owners are
	/// snapshotted first, since a handler may spawn or destroy.
	private void BroadcastEvent(StringView handler, Variant payload)
	{
		// The bus drains from the scene tick, which a debug pause holds; an external
		// publish arriving meanwhile is dropped rather than dispatched into a held run.
		if ((mHost == null) || mHost.IsDebugPaused)
			return;
		var payload;
		var value = ScriptPayloads.ValueOf(ref payload, mScene);
		var args = ScriptValue[1](value);
		Span<ScriptValue> span = value.IsNil ? default : .(&args[0], 1);

		if ((mLevel != null) && !mLevelFaulted && (mLevelClass != null) && mLevelClass.HasHandler(handler))
			InvokeLevel(handler, span);

		let components = mScene.GetSystem<BehaviorComponentManager>();
		if (components == null)
			return;
		mTickOwners.Clear();
		components.ForEach(scope [&] (component, owner) => { mTickOwners.Add(owner); });
		for (let entity in mTickOwners)
		{
			// An inactive entity receives no bus events. Its behaviours keep Active (only the
			// tick's freeze marks them suspended), so the behaviour filter below does not.
			if (!mScene.IsEffectivelyActive(entity))
				continue;
			for (int i = 0; ; i++)
			{
				let component = components.Get(entity);
				if ((component == null) || (i >= component.Behaviors.Count))
					break;
				let behavior = component.Behaviors[i];
				if ((behavior.Instance == null) || !behavior.Enabled || behavior.Faulted || !behavior.Active)
					continue;
				Invoke(behavior, entity, handler, span);
				if (mHost.IsDebugPaused)
					return;
			}
		}
	}


	// ---- the Level ----

	private void TickLevel(float deltaTime)
	{
		if (!mSettings.Enabled)
		{
			if (mLevel != null)
				StopLevel(true);
			return;
		}
		let levelClass = mSettings.BehaviorClass.Get;
		if (levelClass == null)
		{
			if (mLevel != null)
				StopLevel(true);
			return;
		}
		if ((mLevel != null) && (mLevelClass !== levelClass))
		{
			StopLevel(false);
			mLevelFaulted = false;
		}
		if (mLevelFaulted)
			return;
		if (mLevel == null)
		{
			mLevel = mHost.Instantiate(levelClass, .Scene);
			mLevelClass = levelClass;
			ResourceHold.Replace(ref mLevelHold, mSettings.BehaviorClass.Handle);
			mLevelStarted = false;
			if (mLevel == null)
			{
				mLevelFaulted = true;
				GlobalLog(.Error, scope $"Script: scene '{mScene.Name}': the Level '{levelClass.ClassName}' failed to instantiate; disabled");
				return;
			}
			mLevel.SetProperty("scene", .FromWeak(mScene));
			ScriptProperties.ApplyAll(mLevel, levelClass, mSettings.Overrides, mScene, mScene.Name);
			SubscribeHandlers(levelClass);
		}
		if (!mLevelStarted)
		{
			mLevelStarted = true;
			if (!InvokeLevel(cOnStart, default))
				return;
		}
		var dt = ScriptValue[1](.FromFloat(deltaTime));
		InvokeLevel(cOnUpdate, dt);
	}

	private bool InvokeLevel(StringView handler, Span<ScriptValue> args)
	{
		if ((mLevel == null) || (mLevelClass == null) || !mLevelClass.HasHandler(handler))
			return true;
		if (!mLevel.HasMethod(handler, args.Length))
			return true;
		var result = ScriptValue.Nil;
		if (mLevel.Invoke(handler, args, ref result))
			return true;
		if (mHost.IsDebugPaused)
			return true; // suspended at a breakpoint, not a fault
		mLevelFaulted = true;
		GlobalLog(.Error, scope $"Script: scene '{mScene.Name}': the Level faulted in {handler}; disabled");
		mHost.Scripts.ReportProblems();
		return false;
	}

	private void StopLevel(bool invokeStop)
	{
		if (mLevel == null)
			return;
		// A class its resource no longer has (reloaded while play was paused) is no longer read.
		if (IsStale(mLevelHold, mLevelClass))
			mLevelClass = null;
		if (invokeStop && mLevelStarted && !mLevelFaulted)
			InvokeLevel(cOnStop, default);
		if ((mLevelClass == null) || mLevelClass.UsesCoroutines)
			mLevel.CancelCoroutines();
		mLevel.Release();
		mLevel = null;
		mLevelClass = null;
		ResourceHold.Drop(ref mLevelHold);
		mLevelStarted = false;
	}

	public BehaviorObject Level => mLevel;

	/// Reads a property of the live Level object into `value` (a playtest probes a level's
	/// state with it); false with no Level live or no such property.
	public bool GetLevelProperty(StringView name, ref ScriptValue value)
	{
		if (mLevel == null)
			return false;
		return mLevel.GetProperty(name, ref value);
	}
}
