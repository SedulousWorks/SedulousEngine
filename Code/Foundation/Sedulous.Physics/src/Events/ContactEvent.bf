namespace Sedulous.Physics;

using Sedulous.Core.Mathematics;

/// Data about a contact between two bodies.
struct ContactEvent
{
	/// Contact point in world space.
	public Vector3 Position;

	/// Contact normal (points from body1 to body2).
	public Vector3 Normal;

	/// Penetration depth (positive when overlapping).
	public float PenetrationDepth;

	/// Relative velocity at contact point.
	public Vector3 RelativeVelocity;

	/// Combined friction of the two surfaces.
	public float CombinedFriction;

	/// Combined restitution of the two surfaces.
	public float CombinedRestitution;
}
