namespace Sedulous.Physics;

using Sedulous.Core.Mathematics;

/// Descriptor for creating a fixed constraint.
/// A fixed constraint locks two bodies together with no relative movement.
struct FixedConstraintDescriptor
{
	/// First body handle.
	public BodyHandle Body1 = .Invalid;

	/// Second body handle.
	public BodyHandle Body2 = .Invalid;

	/// Attachment point on body 1 (local space).
	public Vector3 Point1 = .Zero;

	/// Attachment point on body 2 (local space).
	public Vector3 Point2 = .Zero;

	/// Axis direction for body 1 (local space).
	public Vector3 AxisX1 = .(1, 0, 0);

	/// Axis direction for body 1 (local space).
	public Vector3 AxisY1 = .(0, 1, 0);

	/// Axis direction for body 2 (local space).
	public Vector3 AxisX2 = .(1, 0, 0);

	/// Axis direction for body 2 (local space).
	public Vector3 AxisY2 = .(0, 1, 0);

	/// Whether points/axes are in world space (true) or local to body center of mass (false).
	public bool UseWorldSpace = false;

	/// Creates a fixed constraint descriptor.
	public this() { }

	/// Creates a fixed constraint descriptor between two bodies at a world space point.
	public this(BodyHandle body1, BodyHandle body2, Vector3 worldPoint)
	{
		Body1 = body1;
		Body2 = body2;
		Point1 = worldPoint;
		Point2 = worldPoint;
		UseWorldSpace = true;
	}
}
