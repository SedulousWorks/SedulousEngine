namespace Sedulous.Engine.Animation;

using System;
using Sedulous.Engine.Core;
using Sedulous.Resources;
using Sedulous.Animation;
using Sedulous.Core.Mathematics;

/// Component for state-machine-driven skeletal animation.
/// References a Skeleton and AnimationGraph via ResourceRefs. The manager
/// resolves resources, creates the AnimationGraphPlayer, and evaluates
/// bone matrices each frame. When present on the same entity as a
/// SkeletalAnimationComponent, the graph output overrides the simple clip.
///
/// For simple single-clip playback, use SkeletalAnimationComponent instead.
class AnimationGraphComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		s.ResourceRef("SkeletonRef", ref mSkeletonRef);
		s.ResourceRef("GraphRef", ref mGraphRef);
		s.Bool("Active", ref Active);
	}

	// --- Resource refs (serializable) ---

	/// Skeleton resource reference.
	private ResourceRef mSkeletonRef ~ _.Dispose();

	/// Animation graph resource reference.
	private ResourceRef mGraphRef ~ _.Dispose();

	// --- Configuration ---

	/// Whether the graph is actively evaluating.
	public bool Active = true;

	// --- Runtime state (managed by AnimationGraphComponentManager) ---

	/// Resolved skeleton (not owned - owned by resource system).
	public Skeleton Skeleton;

	/// Resolved animation graph (not owned - owned by resource system).
	public AnimationGraph Graph;

	/// Animation graph player (owned by this component, created by manager).
	public AnimationGraphPlayer GraphPlayer ~ delete _;

	/// Whether resources have been resolved and the player created.
	public bool IsReady => GraphPlayer != null;

	// --- Resource ref accessors ---

	public ResourceRef SkeletonRef => mSkeletonRef;

	public void SetSkeletonRef(ResourceRef @ref)
	{
		mSkeletonRef.Dispose();
		mSkeletonRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	public ResourceRef GraphRef => mGraphRef;

	public void SetGraphRef(ResourceRef @ref)
	{
		mGraphRef.Dispose();
		mGraphRef = ResourceRef(@ref.Id, @ref.Path ?? "");
	}

	/// Gets the current skinning matrices from the graph player.
	public Span<Matrix> GetSkinningMatrices()
	{
		if (GraphPlayer != null)
			return GraphPlayer.GetSkinningMatrices();
		return default;
	}

	/// Gets the previous frame's skinning matrices.
	public Span<Matrix> GetPrevSkinningMatrices()
	{
		if (GraphPlayer != null)
			return GraphPlayer.GetPrevSkinningMatrices();
		return default;
	}
}
