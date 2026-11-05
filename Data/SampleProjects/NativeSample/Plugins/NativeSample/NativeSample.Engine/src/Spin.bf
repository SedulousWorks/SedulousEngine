using System;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace NativeSample;

/// How fast an entity spins, in turns a second: the reference game's own component, saved with
/// the scene.
[SerializableComponent("nativesample.Spin")]
struct SpinComponent : ISerializable
{
	public float TurnsPerSecond = 0.25f;

	public this() {}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "turnsPerSecond", ref TurnsPerSecond);
	}
}

/// The spin components of a scene, which the Engine part adds to every scene.
class SpinManager : SerializableComponentManager<SpinComponent>
{
}
