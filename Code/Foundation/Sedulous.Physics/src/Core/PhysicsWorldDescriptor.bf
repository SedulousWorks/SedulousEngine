namespace Sedulous.Physics;

using Sedulous.Core.Mathematics;

/// Descriptor for creating a physics world.
struct PhysicsWorldDescriptor
{
	/// Maximum number of bodies the world can contain.
	public uint32 MaxBodies = 65536;

	/// Maximum number of body pairs for broad phase.
	public uint32 MaxBodyPairs = 65536;

	/// Maximum number of contact constraints.
	public uint32 MaxContactConstraints = 10240;

	/// Gravity vector.
	public Vector3 Gravity = .(0.0f, -9.81f, 0.0f);

	/// Number of velocity solver iterations.
	public uint32 VelocitySteps = 10;

	/// Number of position solver iterations.
	public uint32 PositionSteps = 2;

	/// Creates a default world descriptor.
	public static Self Default => Self();

	/// Creates a world descriptor for a small scene.
	public static Self Small => Self()
	{
		MaxBodies = 1024,
		MaxBodyPairs = 1024,
		MaxContactConstraints = 1024
	};

	/// Creates a world descriptor for a large scene.
	public static Self Large => Self()
	{
		MaxBodies = 262144,
		MaxBodyPairs = 262144,
		MaxContactConstraints = 65536
	};
}
