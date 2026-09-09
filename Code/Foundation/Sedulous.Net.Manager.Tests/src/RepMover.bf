using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Net.Replication;
using Sedulous.Scene;

namespace Sedulous.Net.Manager.Tests;

/// A minimal replicated component, so a manager driven exchange has state to carry.
[SerializableComponent("test.RepMover")]
struct RepMover : ISerializable
{
	[Replicated] public Float3 Position = Float3.Zero;
	[Replicated] public int32 Health = 0;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "position", ref Position);
		SerializeValue(ar, "health", ref Health);
	}
}
