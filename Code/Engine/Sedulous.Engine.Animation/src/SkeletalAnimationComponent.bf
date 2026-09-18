using System;
using System.Collections;
using Sedulous.Animation;
using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;

using Sedulous.Core;

namespace Sedulous.Engine.Animation;

/// Skeletal animation on an entity: a player over a shared skeleton plays a clip and produces
/// the per bone skinning matrices every frame.
///
/// The resource references serialize as ids and resolve through the manager's proxies, which
/// is the editor picker and the scene round trip; runtime code sets the object directly
/// instead. The manager rebuilds the player when the skeleton object changes, so a pick or a
/// hot reload is picked up rather than played against a dead skeleton.
///
/// The feed targets are named by STABLE ids rather than handles, so they serialize and a
/// prefab spawn remaps them: ONE animator can drive every skinned mesh node of a multi part
/// character. An empty list feeds the component's own entity.
///
/// The player and the lists are OWNED BY THE MANAGER, because a component is a struct in a
/// packed pool and cannot own heap data.
[SerializableComponent("skeletal_animation")]
[DisplayName("Skeletal Animation")]
[Category("Animation")]
[Scriptable]
struct SkeletalAnimationComponent : ISerializable, IComponentResources
{
	[Scriptable]
	public Ref<Skeleton> Skeleton = .(Guid());
	[Scriptable]
	public Ref<AnimationClip> Clip = .(Guid());

	/// Created lazily by the manager, on the first tick that has a skeleton.
	public AnimationPlayer Player = null;
	/// The skeleton the player was built for, BORROWED, and compared by reference.
	public Skeleton PlayerSkeleton = null;
	/// The clip last handed to the player, BORROWED.
	public AnimationClip PlayerClip = null;

	/// The entities whose mesh receives the matrices. Empty means the owner.
	[Scriptable]
	public List<EntityRef> MeshEntities = null;

	[Scriptable]
	public float Speed = 1.0f;
	/// The initial clock, which is what desynchronises a herd. Applied on the first tick.
	[Scriptable]
	public float StartTime = 0.0f;
	/// Play the bound clip on the first tick.
	[Scriptable]
	public bool AutoPlay = true;

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		Skeleton.Bind(manager);
		Clip.Bind(manager);
	}

	/// The references and the tunables persist. The player and the per frame feed state are
	/// runtime only.
	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "skeleton", ref Skeleton.Id);
		SerializeValue(ar, "clip", ref Clip.Id);
		SerializeValue(ar, "speed", ref Speed);
		SerializeValue(ar, "startTime", ref StartTime);
		SerializeValue(ar, "autoPlay", ref AutoPlay);
		AnimationFeed.SerializeTargets(ar, MeshEntities);
	}
}
