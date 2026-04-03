namespace Sedulous.Physics.Jolt;

using System;
using System.Collections;
using joltc_Beef;
using Sedulous.Core.Mathematics;
using Sedulous.Physics;

/// Jolt Physics implementation of IPhysicsWorld.
class JoltPhysicsWorld : IPhysicsWorld
{
	// Jolt system handles
	private JPH_PhysicsSystem* mPhysicsSystem;
	private JPH_JobSystem* mJobSystem;
	private JPH_BodyInterface* mBodyInterface;
	private JPH_NarrowPhaseQuery* mNarrowPhaseQuery;

	// Layer configuration (owned)
	private JPH_BroadPhaseLayerInterface* mBroadPhaseLayerInterface;
	private JPH_ObjectLayerPairFilter* mObjectLayerPairFilter;
	private JPH_ObjectVsBroadPhaseLayerFilter* mObjectVsBroadPhaseLayerFilter;

	// Body handle management
	private List<JPH_BodyID> mBodyIds = new .() ~ delete _;
	private List<uint32> mBodyGenerations = new .() ~ delete _;
	private List<uint32> mFreeBodySlots = new .() ~ delete _;

	// Shape handle management
	private List<JPH_Shape*> mShapes = new .() ~ delete _;
	private List<uint32> mShapeGenerations = new .() ~ delete _;
	private List<uint32> mFreeShapeSlots = new .() ~ delete _;

	// Constraint handle management
	private List<JPH_Constraint*> mConstraints = new .() ~ delete _;
	private List<uint32> mConstraintGenerations = new .() ~ delete _;
	private List<uint32> mFreeConstraintSlots = new .() ~ delete _;

	// Character handle management
	private List<JPH_Character*> mCharacters = new .() ~ delete _;
	private List<uint32> mCharacterGenerations = new .() ~ delete _;
	private List<uint32> mFreeCharacterSlots = new .() ~ delete _;

	// Listeners
	private IContactListener mContactListener;
	private IBodyActivationListener mActivationListener;
	private JoltContactListener mJoltContactListener ~ delete _;
	private JoltBodyActivationListener mJoltActivationListener ~ delete _;

	// Layer constants
	private const JPH_ObjectLayer LAYER_STATIC = 0;
	private const JPH_ObjectLayer LAYER_DYNAMIC = 1;
	private const uint32 NUM_OBJECT_LAYERS = 2;
	private const uint32 NUM_BROAD_PHASE_LAYERS = 2;

	// === Properties ===

	public bool IsInitialized => mPhysicsSystem != null;

	public Vector3 Gravity
	{
		get
		{
			if (mPhysicsSystem == null)
				return .(0, -9.81f, 0);

			JPH_Vec3 gravity = default;
			JPH_PhysicsSystem_GetGravity(mPhysicsSystem, &gravity);
			return JoltConversions.ToVector3(gravity);
		}
		set
		{
			if (mPhysicsSystem != null)
			{
				var jphGravity = JoltConversions.ToJPHVec3(value);
				JPH_PhysicsSystem_SetGravity(mPhysicsSystem, &jphGravity);
			}
		}
	}

	public uint32 BodyCount => mPhysicsSystem != null ? JPH_PhysicsSystem_GetNumBodies(mPhysicsSystem) : 0;
	public uint32 ActiveBodyCount => mPhysicsSystem != null ? JPH_PhysicsSystem_GetNumActiveBodies(mPhysicsSystem, .JPH_BodyType_Rigid) : 0;
	public uint32 ConstraintCount => (uint32)(mConstraints.Count - mFreeConstraintSlots.Count);

	// === Initialization ===

	/// Creates a new Jolt physics world.
	public static Result<JoltPhysicsWorld> Create(PhysicsWorldDescriptor desc)
	{
		let world = new JoltPhysicsWorld();
		if (world.Initialize(desc) case .Err)
		{
			delete world;
			return .Err;
		}
		return world;
	}

	private Result<void> Initialize(PhysicsWorldDescriptor desc)
	{
		// Initialize Jolt
		if (!JPH_Init())
			return .Err;

		// Create job system
		JobSystemThreadPoolConfig jobConfig = .();
		jobConfig.maxJobs = JPH_MAX_PHYSICS_JOBS;
		jobConfig.maxBarriers = JPH_MAX_PHYSICS_BARRIERS;
		jobConfig.numThreads = -1; // Auto-detect
		mJobSystem = JPH_JobSystemThreadPool_Create(&jobConfig);
		if (mJobSystem == null)
			return .Err;

		// Setup collision layers
		SetupLayers();

		// Create physics system
		JPH_PhysicsSystemSettings settings = .();
		settings.maxBodies = desc.MaxBodies;
		settings.numBodyMutexes = 0;
		settings.maxBodyPairs = desc.MaxBodyPairs;
		settings.maxContactConstraints = desc.MaxContactConstraints;
		settings.broadPhaseLayerInterface = mBroadPhaseLayerInterface;
		settings.objectLayerPairFilter = mObjectLayerPairFilter;
		settings.objectVsBroadPhaseLayerFilter = mObjectVsBroadPhaseLayerFilter;

		mPhysicsSystem = JPH_PhysicsSystem_Create(&settings);
		if (mPhysicsSystem == null)
			return .Err;

		// Get interfaces
		mBodyInterface = JPH_PhysicsSystem_GetBodyInterface(mPhysicsSystem);
		mNarrowPhaseQuery = JPH_PhysicsSystem_GetNarrowPhaseQuery(mPhysicsSystem);

		// Set gravity
		Gravity = desc.Gravity;

		return .Ok;
	}

	private void SetupLayers()
	{
		// Create broad phase layer interface (maps object layers to broad phase layers)
		mBroadPhaseLayerInterface = JPH_BroadPhaseLayerInterfaceTable_Create(NUM_OBJECT_LAYERS, NUM_BROAD_PHASE_LAYERS);
		JPH_BroadPhaseLayerInterfaceTable_MapObjectToBroadPhaseLayer(mBroadPhaseLayerInterface, LAYER_STATIC, 0);
		JPH_BroadPhaseLayerInterfaceTable_MapObjectToBroadPhaseLayer(mBroadPhaseLayerInterface, LAYER_DYNAMIC, 1);

		// Create object layer pair filter (which object layers collide)
		mObjectLayerPairFilter = JPH_ObjectLayerPairFilterTable_Create(NUM_OBJECT_LAYERS);
		JPH_ObjectLayerPairFilterTable_EnableCollision(mObjectLayerPairFilter, LAYER_STATIC, LAYER_DYNAMIC);
		JPH_ObjectLayerPairFilterTable_EnableCollision(mObjectLayerPairFilter, LAYER_DYNAMIC, LAYER_DYNAMIC);

		// Create object vs broad phase filter
		mObjectVsBroadPhaseLayerFilter = JPH_ObjectVsBroadPhaseLayerFilterTable_Create(
			mBroadPhaseLayerInterface, NUM_BROAD_PHASE_LAYERS,
			mObjectLayerPairFilter, NUM_OBJECT_LAYERS);
	}

	public void Dispose()
	{
		// Destroy all characters first (they have body references)
		for (let character in mCharacters)
		{
			if (character != null)
			{
				JPH_Character_RemoveFromPhysicsSystem(character, true);
				JPH_CharacterBase_Destroy((JPH_CharacterBase*)character);
			}
		}
		mCharacters.Clear();
		mCharacterGenerations.Clear();
		mFreeCharacterSlots.Clear();

		// Destroy all constraints (they reference bodies)
		for (let constraint in mConstraints)
		{
			if (constraint != null)
			{
				JPH_PhysicsSystem_RemoveConstraint(mPhysicsSystem, constraint);
				JPH_Constraint_Destroy(constraint);
			}
		}
		mConstraints.Clear();
		mConstraintGenerations.Clear();
		mFreeConstraintSlots.Clear();

		// Destroy all bodies
		for (let bodyId in mBodyIds)
		{
			if (bodyId != 0)
				JPH_BodyInterface_RemoveAndDestroyBody(mBodyInterface, bodyId);
		}
		mBodyIds.Clear();
		mBodyGenerations.Clear();
		mFreeBodySlots.Clear();

		// Destroy all shapes
		for (let shape in mShapes)
		{
			if (shape != null)
				JPH_Shape_Destroy(shape);
		}
		mShapes.Clear();
		mShapeGenerations.Clear();
		mFreeShapeSlots.Clear();

		// Note: Layer filters are destroyed with the physics system

		// Destroy physics system
		if (mPhysicsSystem != null)
		{
			JPH_PhysicsSystem_Destroy(mPhysicsSystem);
			mPhysicsSystem = null;
		}

		// Destroy job system
		if (mJobSystem != null)
		{
			JPH_JobSystem_Destroy(mJobSystem);
			mJobSystem = null;
		}

		// Shutdown Jolt
		JPH_Shutdown();
	}

	// === Body Management ===

	public Result<BodyHandle> CreateBody(PhysicsBodyDescriptor descriptor)
	{
		if (mPhysicsSystem == null || !descriptor.Shape.IsValid)
			return .Err;

		// Get JPH shape
		let shape = GetJPHShape(descriptor.Shape);
		if (shape == null)
			return .Err;

		// Convert motion type
		let motionType = JoltConversions.ToJPHMotionType(descriptor.BodyType);

		// Object layer: 0 = Static, 1 = Dynamic/Kinematic
		JPH_ObjectLayer objectLayer = (descriptor.BodyType == .Static) ? LAYER_STATIC : LAYER_DYNAMIC;

		// Create body settings
		var position = JoltConversions.ToJPHRVec3(descriptor.Position);
		var rotation = JoltConversions.ToJPHQuat(descriptor.Rotation);

		let bodySettings = JPH_BodyCreationSettings_Create3(shape, &position, &rotation, motionType, objectLayer);
		if (bodySettings == null)
			return .Err;

		// Set properties
		JPH_BodyCreationSettings_SetFriction(bodySettings, descriptor.Friction);
		JPH_BodyCreationSettings_SetRestitution(bodySettings, descriptor.Restitution);
		JPH_BodyCreationSettings_SetLinearDamping(bodySettings, descriptor.LinearDamping);
		JPH_BodyCreationSettings_SetAngularDamping(bodySettings, descriptor.AngularDamping);
		JPH_BodyCreationSettings_SetGravityFactor(bodySettings, descriptor.GravityFactor);
		JPH_BodyCreationSettings_SetIsSensor(bodySettings, descriptor.IsSensor);
		JPH_BodyCreationSettings_SetAllowSleeping(bodySettings, descriptor.AllowSleep);
		JPH_BodyCreationSettings_SetUserData(bodySettings, descriptor.UserData);

		if (descriptor.LinearVelocity != .Zero)
		{
			var vel = JoltConversions.ToJPHVec3(descriptor.LinearVelocity);
			JPH_BodyCreationSettings_SetLinearVelocity(bodySettings, &vel);
		}

		if (descriptor.AngularVelocity != .Zero)
		{
			var vel = JoltConversions.ToJPHVec3(descriptor.AngularVelocity);
			JPH_BodyCreationSettings_SetAngularVelocity(bodySettings, &vel);
		}

		// Mass override
		if (descriptor.Mass > 0)
		{
			JPH_BodyCreationSettings_SetOverrideMassProperties(bodySettings, .JPH_OverrideMassProperties_CalculateInertia);
			var massProps = JPH_MassProperties();
			massProps.mass = descriptor.Mass;
			JPH_BodyCreationSettings_SetMassPropertiesOverride(bodySettings, &massProps);
		}

		// Allowed degrees of freedom
		if (descriptor.AllowedDOFs != .All)
			JPH_BodyCreationSettings_SetAllowedDOFs(bodySettings, (JPH_AllowedDOFs)(int32)descriptor.AllowedDOFs);

		// Create and add body
		let bodyId = JPH_BodyInterface_CreateAndAddBody(mBodyInterface, bodySettings, .JPH_Activation_Activate);
		JPH_BodyCreationSettings_Destroy(bodySettings);

		if (bodyId == 0)
			return .Err;

		// Allocate handle
		let handle = AllocateBodyHandle(bodyId);
		return handle;
	}

	public void DestroyBody(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		if (bodyId != 0)
		{
			JPH_BodyInterface_RemoveAndDestroyBody(mBodyInterface, bodyId);
			mBodyIds[(int)handle.Index] = 0;
			mFreeBodySlots.Add(handle.Index);
		}
	}

	public bool IsValidBody(BodyHandle handle) => ValidateBodyHandle(handle);

	public Vector3 GetBodyPosition(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return .Zero;

		let bodyId = mBodyIds[(int)handle.Index];
		JPH_RVec3 position = default;
		JPH_BodyInterface_GetPosition(mBodyInterface, bodyId, &position);
		return JoltConversions.ToVector3(position);
	}

	public Quaternion GetBodyRotation(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return .Identity;

		let bodyId = mBodyIds[(int)handle.Index];
		JPH_Quat rotation = default;
		JPH_BodyInterface_GetRotation(mBodyInterface, bodyId, &rotation);
		return JoltConversions.ToQuaternion(rotation);
	}

	public void SetBodyTransform(BodyHandle handle, Vector3 position, Quaternion rotation, bool activate = true)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		var jphPos = JoltConversions.ToJPHRVec3(position);
		var jphRot = JoltConversions.ToJPHQuat(rotation);
		let activation = JoltConversions.ToJPHActivation(activate);

		JPH_BodyInterface_SetPositionAndRotation(mBodyInterface, bodyId, &jphPos, &jphRot, activation);
	}

	public Vector3 GetLinearVelocity(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return .Zero;

		let bodyId = mBodyIds[(int)handle.Index];
		JPH_Vec3 velocity = default;
		JPH_BodyInterface_GetLinearVelocity(mBodyInterface, bodyId, &velocity);
		return JoltConversions.ToVector3(velocity);
	}

	public void SetLinearVelocity(BodyHandle handle, Vector3 velocity)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		var jphVel = JoltConversions.ToJPHVec3(velocity);
		JPH_BodyInterface_SetLinearVelocity(mBodyInterface, bodyId, &jphVel);
	}

	public Vector3 GetAngularVelocity(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return .Zero;

		let bodyId = mBodyIds[(int)handle.Index];
		JPH_Vec3 velocity = default;
		JPH_BodyInterface_GetAngularVelocity(mBodyInterface, bodyId, &velocity);
		return JoltConversions.ToVector3(velocity);
	}

	public void SetAngularVelocity(BodyHandle handle, Vector3 velocity)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		var jphVel = JoltConversions.ToJPHVec3(velocity);
		JPH_BodyInterface_SetAngularVelocity(mBodyInterface, bodyId, &jphVel);
	}

	public void AddForce(BodyHandle handle, Vector3 force)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		var jphForce = JoltConversions.ToJPHVec3(force);
		JPH_BodyInterface_AddForce(mBodyInterface, bodyId, &jphForce);
	}

	public void AddForceAtPosition(BodyHandle handle, Vector3 force, Vector3 position)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		var jphForce = JoltConversions.ToJPHVec3(force);
		var jphPos = JoltConversions.ToJPHRVec3(position);
		JPH_BodyInterface_AddForce2(mBodyInterface, bodyId, &jphForce, &jphPos);
	}

	public void AddTorque(BodyHandle handle, Vector3 torque)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		var jphTorque = JoltConversions.ToJPHVec3(torque);
		JPH_BodyInterface_AddTorque(mBodyInterface, bodyId, &jphTorque);
	}

	public void AddImpulse(BodyHandle handle, Vector3 impulse)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		var jphImpulse = JoltConversions.ToJPHVec3(impulse);
		JPH_BodyInterface_AddImpulse(mBodyInterface, bodyId, &jphImpulse);
	}

	public void AddImpulseAtPosition(BodyHandle handle, Vector3 impulse, Vector3 position)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		var jphImpulse = JoltConversions.ToJPHVec3(impulse);
		var jphPos = JoltConversions.ToJPHRVec3(position);
		JPH_BodyInterface_AddImpulse2(mBodyInterface, bodyId, &jphImpulse, &jphPos);
	}

	public void ActivateBody(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		JPH_BodyInterface_ActivateBody(mBodyInterface, bodyId);
	}

	public void DeactivateBody(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		JPH_BodyInterface_DeactivateBody(mBodyInterface, bodyId);
	}

	public bool IsBodyActive(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return false;

		let bodyId = mBodyIds[(int)handle.Index];
		return JPH_BodyInterface_IsActive(mBodyInterface, bodyId);
	}

	public void SetBodyType(BodyHandle handle, BodyType bodyType)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		let motionType = JoltConversions.ToJPHMotionType(bodyType);
		JPH_BodyInterface_SetMotionType(mBodyInterface, bodyId, motionType, .JPH_Activation_Activate);
	}

	public BodyType GetBodyType(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return .Static;

		let bodyId = mBodyIds[(int)handle.Index];
		let motionType = JPH_BodyInterface_GetMotionType(mBodyInterface, bodyId);
		return JoltConversions.ToBodyType(motionType);
	}

	public void SetBodyMass(BodyHandle handle, float mass)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let body = GetJPHBody(handle);
		if (body == null)
			return;

		let motionProps = JPH_Body_GetMotionProperties(body);
		if (motionProps != null)
			JPH_MotionProperties_SetInverseMass(motionProps, mass > 0 ? 1.0f / mass : 0);
	}

	public float GetBodyMass(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return 1.0f;

		let body = GetJPHBody(handle);
		if (body == null)
			return 1.0f;

		let motionProps = JPH_Body_GetMotionProperties(body);
		if (motionProps == null)
			return 0;  // Static body

		let invMass = JPH_MotionProperties_GetInverseMassUnchecked(motionProps);
		return invMass > 0 ? 1.0f / invMass : 0;
	}

	public void SetBodyLinearDamping(BodyHandle handle, float damping)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let body = GetJPHBody(handle);
		if (body == null)
			return;

		let motionProps = JPH_Body_GetMotionProperties(body);
		if (motionProps != null)
			JPH_MotionProperties_SetLinearDamping(motionProps, damping);
	}

	public float GetBodyLinearDamping(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return 0;

		let body = GetJPHBody(handle);
		if (body == null)
			return 0;

		let motionProps = JPH_Body_GetMotionProperties(body);
		if (motionProps == null)
			return 0;

		return JPH_MotionProperties_GetLinearDamping(motionProps);
	}

	public void SetBodyAngularDamping(BodyHandle handle, float damping)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let body = GetJPHBody(handle);
		if (body == null)
			return;

		let motionProps = JPH_Body_GetMotionProperties(body);
		if (motionProps != null)
			JPH_MotionProperties_SetAngularDamping(motionProps, damping);
	}

	public float GetBodyAngularDamping(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return 0;

		let body = GetJPHBody(handle);
		if (body == null)
			return 0;

		let motionProps = JPH_Body_GetMotionProperties(body);
		if (motionProps == null)
			return 0;

		return JPH_MotionProperties_GetAngularDamping(motionProps);
	}

	public void SetBodyFriction(BodyHandle handle, float friction)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		JPH_BodyInterface_SetFriction(mBodyInterface, bodyId, friction);
	}

	public float GetBodyFriction(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return 0;

		let bodyId = mBodyIds[(int)handle.Index];
		return JPH_BodyInterface_GetFriction(mBodyInterface, bodyId);
	}

	public void SetBodyRestitution(BodyHandle handle, float restitution)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		JPH_BodyInterface_SetRestitution(mBodyInterface, bodyId, restitution);
	}

	public float GetBodyRestitution(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return 0;

		let bodyId = mBodyIds[(int)handle.Index];
		return JPH_BodyInterface_GetRestitution(mBodyInterface, bodyId);
	}

	public void SetBodyGravityFactor(BodyHandle handle, float factor)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		JPH_BodyInterface_SetGravityFactor(mBodyInterface, bodyId, factor);
	}

	public float GetBodyGravityFactor(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return 1.0f;

		let bodyId = mBodyIds[(int)handle.Index];
		return JPH_BodyInterface_GetGravityFactor(mBodyInterface, bodyId);
	}

	public void SetBodyUserData(BodyHandle handle, uint64 userData)
	{
		if (!ValidateBodyHandle(handle))
			return;

		let bodyId = mBodyIds[(int)handle.Index];
		JPH_BodyInterface_SetUserData(mBodyInterface, bodyId, userData);
	}

	public uint64 GetBodyUserData(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return 0;

		let bodyId = mBodyIds[(int)handle.Index];
		return JPH_BodyInterface_GetUserData(mBodyInterface, bodyId);
	}

	// === Shape Management ===

	public Result<ShapeHandle> CreateSphereShape(float radius)
	{
		let shape = JPH_SphereShape_Create(radius);
		if (shape == null)
			return .Err;

		return AllocateShapeHandle((.)shape);
	}

	public Result<ShapeHandle> CreateBoxShape(Vector3 halfExtents)
	{
		var jphHalfExtents = JoltConversions.ToJPHVec3(halfExtents);
		let shape = JPH_BoxShape_Create(&jphHalfExtents, JPH_DEFAULT_CONVEX_RADIUS);
		if (shape == null)
			return .Err;

		return AllocateShapeHandle((.)shape);
	}

	public Result<ShapeHandle> CreateCapsuleShape(float halfHeight, float radius)
	{
		let shape = JPH_CapsuleShape_Create(halfHeight, radius);
		if (shape == null)
			return .Err;

		return AllocateShapeHandle((.)shape);
	}

	public Result<ShapeHandle> CreateCylinderShape(float halfHeight, float radius)
	{
		let shape = JPH_CylinderShape_Create(halfHeight, radius);
		if (shape == null)
			return .Err;

		return AllocateShapeHandle((.)shape);
	}

	public Result<ShapeHandle> CreateConvexHullShape(Span<Vector3> points)
	{
		// Convert points to JPH_Vec3 array
		let jphPoints = new JPH_Vec3[points.Length];
		defer delete jphPoints;

		for (int i = 0; i < points.Length; i++)
			jphPoints[i] = JoltConversions.ToJPHVec3(points[i]);

		// Create convex hull settings
		let settings = JPH_ConvexHullShapeSettings_Create(jphPoints.CArray(), (uint32)points.Length, JPH_DEFAULT_CONVEX_RADIUS);
		if (settings == null)
			return .Err;

		let shape = JPH_ConvexHullShapeSettings_CreateShape(settings);
		JPH_ShapeSettings_Destroy((.)settings);

		if (shape == null)
			return .Err;

		return AllocateShapeHandle((JPH_Shape*)shape);
	}

	public Result<ShapeHandle> CreatePlaneShape(Vector3 normal, float distance, float halfExtent = 1000.0f)
	{
		var jphPlane = JPH_Plane();
		jphPlane.normal = JoltConversions.ToJPHVec3(normal);
		jphPlane.distance = distance;

		let shape = JPH_PlaneShape_Create(&jphPlane, null, halfExtent);
		if (shape == null)
			return .Err;

		return AllocateShapeHandle((JPH_Shape*)shape);
	}

	public Result<ShapeHandle> CreateMeshShape(Span<Vector3> vertices, Span<uint32> indices)
	{
		// Convert vertices to JPH_Vec3 array
		let jphVertices = new JPH_Vec3[vertices.Length];
		defer delete jphVertices;

		for (int i = 0; i < vertices.Length; i++)
			jphVertices[i] = JoltConversions.ToJPHVec3(vertices[i]);

		// Build indexed triangles from indices
		let triangleCount = (uint32)(indices.Length / 3);
		let jphTriangles = new JPH_IndexedTriangle[triangleCount];
		defer delete jphTriangles;

		for (uint32 i = 0; i < triangleCount; i++)
		{
			jphTriangles[i].i1 = indices[(int)(i * 3)];
			jphTriangles[i].i2 = indices[(int)(i * 3 + 1)];
			jphTriangles[i].i3 = indices[(int)(i * 3 + 2)];
			jphTriangles[i].materialIndex = 0;
			jphTriangles[i].userData = 0;
		}

		// Create mesh settings using Create2 for indexed triangles
		let settings = JPH_MeshShapeSettings_Create2(jphVertices.CArray(), (uint32)vertices.Length,
			jphTriangles.CArray(), triangleCount);
		if (settings == null)
			return .Err;

		let shape = JPH_MeshShapeSettings_CreateShape(settings);
		JPH_ShapeSettings_Destroy((.)settings);

		if (shape == null)
			return .Err;

		return AllocateShapeHandle((JPH_Shape*)shape);
	}

	public void ReleaseShape(ShapeHandle handle)
	{
		if (!ValidateShapeHandle(handle))
			return;

		let shape = mShapes[(int)handle.Index];
		if (shape != null)
		{
			JPH_Shape_Destroy(shape);
			mShapes[(int)handle.Index] = null;
			mFreeShapeSlots.Add(handle.Index);
		}
	}

	// === Queries ===

	public bool RayCast(RayCastQuery query, out RayCastResult result, IQueryFilter filter = null)
	{
		result = default;

		if (mNarrowPhaseQuery == null)
			return false;

		var origin = JoltConversions.ToJPHRVec3(query.Origin);
		var direction = JoltConversions.ToJPHVec3(query.Direction * query.MaxDistance);
		JPH_RayCastResult jphResult = default;

		if (JPH_NarrowPhaseQuery_CastRay(mNarrowPhaseQuery, &origin, &direction, &jphResult, null, null, null))
		{
			result.Body = GetBodyHandleFromId(jphResult.bodyID);
			result.Fraction = jphResult.fraction;
			result.Distance = query.MaxDistance * jphResult.fraction;
			result.Position = query.Origin + query.Direction * result.Distance;

			// Get user data
			if (result.Body.IsValid)
				result.UserData = GetBodyUserData(result.Body);

			// Note: Normal would require additional query - simplified for now
			result.Normal = -query.Direction;

			return true;
		}

		return false;
	}

	public void RayCastAll(RayCastQuery query, List<RayCastResult> results, IQueryFilter filter = null)
	{
		if (mNarrowPhaseQuery == null)
			return;

		var origin = JoltConversions.ToJPHRVec3(query.Origin);
		var direction = JoltConversions.ToJPHVec3(query.Direction * query.MaxDistance);

		// Use callback-based raycast for multiple hits
		RayCastAllContext context;
		context.World = this;
		context.Results = results;
		context.Query = query;
		context.Filter = filter;

		JPH_NarrowPhaseQuery_CastRay3(mNarrowPhaseQuery, &origin, &direction,
			null, // RayCastSettings
			.JPH_CollisionCollectorType_AllHit,
			=> RayCastAllCallback, &context,
			null, null, null, null);
	}

	private struct RayCastAllContext
	{
		public JoltPhysicsWorld World;
		public List<RayCastResult> Results;
		public RayCastQuery Query;
		public IQueryFilter Filter;
	}

	private static void RayCastAllCallback(void* context, JPH_RayCastResult* jphResult)
	{
		var ctx = (RayCastAllContext*)context;

		let bodyHandle = ctx.World.GetBodyHandleFromId(jphResult.bodyID);
		if (!bodyHandle.IsValid)
			return;

		// Apply filter if present
		if (ctx.Filter != null && !ctx.Filter.ShouldInclude(bodyHandle))
			return;

		RayCastResult result;
		result.Body = bodyHandle;
		result.Fraction = jphResult.fraction;
		result.Distance = ctx.Query.MaxDistance * jphResult.fraction;
		result.Position = ctx.Query.Origin + ctx.Query.Direction * result.Distance;
		result.Normal = -ctx.Query.Direction; // Simplified
		result.UserData = ctx.World.GetBodyUserData(bodyHandle);

		ctx.Results.Add(result);
	}

	public bool ShapeCast(ShapeCastQuery query, out ShapeCastResult result, IQueryFilter filter = null)
	{
		result = default;

		if (mNarrowPhaseQuery == null || !query.Shape.IsValid)
			return false;

		let shape = GetJPHShape(query.Shape);
		if (shape == null)
			return false;

		var worldTransform = JoltConversions.ToJPHMat4(query.Position, query.Rotation);
		var direction = JoltConversions.ToJPHVec3(query.Direction * query.MaxDistance);
		var baseOffset = JoltConversions.ToJPHRVec3(.Zero);

		JPH_ShapeCastSettings settings = default;
		JPH_ShapeCastSettings_Init(&settings);

		// Context for capturing result
		ShapeCastContext context;
		context.World = this;
		context.Result = &result;
		context.Filter = filter;
		context.FoundHit = false;
		context.BestFraction = float.MaxValue;

		JPH_NarrowPhaseQuery_CastShape2(mNarrowPhaseQuery,
			shape, &worldTransform, &direction,
			&settings, &baseOffset,
			.JPH_CollisionCollectorType_ClosestHit,
			=> ShapeCastCallback, &context,
			null, null, null, null);

		return context.FoundHit;
	}

	public void ShapeCastAll(ShapeCastQuery query, List<ShapeCastResult> results, IQueryFilter filter = null)
	{
		if (mNarrowPhaseQuery == null || !query.Shape.IsValid)
			return;

		let shape = GetJPHShape(query.Shape);
		if (shape == null)
			return;

		var worldTransform = JoltConversions.ToJPHMat4(query.Position, query.Rotation);
		var direction = JoltConversions.ToJPHVec3(query.Direction * query.MaxDistance);
		var baseOffset = JoltConversions.ToJPHRVec3(.Zero);

		JPH_ShapeCastSettings settings = default;
		JPH_ShapeCastSettings_Init(&settings);

		ShapeCastAllContext context;
		context.World = this;
		context.Results = results;
		context.Filter = filter;

		JPH_NarrowPhaseQuery_CastShape2(mNarrowPhaseQuery,
			shape, &worldTransform, &direction,
			&settings, &baseOffset,
			.JPH_CollisionCollectorType_AllHit,
			=> ShapeCastAllCallback, &context,
			null, null, null, null);
	}

	private struct ShapeCastContext
	{
		public JoltPhysicsWorld World;
		public ShapeCastResult* Result;
		public IQueryFilter Filter;
		public bool FoundHit;
		public float BestFraction;
	}

	private struct ShapeCastAllContext
	{
		public JoltPhysicsWorld World;
		public List<ShapeCastResult> Results;
		public IQueryFilter Filter;
	}

	private static void ShapeCastCallback(void* context, JPH_ShapeCastResult* jphResult)
	{
		var ctx = (ShapeCastContext*)context;

		let bodyHandle = ctx.World.GetBodyHandleFromId(jphResult.bodyID2);
		if (!bodyHandle.IsValid)
			return;

		// Apply filter if present
		if (ctx.Filter != null && !ctx.Filter.ShouldInclude(bodyHandle))
			return;

		// Keep closest hit
		if (jphResult.fraction < ctx.BestFraction)
		{
			ctx.BestFraction = jphResult.fraction;
			ctx.FoundHit = true;

			ctx.Result.Body = bodyHandle;
			ctx.Result.ContactPointOn1 = JoltConversions.ToVector3(jphResult.contactPointOn1);
			ctx.Result.ContactPointOn2 = JoltConversions.ToVector3(jphResult.contactPointOn2);
			ctx.Result.PenetrationAxis = JoltConversions.ToVector3(jphResult.penetrationAxis);
			ctx.Result.PenetrationDepth = jphResult.penetrationDepth;
			ctx.Result.Fraction = jphResult.fraction;
			ctx.Result.UserData = ctx.World.GetBodyUserData(bodyHandle);
		}
	}

	private static void ShapeCastAllCallback(void* context, JPH_ShapeCastResult* jphResult)
	{
		var ctx = (ShapeCastAllContext*)context;

		let bodyHandle = ctx.World.GetBodyHandleFromId(jphResult.bodyID2);
		if (!bodyHandle.IsValid)
			return;

		// Apply filter if present
		if (ctx.Filter != null && !ctx.Filter.ShouldInclude(bodyHandle))
			return;

		ShapeCastResult result;
		result.Body = bodyHandle;
		result.ContactPointOn1 = JoltConversions.ToVector3(jphResult.contactPointOn1);
		result.ContactPointOn2 = JoltConversions.ToVector3(jphResult.contactPointOn2);
		result.PenetrationAxis = JoltConversions.ToVector3(jphResult.penetrationAxis);
		result.PenetrationDepth = jphResult.penetrationDepth;
		result.Fraction = jphResult.fraction;
		result.UserData = ctx.World.GetBodyUserData(bodyHandle);

		ctx.Results.Add(result);
	}

	// === Simulation ===

	public void Step(float deltaTime, int32 collisionSteps = 1)
	{
		if (mPhysicsSystem == null || mJobSystem == null)
			return;

		JPH_PhysicsSystem_Update(mPhysicsSystem, deltaTime, collisionSteps, mJobSystem);
	}

	public void SetContactListener(IContactListener listener)
	{
		mContactListener = listener;

		// Remove old listener
		if (mJoltContactListener != null)
		{
			JPH_PhysicsSystem_SetContactListener(mPhysicsSystem, null);
			delete mJoltContactListener;
			mJoltContactListener = null;
		}

		// Create new wrapper if listener provided
		if (listener != null && mPhysicsSystem != null)
		{
			mJoltContactListener = new JoltContactListener(this, listener);
			JPH_PhysicsSystem_SetContactListener(mPhysicsSystem, mJoltContactListener.GetHandle());
		}
	}

	public void SetBodyActivationListener(IBodyActivationListener listener)
	{
		mActivationListener = listener;

		// Remove old listener
		if (mJoltActivationListener != null)
		{
			JPH_PhysicsSystem_SetBodyActivationListener(mPhysicsSystem, null);
			delete mJoltActivationListener;
			mJoltActivationListener = null;
		}

		// Create new wrapper if listener provided
		if (listener != null && mPhysicsSystem != null)
		{
			mJoltActivationListener = new JoltBodyActivationListener(this, listener);
			JPH_PhysicsSystem_SetBodyActivationListener(mPhysicsSystem, mJoltActivationListener.GetHandle());
		}
	}

	public void OptimizeBroadPhase()
	{
		if (mPhysicsSystem != null)
			JPH_PhysicsSystem_OptimizeBroadPhase(mPhysicsSystem);
	}

	// === Handle Management ===

	private BodyHandle AllocateBodyHandle(JPH_BodyID bodyId)
	{
		uint32 index;
		uint32 generation;

		if (mFreeBodySlots.Count > 0)
		{
			index = mFreeBodySlots.PopBack();
			generation = mBodyGenerations[(int)index] + 1;
			mBodyGenerations[(int)index] = generation;
			mBodyIds[(int)index] = bodyId;
		}
		else
		{
			index = (uint32)mBodyIds.Count;
			generation = 1;
			mBodyIds.Add(bodyId);
			mBodyGenerations.Add(generation);
		}

		return .(index, generation);
	}

	private bool ValidateBodyHandle(BodyHandle handle)
	{
		if (!handle.IsValid)
			return false;
		if (handle.Index >= (uint32)mBodyIds.Count)
			return false;
		if (mBodyGenerations[(int)handle.Index] != handle.Generation)
			return false;
		if (mBodyIds[(int)handle.Index] == 0)
			return false;
		return true;
	}

	private ShapeHandle AllocateShapeHandle(JPH_Shape* shape)
	{
		uint32 index;
		uint32 generation;

		if (mFreeShapeSlots.Count > 0)
		{
			index = mFreeShapeSlots.PopBack();
			generation = mShapeGenerations[(int)index] + 1;
			mShapeGenerations[(int)index] = generation;
			mShapes[(int)index] = shape;
		}
		else
		{
			index = (uint32)mShapes.Count;
			generation = 1;
			mShapes.Add(shape);
			mShapeGenerations.Add(generation);
		}

		return .(index, generation);
	}

	private bool ValidateShapeHandle(ShapeHandle handle)
	{
		if (!handle.IsValid)
			return false;
		if (handle.Index >= (uint32)mShapes.Count)
			return false;
		if (mShapeGenerations[(int)handle.Index] != handle.Generation)
			return false;
		if (mShapes[(int)handle.Index] == null)
			return false;
		return true;
	}

	private JPH_Shape* GetJPHShape(ShapeHandle handle)
	{
		if (!ValidateShapeHandle(handle))
			return null;
		return mShapes[(int)handle.Index];
	}

	private BodyHandle GetBodyHandleFromId(JPH_BodyID bodyId)
	{
		for (int i = 0; i < mBodyIds.Count; i++)
		{
			if (mBodyIds[i] == bodyId)
				return .((uint32)i, mBodyGenerations[i]);
		}
		return .Invalid;
	}

	// === Constraints ===

	public Result<ConstraintHandle> CreateFixedConstraint(FixedConstraintDescriptor descriptor)
	{
		if (mPhysicsSystem == null)
			return .Err;

		let body1 = GetJPHBody(descriptor.Body1);
		let body2 = GetJPHBody(descriptor.Body2);
		if (body1 == null || body2 == null)
			return .Err;

		JPH_FixedConstraintSettings settings = .();
		settings.@base.enabled = true;
		settings.space = descriptor.UseWorldSpace ? .JPH_ConstraintSpace_WorldSpace : .JPH_ConstraintSpace_LocalToBodyCOM;
		settings.point1 = JoltConversions.ToJPHRVec3(descriptor.Point1);
		settings.point2 = JoltConversions.ToJPHRVec3(descriptor.Point2);
		settings.axisX1 = JoltConversions.ToJPHVec3(descriptor.AxisX1);
		settings.axisY1 = JoltConversions.ToJPHVec3(descriptor.AxisY1);
		settings.axisX2 = JoltConversions.ToJPHVec3(descriptor.AxisX2);
		settings.axisY2 = JoltConversions.ToJPHVec3(descriptor.AxisY2);

		let constraint = JPH_FixedConstraint_Create(&settings, body1, body2);
		if (constraint == null)
			return .Err;

		JPH_PhysicsSystem_AddConstraint(mPhysicsSystem, (JPH_Constraint*)constraint);

		return AllocateConstraintHandle((JPH_Constraint*)constraint);
	}

	public Result<ConstraintHandle> CreatePointConstraint(PointConstraintDescriptor descriptor)
	{
		if (mPhysicsSystem == null)
			return .Err;

		let body1 = GetJPHBody(descriptor.Body1);
		let body2 = GetJPHBody(descriptor.Body2);
		if (body1 == null || body2 == null)
			return .Err;

		JPH_PointConstraintSettings settings = .();
		settings.@base.enabled = true;
		settings.space = descriptor.UseWorldSpace ? .JPH_ConstraintSpace_WorldSpace : .JPH_ConstraintSpace_LocalToBodyCOM;
		settings.point1 = JoltConversions.ToJPHRVec3(descriptor.Point1);
		settings.point2 = JoltConversions.ToJPHRVec3(descriptor.Point2);

		let constraint = JPH_PointConstraint_Create(&settings, body1, body2);
		if (constraint == null)
			return .Err;

		JPH_PhysicsSystem_AddConstraint(mPhysicsSystem, (JPH_Constraint*)constraint);

		return AllocateConstraintHandle((JPH_Constraint*)constraint);
	}

	public Result<ConstraintHandle> CreateHingeConstraint(HingeConstraintDescriptor descriptor)
	{
		if (mPhysicsSystem == null)
			return .Err;

		let body1 = GetJPHBody(descriptor.Body1);
		let body2 = GetJPHBody(descriptor.Body2);
		if (body1 == null || body2 == null)
			return .Err;

		JPH_HingeConstraintSettings settings = .();
		settings.@base.enabled = true;
		settings.space = descriptor.UseWorldSpace ? .JPH_ConstraintSpace_WorldSpace : .JPH_ConstraintSpace_LocalToBodyCOM;
		settings.point1 = JoltConversions.ToJPHRVec3(descriptor.Point1);
		settings.point2 = JoltConversions.ToJPHRVec3(descriptor.Point2);
		settings.hingeAxis1 = JoltConversions.ToJPHVec3(descriptor.HingeAxis1);
		settings.hingeAxis2 = JoltConversions.ToJPHVec3(descriptor.HingeAxis2);
		settings.normalAxis1 = JoltConversions.ToJPHVec3(descriptor.NormalAxis1);
		settings.normalAxis2 = JoltConversions.ToJPHVec3(descriptor.NormalAxis2);
		settings.limitsMin = descriptor.LimitsMin;
		settings.limitsMax = descriptor.LimitsMax;
		settings.limitsSpringSettings.frequencyOrStiffness = descriptor.LimitsSpringFrequency;
		settings.limitsSpringSettings.damping = descriptor.LimitsSpringDamping;

		let constraint = JPH_HingeConstraint_Create(&settings, body1, body2);
		if (constraint == null)
			return .Err;

		JPH_PhysicsSystem_AddConstraint(mPhysicsSystem, (JPH_Constraint*)constraint);

		return AllocateConstraintHandle((JPH_Constraint*)constraint);
	}

	public Result<ConstraintHandle> CreateSliderConstraint(SliderConstraintDescriptor descriptor)
	{
		if (mPhysicsSystem == null)
			return .Err;

		let body1 = GetJPHBody(descriptor.Body1);
		let body2 = GetJPHBody(descriptor.Body2);
		if (body1 == null || body2 == null)
			return .Err;

		JPH_SliderConstraintSettings settings = .();
		settings.@base.enabled = true;
		settings.space = descriptor.UseWorldSpace ? .JPH_ConstraintSpace_WorldSpace : .JPH_ConstraintSpace_LocalToBodyCOM;
		settings.point1 = JoltConversions.ToJPHRVec3(descriptor.Point1);
		settings.point2 = JoltConversions.ToJPHRVec3(descriptor.Point2);
		settings.sliderAxis1 = JoltConversions.ToJPHVec3(descriptor.SliderAxis1);
		settings.sliderAxis2 = JoltConversions.ToJPHVec3(descriptor.SliderAxis2);
		settings.normalAxis1 = JoltConversions.ToJPHVec3(descriptor.NormalAxis1);
		settings.normalAxis2 = JoltConversions.ToJPHVec3(descriptor.NormalAxis2);
		settings.limitsMin = descriptor.LimitsMin;
		settings.limitsMax = descriptor.LimitsMax;
		settings.limitsSpringSettings.frequencyOrStiffness = descriptor.LimitsSpringFrequency;
		settings.limitsSpringSettings.damping = descriptor.LimitsSpringDamping;
		settings.maxFrictionForce = descriptor.MaxFrictionForce;

		let constraint = JPH_SliderConstraint_Create(&settings, body1, body2);
		if (constraint == null)
			return .Err;

		JPH_PhysicsSystem_AddConstraint(mPhysicsSystem, (JPH_Constraint*)constraint);

		return AllocateConstraintHandle((JPH_Constraint*)constraint);
	}

	public Result<ConstraintHandle> CreateDistanceConstraint(DistanceConstraintDescriptor descriptor)
	{
		if (mPhysicsSystem == null)
			return .Err;

		let body1 = GetJPHBody(descriptor.Body1);
		let body2 = GetJPHBody(descriptor.Body2);
		if (body1 == null || body2 == null)
			return .Err;

		JPH_DistanceConstraintSettings settings = .();
		settings.@base.enabled = true;
		settings.space = descriptor.UseWorldSpace ? .JPH_ConstraintSpace_WorldSpace : .JPH_ConstraintSpace_LocalToBodyCOM;
		settings.point1 = JoltConversions.ToJPHRVec3(descriptor.Point1);
		settings.point2 = JoltConversions.ToJPHRVec3(descriptor.Point2);
		settings.minDistance = descriptor.MinDistance;
		settings.maxDistance = descriptor.MaxDistance;
		settings.limitsSpringSettings.frequencyOrStiffness = descriptor.SpringFrequency;
		settings.limitsSpringSettings.damping = descriptor.SpringDamping;

		let constraint = JPH_DistanceConstraint_Create(&settings, body1, body2);
		if (constraint == null)
			return .Err;

		JPH_PhysicsSystem_AddConstraint(mPhysicsSystem, (JPH_Constraint*)constraint);

		return AllocateConstraintHandle((JPH_Constraint*)constraint);
	}

	public void DestroyConstraint(ConstraintHandle handle)
	{
		if (mPhysicsSystem == null)
			return;

		let constraint = GetJPHConstraint(handle);
		if (constraint == null)
			return;

		JPH_PhysicsSystem_RemoveConstraint(mPhysicsSystem, constraint);
		JPH_Constraint_Destroy(constraint);

		// Mark slot as free
		mConstraints[(int)handle.Index] = null;
		mFreeConstraintSlots.Add(handle.Index);
	}

	public bool IsValidConstraint(ConstraintHandle handle)
	{
		return ValidateConstraintHandle(handle);
	}

	private ConstraintHandle AllocateConstraintHandle(JPH_Constraint* constraint)
	{
		uint32 index;
		uint32 generation;

		if (mFreeConstraintSlots.Count > 0)
		{
			index = mFreeConstraintSlots.PopBack();
			generation = mConstraintGenerations[(int)index] + 1;
			mConstraintGenerations[(int)index] = generation;
			mConstraints[(int)index] = constraint;
		}
		else
		{
			index = (uint32)mConstraints.Count;
			generation = 1;
			mConstraints.Add(constraint);
			mConstraintGenerations.Add(generation);
		}

		return .(index, generation);
	}

	private bool ValidateConstraintHandle(ConstraintHandle handle)
	{
		if (!handle.IsValid)
			return false;
		if (handle.Index >= (uint32)mConstraints.Count)
			return false;
		if (mConstraintGenerations[(int)handle.Index] != handle.Generation)
			return false;
		if (mConstraints[(int)handle.Index] == null)
			return false;
		return true;
	}

	private JPH_Constraint* GetJPHConstraint(ConstraintHandle handle)
	{
		if (!ValidateConstraintHandle(handle))
			return null;
		return mConstraints[(int)handle.Index];
	}

	private JPH_Body* GetJPHBody(BodyHandle handle)
	{
		if (!ValidateBodyHandle(handle))
			return null;
		let bodyId = mBodyIds[(int)handle.Index];

		// Use body lock interface to get the body pointer
		let lockInterface = JPH_PhysicsSystem_GetBodyLockInterfaceNoLock(mPhysicsSystem);
		if (lockInterface == null)
			return null;

		JPH_BodyLockRead @lock = default;
		JPH_BodyLockInterface_LockRead(lockInterface, bodyId, &@lock);
		let body = @lock.body;
		JPH_BodyLockInterface_UnlockRead(lockInterface, &@lock);

		return body;
	}

	// === Character Controllers ===

	public Result<CharacterHandle> CreateCharacter(CharacterDescriptor descriptor)
	{
		if (mPhysicsSystem == null)
			return .Err;

		let shape = GetJPHShape(descriptor.Shape);
		if (shape == null)
			return .Err;

		JPH_CharacterSettings settings = .();
		JPH_CharacterSettings_Init(&settings);
		settings.@base.up = JoltConversions.ToJPHVec3(descriptor.Up);
		settings.@base.maxSlopeAngle = descriptor.MaxSlopeAngle;
		settings.@base.shape = shape;
		settings.layer = descriptor.Layer;
		settings.mass = descriptor.Mass;
		settings.friction = descriptor.Friction;

		var position = JoltConversions.ToJPHRVec3(descriptor.Position);
		var rotation = JoltConversions.ToJPHQuat(descriptor.Rotation);

		let character = JPH_Character_Create(&settings, &position, &rotation, 0, mPhysicsSystem);
		if (character == null)
			return .Err;

		JPH_Character_AddToPhysicsSystem(character, .JPH_Activation_Activate, true);

		return AllocateCharacterHandle(character);
	}

	public void DestroyCharacter(CharacterHandle handle)
	{
		let character = GetJPHCharacter(handle);
		if (character == null)
			return;

		JPH_Character_RemoveFromPhysicsSystem(character, true);
		JPH_CharacterBase_Destroy((JPH_CharacterBase*)character);

		// Mark slot as free
		mCharacters[(int)handle.Index] = null;
		mFreeCharacterSlots.Add(handle.Index);
	}

	public bool IsValidCharacter(CharacterHandle handle)
	{
		return ValidateCharacterHandle(handle);
	}

	public Vector3 GetCharacterPosition(CharacterHandle handle)
	{
		let character = GetJPHCharacter(handle);
		if (character == null)
			return .Zero;

		JPH_RVec3 position = default;
		JPH_Character_GetPosition(character, &position, true);
		return JoltConversions.ToVector3(position);
	}

	public Quaternion GetCharacterRotation(CharacterHandle handle)
	{
		let character = GetJPHCharacter(handle);
		if (character == null)
			return .Identity;

		JPH_Quat rotation = default;
		JPH_Character_GetRotation(character, &rotation, true);
		return JoltConversions.ToQuaternion(rotation);
	}

	public void SetCharacterTransform(CharacterHandle handle, Vector3 position, Quaternion rotation)
	{
		let character = GetJPHCharacter(handle);
		if (character == null)
			return;

		var jphPos = JoltConversions.ToJPHRVec3(position);
		var jphRot = JoltConversions.ToJPHQuat(rotation);
		JPH_Character_SetPositionAndRotation(character, &jphPos, &jphRot, .JPH_Activation_Activate, true);
	}

	public Vector3 GetCharacterLinearVelocity(CharacterHandle handle)
	{
		let character = GetJPHCharacter(handle);
		if (character == null)
			return .Zero;

		JPH_Vec3 velocity = default;
		JPH_Character_GetLinearVelocity(character, &velocity);
		return JoltConversions.ToVector3(velocity);
	}

	public void SetCharacterLinearVelocity(CharacterHandle handle, Vector3 velocity)
	{
		let character = GetJPHCharacter(handle);
		if (character == null)
			return;

		var jphVel = JoltConversions.ToJPHVec3(velocity);
		JPH_Character_SetLinearVelocity(character, &jphVel, true);
	}

	public GroundState GetCharacterGroundState(CharacterHandle handle)
	{
		let character = GetJPHCharacter(handle);
		if (character == null)
			return .InAir;

		let state = JPH_CharacterBase_GetGroundState((JPH_CharacterBase*)character);
		switch (state)
		{
		case .JPH_GroundState_OnGround: return .OnGround;
		case .JPH_GroundState_OnSteepGround: return .OnSteepGround;
		case .JPH_GroundState_NotSupported: return .NotSupported;
		case .JPH_GroundState_InAir: return .InAir;
		default: return .InAir;
		}
	}

	public bool IsCharacterSupported(CharacterHandle handle)
	{
		let character = GetJPHCharacter(handle);
		if (character == null)
			return false;

		return JPH_CharacterBase_IsSupported((JPH_CharacterBase*)character);
	}

	public Vector3 GetCharacterGroundNormal(CharacterHandle handle)
	{
		let character = GetJPHCharacter(handle);
		if (character == null)
			return .(0, 1, 0);

		JPH_Vec3 normal = default;
		JPH_CharacterBase_GetGroundNormal((JPH_CharacterBase*)character, &normal);
		return JoltConversions.ToVector3(normal);
	}

	public Vector3 GetCharacterGroundVelocity(CharacterHandle handle)
	{
		let character = GetJPHCharacter(handle);
		if (character == null)
			return .Zero;

		JPH_Vec3 velocity = default;
		JPH_CharacterBase_GetGroundVelocity((JPH_CharacterBase*)character, &velocity);
		return JoltConversions.ToVector3(velocity);
	}

	public void UpdateCharacter(CharacterHandle handle, float maxSeparationDistance)
	{
		let character = GetJPHCharacter(handle);
		if (character == null)
			return;

		JPH_Character_PostSimulation(character, maxSeparationDistance, true);
	}

	private CharacterHandle AllocateCharacterHandle(JPH_Character* character)
	{
		uint32 index;
		uint32 generation;

		if (mFreeCharacterSlots.Count > 0)
		{
			index = mFreeCharacterSlots.PopBack();
			generation = mCharacterGenerations[(int)index] + 1;
			mCharacterGenerations[(int)index] = generation;
			mCharacters[(int)index] = character;
		}
		else
		{
			index = (uint32)mCharacters.Count;
			generation = 1;
			mCharacters.Add(character);
			mCharacterGenerations.Add(generation);
		}

		return .(index, generation);
	}

	private bool ValidateCharacterHandle(CharacterHandle handle)
	{
		if (!handle.IsValid)
			return false;
		if (handle.Index >= (uint32)mCharacters.Count)
			return false;
		if (mCharacterGenerations[(int)handle.Index] != handle.Generation)
			return false;
		if (mCharacters[(int)handle.Index] == null)
			return false;
		return true;
	}

	private JPH_Character* GetJPHCharacter(CharacterHandle handle)
	{
		if (!ValidateCharacterHandle(handle))
			return null;
		return mCharacters[(int)handle.Index];
	}
}
