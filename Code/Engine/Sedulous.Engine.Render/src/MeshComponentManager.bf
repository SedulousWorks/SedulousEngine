using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Materials;
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
	}

	protected override void OnComponentDestroyed(MeshComponent* component, EntityHandle entity)
	{
		DeleteAndNullify!(component.Materials);
		DeleteAndNullify!(component.MaterialCache);
	}

	/// Points the entity's mesh at a resource ID and binds it through the manager the scene
	/// was resolved with, so the swap takes effect live.
	///
	/// Raptor offers this through the SceneRender script facade; it belongs here, where the
	/// components already are. Before any resolve there is no manager: the id is set and
	/// nothing binds, which is what a bare tool gets.
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
	/// The counterpart to SetMesh, and Raptor's other half of the same facade. Slot 0 is the
	/// whole-mesh slot a single material mesh uses, so it is the default; the list grows to
	/// reach a higher slot, because a mesh may be bound before its materials are.
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
}
