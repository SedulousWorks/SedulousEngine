namespace Sedulous.Physics;

/// The current ground state of a character controller.
enum GroundState
{
	/// Character is on the ground and supported.
	OnGround,

	/// Character is on a slope that is too steep to stand on.
	OnSteepGround,

	/// Character is not touching any ground.
	InAir,

	/// Character is not supported because it's touching something that doesn't count as ground.
	NotSupported
}
