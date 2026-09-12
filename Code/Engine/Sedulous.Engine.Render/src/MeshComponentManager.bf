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
class MeshComponentManager : SerializableComponentManager<MeshComponent>
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

	/// Points the entity's mesh at a resource ID and binds it, so the swap takes effect live.
	///
	/// Raptor offers this through the SceneRender script facade; it belongs here, where the
	/// components already are. A null manager binds nothing and leaves the id set, which is
	/// what a bare tool with no resource manager gets.
	public bool SetMesh(EntityHandle entity, Guid id, ResourceManager resources = null)
	{
		let component = Get(entity);
		if (component == null)
			return false;

		component.Mesh.SetId(id);
		if (resources != null)
			component.Mesh.Bind(resources);

		return true;
	}

	/// Attaches every reference to the manager's proxies. The material CACHE is refreshed at
	/// extract instead, once per frame, so a late cook heals without a reload.
	public void ResolveResources(ResourceManager resources, EntityHandle entity)
	{
		let component = Get(entity);
		if (component == null)
			return;

		component.Mesh.Bind(resources);
		for (int i < component.Materials.Count)
		{
			var reference = component.Materials[i];
			reference.Bind(resources);
			component.Materials[i] = reference;
		}
	}
}
