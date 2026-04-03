namespace Sedulous.Physics;

using Sedulous.Core.Mathematics;

/// Result of a shape cast hit.
struct ShapeCastResult
{
	/// The body that was hit.
	public BodyHandle Body;

	/// Contact point on the cast shape in world space.
	public Vector3 ContactPointOn1;

	/// Contact point on the hit body in world space.
	public Vector3 ContactPointOn2;

	/// Penetration axis (direction to push shapes apart).
	public Vector3 PenetrationAxis;

	/// Penetration depth (negative if shapes don't overlap at hit).
	public float PenetrationDepth;

	/// Fraction along the cast direction (0-1).
	public float Fraction;

	/// User data from the hit body.
	public uint64 UserData;

	/// Returns true if this result represents a valid hit.
	public bool HasHit => Body.IsValid;
}
