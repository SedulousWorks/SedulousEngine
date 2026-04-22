namespace Sedulous.Engine.Animation;

using System;
using Sedulous.Engine.Core;
using Sedulous.Resources;
using Sedulous.Animation;
using Sedulous.Core.Mathematics;

/// Component for simple skeletal animation playback on an entity.
/// References a Skeleton and AnimationClip via ResourceRefs. The manager
/// resolves resources, creates the AnimationPlayer, and evaluates bone
/// matrices each frame. SkinnedMeshComponentManager reads the matrices
/// from this component for GPU skinning.
///
/// For complex state-machine-driven animation, use AnimationGraphComponent instead.
class SkeletalAnimationComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.ResourceRef("SkeletonRef", ref mSkeletonRef);
		s.ResourceRef("ClipRef", ref mClipRef);
		s.Float("Speed", ref Speed);
		s.Bool("Loop", ref Loop);
		s.Bool("AutoPlay", ref AutoPlay);
	}

	// --- Resource refs (serializable) ---

	/// Skeleton resource reference.
	private ResourceRef mSkeletonRef ~ _.Dispose();

	/// Animation clip resource reference.
	private ResourceRef mClipRef ~ _.Dispose();

	// --- Configuration ---

	/// Playback speed multiplier (1.0 = normal).
	public float Speed = 1.0f;

	/// Whether the animation loops.
	public bool Loop = true;

	/// Whether to start playing automatically on initialization.
	public bool AutoPlay = true;

	/// Whether the animation is currently playing.
	public bool Playing = false;

	// --- Runtime state (managed by SkeletalAnimationComponentManager) ---

	/// Resolved skeleton (not owned - owned by resource system).
	public Skeleton Skeleton;

	/// Resolved animation clip (not owned - owned by resource system).
	public AnimationClip CurrentClip;

	/// Animation player (owned by this component, created by manager on init).
	public AnimationPlayer Player ~ delete _;

	/// Whether resources have been resolved and the player created.
	public bool IsReady => Player != null;

	// --- Resource ref accessors ---

	public ResourceRef SkeletonRef => mSkeletonRef;

	public void SetSkeletonRef(ResourceRef @ref)
	{
		mSkeletonRef.Dispose();
		mSkeletonRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	public ResourceRef ClipRef => mClipRef;

	public void SetClipRef(ResourceRef @ref)
	{
		mClipRef.Dispose();
		mClipRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	/// Gets the current skinning matrices (valid after Update).
	public Span<Matrix> GetSkinningMatrices()
	{
		if (Player != null)
			return Player.GetSkinningMatrices();
		return default;
	}

	/// Gets the previous frame's skinning matrices (for motion vectors).
	public Span<Matrix> GetPrevSkinningMatrices()
	{
		if (Player != null)
			return Player.GetPrevSkinningMatrices();
		return default;
	}
}
