using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// How a trail system records and draws its ribbons.
struct TrailSettings
{
	public bool Enabled = false;
	/// The ring buffer's length per particle.
	public int32 MaxPoints = 16;
	/// The least time between recorded points.
	public float RecordInterval = 0.033f;
	/// How long a point takes to fade out.
	public float Lifetime = 1.0f;
	/// The ribbon's half width at the newest point and at the oldest.
	public float WidthStart = 0.15f;
	public float WidthEnd = 0.0f;
	/// A point is also recorded once the particle has moved this far, so a fast particle
	/// leaves a smooth ribbon rather than a dotted one.
	public float MinVertexDistance = 0.05f;
	/// Whether the ribbon takes the particle's colour rather than its own.
	public bool UseParticleColor = true;
	public Float4 TrailColor = .(1, 1, 1, 1);

	public this() {}

	/// Two points is the fewest a ribbon can be drawn from.
	public bool IsActive => Enabled && (MaxPoints >= 2);

	public static TrailSettings Default() => .();

	public void Serialize(ISerializer ar) mut
	{
		SerializeValue(ar, "enabled", ref Enabled);
		SerializeValue(ar, "maxPoints", ref MaxPoints);
		SerializeValue(ar, "recordInterval", ref RecordInterval);
		SerializeValue(ar, "lifetime", ref Lifetime);
		SerializeValue(ar, "widthStart", ref WidthStart);
		SerializeValue(ar, "widthEnd", ref WidthEnd);
		SerializeValue(ar, "minVertexDistance", ref MinVertexDistance);
		SerializeValue(ar, "useParticleColor", ref UseParticleColor);
		SerializeValue(ar, "trailColor", ref TrailColor);
	}
}
