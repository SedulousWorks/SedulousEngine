using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// Instanced skinning for CROWDS: the companion to an instanced mesh that makes its instances
/// animate at only a handful of unique phases.
///
/// Each frame the manager samples the clip at that many evenly spaced phases, advancing
/// together on one clock, into a shared POSE POOL of palettes, and hands the pool to the
/// target set, which draws instance i with pose i modulo the count. So a crowd of thirty
/// thousand costs a few dozen palette computes rather than thirty thousand.
///
/// Put it on the entity that carries the instanced mesh, or point the targets at one. The
/// skeleton and clip are BORROWED and must outlive it; the pools are the manager's.
[Component]
struct InstancedSkinningComponent
{
	/// BORROWED, and shared across the crowd.
	public Skeleton Skeleton = null;
	/// BORROWED: the clip the crowd plays.
	public AnimationClip Clip = null;

	/// The number of unique phase buckets. More is a smoother spread and more compute.
	public uint32 PoseCount = 32;
	public float Speed = 1.0f;

	/// The instanced mesh entities to feed, which is one set per skinned mesh of a multi part
	/// character. Empty means the owner.
	public List<EntityHandle> Targets = null;

	// ---- the manager's own per frame state, not authored ----

	/// Pose count by bone count skinning matrices, recomputed each frame.
	public List<Float4x4> PosePool = null;
	/// LAST frame's palettes, for the per bone motion vectors. Ping ponged rather than
	/// recomputed.
	public List<Float4x4> PrevPosePool = null;
	/// Bone count scratch, for the sampling.
	public List<BoneTransform> Scratch = null;

	/// The shared clock, wrapped to the clip's duration.
	public float Time = 0.0f;
	public uint32 BoneCount = 0;

	public this() {}
}
