namespace Sedulous.Physics;

using System;
using Sedulous.Core.Mathematics;

/// Descriptor for creating a slider constraint.
/// A slider constraint allows translation along a single axis.
struct SliderConstraintDescriptor
{
	/// First body handle.
	public BodyHandle Body1 = .Invalid;

	/// Second body handle.
	public BodyHandle Body2 = .Invalid;

	/// Slider point on body 1.
	public Vector3 Point1 = .Zero;

	/// Slider point on body 2.
	public Vector3 Point2 = .Zero;

	/// Slider axis on body 1.
	public Vector3 SliderAxis1 = .(1, 0, 0);

	/// Slider axis on body 2.
	public Vector3 SliderAxis2 = .(1, 0, 0);

	/// Normal axis on body 1 (perpendicular to slider axis).
	public Vector3 NormalAxis1 = .(0, 1, 0);

	/// Normal axis on body 2 (perpendicular to slider axis).
	public Vector3 NormalAxis2 = .(0, 1, 0);

	/// Whether points/axes are in world space (true) or local to body center of mass (false).
	public bool UseWorldSpace = false;

	/// Whether to enable position limits.
	public bool HasLimits = false;

	/// Minimum slider position (when limits enabled).
	public float LimitsMin = -1.0f;

	/// Maximum slider position (when limits enabled).
	public float LimitsMax = 1.0f;

	/// Spring frequency for limits (0 = no spring).
	public float LimitsSpringFrequency = 0.0f;

	/// Spring damping for limits.
	public float LimitsSpringDamping = 0.0f;

	/// Maximum friction force.
	public float MaxFrictionForce = 0.0f;

	/// Motor target velocity.
	public float MotorTargetVelocity = 0.0f;

	/// Motor target position (for position motor).
	public float MotorTargetPosition = 0.0f;

	/// Creates a slider constraint descriptor.
	public this() { }

	/// Creates a slider constraint at a world point with a world axis.
	public this(BodyHandle body1, BodyHandle body2, Vector3 worldPoint, Vector3 worldSliderAxis)
	{
		Body1 = body1;
		Body2 = body2;
		Point1 = worldPoint;
		Point2 = worldPoint;
		SliderAxis1 = worldSliderAxis;
		SliderAxis2 = worldSliderAxis;

		// Calculate a perpendicular normal axis
		if (Math.Abs(worldSliderAxis.Y) < 0.9f)
			NormalAxis1 = Vector3.Normalize(Vector3.Cross(worldSliderAxis, .(0, 1, 0)));
		else
			NormalAxis1 = Vector3.Normalize(Vector3.Cross(worldSliderAxis, .(1, 0, 0)));
		NormalAxis2 = NormalAxis1;

		UseWorldSpace = true;
	}
}
