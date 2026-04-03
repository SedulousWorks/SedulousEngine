namespace Sedulous.Physics;

using Sedulous.Core.Mathematics;

/// Result of a ray cast hit.
struct RayCastResult
{
	/// The body that was hit.
	public BodyHandle Body;

	/// Hit point in world space.
	public Vector3 Position;

	/// Surface normal at hit point.
	public Vector3 Normal;

	/// Distance from ray origin to hit point.
	public float Distance;

	/// Fraction along the ray (0-1 based on MaxDistance).
	public float Fraction;

	/// User data from the hit body.
	public uint64 UserData;

	/// Returns true if this result represents a valid hit.
	public bool HasHit => Body.IsValid;
}
