using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Animation;

/// State machine driven skeletal animation: a graph player over a shared skeleton and graph
/// evaluates transitions, blend trees and layer blending each frame, and produces the per bone
/// skinning matrices.
///
/// The richer counterpart to [SkeletalAnimationComponent], which plays one clip. Transitions
/// are driven through the player's parameters. The feed contract is the same: the named
/// entities receive the matrices, and an empty list feeds the owner.
[SerializableComponent("animation_graph")]
struct AnimationGraphComponent : ISerializable, IComponentResources
{
	public Ref<Skeleton> Skeleton = .(Guid());
	public Ref<AnimationGraph> Graph = .(Guid());

	/// Created lazily by the manager.
	public AnimationGraphPlayer Player = null;
	/// What the player was built for, BORROWED and compared by reference.
	public Skeleton PlayerSkeleton = null;
	public AnimationGraph PlayerGraph = null;

	/// The feed targets, by stable id. Empty means the owner.
	public List<EntityRef> MeshEntities = null;

	/// Whether to evaluate at all this frame.
	public bool Active = true;

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		Skeleton.Bind(manager);
		Graph.Bind(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "skeleton", ref Skeleton.Id);
		SerializeValue(ar, "graph", ref Graph.Id);
		SerializeValue(ar, "active", ref Active);
		AnimationFeed.SerializeTargets(ar, MeshEntities);
	}
}
