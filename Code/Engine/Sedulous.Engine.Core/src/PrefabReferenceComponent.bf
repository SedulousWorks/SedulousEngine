namespace Sedulous.Engine.Core;

using System;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Inspection;

/// Component that instantiates a prefab's entity subgraph as children of
/// its owning entity. Stores per-instance parameter overrides.
///
/// Lifecycle:
///   1. Component created, PrefabRef set (editor drag-drop or scene load)
///   2. PrefabComponentManager resolves ResourceRef -> PrefabResource
///   3. Manager instantiates entity subtree under owning entity
///   4. Manager applies per-instance overrides from Overrides dictionary
///   5. On prefab change: manager destroys subtree, re-instantiates, re-applies
///   6. On component destroy: manager destroys instantiated entities
[Component]
class PrefabReferenceComponent : Component, ISerializableComponent
{
	/// Reference to the .prefab resource.
	[Property]
	[ResourceRefType(".prefab")]
	public ResourceRef PrefabRef ~ _.Dispose();

	/// Per-instance parameter overrides (parameter name -> serialized value string).
	/// Populated by the editor when the user overrides an exposed parameter.
	public Dictionary<String, String> Overrides = new .() ~ {
		for (let kv in _) { delete kv.key; delete kv.value; }
		delete _;
	};

	// === Runtime state (not serialized) ===

	/// Handles of entities created by instantiation (for cleanup on re-instantiate/destroy).
	public List<EntityHandle> InstantiatedEntities = new .() ~ delete _;

	/// Map from prefab source entity Guid -> live instance handle (for override targeting).
	public Dictionary<Guid, EntityHandle> GuidMap ~ { if (_ != null) delete _; };

	/// Whether the prefab has been instantiated at least once.
	public bool IsInstantiated = false;

	/// The resolved resource's Guid (to detect resource changes for re-instantiation).
	public Guid ResolvedPrefabId;

	// === Serialization ===

	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.ResourceRef("PrefabRef", ref PrefabRef);

		// Overrides as array of name-value pairs
		var overrideCount = (int32)Overrides.Count;
		s.BeginArray("Overrides", ref overrideCount);

		if (s.IsReading)
		{
			for (int32 i = 0; i < overrideCount; i++)
			{
				s.BeginObject("");
				let name = new String();
				s.String("Name", name);
				let value = new String();
				s.String("Value", value);
				Overrides[name] = value;
				s.EndObject();
			}
		}
		else
		{
			for (let kv in Overrides)
			{
				s.BeginObject("");
				s.String("Name", kv.key);
				s.String("Value", kv.value);
				s.EndObject();
			}
		}

		s.EndArray();
	}

	// === Helpers ===

	public void SetPrefabRef(ResourceRef @ref)
	{
		PrefabRef.Dispose();
		PrefabRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	/// Sets or replaces an override value for a parameter.
	public void SetOverride(StringView paramName, StringView value)
	{
		for (let kv in Overrides)
		{
			if (kv.key == paramName)
			{
				kv.value.Set(value);
				return;
			}
		}
		Overrides[new String(paramName)] = new String(value);
	}

	/// Removes an override for a parameter (reverts to prefab default).
	public void RemoveOverride(StringView paramName)
	{
		for (let kv in Overrides)
		{
			if (kv.key == paramName)
			{
				delete kv.key;
				delete kv.value;
				Overrides.Remove(kv.key);
				return;
			}
		}
	}
}
