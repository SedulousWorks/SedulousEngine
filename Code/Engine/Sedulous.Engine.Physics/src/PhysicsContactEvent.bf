namespace Sedulous.Engine.Physics;

using Sedulous.Engine.Core;
using Sedulous.Physics;
using Sedulous.Core.Mathematics;

/// Engine-level contact event with EntityHandles instead of BodyHandles.
/// Dispatched to gameplay code after the physics step completes.
struct PhysicsContactEvent
{
	/// The other entity involved in the contact.
	public EntityHandle OtherEntity;

	/// Contact point in world space.
	public Vector3 Position;

	/// Contact normal (points from this entity to the other).
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
