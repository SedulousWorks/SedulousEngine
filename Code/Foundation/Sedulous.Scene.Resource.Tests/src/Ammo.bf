using Sedulous.Core.Serialization;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource.Tests;

/// A component holding a resource reference, so the post load bind has something to bind.
[SerializableComponent("test.Ammo")]
struct Ammo : ISerializable, IComponentResources
{
	public int32 Rounds = 0;
	/// Counts the binds, which is how a test sees the pass reach this component at all.
	public int32 Binds = 0;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "rounds", ref Rounds);
	}

	public void ResolveResources(ResourceManager manager) mut
	{
		Binds++;
	}
}
