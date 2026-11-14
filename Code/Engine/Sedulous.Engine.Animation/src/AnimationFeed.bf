using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// What the animation managers share: naming the meshes a player poses.
///
/// Both the clip and the graph managers do exactly this, and the instanced one does its own
/// version over the instanced pool, so the target list lives here rather than being written
/// out twice.
static class AnimationFeed
{
	/// The target list, by stable id. The same shape for every animation component, so a
	/// scene written by one reads the same as a scene written by the other; the instanced one
	/// keys it "targets", as its field is named.
	public static void SerializeTargets(ISerializer ar, List<EntityRef> targets,
		String key = "meshEntities")
	{
		ar.Key(key);
		uint32 count = (uint32)targets.Count;
		ar.BeginArray(ref count);
		if (ar.Mode == .Read)
		{
			targets.Clear();
			targets.Reserve((int)count);
			for (uint32 i < count)
			{
				var id = Guid();
				SerializeValue(ar, ref id);
				targets.Add(EntityRef(id));
			}
		}
		else
		{
			for (int i < targets.Count)
			{
				var id = targets[i].Id;
				SerializeValue(ar, ref id);
			}
		}
		ar.EndArray();
	}
}

/// Which animator posed each mesh at its last update: what an animator manager answers
/// ISkinningPaletteSource from, so a mesh holds no pointer into the animator's player.
class PosedMeshes
{
	private struct Posed
	{
		public EntityHandle Mesh;
		public EntityHandle Animator;

		public this(EntityHandle mesh, EntityHandle animator)
		{
			Mesh = mesh;
			Animator = animator;
		}
	}

	/// By the mesh's entity index; the whole handle kept, so a reused slot reads as unposed.
	private Dictionary<uint32, Posed> mByMesh = new .() ~ delete _;

	public void Clear() => mByMesh.Clear();

	public void Record(EntityHandle mesh, EntityHandle animator)
	{
		mByMesh[mesh.Index] = Posed(mesh, animator);
	}

	/// The animator that posed `mesh` at its last update, or Invalid.
	public EntityHandle AnimatorOf(EntityHandle mesh)
	{
		if (mByMesh.TryGetValue(mesh.Index, let posed) && (posed.Mesh == mesh))
			return posed.Animator;
		return EntityHandle.Invalid;
	}

	/// Records the meshes the animator on `owner` poses: its own entity's when it names none,
	/// otherwise every named target resolved afresh (an id becomes a live handle each frame, so
	/// a target destroyed and respawned is picked up).
	public void RecordAll(Scene scene, MeshComponentManager meshes, EntityHandle owner, List<EntityRef> targets)
	{
		if (targets.IsEmpty)
		{
			RecordOne(meshes, owner, owner);
			return;
		}
		for (let target in targets)
			RecordOne(meshes, scene.FindEntity(target.Id), owner);
	}

	private void RecordOne(MeshComponentManager meshes, EntityHandle mesh, EntityHandle owner)
	{
		if (mesh.IsAssigned && meshes.Has(mesh))
			Record(mesh, owner);
	}
}
