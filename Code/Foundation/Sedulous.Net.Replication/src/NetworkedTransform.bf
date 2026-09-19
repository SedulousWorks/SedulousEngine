using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Net.Replication;

/// A replicated transform: an entity's LOCAL transform, mirrored over the network. Add it
/// alongside a NetworkComponent to replicate movement.
///
/// Unlike NetworkComponent's identity fields, these ARE replicated, so the field codec and
/// interpolation handle them. It is the engine's bridge between the reflected component
/// replication pipe and the transform the entity system stores, which is not reflected: the
/// server copies the entity transform INTO this component before sending, and the client
/// applies this component, interpolated, BACK onto the entity transform after receiving.
[SerializableComponent("net.Transform")]
[Scriptable]
struct NetworkedTransform : ISerializable
{
	[Scriptable]
	[Replicated] public Float3 Position = Float3.Zero;
	[Scriptable]
	[Replicated] public Quaternion Rotation = Quaternion.Identity;
	[Scriptable]
	[Replicated] public Float3 Scale = Float3.One;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "position", ref Position);
		SerializeValue(ar, "rotation", ref Rotation);
		SerializeValue(ar, "scale", ref Scale);
	}
}
