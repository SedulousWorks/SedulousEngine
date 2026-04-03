namespace Sedulous.Physics;

using Sedulous.Core.Mathematics;

/// Input for a ray cast query.
struct RayCastQuery
{
	/// Ray origin in world space.
	public Vector3 Origin;

	/// Ray direction (should be normalized).
	public Vector3 Direction;

	/// Maximum distance to cast.
	public float MaxDistance = 1000.0f;

	/// Collision layer mask. Only bodies in matching layers are tested.
	public uint32 LayerMask = 0xFFFFFFFF;

	/// Creates a ray cast query.
	public this(Vector3 origin, Vector3 direction, float maxDistance = 1000.0f)
	{
		Origin = origin;
		Direction = direction;
		MaxDistance = maxDistance;
		LayerMask = 0xFFFFFFFF;
	}
}
