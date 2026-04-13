namespace Sedulous.Engine.Physics;

using Sedulous.Scenes;
using Sedulous.Physics;
using Sedulous.Core.Mathematics;

/// Component for a physics rigid body attached to an entity.
///
/// Holds configuration data (body type, mass, shape, material properties)
/// and runtime state (BodyHandle, ShapeHandle). The PhysicsComponentManager
/// creates/destroys the actual physics bodies and syncs transforms.
class RigidBodyComponent : Component
{
	// --- Configuration (set by app, serializable) ---

	/// Body motion type.
	public BodyType BodyType = .Dynamic;

	/// Collision shape configuration.
	public ShapeConfig Shape = .Box(0.5f);

	/// Mass in kg. 0 = use shape volume default.
	public float Mass = 0.0f;

	/// Friction coefficient [0, 1].
	public float Friction = 0.5f;

	/// Restitution / bounciness [0, 1].
	public float Restitution = 0.0f;

	/// Linear damping (velocity decay).
	public float LinearDamping = 0.05f;

	/// Angular damping (rotation decay).
	public float AngularDamping = 0.05f;

	/// Gravity factor (0 = no gravity, 1 = normal).
	public float GravityFactor = 1.0f;

	/// Whether this body is a sensor (trigger, detects but doesn't collide).
	public bool IsSensor = false;

	/// Whether the body can sleep when inactive.
	public bool AllowSleep = true;

	/// Collision layer (0 = static, 1+ = dynamic/kinematic).
	public uint16 CollisionLayer = 1;

	// --- Runtime state (managed by PhysicsComponentManager) ---

	/// Handle to the physics body in the IPhysicsWorld.
	public BodyHandle PhysicsBody = .Invalid;

	/// Handle to the collision shape (shared, ref-counted by physics world).
	public ShapeHandle PhysicsShape = .Invalid;

	/// Whether this component needs its physics body to be created.
	public bool NeedsBodyCreation = true;

	/// Whether this component needs its shape to be recreated (config changed).
	public bool NeedsShapeUpdate = false;
}
