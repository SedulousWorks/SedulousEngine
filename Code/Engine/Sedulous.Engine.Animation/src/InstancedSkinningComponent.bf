using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// Instanced skinning for CROWDS: the companion to an instanced mesh that makes its instances
/// animate from a few shared poses.
///
/// Each frame the manager samples each of its clips at PoseCount evenly spaced phases, each
/// clip on its own clock, into one POSE POOL: a block of PoseCount palettes per clip, in list
/// order. It hands the pool to the target sets, where an instance's clip picks the block and
/// the set's pose policy the phase inside it (PoseSelection.SelectPose). So a crowd of
/// thousands costs clips by PoseCount palette computes.
///
/// Authored like SkeletalAnimationComponent: the skeleton and clips are resource references
/// (or direct objects from runtime code), the targets entity references, by stable id so a
/// prefab spawn remaps them. Empty targets feed the owner. The pools are the manager's.
[SerializableComponent("instanced_skinning", 1, 1)]
[DisplayName("Instanced Skinning")]
[Category("Animation")]
[Scriptable]
[Description("Animates an instanced mesh crowd from a small shared pool of poses, each instance on one of its clips.")]
struct InstancedSkinningComponent : ISerializable, IComponentResources
{
	/// Shared across the crowd.
	[Scriptable]
	public Ref<Skeleton> Skeleton = .(Guid());
	/// The clips the instances play; an instance's clip is its index here. Not on the script
	/// surface: a list of references does not cross yet (Backlog).
	[Description("The clips the instances play; an instance's clip is its index here")]
	public List<Ref<AnimationClip>> Clips = null;

	/// Phases sampled per clip. More is a smoother spread and more compute.
	[Scriptable]
	[Description("Phases sampled per clip: more is a smoother spread, and costs more")]
	public uint32 PoseCount = 32;
	[Scriptable]
	public float Speed = 1.0f;

	/// The instanced meshes to feed, which is one set per skinned mesh of a multi part
	/// character. Empty means the owner.
	[Scriptable]
	[Description("The instanced meshes it animates (none: its own)")]
	public List<EntityRef> Targets = null;

	// ---- the manager's own per frame state, not authored ----

	/// Clips by pose count by bone count skinning matrices, recomputed each frame.
	public List<Float4x4> PosePool = null;
	/// LAST frame's palettes, for the per bone motion vectors. Ping ponged rather than
	/// recomputed.
	public List<Float4x4> PrevPosePool = null;
	/// Bone count scratch, for the sampling.
	public List<BoneTransform> Scratch = null;

	/// Each clip's clock, wrapped to its duration.
	[Hidden]
	public List<float> Times = null;
	[Hidden]
	public uint32 BoneCount = 0;

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		Skeleton.Bind(manager);
		for (int i < Clips.Count)
		{
			var reference = Clips[i];
			reference.Bind(manager);
			Clips[i] = reference;
		}
	}

	/// The references and the tunables persist. The pools and the clocks are runtime only.
	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "skeleton", ref Skeleton.Id);

		ar.Key("clips");
		uint32 count = (uint32)Clips.Count;
		ar.BeginArray(ref count);
		if (ar.Mode == .Read)
		{
			Clips.Clear();
			Clips.Reserve((int)count);
			for (uint32 i < count)
			{
				var reference = Ref<AnimationClip>(Guid());
				SerializeValue(ar, ref reference.Id);
				Clips.Add(reference);
			}
		}
		else
		{
			for (int i < Clips.Count)
			{
				var id = Clips[i].Id;
				SerializeValue(ar, ref id);
			}
		}
		ar.EndArray();

		SerializeValue(ar, "poseCount", ref PoseCount);
		SerializeValue(ar, "speed", ref Speed);
		AnimationFeed.SerializeTargets(ar, Targets, "targets");
	}
}
