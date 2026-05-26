namespace Sedulous.Engine.Animation;

using System;
using Sedulous.Engine.Core;
using Sedulous.Resources;
using Sedulous.Animation;
using Sedulous.Core.Mathematics;
using Sedulous.Inspection;

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
	[Property(.Default, "Skeleton Ref", "SkeletonRef")]
	[ResourceRefType(".skeleton")]
	private ResourceRef mSkeletonRef ~ _.Dispose();

	/// Animation graph resource reference.
	[Property(.Default, "Graph Ref", "GraphRef")]
	[ResourceRefType(".animgraph")]
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

	/// Set when SkeletonRef or GraphRef changes, or on first resolve.
	/// Drains the manager's resolve queue. Cleared after resolving.
	public bool ResolveDirty;

	/// Fires after SetSkeletonRef changes the skeleton resource ref.
	public Event<delegate void(AnimationGraphComponent)> SkeletonChanged ~ _.Dispose();

	/// Fires after SetGraphRef changes the graph resource ref.
	public Event<delegate void(AnimationGraphComponent)> GraphChanged ~ _.Dispose();

	// --- Resource ref accessors ---

	public ResourceRef SkeletonRef => mSkeletonRef;

	/// Sets the skeleton resource ref (deep copy). Fires SkeletonChanged
	/// so the manager can enqueue a re-resolve.
	public void SetSkeletonRef(ResourceRef @ref)
	{
		mSkeletonRef.Dispose();
		mSkeletonRef = ResourceRef(@ref.Id, @ref.Path ?? "");
		SkeletonChanged(this);
	}

	public ResourceRef GraphRef => mGraphRef;

	/// Sets the graph resource ref (deep copy). Fires GraphChanged so
	/// the manager can enqueue a re-resolve.
	public void SetGraphRef(ResourceRef @ref)
	{
		mGraphRef.Dispose();
		mGraphRef = ResourceRef(@ref.Id, @ref.Path ?? "");
		GraphChanged(this);
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
