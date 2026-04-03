namespace Sedulous.Physics;

using Sedulous.Core.Mathematics;

/// Descriptor for creating a physics body.
struct PhysicsBodyDescriptor
{
	/// The collision shape for this body.
	public ShapeHandle Shape = .Invalid;

	/// Initial position in world space.
	public Vector3 Position = .Zero;

	/// Initial rotation.
	public Quaternion Rotation = .Identity;

	/// Body motion type (Static, Kinematic, Dynamic).
	public BodyType BodyType = .Dynamic;

	/// Collision layer (0-65535).
	public uint16 Layer = 1;

	/// Friction coefficient (0-1).
	public float Friction = 0.5f;

	/// Restitution/bounciness (0-1).
	public float Restitution = 0.0f;

	/// Linear damping for velocity decay.
	public float LinearDamping = 0.05f;

	/// Angular damping for rotation decay.
	public float AngularDamping = 0.05f;

	/// Gravity factor (1.0 = normal gravity, 0 = no gravity).
	public float GravityFactor = 1.0f;

	/// Motion quality (Discrete or LinearCast).
	public MotionQuality MotionQuality = .Discrete;

	/// Allowed degrees of freedom.
	public AllowedDOFs AllowedDOFs = .All;

	/// Mass override in kg. If > 0, overrides the mass calculated from shape volume.
	/// Inertia is still calculated from the shape.
	public float Mass = 0.0f;

	/// Whether this body is a sensor (trigger) that detects but doesn't collide.
	public bool IsSensor = false;

	/// Whether the body can sleep when inactive.
	public bool AllowSleep = true;

	/// Initial linear velocity.
	public Vector3 LinearVelocity = .Zero;

	/// Initial angular velocity.
	public Vector3 AngularVelocity = .Zero;

	/// User data for application use.
	public uint64 UserData = 0;

	/// Creates a static body descriptor.
	public static Self Static(ShapeHandle shape, Vector3 position) =>
		Self() { Shape = shape, Position = position, BodyType = .Static, Layer = 0 };

	/// Creates a dynamic body descriptor.
	public static Self Dynamic(ShapeHandle shape, Vector3 position) =>
		Self() { Shape = shape, Position = position, BodyType = .Dynamic, Layer = 1 };

	/// Creates a kinematic body descriptor.
	public static Self Kinematic(ShapeHandle shape, Vector3 position) =>
		Self() { Shape = shape, Position = position, BodyType = .Kinematic, Layer = 1 };
}
