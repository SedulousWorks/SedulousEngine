using System;
using System.Collections;
using System.Threading;
using Sedulous.Core;
using joltc_Beef;

namespace Sedulous.Physics;

/// The rigid body world.
///
/// The backend is COMMITTED rather than abstracted: there is no layer to swap it out, and
/// none of its types appear in this surface. A body is a handle, and the shapes, queries and
/// events all speak our own vocabulary. The per body user word carries the scene entity's
/// reverse map.
///
/// ONE WORLD PER SCENE, stepped from the fixed update lane.
class PhysicsWorld
{
	private PhysicsWorldSettings mSettings = new .() ~ delete _;

	private JPH_BroadPhaseLayerInterface* mBroadPhaseLayers = null;
	private JPH_ObjectLayerPairFilter* mPairFilter = null;
	private JPH_ObjectVsBroadPhaseLayerFilter* mObjectVsBroadPhase = null;
	private JPH_PhysicsSystem* mSystem = null;
	private JPH_JobSystem* mJobSystem = null;
	private JPH_ContactListener* mContactListener = null;

	/// A joint's id is its slot, and a freed slot is a null joint.
	///
	/// The two body ids ride the slot so a teardown can wake the SURVIVING bodies by id: the
	/// constraint's own body pointers dangle when a connected body was destroyed first.
	private struct JointSlot
	{
		public JPH_Constraint* Joint;
		public JPH_BodyID BodyA;
		/// Invalid is an attachment to the world.
		public JPH_BodyID BodyB;
	}

	private struct CharacterSlot
	{
		public JPH_CharacterVirtual* Character;
		public float StepUp;
		public float StepDown;
	}

	private List<JointSlot> mJoints = new .() ~ delete _;
	private List<CharacterSlot> mCharacters = new .() ~ delete _;

	/// The contacts buffered during a step. The backend's WORKER THREADS append to this, so
	/// everything that touches it holds the lock; the fixed step driver drains it after.
	private Monitor mContactLock = new .() ~ delete _;
	private List<ContactEvent> mContacts = new .() ~ delete _;

	// ==================== bring up ====================

	public this(PhysicsWorldSettings settings = null)
	{
		// Its OWN copy, so the caller may keep, change or free what it passed.
		if (settings != null)
			mSettings.CopyFrom(settings);

		JoltRuntime.Acquire();
		InstallCallbacks();

		BuildLayerTables();

		var systemSettings = JPH_PhysicsSystemSettings()
			{
				maxBodies = mSettings.MaxBodies,
				numBodyMutexes = 0,
				maxBodyPairs = mSettings.MaxBodyPairs,
				maxContactConstraints = mSettings.MaxContactConstraints,
				broadPhaseLayerInterface = mBroadPhaseLayers,
				objectLayerPairFilter = mPairFilter,
				objectVsBroadPhaseLayerFilter = mObjectVsBroadPhase
			};
		mSystem = JPH_PhysicsSystem_Create(&systemSettings);

		var config = JobSystemThreadPoolConfig()
			{
				maxJobs = (uint32)JPH_MAX_PHYSICS_JOBS,
				maxBarriers = (uint32)JPH_MAX_PHYSICS_BARRIERS,
				// One less than the machine has, since the calling thread joins the step.
				numThreads = Math.Max(JobSystem.LogicalCoreCount() - 1, 1)
			};
		mJobSystem = JPH_JobSystemThreadPool_Create(&config);

		var gravity = ToJolt(mSettings.Gravity);
		JPH_PhysicsSystem_SetGravity(mSystem, &gravity);

		mContactListener = JPH_ContactListener_Create(Internal.UnsafeCastToPtr(this));
		JPH_PhysicsSystem_SetContactListener(mSystem, mContactListener);
	}

	public ~this()
	{
		for (var slot in mJoints)
		{
			if (slot.Joint != null)
			{
				JPH_PhysicsSystem_RemoveConstraint(mSystem, slot.Joint);
				JPH_Constraint_Destroy(slot.Joint);
			}
		}
		for (var slot in mCharacters)
		{
			if (slot.Character != null)
				JPH_CharacterBase_Destroy((JPH_CharacterBase*)slot.Character);
		}

		if (mSystem != null)
		{
			JPH_PhysicsSystem_SetContactListener(mSystem, null);
			JPH_PhysicsSystem_Destroy(mSystem);
		}
		if (mContactListener != null)
			JPH_ContactListener_Destroy(mContactListener);
		if (mJobSystem != null)
			JPH_JobSystem_Destroy(mJobSystem);

		JoltRuntime.Release();
	}

	/// The layer tables the broad phase and the pair filter are driven by.
	///
	/// The backend takes these as TABLES rather than as functions, so the rules are evaluated
	/// once here for every pair instead of once per query. That is why the encoding is dense,
	/// and it is also why the group matrix is read at construction: a world's matrix is fixed
	/// for its life.
	private void BuildLayerTables()
	{
		mBroadPhaseLayers = JPH_BroadPhaseLayerInterfaceTable_Create(PhysicsLayers.Count,
			PhysicsLayers.BroadPhaseCount);
		for (uint32 layer = 0; layer < PhysicsLayers.Count; layer++)
		{
			// Only the statics sit in the static half, which is what keeps the broad phase
			// from re-walking immovable geometry every step.
			let broadPhase = (PhysicsLayers.Semantic((JPH_ObjectLayer)layer) == .Static)
				? PhysicsLayers.BroadPhaseStatic
				: PhysicsLayers.BroadPhaseMoving;
			JPH_BroadPhaseLayerInterfaceTable_MapObjectToBroadPhaseLayer(mBroadPhaseLayers,
				(JPH_ObjectLayer)layer, (JPH_BroadPhaseLayer)broadPhase);
		}

		mPairFilter = JPH_ObjectLayerPairFilterTable_Create(PhysicsLayers.Count);
		for (uint32 a = 0; a < PhysicsLayers.Count; a++)
		{
			for (uint32 b = a; b < PhysicsLayers.Count; b++)
			{
				if (Collides((JPH_ObjectLayer)a, (JPH_ObjectLayer)b))
					JPH_ObjectLayerPairFilterTable_EnableCollision(mPairFilter,
						(JPH_ObjectLayer)a, (JPH_ObjectLayer)b);
				else
					JPH_ObjectLayerPairFilterTable_DisableCollision(mPairFilter,
						(JPH_ObjectLayer)a, (JPH_ObjectLayer)b);
			}
		}

		mObjectVsBroadPhase = JPH_ObjectVsBroadPhaseLayerFilterTable_Create(mBroadPhaseLayers,
			PhysicsLayers.BroadPhaseCount, mPairFilter, PhysicsLayers.Count);
	}

	/// The semantic rules first, then the group matrix BOTH WAYS: a matrix that disagrees
	/// with itself refuses the pair rather than deciding by which body was asked about first.
	private bool Collides(JPH_ObjectLayer a, JPH_ObjectLayer b)
	{
		if (!PhysicsLayers.SemanticCollides(PhysicsLayers.Semantic(a), PhysicsLayers.Semantic(b)))
			return false;

		let groupA = PhysicsLayers.Group(a);
		let groupB = PhysicsLayers.Group(b);
		return ((mSettings.GroupCollides[groupA] & (1 << groupB)) != 0)
			&& ((mSettings.GroupCollides[groupB] & (1 << groupA)) != 0);
	}

	// ==================== conversions ====================

	private static JPH_Vec3 ToJolt(Float3 v) => .() { x = v.X, y = v.Y, z = v.Z };
	private static JPH_Quat ToJolt(Quaternion q) => .() { x = q.X, y = q.Y, z = q.Z, w = q.W };
	private static Float3 FromJolt(JPH_Vec3 v) => .(v.x, v.y, v.z);
	private static Quaternion FromJolt(JPH_Quat q) => .(q.x, q.y, q.z, q.w);

	// ==================== the world ====================

	public void SetGravity(Float3 gravity)
	{
		var value = ToJolt(gravity);
		JPH_PhysicsSystem_SetGravity(mSystem, &value);
	}

	public Float3 Gravity
	{
		get
		{
			var value = JPH_Vec3();
			JPH_PhysicsSystem_GetGravity(mSystem, &value);
			return FromJolt(value);
		}
	}

	/// One fixed step. The contacts buffered during it are drained afterwards.
	public void Step(float deltaTime, int32 collisionSteps = 1)
	{
		JPH_PhysicsSystem_Update(mSystem, deltaTime, collisionSteps, mJobSystem);
	}

	public int BodyCount => (int)JPH_PhysicsSystem_GetNumBodies(mSystem);

	private JPH_BodyInterface* Bodies => JPH_PhysicsSystem_GetBodyInterface(mSystem);

	// ==================== shapes ====================

	/// Builds one shape. Null when it cannot be built, which a caller reads as a body that
	/// does not exist rather than one that exists and collides with nothing.
	///
	/// THE CALLER OWNS what comes back.
	private JPH_Shape* BuildOne(ShapeDesc desc, float density)
	{
		JPH_Shape* shape = null;
		switch (desc.Kind)
		{
		case .Box:
			var halfExtents = ToJolt(desc.HalfExtents);
			shape = (JPH_Shape*)JPH_BoxShape_Create(&halfExtents, JPH_DEFAULT_CONVEX_RADIUS);
		case .Sphere:
			shape = (JPH_Shape*)JPH_SphereShape_Create(desc.Radius);
		case .Capsule:
			shape = (JPH_Shape*)JPH_CapsuleShape_Create(desc.HalfHeight, desc.Radius);
		case .Cooked:
			shape = ShapeCooking.Restore(desc.Cooked);
		case .Plane:
			let normal = Normalized(desc.PlaneNormal);
			var plane = JPH_Plane() { normal = ToJolt(normal), distance = desc.PlaneDistance };
			shape = (JPH_Shape*)JPH_PlaneShape_Create(&plane, null, desc.PlaneHalfExtent);
		case .Heightfield:
			shape = BuildHeightfield(desc);
		}

		if (shape == null)
			return null;

		// The density drives the mass and inertia the backend calculates, and only a convex
		// shape carries one: a mesh or a heightfield has no volume to weigh.
		if ((density > 0.0f) && (JPH_Shape_GetType(shape) == .JPH_ShapeType_Convex))
			JPH_ConvexShape_SetDensity((JPH_ConvexShape*)shape, density);

		if ((desc.Scale.X != 1.0f) || (desc.Scale.Y != 1.0f) || (desc.Scale.Z != 1.0f))
		{
			var scale = ToJolt(desc.Scale);
			let scaled = (JPH_Shape*)JPH_ScaledShape_Create(shape, &scale);
			// The wrapper took its own reference, so ours goes back.
			JPH_Shape_Destroy(shape);
			shape = scaled;
		}
		return shape;
	}

	/// A heightfield from a square grid of world Y heights.
	///
	/// The backend maps sample (x, z) to offset plus scale times (x, height, z), so the
	/// footprint is centred on the shape's origin by offsetting it half the world size and
	/// scaling by the spacing between samples. The count is passed through UNPADDED: the
	/// backend rounds it up to its own block size and fills the padding with no collision
	/// values, and hand padding it would move the footprint.
	private JPH_Shape* BuildHeightfield(ShapeDesc desc)
	{
		let n = desc.HeightSampleCount;
		if ((n < 2) || (desc.HeightSamples.Length < (int)n * (int)n))
			return null;

		var offset = JPH_Vec3()
			{
				x = -desc.HeightWorldSize.X * 0.5f,
				y = 0.0f,
				z = -desc.HeightWorldSize.Y * 0.5f
			};
		var scale = JPH_Vec3()
			{
				x = desc.HeightWorldSize.X / (float)(n - 1),
				y = 1.0f,
				z = desc.HeightWorldSize.Y / (float)(n - 1)
			};

		let settings = JPH_HeightFieldShapeSettings_Create(desc.HeightSamples.Ptr, &offset,
			&scale, n, null);
		if (settings == null)
			return null;
		defer JPH_ShapeSettings_Destroy((JPH_ShapeSettings*)settings);

		return (JPH_Shape*)JPH_HeightFieldShapeSettings_CreateShape(settings);
	}

	/// One shape with NO PLACEMENT of its own is used as it is; anything else becomes a
	/// compound, since a compound of one still costs a level of indirection on every query
	/// through it.
	///
	/// A placement is a rotation as much as an offset: a lone shape carrying only a rotation
	/// used bare would drop it silently, and a bar authored on its side would collide
	/// upright.
	///
	/// THE CALLER OWNS what comes back.
	private JPH_Shape* BuildShape(BodyDesc desc)
	{
		if (desc.Shapes.IsEmpty)
			return null;

		if ((desc.Shapes.Count == 1) && IsUnplaced(desc.Shapes[0]))
			return BuildOne(desc.Shapes[0], desc.Density);

		let compound = JPH_StaticCompoundShapeSettings_Create();
		if (compound == null)
			return null;
		defer JPH_ShapeSettings_Destroy((JPH_ShapeSettings*)compound);

		// A child that fails takes the whole body with it: a compound silently missing a
		// limb collides wrongly rather than visibly.
		for (let child in desc.Shapes)
		{
			let shape = BuildOne(child, desc.Density);
			if (shape == null)
				return null;

			var position = ToJolt(child.LocalPosition);
			var rotation = ToJolt(child.LocalRotation);
			JPH_CompoundShapeSettings_AddShape2((JPH_CompoundShapeSettings*)compound, &position,
				&rotation, shape, 0);
			// The compound took its own reference.
			JPH_Shape_Destroy(shape);
		}

		return (JPH_Shape*)JPH_StaticCompoundShape_Create(compound);
	}

	/// Whether a shape sits at its body's own origin, unrotated.
	private static bool IsUnplaced(ShapeDesc desc) =>
		(desc.LocalPosition.X == 0.0f) && (desc.LocalPosition.Y == 0.0f)
		&& (desc.LocalPosition.Z == 0.0f)
		&& (desc.LocalRotation.X == 0.0f) && (desc.LocalRotation.Y == 0.0f)
		&& (desc.LocalRotation.Z == 0.0f) && (desc.LocalRotation.W == 1.0f);

	/// The mass and inertia of a solid box of the size and density, the backend's own
	/// formula: the inertia is diagonal, mass over twelve times the squared sizes of the
	/// other two axes.
	private static JPH_MassProperties SolidBoxMassProperties(Float3 size, float density)
	{
		var properties = JPH_MassProperties();
		properties.mass = size.X * size.Y * size.Z * density;
		let scale = properties.mass / 12.0f;
		properties.inertia.column[0].x = scale * (size.Y * size.Y + size.Z * size.Z);
		properties.inertia.column[1].y = scale * (size.X * size.X + size.Z * size.Z);
		properties.inertia.column[2].z = scale * (size.X * size.X + size.Y * size.Y);
		properties.inertia.column[3].w = 1.0f;
		return properties;
	}

	// ==================== bodies ====================

	public BodyId CreateBody(BodyDesc desc)
	{
		if (desc == null)
			return .();

		let shape = BuildShape(desc);
		if (shape == null)
			return .();
		defer JPH_Shape_Destroy(shape);

		// A trigger IS the Trigger layer, whatever the desc's layer says: a sensor on the
		// Dynamic layer would take part in the solve.
		let layer = desc.IsTrigger ? PhysicsLayer.Trigger : desc.Layer;
		// The backend's own rule, MustBeStatic: a mesh, a heightfield, a plane, and any
		// compound or decorated shape holding one derive no mass, and mass properties are set
		// for EVERY non static body, kinematic as much as dynamic, so a moving one asserts on
		// the invalid mass in a checked build and gets a body with no inertia in a release
		// one. A data error, not a crash: such a body is static whatever was asked, and the
		// scene system names the entity.
		let kind = JPH_Shape_MustBeStatic(shape) ? MotionKind.Static : desc.Motion;
		let motion = (kind == .Static) ? JPH_MotionType.JPH_MotionType_Static
			: (kind == .Kinematic) ? JPH_MotionType.JPH_MotionType_Kinematic
			: JPH_MotionType.JPH_MotionType_Dynamic;

		var position = ToJolt(desc.Position);
		var rotation = ToJolt(desc.Rotation);
		let settings = JPH_BodyCreationSettings_Create3(shape, &position, &rotation, motion,
			PhysicsLayers.From(layer, desc.Group));
		if (settings == null)
			return .();
		defer JPH_BodyCreationSettings_Destroy(settings);

		JPH_BodyCreationSettings_SetFriction(settings, desc.Friction);
		JPH_BodyCreationSettings_SetRestitution(settings, desc.Restitution);
		JPH_BodyCreationSettings_SetLinearDamping(settings, desc.LinearDamping);
		JPH_BodyCreationSettings_SetAngularDamping(settings, desc.AngularDamping);
		JPH_BodyCreationSettings_SetIsSensor(settings, desc.IsTrigger);
		JPH_BodyCreationSettings_SetUserData(settings, desc.UserData);
		JPH_BodyCreationSettings_SetOverrideMassProperties(settings,
			.JPH_OverrideMassProperties_CalculateMassAndInertia);

		if (kind == .Dynamic)
		{
			if (desc.ContinuousCollision)
				JPH_BodyCreationSettings_SetMotionQuality(settings,
					.JPH_MotionQuality_LinearCast);

			// A convex shape degenerate to zero volume, a hull cooked from a flat quad, derives
			// no mass and would trip the same assert; a zero scale is refused at shape creation,
			// so the flat hull is the reachable case. It still collides, so it gets the mass and
			// inertia of a solid box filling its local bounds, a centimetre thick at least,
			// density derived or scaled to the explicit mass, and keeps simulating.
			var derived = JPH_MassProperties();
			JPH_Shape_GetMassProperties(shape, &derived);
			if (!(derived.mass > 0.0f) || derived.mass.IsInfinity)
			{
				var bounds = JPH_AABox();
				JPH_Shape_GetLocalBounds(shape, &bounds);
				let size = Float3(Math.Max(bounds.max.x - bounds.min.x, 0.01f),
					Math.Max(bounds.max.y - bounds.min.y, 0.01f),
					Math.Max(bounds.max.z - bounds.min.z, 0.01f));
				var solid = SolidBoxMassProperties(size, (desc.Density > 0.0f) ? desc.Density : 1000.0f);
				if (desc.MassOverride > 0.0f)
					JPH_MassProperties_ScaleToMass(&solid, desc.MassOverride);
				JPH_BodyCreationSettings_SetOverrideMassProperties(settings,
					.JPH_OverrideMassProperties_MassAndInertiaProvided);
				JPH_BodyCreationSettings_SetMassPropertiesOverride(settings, &solid);
			}
			else if (desc.MassOverride > 0.0f)
			{
				// The INERTIA stays density derived; only the scalar mass is overridden, so a
				// prop that shoves hard still tumbles like its shape.
				JPH_BodyCreationSettings_SetOverrideMassProperties(settings,
					.JPH_OverrideMassProperties_CalculateInertia);
				var mass = JPH_MassProperties();
				JPH_BodyCreationSettings_GetMassPropertiesOverride(settings, &mass);
				mass.mass = desc.MassOverride;
				JPH_BodyCreationSettings_SetMassPropertiesOverride(settings, &mass);
			}
		}

		let activation = (kind == .Static) ? JPH_Activation.JPH_Activation_DontActivate
			: JPH_Activation.JPH_Activation_Activate;
		let id = JPH_BodyInterface_CreateAndAddBody(Bodies, settings, activation);
		return (id == BodyId.Invalid) ? BodyId() : BodyId(id);
	}

	public void DestroyBody(BodyId id)
	{
		if (!id.IsValid)
			return;

		let bodies = Bodies;
		JPH_BodyInterface_RemoveBody(bodies, id.Value);
		JPH_BodyInterface_DestroyBody(bodies, id.Value);
	}

	/// The body's real mass in kilograms: the density derived value, or the override when one
	/// was set. Nought for a static, a kinematic or a body that is not there.
	public float BodyMass(BodyId id)
	{
		if (!id.IsValid)
			return 0.0f;

		var lock = JPH_BodyLockRead();
		JPH_BodyLockInterface_LockRead(JPH_PhysicsSystem_GetBodyLockInterface(mSystem), id.Value,
			&lock);
		defer JPH_BodyLockInterface_UnlockRead(JPH_PhysicsSystem_GetBodyLockInterface(mSystem),
			&lock);

		if ((lock.body == null) || !JPH_Body_IsDynamic(lock.body))
			return 0.0f;

		let properties = JPH_Body_GetMotionProperties(lock.body);
		if (properties == null)
			return 0.0f;

		let inverseMass = JPH_MotionProperties_GetInverseMassUnchecked(properties);
		return (inverseMass > 0.0f) ? (1.0f / inverseMass) : 0.0f;
	}

	public void GetBodyTransform(BodyId id, out Float3 outPosition, out Quaternion outRotation)
	{
		var position = JPH_Vec3();
		var rotation = JPH_Quat();
		JPH_BodyInterface_GetPositionAndRotation(Bodies, id.Value, &position, &rotation);
		outPosition = FromJolt(position);
		outRotation = FromJolt(rotation);
	}

	/// A TELEPORT: it snaps the body and leaves its velocities alone. A dynamic body mid
	/// simulation moves this way rather than by a per frame scene write, which is what keeps
	/// the transform's ownership in one place.
	public void SetBodyTransform(BodyId id, Float3 position, Quaternion rotation)
	{
		var p = ToJolt(position);
		var r = ToJolt(rotation);
		JPH_BodyInterface_SetPositionAndRotation(Bodies, id.Value, &p, &r,
			.JPH_Activation_Activate);
	}

	/// A velocity correct kinematic move over the step, so what it pushes is pushed at the
	/// speed it is actually travelling.
	public void MoveKinematic(BodyId id, Float3 position, Quaternion rotation, float deltaTime)
	{
		var p = ToJolt(position);
		var r = ToJolt(rotation);
		JPH_BodyInterface_MoveKinematic(Bodies, id.Value, &p, &r, deltaTime);
	}

	public void SetLinearVelocity(BodyId id, Float3 velocity)
	{
		var value = ToJolt(velocity);
		JPH_BodyInterface_SetLinearVelocity(Bodies, id.Value, &value);
	}

	public Float3 LinearVelocity(BodyId id)
	{
		var value = JPH_Vec3();
		JPH_BodyInterface_GetLinearVelocity(Bodies, id.Value, &value);
		return FromJolt(value);
	}

	public void AddImpulse(BodyId id, Float3 impulse)
	{
		var value = ToJolt(impulse);
		JPH_BodyInterface_AddImpulse(Bodies, id.Value, &value);
	}

	public void AddForce(BodyId id, Float3 force)
	{
		var value = ToJolt(force);
		JPH_BodyInterface_AddForce(Bodies, id.Value, &value);
	}

	public bool IsActive(BodyId id) => JPH_BodyInterface_IsActive(Bodies, id.Value);

	public uint64 UserData(BodyId id) => JPH_BodyInterface_GetUserData(Bodies, id.Value);

	// ==================== queries ====================

	/// The query side layer filter: a body is considered when its GROUP's bit is in the mask.
	///
	/// The mask rides in the user word rather than in an object, because the backend's filter
	/// procedures are process wide and only the user word is per filter.
	private static bool GroupMaskShouldCollide(void* user, JPH_ObjectLayer layer)
	{
		let mask = (uint32)(int)user;
		return (mask & (1 << PhysicsLayers.Group(layer))) != 0;
	}

	/// The procedures are PROCESS WIDE, one table for every filter and listener of a kind,
	/// so they are installed once and dispatch on the user word.
	///
	/// The tables themselves are STATIC because the backend keeps the pointer it is handed
	/// rather than copying what it points at: a table built on the stack would be read long
	/// after the frame that held it was gone.
	///
	/// PROCESS WIDE also means exclusive: another module installing its own procedures for
	/// either of these would REPLACE ours for every world in the process, not add to them.
	/// Anything else needing a query side layer filter goes through this one and dispatches
	/// on the user word.
	private static bool sCallbacksInstalled = false;
	private static Monitor sCallbackLock = new .() ~ delete _;
	private static JPH_ObjectLayerFilter_Procs sLayerProcs = .();
	private static JPH_ContactListener_Procs sContactProcs = .();

	private static void InstallCallbacks()
	{
		using (sCallbackLock.Enter())
		{
			if (sCallbacksInstalled)
				return;
			sCallbacksInstalled = true;

			sLayerProcs.ShouldCollide = => GroupMaskShouldCollide;
			JPH_ObjectLayerFilter_SetProcs(&sLayerProcs);

			sContactProcs.OnContactValidate = null;
			sContactProcs.OnContactAdded = => OnContactAdded;
			sContactProcs.OnContactPersisted = null;
			sContactProcs.OnContactRemoved = => OnContactRemoved;
			JPH_ContactListener_SetProcs(&sContactProcs);
		}
	}

	/// Builds the transient convex volume a sweep or an overlap is done with, runs the body
	/// against it, and frees it.
	///
	/// A cooked, plane or heightfield kind is not a query shape and answers false, so the
	/// query no-ops rather than asserting. The dimensions come straight off a script surface,
	/// so a non positive one is refused HERE instead of feeding the broad phase a NaN.
	private bool WithQueryShape(QueryShape query, delegate void(JPH_Shape* shape) body)
	{
		JPH_Shape* shape = null;
		switch (query.Kind)
		{
		case .Box:
			let minExtent = Min(query.HalfExtents.X,
				Min(query.HalfExtents.Y, query.HalfExtents.Z));
			if (!(minExtent > 0.0f))
				return false;
			// The backend asserts the half extent is at least the convex radius, so a thin
			// box gets a smaller radius rather than a failed assertion.
			var halfExtents = ToJolt(query.HalfExtents);
			shape = (JPH_Shape*)JPH_BoxShape_Create(&halfExtents,
				Min(JPH_DEFAULT_CONVEX_RADIUS, minExtent * 0.5f));
		case .Sphere:
			if (!(query.Radius > 0.0f))
				return false;
			shape = (JPH_Shape*)JPH_SphereShape_Create(query.Radius);
		case .Capsule:
			if (!(query.Radius > 0.0f) || !(query.HalfHeight > 0.0f))
				return false;
			shape = (JPH_Shape*)JPH_CapsuleShape_Create(query.HalfHeight, query.Radius);
		default:
			return false;
		}

		if (shape == null)
			return false;
		defer JPH_Shape_Destroy(shape);

		body(shape);
		return true;
	}

	/// The closest body along the ray. The mask's bit g considers bodies in group g.
	public bool RayCast(Float3 from, Float3 direction, float maxDistance, out RayHit outHit,
		uint32 groupMask = 0xFFFFFFFF)
	{
		outHit = .();

		var origin = ToJolt(from);
		// The backend takes the ray's direction UNNORMALISED and reports the hit as a
		// fraction along it, so the distance rides in its length.
		var ray = ToJolt(direction * maxDistance);
		var hit = JPH_RayCastResult();

		let filter = JPH_ObjectLayerFilter_Create((void*)(int)groupMask);
		defer JPH_ObjectLayerFilter_Destroy(filter);

		if (!JPH_NarrowPhaseQuery_CastRay(JPH_PhysicsSystem_GetNarrowPhaseQuery(mSystem), &origin,
			&ray, &hit, null, filter, null))
			return false;

		outHit.Body = BodyId(hit.bodyID);
		outHit.Fraction = hit.fraction;
		outHit.Position = from + direction * (maxDistance * hit.fraction);
		outHit.UserData = UserData(outHit.Body);

		var lock = JPH_BodyLockRead();
		let bodies = JPH_PhysicsSystem_GetBodyLockInterface(mSystem);
		JPH_BodyLockInterface_LockRead(bodies, hit.bodyID, &lock);
		defer JPH_BodyLockInterface_UnlockRead(bodies, &lock);

		if (lock.body != null)
		{
			var point = ToJolt(outHit.Position);
			var normal = JPH_Vec3();
			JPH_Body_GetWorldSpaceSurfaceNormal(lock.body, hit.subShapeID2, &point, &normal);
			outHit.Normal = FromJolt(normal);

			// The material slot the cooker stored, which only a triangle mesh carries. The
			// leaf is what holds it: a compound's sub shape id has to be walked down first.
			//
			// Read off the body ALREADY LOCKED above, never through the body interface: that
			// would take a second shared lock on the same body, which is undefined on a
			// shared mutex and deadlocks outright if a writer is waiting between the two.
			let shape = JPH_Body_GetShape(lock.body);
			if (shape != null)
			{
				JPH_SubShapeID remainder = 0;
				let leaf = JPH_Shape_GetLeafShape(shape, hit.subShapeID2, &remainder);
				if ((leaf != null) && (JPH_Shape_GetSubType(leaf) == .JPH_ShapeSubType_Mesh))
					outHit.Surface = JPH_MeshShape_GetTriangleUserData((JPH_MeshShape*)leaf,
						remainder);
			}
		}
		return true;
	}

	/// The bodies whose shapes contain the point, triggers included. FILLED rather than
	/// appended, so a reused list never mixes two queries' results.
	public void QueryPoint(Float3 point, List<BodyId> outBodies, uint32 groupMask = 0xFFFFFFFF)
	{
		outBodies.Clear();

		var position = ToJolt(point);
		let filter = JPH_ObjectLayerFilter_Create((void*)(int)groupMask);
		defer JPH_ObjectLayerFilter_Destroy(filter);

		JPH_NarrowPhaseQuery_CollidePoint2(JPH_PhysicsSystem_GetNarrowPhaseQuery(mSystem),
			&position, .JPH_CollisionCollectorType_AllHit,
			=> CollectPoint, Internal.UnsafeCastToPtr(outBodies), null, filter, null, null);
	}

	private static void CollectPoint(void* user, JPH_CollidePointResult* result)
	{
		let bodies = (List<BodyId>)Internal.UnsafeCastToObject(user);
		bodies.Add(BodyId(result.bodyID));
	}

	/// The bodies overlapping the shape where it is placed, triggers included.
	///
	/// Each body appears ONCE: a compound reports a hit per sub shape, and a caller counting
	/// bodies would count one body several times. FILLED rather than appended.
	public void ShapeOverlap(QueryShape shape, Float3 position, Quaternion rotation,
		List<BodyId> outBodies, uint32 groupMask = 0xFFFFFFFF)
	{
		outBodies.Clear();

		let filter = JPH_ObjectLayerFilter_Create((void*)(int)groupMask);
		defer JPH_ObjectLayerFilter_Destroy(filter);

		WithQueryShape(shape, scope (js) =>
			{
				var rotationValue = ToJolt(rotation);
				var positionValue = ToJolt(position);
				var transform = JPH_Mat4();
				JPH_Mat4_RotationTranslation(&transform, &rotationValue, &positionValue);

				var settings = JPH_CollideShapeSettings();
				JPH_CollideShapeSettings_Init(&settings);
				var scale = JPH_Vec3() { x = 1.0f, y = 1.0f, z = 1.0f };
				var baseOffset = JPH_Vec3();

				JPH_NarrowPhaseQuery_CollideShape2(
					JPH_PhysicsSystem_GetNarrowPhaseQuery(mSystem), js, &scale, &transform,
					&settings, &baseOffset, .JPH_CollisionCollectorType_AllHit,
					=> CollectOverlap, Internal.UnsafeCastToPtr(outBodies), null, filter, null,
					null);
			});
	}

	private static void CollectOverlap(void* user, JPH_CollideShapeResult* result)
	{
		let bodies = (List<BodyId>)Internal.UnsafeCastToObject(user);
		let id = BodyId(result.bodyID2);
		for (let existing in bodies)
		{
			if (existing == id)
				return;
		}
		bodies.Add(id);
	}

	/// Sweeps the shape from a placement along a direction and reports the CLOSEST hit, which
	/// is a ray cast with a volume. The fraction is the sweep's.
	public bool ShapeCast(QueryShape shape, Float3 from, Quaternion rotation, Float3 direction,
		float maxDistance, out RayHit outHit, uint32 groupMask = 0xFFFFFFFF)
	{
		var hit = RayHit();
		var hitAny = false;

		let filter = JPH_ObjectLayerFilter_Create((void*)(int)groupMask);
		defer JPH_ObjectLayerFilter_Destroy(filter);

		WithQueryShape(shape, scope [&](js) =>
			{
				var rotationValue = ToJolt(rotation);
				var fromValue = ToJolt(from);
				var transform = JPH_Mat4();
				JPH_Mat4_RotationTranslation(&transform, &rotationValue, &fromValue);
				var sweep = ToJolt(direction * maxDistance);

				var settings = JPH_ShapeCastSettings();
				JPH_ShapeCastSettings_Init(&settings);
				var baseOffset = JPH_Vec3();

				var closest = JPH_ShapeCastResult();
				var found = false;
				let collected = scope ShapeCastCollected() { Hit = &closest, Found = &found };

				JPH_NarrowPhaseQuery_CastShape2(JPH_PhysicsSystem_GetNarrowPhaseQuery(mSystem),
					js, &transform, &sweep, &settings, &baseOffset,
					.JPH_CollisionCollectorType_ClosestHit, => CollectCast,
					Internal.UnsafeCastToPtr(collected), null, filter, null, null);

				if (!found)
					return;

				hit.Body = BodyId(closest.bodyID2);
				hit.Fraction = closest.fraction;
				hit.Position = FromJolt(closest.contactPointOn2);
				// The penetration axis points from the query shape INTO the body it hit, so
				// the outward surface normal is its negation. A touch with no penetration has
				// no axis to negate.
				let axis = FromJolt(closest.penetrationAxis);
				hit.Normal = (LengthSquared(axis) > 1.0e-12f)
					? -Normalized(axis)
					: Float3(0, 0, 0);
				hit.UserData = UserData(hit.Body);
				hitAny = true;
			});

		outHit = hit;
		return hitAny;
	}

	/// What a sweep's closest hit is collected into. The backend hands one result at a time
	/// through a plain function, so the destination has to travel as the user word.
	private class ShapeCastCollected
	{
		public JPH_ShapeCastResult* Hit;
		public bool* Found;
	}

	private static void CollectCast(void* user, JPH_ShapeCastResult* result)
	{
		let collected = (ShapeCastCollected)Internal.UnsafeCastToObject(user);
		*collected.Hit = *result;
		*collected.Found = true;
	}

	// ==================== contacts ====================

	private static void OnContactAdded(void* user, JPH_Body* bodyA, JPH_Body* bodyB,
		JPH_ContactManifold* manifold, JPH_ContactSettings* settings)
	{
		let world = (PhysicsWorld)Internal.UnsafeCastToObject(user);

		var event = ContactEvent();
		// A sensor on either side makes this an overlap rather than a collision: the solver
		// ran no response for it.
		event.Kind = (JPH_Body_IsSensor(bodyA) || JPH_Body_IsSensor(bodyB))
			? ContactKind.TriggerEnter
			: ContactKind.Begin;
		event.BodyA = BodyId(JPH_Body_GetID(bodyA));
		event.BodyB = BodyId(JPH_Body_GetID(bodyB));
		event.UserA = JPH_Body_GetUserData(bodyA);
		event.UserB = JPH_Body_GetUserData(bodyB);

		var normal = JPH_Vec3();
		JPH_ContactManifold_GetWorldSpaceNormal(manifold, &normal);
		event.Normal = FromJolt(normal);

		if (JPH_ContactManifold_GetPointCount(manifold) > 0)
		{
			var point = JPH_Vec3();
			JPH_ContactManifold_GetWorldSpaceContactPointOn1(manifold, 0, &point);
			event.Point = FromJolt(point);
		}

		// The APPROACH SPEED rather than a solver impulse: the backend does not surface the
		// true impulse cleanly here, and the relative velocity along the normal is the honest
		// measure of how hard the two met.
		var velocityA = JPH_Vec3();
		var velocityB = JPH_Vec3();
		JPH_Body_GetLinearVelocity(bodyA, &velocityA);
		JPH_Body_GetLinearVelocity(bodyB, &velocityB);
		event.Speed = Abs(Dot(FromJolt(velocityA) - FromJolt(velocityB), event.Normal));

		world.Buffer(event);
	}

	private static void OnContactRemoved(void* user, JPH_SubShapeIDPair* pair)
	{
		let world = (PhysicsWorld)Internal.UnsafeCastToObject(user);

		var event = ContactEvent();
		event.Kind = .End;
		event.BodyA = BodyId(pair.Body1ID);
		event.BodyB = BodyId(pair.Body2ID);

		// The user words are resolved BY ID, since a removal carries no bodies: this fires
		// for an already destroyed body too, and that side stays nought so a subsystem skips
		// it rather than acting on a corpse.
		//
		// The NO LOCK interface, because a contact callback already runs with the bodies
		// locked and taking them again would deadlock.
		let bodies = JPH_PhysicsSystem_GetBodyLockInterfaceNoLock(world.mSystem);
		event.UserA = world.UserDataOrZero(bodies, pair.Body1ID);
		event.UserB = world.UserDataOrZero(bodies, pair.Body2ID);

		world.Buffer(event);
	}

	private uint64 UserDataOrZero(JPH_BodyLockInterface* bodies, JPH_BodyID id)
	{
		var lock = JPH_BodyLockRead();
		JPH_BodyLockInterface_LockRead(bodies, id, &lock);
		defer JPH_BodyLockInterface_UnlockRead(bodies, &lock);
		return (lock.body != null) ? JPH_Body_GetUserData(lock.body) : 0;
	}

	/// Appends one event. Called from the backend's WORKER THREADS, which is the whole reason
	/// for the lock.
	private void Buffer(ContactEvent event)
	{
		using (mContactLock.Enter())
			mContacts.Add(event);
	}

	/// Moves everything buffered since the last drain. APPENDS, so a caller may drain several
	/// worlds into one list.
	public void DrainContacts(List<ContactEvent> outEvents)
	{
		using (mContactLock.Enter())
		{
			outEvents.AddRange(mContacts);
			mContacts.Clear();
		}
	}

	// ==================== characters ====================

	public CharacterId CreateCharacter(CharacterDesc desc)
	{
		var settings = JPH_CharacterVirtualSettings();
		JPH_CharacterVirtualSettings_Init(&settings);
		// Init hands back a default empty shape holding a reference, so replacing the pointer
		// below would strand it.
		if (settings.@base.shape != null)
			JPH_Shape_Destroy((JPH_Shape*)settings.@base.shape);

		let shape = (JPH_Shape*)JPH_CapsuleShape_Create(desc.CapsuleHalfHeight,
			desc.CapsuleRadius);
		if (shape == null)
			return .();
		defer JPH_Shape_Destroy(shape);

		settings.@base.shape = shape;
		// Support only under the BOTTOM sphere: standing on a ledge at waist height is not
		// standing on it.
		settings.@base.supportingVolume = .()
			{
				normal = .() { x = 0.0f, y = 1.0f, z = 0.0f },
				distance = -desc.CapsuleHalfHeight
			};
		settings.@base.maxSlopeAngle = desc.MaxSlopeDegrees * (JPH_M_PI / 180.0f);
		settings.mass = desc.Mass;
		settings.maxStrength = desc.MaxStrength;

		var position = ToJolt(desc.Position);
		var rotation = ToJolt(Quaternion.Identity);
		let character = JPH_CharacterVirtual_Create(&settings, &position, &rotation,
			desc.UserData, mSystem);
		if (character == null)
			return .();

		// The step settings are authored PER CHARACTER, so they ride the slot rather than
		// being a property of the world.
		let slot = CharacterSlot()
			{
				Character = character,
				StepUp = desc.StepUp,
				StepDown = desc.StepDown
			};

		for (int i = 0; i < mCharacters.Count; i++)
		{
			if (mCharacters[i].Character == null)
			{
				mCharacters[i] = slot;
				return CharacterId((uint32)i);
			}
		}
		mCharacters.Add(slot);
		return CharacterId((uint32)(mCharacters.Count - 1));
	}

	public void DestroyCharacter(CharacterId id)
	{
		if (!ResolveCharacter(id, let index))
			return;

		JPH_CharacterBase_Destroy((JPH_CharacterBase*)mCharacters[index].Character);
		mCharacters[index] = .();
	}

	private bool ResolveCharacter(CharacterId id, out int index)
	{
		index = (int)id.Value;
		return id.IsValid && (index < mCharacters.Count)
			&& (mCharacters[index].Character != null);
	}

	/// The FULL velocity for the coming update: the caller folds gravity and jumping in.
	public void SetCharacterVelocity(CharacterId id, Float3 velocity)
	{
		if (!ResolveCharacter(id, let index))
			return;
		var value = ToJolt(velocity);
		JPH_CharacterVirtual_SetLinearVelocity(mCharacters[index].Character, &value);
	}

	public Float3 CharacterVelocity(CharacterId id)
	{
		if (!ResolveCharacter(id, let index))
			return .(0, 0, 0);
		var value = JPH_Vec3();
		JPH_CharacterVirtual_GetLinearVelocity(mCharacters[index].Character, &value);
		return FromJolt(value);
	}

	/// The most it pushes a dynamic body with, in newtons. Set live each step, so an authored
	/// or inspector change takes effect; creating one seeds it too.
	public void SetCharacterStrength(CharacterId id, float strength)
	{
		if (!ResolveCharacter(id, let index))
			return;
		JPH_CharacterVirtual_SetMaxStrength(mCharacters[index].Character, strength);
	}

	/// Sweeps the character against the world: sliding, stairs and sticking to the floor.
	/// Once per fixed step, AFTER the step itself.
	public void UpdateCharacter(CharacterId id, float deltaTime)
	{
		if (!ResolveCharacter(id, let index))
			return;

		let slot = mCharacters[index];
		var settings = JPH_ExtendedUpdateSettings()
			{
				walkStairsStepUp = .() { x = 0.0f, y = slot.StepUp, z = 0.0f },
				stickToFloorStepDown = .() { x = 0.0f, y = -slot.StepDown, z = 0.0f },
				walkStairsMinStepForward = 0.02f,
				walkStairsStepForwardTest = 0.15f,
				walkStairsCosAngleForwardContact = Cos(75.0f * (JPH_M_PI / 180.0f)),
				walkStairsStepDownExtra = .()
			};

		// It sweeps against the DYNAMIC layer's filters, which is what a character collides
		// with; its own group is nought, since a character is not a designer group member.
		JPH_CharacterVirtual_ExtendedUpdate(slot.Character, deltaTime, &settings,
			PhysicsLayers.From(.Dynamic, 0), mSystem, null, null);
	}

	public Float3 CharacterPosition(CharacterId id)
	{
		if (!ResolveCharacter(id, let index))
			return .(0, 0, 0);
		var value = JPH_Vec3();
		JPH_CharacterVirtual_GetPosition(mCharacters[index].Character, &value);
		return FromJolt(value);
	}

	/// A teleport.
	public void SetCharacterPosition(CharacterId id, Float3 position)
	{
		if (!ResolveCharacter(id, let index))
			return;
		var value = ToJolt(position);
		JPH_CharacterVirtual_SetPosition(mCharacters[index].Character, &value);
	}

	public CharacterGround GetCharacterGround(CharacterId id)
	{
		if (!ResolveCharacter(id, let index))
			return .InAir;

		switch (JPH_CharacterBase_GetGroundState((JPH_CharacterBase*)mCharacters[index].Character))
		{
		case .JPH_GroundState_OnGround: return .OnGround;
		case .JPH_GroundState_OnSteepGround: return .OnSteepGround;
		case .JPH_GroundState_NotSupported: return .NotSupported;
		default: return .InAir;
		}
	}

	// ==================== joints ====================

	public JointId CreateJoint(JointDesc desc)
	{
		if (!desc.BodyA.IsValid)
			return .();

		// The NO LOCK interface: joints are created on the caller's thread outside a step,
		// which is the same contract a body's creation has.
		let bodies = JPH_PhysicsSystem_GetBodyLockInterfaceNoLock(mSystem);

		var lockA = JPH_BodyLockRead();
		JPH_BodyLockInterface_LockRead(bodies, desc.BodyA.Value, &lockA);
		defer JPH_BodyLockInterface_UnlockRead(bodies, &lockA);

		var lockB = JPH_BodyLockRead();
		if (desc.BodyB.IsValid)
			JPH_BodyLockInterface_LockRead(bodies, desc.BodyB.Value, &lockB);
		defer { if (desc.BodyB.IsValid) JPH_BodyLockInterface_UnlockRead(bodies, &lockB); }

		let bodyA = lockA.body;
		// An invalid second body anchors the joint to the WORLD, which the backend models as
		// a body that never moves.
		let bodyB = desc.BodyB.IsValid ? lockB.body : JPH_Body_GetFixedToWorldBody();
		if ((bodyA == null) || (bodyB == null))
			return .();

		var anchor = ToJolt(desc.Anchor);
		let axisLength = Length(desc.Axis);
		let axis = ToJolt((axisLength > 1.0e-12f) ? Normalized(desc.Axis) : Float3(0, 1, 0));
		// A minimum ABOVE the maximum is the unlimited spelling, so the limits are only
		// written when they actually bound something.
		let limited = desc.LimitMin <= desc.LimitMax;

		JPH_Constraint* joint = null;
		switch (desc.Kind)
		{
		case .Fixed:
			var settings = JPH_FixedConstraintSettings();
			JPH_FixedConstraintSettings_Init(&settings);
			settings.space = .JPH_ConstraintSpace_WorldSpace;
			settings.autoDetectPoint = true;
			joint = (JPH_Constraint*)JPH_FixedConstraint_Create(&settings, bodyA, bodyB);

		case .Point:
			var settings = JPH_PointConstraintSettings();
			JPH_PointConstraintSettings_Init(&settings);
			settings.space = .JPH_ConstraintSpace_WorldSpace;
			settings.point1 = anchor;
			settings.point2 = anchor;
			joint = (JPH_Constraint*)JPH_PointConstraint_Create(&settings, bodyA, bodyB);

		case .Hinge:
			var settings = JPH_HingeConstraintSettings();
			JPH_HingeConstraintSettings_Init(&settings);
			settings.space = .JPH_ConstraintSpace_WorldSpace;
			settings.point1 = anchor;
			settings.point2 = anchor;
			settings.hingeAxis1 = axis;
			settings.hingeAxis2 = axis;
			let normal = ToJolt(PerpendicularTo(FromJolt(axis)));
			settings.normalAxis1 = normal;
			settings.normalAxis2 = normal;
			if (limited)
			{
				settings.limitsMin = desc.LimitMin;
				settings.limitsMax = desc.LimitMax;
			}
			settings.motorSettings.minTorqueLimit = -desc.MotorLimit;
			settings.motorSettings.maxTorqueLimit = desc.MotorLimit;
			let hinge = JPH_HingeConstraint_Create(&settings, bodyA, bodyB);
			joint = (JPH_Constraint*)hinge;
			if ((hinge != null) && desc.MotorEnabled)
			{
				JPH_HingeConstraint_SetTargetAngularVelocity(hinge, desc.MotorTargetVelocity);
				JPH_HingeConstraint_SetMotorState(hinge, .JPH_MotorState_Velocity);
			}

		case .Slider:
			var settings = JPH_SliderConstraintSettings();
			JPH_SliderConstraintSettings_Init(&settings);
			settings.space = .JPH_ConstraintSpace_WorldSpace;
			settings.autoDetectPoint = true;
			var axisValue = axis;
			JPH_SliderConstraintSettings_SetSliderAxis(&settings, &axisValue);
			if (limited)
			{
				settings.limitsMin = desc.LimitMin;
				settings.limitsMax = desc.LimitMax;
			}
			settings.motorSettings.minForceLimit = -desc.MotorLimit;
			settings.motorSettings.maxForceLimit = desc.MotorLimit;
			let slider = JPH_SliderConstraint_Create(&settings, bodyA, bodyB);
			joint = (JPH_Constraint*)slider;
			if ((slider != null) && desc.MotorEnabled)
			{
				JPH_SliderConstraint_SetTargetVelocity(slider, desc.MotorTargetVelocity);
				JPH_SliderConstraint_SetMotorState(slider, .JPH_MotorState_Velocity);
			}

		case .Distance:
			var settings = JPH_DistanceConstraintSettings();
			JPH_DistanceConstraintSettings_Init(&settings);
			settings.space = .JPH_ConstraintSpace_WorldSpace;
			// Rope semantics: from each body's own centre, or from the anchor for the end
			// attached to the world.
			var centreA = JPH_Vec3();
			JPH_Body_GetCenterOfMassPosition(bodyA, &centreA);
			settings.point1 = centreA;
			if (desc.BodyB.IsValid)
			{
				var centreB = JPH_Vec3();
				JPH_Body_GetCenterOfMassPosition(bodyB, &centreB);
				settings.point2 = centreB;
			}
			else
			{
				settings.point2 = anchor;
			}
			settings.minDistance = desc.MinDistance;
			settings.maxDistance = desc.MaxDistance;
			joint = (JPH_Constraint*)JPH_DistanceConstraint_Create(&settings, bodyA, bodyB);
		}

		if (joint == null)
			return .();

		JPH_PhysicsSystem_AddConstraint(mSystem, joint);

		let slot = JointSlot()
			{
				Joint = joint,
				BodyA = desc.BodyA.Value,
				BodyB = desc.BodyB.IsValid ? desc.BodyB.Value : BodyId.Invalid
			};
		for (int i = 0; i < mJoints.Count; i++)
		{
			if (mJoints[i].Joint == null)
			{
				mJoints[i] = slot;
				return JointId((uint32)i);
			}
		}
		mJoints.Add(slot);
		return JointId((uint32)(mJoints.Count - 1));
	}

	public void DestroyJoint(JointId id)
	{
		if (!id.IsValid || ((int)id.Value >= mJoints.Count))
			return;

		let slot = mJoints[(int)id.Value];
		if (slot.Joint == null)
			return;

		// The connected bodies are WOKEN: one held asleep by the joint must answer to gravity
		// again once it is released, and removing the constraint alone leaves it sleeping.
		WakeJointBodies(slot);

		JPH_PhysicsSystem_RemoveConstraint(mSystem, slot.Joint);
		JPH_Constraint_Destroy(slot.Joint);
		mJoints[(int)id.Value] = .();
	}

	/// Drives the velocity motor on a hinge or a slider, and does nothing on any other kind.
	/// The target is radians per second for a hinge and metres per second for a slider.
	public void SetJointMotor(JointId id, bool enabled, float targetVelocity)
	{
		if (!id.IsValid || ((int)id.Value >= mJoints.Count))
			return;

		let joint = mJoints[(int)id.Value].Joint;
		if (joint == null)
			return;

		let state = enabled ? JPH_MotorState.JPH_MotorState_Velocity : JPH_MotorState.JPH_MotorState_Off;
		switch (JPH_Constraint_GetSubType(joint))
		{
		case .JPH_ConstraintSubType_Hinge:
			JPH_HingeConstraint_SetTargetAngularVelocity((JPH_HingeConstraint*)joint,
				targetVelocity);
			JPH_HingeConstraint_SetMotorState((JPH_HingeConstraint*)joint, state);
		case .JPH_ConstraintSubType_Slider:
			JPH_SliderConstraint_SetTargetVelocity((JPH_SliderConstraint*)joint, targetVelocity);
			JPH_SliderConstraint_SetMotorState((JPH_SliderConstraint*)joint, state);
		default:
			// No motor on this kind.
			return;
		}

		// A motor with real drive keeps its bodies AWAKE. One that fell asleep while the
		// target was nought, or before the motor was enabled, would otherwise ignore the
		// constraint and a live edit would do nothing. Only while actually driving, so a
		// settled motor can still sleep.
		//
		// BY ID off the slot, never through the constraint's own body pointers: those dangle
		// once a connected body is destroyed before the joint, and this is called every fixed
		// step. The same reason DestroyJoint wakes by id.
		if (enabled && (targetVelocity != 0.0f))
			WakeJointBodies(mJoints[(int)id.Value]);
	}

	/// Wakes a joint's surviving bodies. A dead id is refused by the interface rather than
	/// followed, which is the whole point of going through it.
	private void WakeJointBodies(JointSlot slot)
	{
		let bodies = Bodies;
		for (let bodyId in scope JPH_BodyID[](slot.BodyA, slot.BodyB))
		{
			if ((bodyId != BodyId.Invalid) && JPH_BodyInterface_IsAdded(bodies, bodyId)
				&& (JPH_BodyInterface_GetMotionType(bodies, bodyId) != .JPH_MotionType_Static))
				JPH_BodyInterface_ActivateBody(bodies, bodyId);
		}
	}

	/// A unit vector at right angles to the one given, which is the hinge's reference for its
	/// own limits. Any perpendicular will do; the axis' smallest component picks one that is
	/// numerically well conditioned.
	private static Float3 PerpendicularTo(Float3 axis)
	{
		let ax = Abs(axis.X);
		let ay = Abs(axis.Y);
		let az = Abs(axis.Z);
		let other = ((ax <= ay) && (ax <= az)) ? Float3(1, 0, 0)
			: (ay <= az) ? Float3(0, 1, 0) : Float3(0, 0, 1);
		return Normalized(Cross(axis, other));
	}
}
