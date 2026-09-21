using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Net.Replication;
using Sedulous.Scene;

namespace Sedulous.Net.Replication.Tests;

/// A stand in networked component: a transform like mix of replicated and local only fields,
/// plus a marked but UNSUPPORTED field, so layout exclusion is exercised.
///
/// A Guid for the unsupported case: it tests the rule without giving a value component
/// something to own.
[SerializableComponent("test.Mover")]
struct Mover : ISerializable
{
	[Replicated] public Float3 Position = Float3.Zero;
	[Replicated] public Quaternion Rotation = Quaternion.Identity;
	[Replicated] public float Speed = 0.0f;
	[Replicated] public bool Grounded = false;
	[Replicated] public int32 Health = 0;

	/// Unmarked, so it stays local.
	public float LocalOnly = 0.0f;
	/// Marked, but of a type the codec cannot encode, so the harvest drops it.
	[Replicated] public Guid Tag = .();

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "position", ref Position);
		SerializeValue(ar, "rotation", ref Rotation);
		SerializeValue(ar, "speed", ref Speed);
		SerializeValue(ar, "grounded", ref Grounded);
		SerializeValue(ar, "health", ref Health);
		SerializeValue(ar, "localOnly", ref LocalOnly);
		Sedulous.Core.Serialization.Serialize(ar, ref Tag);
	}
}
