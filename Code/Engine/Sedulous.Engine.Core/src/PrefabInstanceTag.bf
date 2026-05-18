namespace Sedulous.Engine.Core;

using System;

/// Tag component on every entity that belongs to a V2 prefab instance.
/// Carries enough information to reconstruct the link to the template.
///
/// Not serialized — reconstructed from scene file prefab instance
/// metadata during load.
class PrefabInstanceTag : Component
{
	/// Resource ID of the .prefab file.
	public Guid PrefabId;

	/// URI path to the .prefab file (e.g., "project://Prefabs/Enemy.prefab").
	/// Stored so the scene serializer can reload the prefab on scene load.
	public String PrefabPath ~ delete _;

	/// This entity's GUID within the .prefab file (for mapping back to template).
	public Guid SourceEntityId;

	/// The root entity of this prefab instance (the entity the user dragged in).
	/// For the root itself, this equals Owner.
	public EntityHandle InstanceRoot = .Invalid;

	public void SetPrefabPath(StringView path)
	{
		if (PrefabPath == null)
			PrefabPath = new String(path);
		else
			PrefabPath.Set(path);
	}
}

/// Manages PrefabInstanceTag components. No update logic, just storage.
/// Empty SerializationTypeId opts out of serialization entirely —
/// tags are runtime-only, recreated on each prefab instantiation or scene load.
class PrefabInstanceTagManager : ComponentManager<PrefabInstanceTag>
{
	public override StringView SerializationTypeId => "";
}
