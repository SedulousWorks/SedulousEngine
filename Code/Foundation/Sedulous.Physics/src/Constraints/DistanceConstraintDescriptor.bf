namespace Sedulous.Physics;

using Sedulous.Core.Mathematics;

/// Descriptor for creating a distance constraint.
/// A distance constraint maintains a fixed distance between two points.
struct DistanceConstraintDescriptor
{
	/// First body handle.
	public BodyHandle Body1 = .Invalid;

	/// Second body handle.
	public BodyHandle Body2 = .Invalid;

	/// Attachment point on body 1.
	public Vector3 Point1 = .Zero;

	/// Attachment point on body 2.
	public Vector3 Point2 = .Zero;

	/// Whether points are in world space (true) or local to body center of mass (false).
	public bool UseWorldSpace = false;

	/// Minimum distance (can be used to create a rope-like constraint when < MaxDistance).
	public float MinDistance = -1.0f;

	/// Maximum distance (negative = compute from initial positions).
	public float MaxDistance = -1.0f;

	/// Spring frequency (0 = rigid constraint).
	public float SpringFrequency = 0.0f;

	/// Spring damping.
	public float SpringDamping = 0.0f;

	/// Creates a distance constraint descriptor.
	public this() { }

	/// Creates a distance constraint between two world points.
	public this(BodyHandle body1, BodyHandle body2, Vector3 worldPoint1, Vector3 worldPoint2)
	{
		Body1 = body1;
		Body2 = body2;
		Point1 = worldPoint1;
		Point2 = worldPoint2;
		UseWorldSpace = true;
	}

	/// Creates a distance constraint at a fixed distance.
	public this(BodyHandle body1, BodyHandle body2, Vector3 worldPoint1, Vector3 worldPoint2, float distance)
	{
		Body1 = body1;
		Body2 = body2;
		Point1 = worldPoint1;
		Point2 = worldPoint2;
		MinDistance = distance;
		MaxDistance = distance;
		UseWorldSpace = true;
	}
}
