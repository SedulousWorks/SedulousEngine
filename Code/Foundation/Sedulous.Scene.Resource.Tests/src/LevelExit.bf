using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource.Tests;

/// A component naming a scene: where a level's exit leads.
[SerializableComponent("test.LevelExit")]
struct LevelExit : ISerializable
{
	public SceneRef Next = .();
	public float Radius = 1.0f;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		ar.Key("next");
		Next.Serialize(ar);
		SerializeValue(ar, "radius", ref Radius);
	}
}

class LevelExitManager : SerializableComponentManager<LevelExit>
{
}
