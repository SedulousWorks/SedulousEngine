namespace Sedulous.Physics;

/// Type of physics constraint.
enum ConstraintType
{
	/// Fixed constraint - locks two bodies together with no relative movement.
	Fixed,

	/// Point constraint - connects two bodies at a single point (ball-and-socket joint).
	Point,

	/// Hinge constraint - allows rotation around a single axis.
	Hinge,

	/// Slider constraint - allows translation along a single axis.
	Slider,

	/// Distance constraint - maintains a fixed distance between two points.
	Distance,

	/// Cone constraint - limits rotation to a cone around an axis.
	Cone,

	/// Swing-twist constraint - limits swing and twist rotation (useful for ragdolls).
	SwingTwist,

	/// Six degrees of freedom constraint - configurable limits on all axes.
	SixDOF
}
