using System;
using System.Collections;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Script;
using Sedulous.Script.Resource;

namespace Sedulous.Engine.Script;

/// One behaviour on an entity: a cooked script class, whether it runs, how often, and the
/// property values the author changed from the class's defaults. The runtime state (the
/// live instance and where it is in its lifecycle) is transient and never serialized.
///
/// Because the overrides live in the component's payload, the prefab delta machinery
/// covers them with no new code: an override is data like any other field.
class ScriptBehavior : ISerializable
{
	// ---- authored ----

	public Ref<ScriptClass> Script = .(Guid());
	public bool Enabled = true;
	/// Seconds between onUpdate calls; zero or less is every tick. The delivered dt is the
	/// ACCUMULATED time, so movement integrates correctly at the lower rate.
	public float UpdateInterval = 0.0f;
	public List<ScriptPropertyOverride> Overrides = new .() ~ DeleteContainerAndItems!(_);

	// ---- runtime, transient ----

	/// The live object, the runtime's; null until the first simulated tick builds it.
	public ScriptObject Instance = null;
	/// The product the instance was built from, BORROWED: a reload swaps the product and
	/// the instance is rebuilt.
	public ScriptClass BoundClass = null;
	/// onStart delivered.
	public bool Started = false;
	/// The last delivered enable state: the onEnable/onDisable edges.
	public bool Active = false;
	/// Frozen by an inactive entity.
	public bool EntitySuspended = false;
	/// A fault disabled this one behaviour, until a reload.
	public bool Faulted = false;
	/// Time banked toward the next throttled onUpdate.
	public float UpdateAccumulator = 0.0f;

	public ScriptPropertyOverride FindOverride(uint64 hash)
	{
		for (let entry in Overrides)
		{
			if (entry.Hash == hash)
				return entry;
		}
		return null;
	}

	/// Sets an override, taking the value's Text if it has one.
	public void SetOverride(uint64 hash, ScriptPropertyValue value)
	{
		var existing = FindOverride(hash);
		if (existing == null)
		{
			existing = new ScriptPropertyOverride();
			existing.Hash = hash;
			Overrides.Add(existing);
		}
		if (existing.Value.Text != null)
			delete existing.Value.Text;
		existing.Value = value;
	}

	public void RemoveOverride(uint64 hash)
	{
		for (int i = 0; i < Overrides.Count; i++)
		{
			if (Overrides[i].Hash == hash)
			{
				delete Overrides[i];
				Overrides.RemoveAt(i);
				return;
			}
		}
	}

	public void Serialize(ISerializer ar)
	{
		SerializeValue(ar, "script", ref Script.Id);
		SerializeValue(ar, "enabled", ref Enabled);
		SerializeValue(ar, "updateInterval", ref UpdateInterval);
		ar.Key("overrides");
		SerializeList(ar, Overrides);
	}
}
