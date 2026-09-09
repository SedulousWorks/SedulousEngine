using Sedulous.Core;

namespace Sedulous.Physics;

/// What one joint asks for.
struct JointDesc
{
	public JointKind Kind = .Fixed;

	/// Required.
	public BodyId BodyA = .();
	/// Invalid anchors the joint to the WORLD.
	public BodyId BodyB = .();

	/// The world space pivot, which is the hinge, point and slider origin.
	public Float3 Anchor = .(0, 0, 0);
	/// The world space hinge rotation or slider travel axis.
	public Float3 Axis = .(0, 1, 0);

	/// A hinge's limits in radians, the minimum within minus pi to nought and the maximum
	/// within nought to pi; a slider's in metres around the rest point. A minimum ABOVE the
	/// maximum is unlimited.
	public float LimitMin = 1.0f;
	public float LimitMax = -1.0f;

	/// A distance joint's range. Below nought keeps the distance it started at.
	public float MinDistance = -1.0f;
	public float MaxDistance = -1.0f;

	/// The velocity motor: radians per second and a torque limit for a hinge, metres per
	/// second and a force limit for a slider.
	public bool MotorEnabled = false;
	public float MotorTargetVelocity = 0.0f;
	public float MotorLimit = 3.4e38f;

	public this() {}
}
