using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Render;

/// The pool of drawable meshes.
///
/// It creates and frees each component's material lists, because a component is a struct in a
/// packed pool and cannot own heap data itself.
///
/// It measures its entities for the scene (ISceneEntityBounds): a mesh's bounds through the
/// entity's world matrix, once the mesh is loaded. And it answers rays against its meshes'
/// triangles (ISceneSurfaceQuery; a skinned mesh in its bind pose, the pose its CPU vertices
/// hold).
class MeshComponentManager : ResourceBindingComponentManager<MeshComponent>, ISceneEntityBounds, ISceneSurfaceQuery
{
	public override ISceneEntityBounds AsEntityBounds => this;
	public override ISceneSurfaceQuery AsSurfaceQuery => this;

	public bool RaycastSurface(Scene scene, Float3 origin, Float3 direction, float maxDistance, delegate bool(EntityHandle entity) accept, out SceneSurfaceHit outHit)
	{
		var found = SceneSurfaceHit();
		var any = false;
		var reach = maxDistance;
		ForEach(scope [&] (component, entity) =>
			{
				let mesh = component.Mesh.Get;
				if ((mesh == null) || mesh.Vertices.IsEmpty || !scene.IsEffectivelyActive(entity))
					return;
				if ((accept != null) && !accept(entity))
					return;
				// The ray in the mesh's space, its direction NOT normalized: distances along it
				// stay world distances along the world ray.
				let world = scene.GetWorldMatrix(entity);
				let toLocal = Inverse(world);
				let localOrigin = TransformPoint(origin, toLocal);
				let localDirection = TransformDirection(direction, toLocal);
				if (mesh.Bounds.IsValid() && !RayMeetsBox(localOrigin, localDirection, mesh.Bounds, reach))
					return;
				if (!MeshRaycast.Raycast(mesh, localOrigin, localDirection, reach, let hit))
					return;
				reach = hit.Distance;
				any = true;
				found.Entity = entity;
				found.Distance = hit.Distance;
				found.Position = TransformPoint(hit.Position, world);
				let normal = TransformDirection(hit.Normal, Transpose(toLocal));
				found.Normal = (LengthSquared(normal) > 0.0f) ? Normalized(normal) : Float3.UnitY;
				// The corner nearest the hit, measured in the world (a scaled mesh's nearest
				// corner in its own space need not be the nearest on screen).
				var best = -1.0f;
				for (let corner in hit.Corners)
				{
					let at = TransformPoint(corner, world);
					let d = LengthSquared(at - found.Position);
					if ((best < 0.0f) || (d < best))
					{
						best = d;
						found.Vertex = at;
					}
				}
			});
		outHit = found;
		return any;
	}

	/// Whether the ray (any direction length) meets `bounds` before `reach`, in its units.
	private static bool RayMeetsBox(Float3 origin, Float3 direction, AABB bounds, float reach)
	{
		var enter = 0.0f;
		var leave = reach;
		float[3] o = .(origin.X, origin.Y, origin.Z);
		float[3] d = .(direction.X, direction.Y, direction.Z);
		float[3] lo = .(bounds.Min.X, bounds.Min.Y, bounds.Min.Z);
		float[3] hi = .(bounds.Max.X, bounds.Max.Y, bounds.Max.Z);
		for (int axis < 3)
		{
			if (Math.Abs(d[axis]) < 1e-12f)
			{
				if ((o[axis] < lo[axis]) || (o[axis] > hi[axis]))
					return false; // parallel to the slab and outside it
				continue;
			}
			var t0 = (lo[axis] - o[axis]) / d[axis];
			var t1 = (hi[axis] - o[axis]) / d[axis];
			if (t0 > t1)
				Swap!(t0, t1);
			enter = Math.Max(enter, t0);
			leave = Math.Min(leave, t1);
			if (enter > leave)
				return false;
		}
		return true;
	}

	public bool EntityBounds(Scene scene, EntityHandle entity, out AABB outBounds)
	{
		outBounds = AABB.Empty();
		let component = Get(entity);
		let mesh = (component != null) ? component.Mesh.Get : null;
		if ((mesh == null) || !mesh.Bounds.IsValid())
			return false;
		outBounds = TransformAABB(mesh.Bounds, scene.GetWorldMatrix(entity));
		return true;
	}

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
