using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// A world space sphere particles bounce off.
[Scriptable]
struct CollisionSphere
{
	[Scriptable]
	public Float3 Center = .(0, 0, 0);
	[Scriptable]
	public float Radius = 1.0f;

	public this() {}

	public this(Float3 center, float radius)
	{
		Center = center;
		Radius = radius;
	}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "center", ref Center);
		SerializeValue(ar, "radius", ref Radius);
	}
}
