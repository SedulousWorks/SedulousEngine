using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// A world space half space. A point with Dot(Normal, p) below Distance is BEHIND the plane,
/// which is what counts as penetrating it.
[Scriptable]
struct CollisionPlane
{
	[Scriptable]
	public Float3 Normal = .(0, 1, 0);
	[Scriptable]
	public float Distance = 0.0f;

	public this() {}

	public this(Float3 normal, float distance)
	{
		Normal = normal;
		Distance = distance;
	}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "normal", ref Normal);
		SerializeValue(ar, "distance", ref Distance);
	}
}
