using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource.Tests;

/// A serializable value component, naming itself on disk.
[SerializableComponent("test.Health")]
struct Health : ISerializable
{
	public float Value = 100.0f;
	public int32 Armour = 0;
	/// A reference to ANOTHER entity, which is what prefab spawning has to remap.
	public EntityRef Target = .();

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "value", ref Value);
		SerializeValue(ar, "armour", ref Armour);
		Sedulous.Scene.Serialize(ar, ref Target);
	}
}
