using Sedulous.Core;

namespace Sedulous.Physics;

/// What one character controller asks for.
///
/// It is NOT a rigid body: a kinematic capsule swept with slope and step handling, which
/// pushes dynamic bodies up to its strength. The CALLER owns the velocity policy, folding
/// gravity and jumping into the velocity it sets each step.
struct CharacterDesc
{
	public float CapsuleRadius = 0.35f;
	/// The cylinder's half length, so the total height is twice this plus twice the radius.
	public float CapsuleHalfHeight = 0.55f;

	public float MaxSlopeDegrees = 50.0f;
	/// In kilograms, which is what the impulses given to a pushed body are scaled by.
	public float Mass = 70.0f;
	/// The most it can push with, in newtons.
	public float MaxStrength = 100.0f;

	/// How high a stair it climbs in one step.
	public float StepUp = 0.4f;
	/// How far below it scans to stay stuck to the floor.
	public float StepDown = 0.5f;

	public Float3 Position = .(0, 0, 0);
	public uint64 UserData = 0;

	public this() {}
}
