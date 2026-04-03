namespace Sedulous.Physics;

using System;
using Sedulous.Core.Mathematics;

/// Descriptor for creating a hinge constraint.
/// A hinge constraint allows rotation around a single axis.
struct HingeConstraintDescriptor
{
	/// First body handle.
	public BodyHandle Body1 = .Invalid;

	/// Second body handle.
	public BodyHandle Body2 = .Invalid;

	/// Hinge point on body 1.
	public Vector3 Point1 = .Zero;

	/// Hinge point on body 2.
	public Vector3 Point2 = .Zero;

	/// Hinge axis on body 1.
	public Vector3 HingeAxis1 = .(0, 1, 0);

	/// Hinge axis on body 2.
	public Vector3 HingeAxis2 = .(0, 1, 0);

	/// Normal axis on body 1 (perpendicular to hinge axis).
	public Vector3 NormalAxis1 = .(1, 0, 0);

	/// Normal axis on body 2 (perpendicular to hinge axis).
	public Vector3 NormalAxis2 = .(1, 0, 0);

	/// Whether points/axes are in world space (true) or local to body center of mass (false).
	public bool UseWorldSpace = false;

	/// Whether to enable angle limits.
	public bool HasLimits = false;

	/// Minimum angle in radians (when limits enabled).
	public float LimitsMin = -Math.PI_f;

	/// Maximum angle in radians (when limits enabled).
	public float LimitsMax = Math.PI_f;

	/// Spring frequency for limits (0 = no spring).
	public float LimitsSpringFrequency = 0.0f;

	/// Spring damping for limits.
	public float LimitsSpringDamping = 0.0f;

	/// Motor target angular velocity.
	public float MotorTargetAngularVelocity = 0.0f;

	/// Motor target angle (for position motor).
	public float MotorTargetAngle = 0.0f;

	/// Creates a hinge constraint descriptor.
	public this() { }

	/// Creates a hinge constraint at a world point with a world axis.
	public this(BodyHandle body1, BodyHandle body2, Vector3 worldPoint, Vector3 worldAxis)
	{
		Body1 = body1;
		Body2 = body2;
		Point1 = worldPoint;
		Point2 = worldPoint;
		HingeAxis1 = worldAxis;
		HingeAxis2 = worldAxis;

		// Calculate a perpendicular normal axis
		if (Math.Abs(worldAxis.Y) < 0.9f)
			NormalAxis1 = Vector3.Normalize(Vector3.Cross(worldAxis, .(0, 1, 0)));
		else
			NormalAxis1 = Vector3.Normalize(Vector3.Cross(worldAxis, .(1, 0, 0)));
		NormalAxis2 = NormalAxis1;

		UseWorldSpace = true;
	}
}
