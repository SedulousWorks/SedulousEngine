using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Script;
using Sedulous.Engine.Script;

namespace Sedulous.Engine.Script.Facades;

/// `scene.Scripts`: the scene's script time, the messages between behaviours, the events
/// on the scene's bus, and a behaviour added at runtime.
[Scriptable, SceneFacade("Scripts")]
class ScriptsFacade : SceneFacade
{
	private ScriptSceneSystem System => Scene.GetSystem<ScriptSceneSystem>();
	private ScriptComponentManager Components => Scene.GetSystem<ScriptComponentManager>();

	/// The last delivered frame time.
	[Scriptable]
	public float DeltaTime => System?.DeltaTime ?? 0.0f;
	/// Simulated seconds since the scene started.
	[Scriptable]
	public double Elapsed => System?.Elapsed ?? 0.0;

	/// Queues `on<Message>()` for every enabled behaviour of `target` that declares it,
	/// delivered at the tick's top level: `other.Send("hit", 5)` too.
	[Scriptable, ScriptOnEntity]
	public void Send(EntityHandle target, StringView message) => System?.Send(target, message);
	[Scriptable, ScriptOnEntity]
	public void Send(EntityHandle target, StringView message, float payload) => System?.Send(target, message, payload);
	[Scriptable, ScriptOnEntity]
	public void Send(EntityHandle target, StringView message, int32 payload) => System?.Send(target, message, payload);
	[Scriptable, ScriptOnEntity]
	public void Send(EntityHandle target, StringView message, bool payload) => System?.Send(target, message, payload);
	[Scriptable, ScriptOnEntity]
	public void Send(EntityHandle target, StringView message, StringView payload) => System?.Send(target, message, payload);
	[Scriptable, ScriptOnEntity]
	public void Send(EntityHandle target, StringView message, EntityHandle payload) => System?.Send(target, message, payload);

	/// Publishes on the scene's bus: every behaviour and the Level declaring `on<Event>`.
	[Scriptable]
	public void Emit(StringView eventName) => System?.Emit(eventName);
	[Scriptable]
	public void Emit(StringView eventName, float payload) => System?.Emit(eventName, payload);
	[Scriptable]
	public void Emit(StringView eventName, int32 payload) => System?.Emit(eventName, payload);
	[Scriptable]
	public void Emit(StringView eventName, bool payload) => System?.Emit(eventName, payload);
	[Scriptable]
	public void Emit(StringView eventName, StringView payload) => System?.Emit(eventName, payload);
	[Scriptable]
	public void Emit(StringView eventName, EntityHandle payload) => System?.Emit(eventName, payload);

	/// A behaviour of the class, by asset id, on the entity: started on the next tick.
	[Scriptable]
	public bool AddBehavior(EntityHandle entity, Guid scriptClass) => Components?.AddBehavior(entity, scriptClass) ?? false;
}

/// `scene.Prefabs`: instantiating an authored prefab.
[Scriptable, SceneFacade("Prefabs")]
class PrefabsFacade : SceneFacade
{
	private PrefabSpawnSystem Spawner => Scene.GetSystem<PrefabSpawnSystem>();

	/// The prefab's root entity, unassigned when it could not be spawned.
	[Scriptable]
	public EntityHandle Spawn(Guid prefab, Float3 position, Quaternion rotation = .Identity, EntityHandle parent = .Invalid)
		=> Spawner?.Spawn(prefab, position, rotation, parent) ?? .Invalid;
}
