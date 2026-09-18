using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Heightfield;
using Sedulous.Physics;
using Sedulous.Physics.Resource;
using Sedulous.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// A physics body on an entity.
///
/// Everything below the authored block is runtime state the scene system owns, and none of it
/// is serialized: a body handle names a slot in a world that no longer exists by the time a
/// scene is loaded again.
[SerializableComponent("physics.RigidBody")]
[DisplayName("Rigid Body")]
[Category("Physics")]
[Scriptable]
struct RigidBodyComponent : ISerializable, IComponentResources
{
	// ---- authored ----

	[Scriptable]
	public MotionKind Motion = .Dynamic;
	[Scriptable]
	public PhysicsLayer Layer = .Dynamic;
	[Scriptable]
	public ShapeKind Shape = .Box;

	[Scriptable]
	public Float3 HalfExtents = .(0.5f, 0.5f, 0.5f);
	[Scriptable]
	public float Radius = 0.5f;
	[Scriptable]
	public float HalfHeight = 0.5f;
	/// A PLANE shape is the entity's local horizontal plane, solid below, and collides within
	/// this reach of the entity. Static and kinematic only.
	[Scriptable]
	public float PlaneHalfExtent = 1000.0f;

	[Scriptable]
	public float Friction = 0.5f;
	[Scriptable]
	public float Restitution = 0.0f;
	[Scriptable]
	public float LinearDamping = 0.05f;
	[Scriptable]
	public float AngularDamping = 0.05f;
	[Scriptable]
	public bool IsTrigger = false;

	/// Continuous collision, which stops a small fast body tunnelling through thin geometry.
	/// OPT IN, because it costs an extra cast per fast body per step.
	[Scriptable]
	public bool ContinuousCollision = false;

	/// An explicit mass in kilograms, for a dynamic body. Nought derives one from the
	/// density; anything else overrides the scalar mass while the inertia stays derived.
	[Scriptable]
	public float Mass = 0.0f;

	/// The designer's collision group. A pair collides when the scene's matrix allows it.
	[Scriptable]
	public uint8 CollisionGroup = 0;

	/// A COOKED shape, for the shape kind that names one.
	[Scriptable]
	public Ref<CollisionShape> CollisionShape = .(Guid());
	/// A HEIGHTFIELD, which is a collision surface with no terrain renderer behind it. Static
	/// and kinematic only.
	[Scriptable]
	public Ref<Heightfield> Heightfield = .(Guid());
	/// A surface override. When set it WINS over the inline friction and restitution.
	[Scriptable]
	public Ref<PhysicalMaterial> Material = .(Guid());

	// ---- runtime ----

	public BodyId Body = .();

	/// An impulse applied BEFORE the body existed, which is what a script that spawns a thing
	/// and launches it in the same frame produces. Accumulated while the handle is invalid,
	/// then flushed once the body is created.
	public Float3 PendingImpulse = .(0, 0, 0);

	/// The effective active state this domain last reconciled against, which is what turns a
	/// change into an edge rather than a per frame comparison.
	public bool SimActive = false;

	public Float3 PrevPosition = .(0, 0, 0);
	public Float3 CurrPosition = .(0, 0, 0);
	public Quaternion PrevRotation = Quaternion.Identity;
	public Quaternion CurrRotation = Quaternion.Identity;

	public this() {}

	public void ResolveResources(ResourceManager manager) mut
	{
		CollisionShape.Bind(manager);
		Heightfield.Bind(manager);
		Material.Bind(manager);
	}

	public void Serialize(ISerializer ar) mut
	{
		ar.Key("motion");
		SerializeEnum(ar, ref Motion);
		ar.Key("layer");
		SerializeEnum(ar, ref Layer);
		ar.Key("shape");
		SerializeEnum(ar, ref Shape);

		ar.Key("halfExtents");
		Sedulous.Core.Serialization.Serialize(ar, ref HalfExtents);
		SerializeValue(ar, "radius", ref Radius);
		SerializeValue(ar, "halfHeight", ref HalfHeight);
		SerializeValue(ar, "planeHalfExtent", ref PlaneHalfExtent);
		SerializeValue(ar, "friction", ref Friction);
		SerializeValue(ar, "restitution", ref Restitution);
		SerializeValue(ar, "linearDamping", ref LinearDamping);
		SerializeValue(ar, "angularDamping", ref AngularDamping);
		SerializeValue(ar, "isTrigger", ref IsTrigger);
		SerializeValue(ar, "collisionGroup", ref CollisionGroup);
		SerializeValue(ar, "collisionShape", ref CollisionShape.Id);
		SerializeValue(ar, "material", ref Material.Id);
		SerializeValue(ar, "heightfield", ref Heightfield.Id);
		SerializeValue(ar, "continuousCollision", ref ContinuousCollision);
		SerializeValue(ar, "mass", ref Mass);
	}
}
