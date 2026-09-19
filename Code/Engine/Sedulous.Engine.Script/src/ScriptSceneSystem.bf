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

namespace Sedulous.Engine.Script;

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
[Scriptable]
[DisplayName("Scripts")]
class ScriptSceneSystem : SceneSystem
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
	private ScriptRunHost mHost = null;
	private bool mStarted = false;
	private float mDeltaTime = 0.0f;
	private double mElapsed = 0.0;

	private List<EntityHandle> mTickOwners = new .() ~ delete _;
	private List<PendingScriptMessage> mMessages = new .() ~ DeleteContainerAndItems!(_);

	/// The bus subscriptions, one per event name any loaded class handles.
	private Dictionary<String, uint32> mSubscriptions = new .() ~ DeleteDictionaryAndKeys!(_);
	private List<delegate void(Variant)> mSubscriptionCallbacks = new .() ~ DeleteContainerAndItems!(_);

	// ---- the Level tier ----
	private SceneScriptSettings mSettings = new .() ~ delete _;
	private ScriptObject mLevel = null;
	private ScriptClass mLevelClass = null;
	private bool mLevelStarted = false;
	private bool mLevelFaulted = false;

	public override void OnSceneCreate(Scene scene)
	{
		mScene = scene;
		if (let components = scene.GetSystem<ScriptComponentManager>())
			components.SetScriptSystem(this);
	}

	/// Behaviours run BEFORE the rest of the update phase's gameplay: a script's writes
	/// land before the systems that read them.
	public override int32 UpdateOrder => -100;

	public override bool IsSimulationOnly => true;

	/// The subsystem, or a headless test, wires the run host in.
	public void SetRunHost(ScriptRunHost host)
	{
		mHost = host;
	}

	public ScriptRunHost Host => mHost;
	public Scene OwningScene => mScene;
	public SceneScriptSettings Settings => mSettings;
	public bool Started => mStarted;

	// ---- settings ----

	public override Type SettingsType => typeof(SceneScriptSettings);
	public override void* SettingsInstance => Internal.UnsafeCastToPtr(mSettings);
	public override StringView SettingsId => "script";
	public override void SerializeSettings(ISerializer ar) => mSettings.Serialize(ar);

	public override void ResolveResources(ResourceManager manager)
	{
		mSettings.Script.Bind(manager);
	}

	// ---- the script surface ----

	/// The last delivered frame time.
	[Scriptable]
	public float DeltaTime => mDeltaTime;

	/// Simulated seconds since the scene started.
	[Scriptable]
	public double Elapsed => mElapsed;

	/// Queues `on<Message>()` for every enabled behaviour of `target` that declares it.
	/// Delivered at the tick's top level, never inside the caller. On the entity too, so a
	/// script writes `other.Send("hit", 5)`.
	[Scriptable, ScriptOnEntity]
	public void Send(EntityHandle target, StringView message) => Queue(target, message, .Nil, false);
	[Scriptable, ScriptOnEntity]
	public void Send(EntityHandle target, StringView message, float payload) => Queue(target, message, .FromFloat(payload), true);
	[Scriptable, ScriptOnEntity]
	public void Send(EntityHandle target, StringView message, int32 payload) => Queue(target, message, .FromInt(payload), true);
	[Scriptable, ScriptOnEntity]
	public void Send(EntityHandle target, StringView message, bool payload) => Queue(target, message, .FromBool(payload), true);
	[Scriptable, ScriptOnEntity]
	public void Send(EntityHandle target, StringView message, StringView payload) => Queue(target, message, .FromString(payload), true);
	[Scriptable, ScriptOnEntity]
	public void Send(EntityHandle target, StringView message, EntityHandle payload) => Queue(target, message, .FromEntity(payload, mScene), true);

	/// Publishes an event on the scene's bus: every behaviour and the Level declaring
	/// `on<Event>` hears it when the bus drains.
	[Scriptable]
	public void Emit(StringView eventName) => Publish(eventName, Variant());
	[Scriptable]
	public void Emit(StringView eventName, float payload) => Publish(eventName, Variant.Create(payload));
	[Scriptable]
	public void Emit(StringView eventName, int32 payload) => Publish(eventName, Variant.Create(payload));
	[Scriptable]
	public void Emit(StringView eventName, bool payload) => Publish(eventName, Variant.Create(payload));
	[Scriptable]
	public void Emit(StringView eventName, StringView payload) => Publish(eventName, Variant.Create(new String(payload), true));
	[Scriptable]
	public void Emit(StringView eventName, EntityHandle payload) => Publish(eventName, Variant.Create(payload));

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

	/// A contact between two of this scene's entities, to BOTH sides' declared handlers,
	/// each seeing the OTHER as the entity. A collision kind gets (other, point, normal,
	/// speed); a trigger kind gets (other). Queued, never delivered inside the caller.
	public void DeliverContact(EntityHandle a, EntityHandle b, ScriptContactKind kind, Float3 point,
		Float3 normal, float speed)
	{
		StringView handler;
		bool trigger = false;
		switch (kind)
		{
		case .Begin: handler = "onContactBegin";
		case .End: handler = "onContactEnd";
		case .TriggerEnter: handler = "onTriggerEnter"; trigger = true;
		case .TriggerExit: handler = "onTriggerExit"; trigger = true;
		}
		DeliverContactSide(a, b, handler, point, normal, speed, trigger);
		DeliverContactSide(b, a, handler, point, normal, speed, trigger);
	}

	private void DeliverContactSide(EntityHandle self, EntityHandle other, StringView handler,
		Float3 point, Float3 normal, float speed, bool trigger)
	{
		// A side whose body no longer maps to a live entity, an end after a destroy, has
		// nobody to tell.
		if (!self.IsAssigned)
			return;
		var args = ScriptValue[4](.FromEntity(other, mScene), .FromFloat3(point), .FromFloat3(normal),
			.FromFloat(speed));
		EnqueueContact(self, handler, .(&args[0], trigger ? 1 : 4));
	}

	/// Physics contacts: queues a contact handler call, the name already the final
	/// `on<Event>` such as "onContactBegin", with its arguments marshalled. The SAME deferred
	/// queue as Send, so it drains at the tick's top level: the physics tick pushes contacts,
	/// never nested in a script call, and delivery is gated by HasHandler like a message.
	public void EnqueueContact(EntityHandle target, StringView handler, Span<ScriptValue> args)
	{
		if (handler.IsEmpty)
			return;
		let pending = new PendingScriptMessage();
		pending.Target = target;
		pending.Handler.Set(handler);
		for (let arg in args)
			pending.AddArg(arg);
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
			"onContactBegin", "onContactEnd", "onTriggerEnter", "onTriggerExit":
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
	}

	public override void OnEntityDestroyed(EntityHandle entity)
	{
		// The component's destruction routes here through the manager.
	}

	public override void OnUpdate(ScenePhase phase, float deltaTime)
	{
		if ((phase != .Update) || (mScene == null) || (mHost == null))
			return;

		mDeltaTime = deltaTime;
		mElapsed += deltaTime;
		using (ProfileScope("Script.Tick"))
		{
			TickLevel(deltaTime);
			TickBehaviors(deltaTime);
			// The top level: no script call is active, so the deferred work is safe here.
			DrainMessages();
		}
	}

	public override void OnFixedUpdate(float fixedDeltaTime)
	{
		if ((mScene == null) || (mHost == null) || (mLevel == null) || mLevelFaulted || !mSettings.Enabled)
			return;
		var dt = ScriptValue[1](.FromFloat(fixedDeltaTime));
		InvokeLevel(cOnFixedUpdate, dt);
	}

	// ---- behaviours ----

	private void TickBehaviors(float deltaTime)
	{
		let components = mScene.GetSystem<ScriptComponentManager>();
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
			}
		}
	}

	private void TickBehavior(ScriptBehavior behavior, EntityHandle entity, float deltaTime)
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

		let scriptClass = behavior.Script.Get;
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

	private void InstantiateBehavior(ScriptBehavior behavior, EntityHandle entity, ScriptClass scriptClass)
	{
		if (scriptClass.IsModule)
		{
			// A utility module: nothing to instantiate, not an error.
			behavior.BoundClass = scriptClass;
			return;
		}

		using (ProfileScope(scriptClass.ProfileName))
		{
			behavior.Instance = mHost.Instantiate(scriptClass);
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
		let runtime = mHost.Runtime;
		runtime.SetProperty(behavior.Instance, "self", .FromEntity(entity, mScene));
		runtime.SetProperty(behavior.Instance, "scene", .FromObject(mScene));
		ScriptProperties.ApplyAll(runtime, behavior.Instance, scriptClass, behavior.Overrides, mScene, mScene.GetEntityName(entity));
		SubscribeHandlers(scriptClass);
	}

	/// One handler dispatch, gated by the class declaring it. A fault disables this
	/// behaviour and is logged; true when the behaviour may go on.
	private bool Invoke(ScriptBehavior behavior, EntityHandle entity, StringView handler, Span<ScriptValue> args)
	{
		let scriptClass = behavior.BoundClass;
		if ((behavior.Instance == null) || (scriptClass == null) || !scriptClass.HasHandler(handler))
			return true;
		if (!mHost.Runtime.HasMethod(behavior.Instance, handler, args.Length))
			return true;

		var result = ScriptValue.Nil;
		bool ok;
		using (ProfileScope(scriptClass.ProfileName))
		{
			ok = mHost.Runtime.Invoke(behavior.Instance, handler, args, ref result);
		}
		if (ok)
			return true;

		behavior.Faulted = true;
		GlobalLog(.Error, scope $"Script: '{mScene.GetEntityName(entity)}': behaviour '{scriptClass.ClassName}' faulted in {handler}; disabled");
		mHost.ReportProblems();
		return false;
	}

	private void CancelCoroutines(ScriptBehavior behavior)
	{
		if ((behavior.Instance == null) || (behavior.BoundClass == null) || !behavior.BoundClass.UsesCoroutines)
			return;
		mHost.Runtime.CancelCoroutinesFor(behavior.Instance);
	}

	private void StopBehavior(ScriptBehavior behavior, EntityHandle entity, bool invokeDestroy)
	{
		if ((behavior.Instance != null) && invokeDestroy && behavior.Started && (behavior.BoundClass != null) && !behavior.Faulted)
			Invoke(behavior, entity, cOnDestroy, default);
		CancelCoroutines(behavior);
		if (behavior.Instance != null)
		{
			mHost.Runtime.Release(behavior.Instance);
			behavior.Instance = null;
		}
		behavior.BoundClass = null;
		behavior.Started = false;
		behavior.Active = false;
	}

	/// onDestroy and release for one component's behaviours: entity or component removal.
	public void ReleaseComponentInstances(ScriptComponent* component, EntityHandle entity)
	{
		if ((mHost == null) || (mHost.Runtime == null))
			return;
		for (let behavior in component.Behaviors)
			StopBehavior(behavior, entity, true);
	}

	private void DestroyAllInstances()
	{
		let components = (mScene != null) ? mScene.GetSystem<ScriptComponentManager>() : null;
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
			let components = (mScene != null) ? mScene.GetSystem<ScriptComponentManager>() : null;
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
		let components = mScene.GetSystem<ScriptComponentManager>();
		if ((components == null) || !mScene.IsValid(pending.Target))
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
	private void SubscribeHandlers(ScriptClass scriptClass)
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
			let handlerName = new String(handler);
			delegate void(Variant) callback = new (payload) => { BroadcastEvent(handlerName, payload); };
			mSubscriptionCallbacks.Add(callback);
			mSubscriptions[name] = bus.Subscribe(StringHash(eventName), callback);
			// The handler name string lives as long as the callback; parked with it.
			mOwnedHandlerNames.Add(handlerName);
		}
	}
	private List<String> mOwnedHandlerNames = new .() ~ DeleteContainerAndItems!(_);

	private void ClearSubscriptions()
	{
		let bus = (mScene != null) ? mScene.Events : null;
		if (bus != null)
		{
			for (let entry in mSubscriptions)
				bus.Unsubscribe(entry.value);
		}
		DeleteDictionaryAndKeys!(mSubscriptions);
		mSubscriptions = new .();
		ClearAndDeleteItems!(mSubscriptionCallbacks);
		ClearAndDeleteItems!(mOwnedHandlerNames);
	}

	/// The bus drains at the scene tick's top level, so this dispatches directly: every
	/// enabled behaviour of this scene declaring the handler, and the Level. Owners are
	/// snapshotted first, since a handler may spawn or destroy.
	private void BroadcastEvent(StringView handler, Variant payload)
	{
		var value = ScriptPayloads.ValueOf(payload, mScene);
		var args = ScriptValue[1](value);
		Span<ScriptValue> span = value.IsNil ? default : .(&args[0], 1);

		if ((mLevel != null) && !mLevelFaulted && (mLevelClass != null) && mLevelClass.HasHandler(handler))
			InvokeLevel(handler, span);

		let components = mScene.GetSystem<ScriptComponentManager>();
		if (components == null)
			return;
		mTickOwners.Clear();
		components.ForEach(scope [&] (component, owner) => { mTickOwners.Add(owner); });
		for (let entity in mTickOwners)
		{
			for (int i = 0; ; i++)
			{
				let component = components.Get(entity);
				if ((component == null) || (i >= component.Behaviors.Count))
					break;
				let behavior = component.Behaviors[i];
				if ((behavior.Instance == null) || !behavior.Enabled || behavior.Faulted || !behavior.Active)
					continue;
				Invoke(behavior, entity, handler, span);
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
		let levelClass = mSettings.Script.Get;
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
			mLevel = mHost.Instantiate(levelClass);
			mLevelClass = levelClass;
			mLevelStarted = false;
			if (mLevel == null)
			{
				mLevelFaulted = true;
				GlobalLog(.Error, scope $"Script: scene '{mScene.Name}': the Level '{levelClass.ClassName}' failed to instantiate; disabled");
				return;
			}
			mHost.Runtime.SetProperty(mLevel, "scene", .FromObject(mScene));
			ScriptProperties.ApplyAll(mHost.Runtime, mLevel, levelClass, mSettings.Overrides, mScene, mScene.Name);
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
		if (!mHost.Runtime.HasMethod(mLevel, handler, args.Length))
			return true;
		var result = ScriptValue.Nil;
		if (mHost.Runtime.Invoke(mLevel, handler, args, ref result))
			return true;
		mLevelFaulted = true;
		GlobalLog(.Error, scope $"Script: scene '{mScene.Name}': the Level faulted in {handler}; disabled");
		mHost.ReportProblems();
		return false;
	}

	private void StopLevel(bool invokeStop)
	{
		if (mLevel == null)
			return;
		if (invokeStop && mLevelStarted && !mLevelFaulted)
			InvokeLevel(cOnStop, default);
		if (mLevelClass?.UsesCoroutines == true)
			mHost.Runtime.CancelCoroutinesFor(mLevel);
		mHost.Runtime.Release(mLevel);
		mLevel = null;
		mLevelClass = null;
		mLevelStarted = false;
	}

	public ScriptObject Level => mLevel;
}
