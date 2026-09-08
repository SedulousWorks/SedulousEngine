using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource.Integration.Tests;

/// A serializable value component, so a stored scene carries something besides names.
[SerializableComponent("demo.Tag")]
struct Tag : ISerializable
{
	public int32 Team = 0;

	public this() {}

	public void Serialize(ISerializer ar) mut => SerializeValue(ar, "team", ref Team);
}
