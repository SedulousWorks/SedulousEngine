namespace Sedulous.Physics;

/// Type of physics body motion.
enum BodyType : uint8
{
	/// Static bodies never move and have infinite mass.
	/// Used for terrain, walls, and other immovable geometry.
	Static = 0,

	/// Kinematic bodies are moved by code but affect dynamic bodies.
	/// Used for moving platforms, animated characters, etc.
	Kinematic = 1,

	/// Dynamic bodies are fully simulated by the physics engine.
	/// Used for objects that respond to forces and collisions.
	Dynamic = 2
}
