using Sedulous.Core.Serialization;

namespace Sedulous.Scene.Resource.Tests;

/// A serializable value component.
struct Health : ISerializable
{
	public float Value = 100.0f;
	public int32 Armour = 0;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "value", ref Value);
		SerializeValue(ar, "armour", ref Armour);
	}
}
