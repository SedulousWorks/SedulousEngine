using System;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Editor.Scene.Tests;

/// A serializable component, so a destroy or remove undo restores it from its bytes.
[SerializableComponent("test.health")]
struct Health : ISerializable
{
	public int32 Amount = 0;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "amount", ref Amount);
	}
}
