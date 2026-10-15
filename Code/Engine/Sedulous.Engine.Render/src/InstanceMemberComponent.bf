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
///
/// Data version 2 adds the tint (a version 1 member reads untinted).
[SerializableComponent("instance_member", 2)]
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
	/// Its own tint (sRGB, as entered), times the set's colour when the set authors no tints:
	/// the instance's colour, which a custom shader reads as its input colour (a glow, a mark),
	/// so one guest can look different from the rest.
	[Scriptable, Description("Its own tint, times the set's colour: the colour a custom shader reads")]
	public Color Tint = .(1.0f, 1.0f, 1.0f, 1.0f);

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "instancedMesh", ref InstancedMesh.Id);
		SerializeValue(ar, "clip", ref Clip);
		// A version 1 member is untinted.
		if ((ar.Mode == .Write) || (ar.Version >= 2))
		{
			ar.Key("tint");
			Sedulous.Core.Serialization.Serialize(ar, ref Tint);
		}
	}
}

/// The pool of instance members.
class InstanceMemberComponentManager : SerializableComponentManager<InstanceMemberComponent>
{
}
