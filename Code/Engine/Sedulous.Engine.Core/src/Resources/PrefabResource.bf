namespace Sedulous.Engine.Core.Resources;

using System;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Engine.Core;

/// A loadable prefab asset - a serialized entity subgraph.
/// Entities are serialized in the same format as scenes (via PrefabSerializer)
/// and instantiated into live scenes by PrefabSpawner.
class PrefabResource : Resource
{
	/// Live scene for editing (set for saving, null for read-only use).
	public Scene Scene;

	/// Type registry for component deserialization (not owned).
	public ComponentTypeRegistry TypeRegistry;

	public override ResourceType ResourceType => .("Sedulous.Engine.Core.Resources.PrefabResource");

	public override int32 SerializationVersion => 2;

	protected override SerializationResult OnSerialize(Serializer serializer)
	{
		let prefabSerializer = scope PrefabSerializer(TypeRegistry);

		if (serializer.IsWriting)
			return prefabSerializer.Save(Scene, serializer);
		else if (Scene != null)
			return prefabSerializer.Load(Scene, serializer);
		else
			return .Ok; // Header-only load
	}
}
