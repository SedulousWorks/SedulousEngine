using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// A world space axis aligned box particles bounce off.
[Scriptable]
struct CollisionBox
{
	[Scriptable]
	public Float3 Center = .(0, 0, 0);
	[Scriptable]
	public Float3 HalfExtents = .(0.5f, 0.5f, 0.5f);

	public this() {}

	public this(Float3 center, Float3 halfExtents)
	{
		Center = center;
		HalfExtents = halfExtents;
	}

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "center", ref Center);
		SerializeValue(ar, "halfExtents", ref HalfExtents);
	}
}
