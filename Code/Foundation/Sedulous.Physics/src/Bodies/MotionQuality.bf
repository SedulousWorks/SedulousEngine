namespace Sedulous.Physics;

/// Motion quality determines how collision detection is performed.
enum MotionQuality : uint8
{
	/// Discrete collision detection.
	/// Fast but can miss collisions for fast-moving objects (tunneling).
	Discrete = 0,

	/// Continuous collision detection using linear cast.
	/// Prevents tunneling but is more expensive.
	/// Use for fast-moving objects like bullets or projectiles.
	LinearCast = 1
}
