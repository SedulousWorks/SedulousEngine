namespace Sedulous.Engine.Physics;

using Sedulous.Engine.Core;
using Sedulous.Physics;
using Sedulous.Core.Mathematics;
using Sedulous.Inspection;

/// Component for a physics rigid body attached to an entity.
///
/// Holds configuration data (body type, mass, shape, material properties)
/// and runtime state (BodyHandle, ShapeHandle). The PhysicsComponentManager
/// creates/destroys the actual physics bodies and syncs transforms.
[Component]
class RigidBodyComponent : Component, ISerializableComponent
{
	public int32 SerializationVersion => 1;

	public void Serialize(IComponentSerializer s)
	{
		var bodyType = (uint8)BodyType;
		s.UInt8("BodyType", ref bodyType);
		if (s.IsReading) BodyType = (BodyType)bodyType;

		var shapeType = (uint8)Shape.Type;
		s.UInt8("ShapeType", ref shapeType);
		if (s.IsReading) Shape.Type = (ShapeType)shapeType;
		s.Float("ShapeHalfX", ref Shape.HalfExtents.X);
		s.Float("ShapeHalfY", ref Shape.HalfExtents.Y);
		s.Float("ShapeHalfZ", ref Shape.HalfExtents.Z);
		s.Float("ShapeRadius", ref Shape.Radius);
		s.Float("ShapeHalfHeight", ref Shape.HalfHeight);

		s.Float("Mass", ref Mass);
		s.Float("Friction", ref Friction);
		s.Float("Restitution", ref Restitution);
		s.Float("LinearDamping", ref LinearDamping);
		s.Float("AngularDamping", ref AngularDamping);
		s.Float("GravityFactor", ref GravityFactor);
		s.Bool("IsSensor", ref IsSensor);
		s.Bool("AllowSleep", ref AllowSleep);
	}

	// --- Configuration (set by app, serializable) ---

	/// Body motion type.
	[Property(.Default, "Body Type", "BodyType")]
	public BodyType BodyType = .Dynamic;

	/// Collision shape configuration. Edited via code today - a dedicated
	/// editor for ShapeConfig (type + bounds selector) is a future addition;
	/// the serialized sub-fields (ShapeType / ShapeHalfX..Z / ShapeRadius /
	/// ShapeHalfHeight) still round-trip via Serialize().
	public ShapeConfig Shape = .Box(0.5f);

	/// Mass in kg. 0 = use shape volume default.
	[Property(.Default, "Mass", "Mass")]
	public float Mass = 0.0f;

	/// Friction coefficient [0, 1].
	[Property(.Slider, "Friction", "Friction"), Range(0.0f, 1.0f)]
	public float Friction = 0.5f;

	/// Restitution / bounciness [0, 1].
	[Property(.Slider, "Restitution", "Restitution"), Range(0.0f, 1.0f)]
	public float Restitution = 0.0f;

	/// Linear damping (velocity decay).
	[Property(.Default, "Linear Damping", "LinearDamping")]
	public float LinearDamping = 0.05f;

	/// Angular damping (rotation decay).
	[Property(.Default, "Angular Damping", "AngularDamping")]
	public float AngularDamping = 0.05f;

	/// Gravity factor (0 = no gravity, 1 = normal).
	[Property(.Slider, "Gravity Factor", "GravityFactor"), Range(0.0f, 2.0f)]
	public float GravityFactor = 1.0f;

	/// Whether this body is a sensor (trigger, detects but doesn't collide).
	[Property(.Default, "Is Sensor", "IsSensor")]
	public bool IsSensor = false;

	/// Whether the body can sleep when inactive.
	[Property(.Default, "Allow Sleep", "AllowSleep")]
	public bool AllowSleep = true;

	/// Collision layer (0 = static, 1+ = dynamic/kinematic). Not serialized -
	/// gameplay code sets this at component creation time.
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

	// --- Contact event handlers (set by gameplay code) ---

	/// Called when this body first contacts another body.
	/// Return false to reject the contact (bodies pass through each other).
	public delegate bool(RigidBodyComponent self, PhysicsContactEvent event) OnContactAdded ~ delete _;

	/// Called each frame while this body remains in contact with another.
	public delegate void(RigidBodyComponent self, PhysicsContactEvent event) OnContactPersisted ~ delete _;

	/// Called when this body stops contacting another body.
	public delegate void(RigidBodyComponent self, EntityHandle otherEntity) OnContactRemoved ~ delete _;
}
