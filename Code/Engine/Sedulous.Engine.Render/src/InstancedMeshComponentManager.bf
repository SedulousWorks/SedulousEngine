using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Render;

/// The pool of instanced sets.
///
/// It creates and frees every list a component points at, for the same reason the mesh pool
/// does: the component is a struct the pool copies.
///
/// It measures its entities for the scene (ISceneEntityBounds): the set's merged world sphere,
/// which extraction keeps current, as a box.
class InstancedMeshComponentManager : ResourceBindingComponentManager<InstancedMeshComponent>, ISceneEntityBounds
{
	public override ISceneEntityBounds AsEntityBounds => this;

	public bool EntityBounds(Scene scene, EntityHandle entity, out AABB outBounds)
	{
		outBounds = AABB.Empty();
		let set = Get(entity);
		// Empty, or not measured by extraction yet.
		if ((set == null) || (set.Count == 0) || (set.CachedRadius <= 0.0f))
			return false;
		let r = set.CachedRadius;
		outBounds = AABB.FromCenterExtents(set.CachedCenter, .(r, r, r));
		return true;
	}

	protected override void OnComponentCreated(InstancedMeshComponent* component,
		EntityHandle entity)
	{
		component.SubmeshMaterials = new List<Material>();
		component.Instances = new List<Float4x4>();
		component.Tints = new List<Color>();
		component.PoseIndices = new List<uint32>();
		component.WorldTransforms = new List<Float4x4>();
		component.LinearTints = new List<Color>();

		// ONE identity instance, so a component just added in an editor draws its mesh at the
		// entity's transform straight away. An authored set replaces it.
		component.Instances.Add(Float4x4.Identity());
	}

	protected override void OnComponentDestroyed(InstancedMeshComponent* component,
		EntityHandle entity)
	{
		DeleteAndNullify!(component.SubmeshMaterials);
		DeleteAndNullify!(component.Instances);
		DeleteAndNullify!(component.Tints);
		DeleteAndNullify!(component.PoseIndices);
		DeleteAndNullify!(component.WorldTransforms);
		DeleteAndNullify!(component.LinearTints);
	}
}
