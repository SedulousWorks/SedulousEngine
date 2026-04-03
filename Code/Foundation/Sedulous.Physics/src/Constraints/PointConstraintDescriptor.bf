namespace Sedulous.Physics;

using Sedulous.Core.Mathematics;

/// Descriptor for creating a point constraint (ball-and-socket joint).
/// A point constraint connects two bodies at a single point, allowing rotation but not translation.
struct PointConstraintDescriptor
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

	/// Creates a point constraint descriptor.
	public this() { }

	/// Creates a point constraint at a world point.
	public this(BodyHandle body1, BodyHandle body2, Vector3 worldPoint)
	{
		Body1 = body1;
		Body2 = body2;
		Point1 = worldPoint;
		Point2 = worldPoint;
		UseWorldSpace = true;
	}
}
