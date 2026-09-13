using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// What the animation managers share: naming the meshes a player feeds, and handing them the
/// frame's matrices.
///
/// Both the clip and the graph managers do exactly this, and the instanced one does its own
/// version over the instanced pool, so the target list lives here rather than being written
/// out twice.
static class AnimationFeed
{
	/// The target list, by stable id. The same shape for every animation component, so a
	/// scene written by one reads the same as a scene written by the other.
	public static void SerializeTargets(ISerializer ar, List<EntityRef> targets)
	{
		ar.Key("meshEntities");
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

	/// Points one mesh at this frame's palettes. BORROWED for the frame: the player, owned by
	/// the component, is what keeps the storage alive.
	public static void Feed(MeshComponentManager meshes, EntityHandle entity,
		Span<Float4x4> current, Span<Float4x4> previous)
	{
		let mesh = meshes.Get(entity);
		if (mesh == null)
			return;

		mesh.BoneMatrices = current.Ptr;
		mesh.PrevBoneMatrices = previous.Ptr;
		mesh.BoneCount = (uint32)current.Length;
	}

	/// The owner when nothing was named, otherwise every named target resolved afresh: an id
	/// becomes a live handle each frame, so a target destroyed and respawned is picked up.
	public static void FeedAll(Scene scene, MeshComponentManager meshes, EntityHandle owner,
		List<EntityRef> targets, Span<Float4x4> current, Span<Float4x4> previous)
	{
		if (targets.IsEmpty)
		{
			Feed(meshes, owner, current, previous);
			return;
		}

		for (let target in targets)
			Feed(meshes, scene.FindEntity(target.Id), current, previous);
	}
}
