using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Render;

/// The pool of drawable meshes.
///
/// It creates and frees each component's material lists, because a component is a struct in a
/// packed pool and cannot own heap data itself.
class MeshComponentManager : ResourceBindingComponentManager<MeshComponent>
{
	protected override void OnComponentCreated(MeshComponent* component, EntityHandle entity)
	{
		component.Materials = new List<Ref<Material>>();
		component.MaterialCache = new List<Material>();
		component.MaterialOverrides = new List<MaterialPropertyOverride>();
	}

	protected override void OnComponentDestroyed(MeshComponent* component, EntityHandle entity)
	{
		DeleteAndNullify!(component.Materials);
		DeleteAndNullify!(component.MaterialCache);
		for (let entry in component.MaterialOverrides)
			delete entry.Name;
		DeleteAndNullify!(component.MaterialOverrides);
	}

	/// Points the entity's mesh at a resource ID and binds it through the manager the scene
	/// was resolved with, so the swap takes effect live.
	///
	/// It belongs here, where the components already are, rather than on a script facade.
	/// Before any resolve there is no manager: the id is set and nothing binds, which is what
	/// a bare tool gets.
	public bool SetMesh(EntityHandle entity, Guid id)
	{
		let component = Get(entity);
		if (component == null)
			return false;

		component.Mesh.SetId(id);
		component.Mesh.Rebind(Resources);

		return true;
	}

	/// Points one of the entity's material slots at a resource ID and binds it.
	///
	/// The counterpart to SetMesh. Slot 0 is the whole-mesh slot a single material mesh uses,
	/// so it is the default; the list grows to reach a higher slot, because a mesh may be
	/// bound before its materials are.
	public bool SetMaterial(EntityHandle entity, Guid id, int slot = 0)
	{
		let component = Get(entity);
		if ((component == null) || (slot < 0))
			return false;

		while (component.Materials.Count <= slot)
			component.Materials.Add(.(Guid()));

		component.Materials[slot].SetId(id);
		component.Materials[slot].Rebind(Resources);

		return true;
	}

	/// Sets one of the entity's material properties for it alone: the material in `slot`
	/// draws with `value` for the property `name` (as the material editor shows it: Roughness,
	/// EmissiveColor), every other mesh using that material unchanged. `size` is 4 for a float,
	/// 16 for a Float4. A name the material does not have, or a value wider than the property,
	/// changes nothing when drawn. Runtime only: not saved with the scene. False for an entity
	/// without a mesh or a negative slot.
	public bool SetMaterialProperty(EntityHandle entity, int slot, StringView name, Float4 value,
		uint32 size)
	{
		let component = Get(entity);
		if ((component == null) || (slot < 0))
			return false;

		component.SetMaterialProperty((uint32)slot, name, value, size);
		return true;
	}

	/// Puts a property set by SetMaterialProperty back to the material's own value; false if
	/// it was not set.
	public bool ClearMaterialProperty(EntityHandle entity, int slot, StringView name)
	{
		let component = Get(entity);
		return (component != null) && (slot >= 0)
			&& component.ClearMaterialProperty((uint32)slot, name);
	}
}
