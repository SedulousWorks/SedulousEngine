using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Engine.Render;

/// An entity drawn as one instance of another entity's instanced mesh, at its own world
/// transform and on its clip (an index into the pose pool's clips: an instanced skinning's
/// list), instead of a mesh of its own. Whatever moves the entity moves the instance:
/// navigation, physics, replication, a script, the editor's gizmo. Many entities, one draw:
/// pickups, props, units, the guests of a crowd. Extraction adds the members after the
/// instanced mesh's own authored instances each frame; nothing of theirs is saved into it.
[SerializableComponent("instance_member")]
[DisplayName("Instance Member")]
[Category("Rendering")]
[Scriptable]
[Description("Draws this entity as one instance of another entity's instanced mesh, wherever it moves, on one of that mesh's animation clips.")]
struct InstanceMemberComponent : ISerializable
{
	/// The entity whose instanced mesh draws this one.
	[Scriptable, Description("The entity whose instanced mesh draws this one")]
	public EntityRef InstancedMesh = .();
	/// Its clip: the index in the instanced skinning's clip list.
	[Scriptable, Description("Its clip: the index in the instanced skinning's clip list")]
	public uint32 Clip = 0;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "instancedMesh", ref InstancedMesh.Id);
		SerializeValue(ar, "clip", ref Clip);
	}
}

/// The pool of instance members.
class InstanceMemberComponentManager : SerializableComponentManager<InstanceMemberComponent>
{
}
