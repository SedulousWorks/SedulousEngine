using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;

using Sedulous.Core;

namespace Sedulous.Engine.Animation;

/// State machine driven skeletal animation: a graph player over a shared skeleton and graph
/// evaluates transitions, blend trees and layer blending each frame, and produces the per bone
/// skinning matrices.
///
/// The richer counterpart to [SkeletalAnimationComponent], which plays one clip. Transitions
/// are driven through the player's parameters. The feed contract is the same: the named
/// entities receive the matrices, and an empty list feeds the owner.
[SerializableComponent("animation_graph", 2, 1)]
[DisplayName("Animation Graph")]
[Category("Animation")]
[Scriptable]
struct AnimationGraphComponent : ISerializable, IComponentResources
{
	[Scriptable]
	public Ref<Skeleton> Skeleton = .(Guid());
	[Scriptable]
	public Ref<AnimationGraph> Graph = .(Guid());

	/// Created lazily by the manager.
	public AnimationGraphPlayer Player = null;
	/// What the player was built for, BORROWED and compared by reference.
	public Skeleton PlayerSkeleton = null;
	public AnimationGraph PlayerGraph = null;

	/// The feed targets, by stable id. Empty means the owner.
	[Scriptable]
	[DisplayName("Mesh Entities")]
	public List<EntityRef> MeshEntities = null;

	/// Whether to evaluate at all this frame.
	[Scriptable]
	public bool Active = true;

	/// What the animator does with its clips' root motion (root-motion.md P2): Ignore by default.
	[Scriptable, DisplayName("Root Motion")]
	public RootMotionMode RootMotion = .Ignore;
	/// What Entity mode moves: a gameplay root holding the model; empty is this entity.
	[Scriptable, DisplayName("Root Motion Target")]
	public EntityRef RootMotionTarget = .();
	/// The last tick's root motion, runtime only.
	[Hidden]
	public RootMotionRuntime RootMotionState = .();

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
		// Data version 2: root motion; a version 1 record reads as Ignore.
		if ((ar.Mode == .Write) || (ar.Version >= 2))
		{
			var mode = (uint8)RootMotion;
			SerializeValue(ar, "rootMotion", ref mode);
			RootMotion = (RootMotionMode)mode;
			SerializeValue(ar, "rootMotionTarget", ref RootMotionTarget.Id);
		}
	}
}
