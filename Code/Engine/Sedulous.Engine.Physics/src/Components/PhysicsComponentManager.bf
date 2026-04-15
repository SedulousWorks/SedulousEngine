namespace Sedulous.Engine.Physics;

using System;
using System.Collections;
using System.Threading;
using Sedulous.Scenes;
using Sedulous.Physics;
using Sedulous.Core.Mathematics;

/// Manages rigid body components: creates/destroys physics bodies, syncs
/// transforms between the scene hierarchy and the physics world each fixed step.
/// Implements IContactListener to receive collision events from the physics
/// engine and dispatch them to gameplay code via RigidBodyComponent delegates.
///
/// FixedUpdate order:
///   1. Create bodies for new components
///   2. Sync kinematic entity transforms → physics (app moves entity, physics follows)
///   3. Step physics simulation (contact events buffered during step)
///   4. Dispatch buffered contact events to components
///   5. Sync dynamic physics results -> entity transforms (physics drives entity)
class PhysicsComponentManager : ComponentManager<RigidBodyComponent>, IContactListener
{
	/// The physics world for this scene (set by PhysicsSubsystem).
	public IPhysicsWorld PhysicsWorld
	{
		get => mPhysicsWorld;
		set
		{
			mPhysicsWorld = value;
			// Register/unregister contact listener with the world
			if (value != null)
				value.SetContactListener(this);
		}
	}
	private IPhysicsWorld mPhysicsWorld;

	/// Number of collision sub-steps per fixed update.
	public int32 CollisionSteps = 1;

	/// Whether to draw debug collision shapes.
	public bool DebugDrawEnabled = false;

	// Buffered contact events — filled during physics step (on Jolt's thread),
	// dispatched to components after the step completes on the main thread.
	private enum ContactType { Added, Persisted, Removed }
	private struct BufferedContact
	{
		public ContactType Type;
		public EntityHandle Entity1;
		public EntityHandle Entity2;
		public ContactEvent Event;
	}
	private List<BufferedContact> mContactBuffer = new .() ~ delete _;
	private Monitor mContactLock = new .() ~ delete _;

	public override StringView SerializationTypeId => "Sedulous.RigidBodyComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterFixedUpdate(new => FixedUpdatePhysics);
	}

	private void FixedUpdatePhysics(float deltaTime)
	{
		if (mPhysicsWorld == null) return;
		let scene = Scene;
		if (scene == null) return;

		// 1. Safety net: create bodies for any components that missed initialization
		// (e.g., deserialization edge cases). Normal path uses OnComponentInitialized.
		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive) continue;
			if (comp.NeedsBodyCreation)
				CreatePhysicsBody(comp);
		}

		// 2. Sync kinematic entities → physics
		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.PhysicsBody.IsValid) continue;
			if (comp.BodyType != .Kinematic) continue;

			let worldMatrix = scene.GetWorldMatrix(comp.Owner);
			let position = worldMatrix.Translation;
			let rotation = Quaternion.CreateFromRotationMatrix(worldMatrix);
			mPhysicsWorld.SetBodyTransform(comp.PhysicsBody, position, rotation, true);
		}

		// 3. Step physics (contact events are buffered via IContactListener during step)
		mPhysicsWorld.Step(deltaTime, CollisionSteps);

		// 4. Dispatch buffered contact events to components
		DispatchContactEvents();

		// 5. Sync dynamic bodies → entity transforms
		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.PhysicsBody.IsValid) continue;
			if (comp.BodyType != .Dynamic) continue;

			let position = mPhysicsWorld.GetBodyPosition(comp.PhysicsBody);
			let rotation = mPhysicsWorld.GetBodyRotation(comp.PhysicsBody);

			// Preserve the entity's original scale — physics doesn't affect scale.
			let currentTransform = scene.GetLocalTransform(comp.Owner);
			scene.SetLocalTransform(comp.Owner, .()
			{
				Position = position,
				Rotation = rotation,
				Scale = currentTransform.Scale
			});
		}
	}

	/// Called automatically after properties are set, before the first FixedUpdate.
	/// Creates the physics body from the component's configured Shape + BodyType.
	protected override void OnComponentInitialized(RigidBodyComponent comp)
	{
		if (comp.NeedsBodyCreation && mPhysicsWorld != null)
			CreatePhysicsBody(comp);
	}

	protected override void OnComponentDestroyed(RigidBodyComponent comp)
	{
		// PhysicsWorld may already be destroyed during scene teardown —
		// skip cleanup if the world is gone (bodies are already freed).
		if (mPhysicsWorld != null && mPhysicsWorld.IsInitialized)
			DestroyPhysicsBody(comp);
	}

	// ==================== Body Creation ====================

	private void CreatePhysicsBody(RigidBodyComponent comp)
	{
		if (mPhysicsWorld == null) return;
		comp.NeedsBodyCreation = false;

		// Create shape
		let shapeResult = CreateShape(comp.Shape);
		if (shapeResult case .Err)
			return;

		comp.PhysicsShape = shapeResult.Value;

		// Get initial transform from entity
		let scene = Scene;
		let worldMatrix = scene.GetWorldMatrix(comp.Owner);
		let position = worldMatrix.Translation;
		let rotation = Quaternion.CreateFromRotationMatrix(worldMatrix);

		// Build body descriptor
		var desc = PhysicsBodyDescriptor();
		desc.Shape = comp.PhysicsShape;
		desc.Position = position;
		desc.Rotation = rotation;
		desc.BodyType = comp.BodyType;
		desc.Layer = comp.CollisionLayer;
		desc.Friction = comp.Friction;
		desc.Restitution = comp.Restitution;
		desc.LinearDamping = comp.LinearDamping;
		desc.AngularDamping = comp.AngularDamping;
		desc.GravityFactor = comp.GravityFactor;
		desc.IsSensor = comp.IsSensor;
		desc.AllowSleep = comp.AllowSleep;
		desc.Mass = comp.Mass;

		// Encode entity handle as user data for raycast identification
		desc.UserData = ((uint64)comp.Owner.Index << 32) | (uint64)comp.Owner.Generation;

		if (mPhysicsWorld.CreateBody(desc) case .Ok(let bodyHandle))
			comp.PhysicsBody = bodyHandle;
	}

	private Result<ShapeHandle> CreateShape(ShapeConfig config)
	{
		switch (config.Type)
		{
		case .Box:
			return mPhysicsWorld.CreateBoxShape(config.HalfExtents);
		case .Sphere:
			return mPhysicsWorld.CreateSphereShape(config.Radius);
		case .Capsule:
			return mPhysicsWorld.CreateCapsuleShape(config.HalfHeight, config.Radius);
		case .Cylinder:
			return mPhysicsWorld.CreateCylinderShape(config.HalfHeight, config.Radius);
		case .Plane:
			return mPhysicsWorld.CreatePlaneShape(.(0, 1, 0), 0);
		}
	}

	private void DestroyPhysicsBody(RigidBodyComponent comp)
	{
		if (mPhysicsWorld == null) return;

		if (comp.PhysicsBody.IsValid)
		{
			mPhysicsWorld.DestroyBody(comp.PhysicsBody);
			comp.PhysicsBody = .Invalid;
		}

		if (comp.PhysicsShape.IsValid)
		{
			mPhysicsWorld.ReleaseShape(comp.PhysicsShape);
			comp.PhysicsShape = .Invalid;
		}
	}

	// ==================== Queries ====================

	/// Casts a ray into the physics world. Returns the hit entity handle and result.
	public bool RayCast(Vector3 origin, Vector3 direction, float maxDistance, out RayCastResult result, out EntityHandle hitEntity)
	{
		hitEntity = .Invalid;
		result = default;

		if (mPhysicsWorld == null) return false;

		let query = RayCastQuery(origin, direction, maxDistance);
		if (mPhysicsWorld.RayCast(query, out result))
		{
			// Decode entity handle from body user data
			let userData = result.UserData;
			hitEntity = .() { Index = (uint32)(userData >> 32), Generation = (uint32)(userData & 0xFFFFFFFF) };
			return true;
		}
		return false;
	}

	// ==================== IContactListener ====================

	/// Decodes an EntityHandle from body user data.
	private EntityHandle DecodeEntityHandle(BodyHandle body)
	{
		if (mPhysicsWorld == null) return .Invalid;
		let userData = mPhysicsWorld.GetBodyUserData(body);
		return .() { Index = (uint32)(userData >> 32), Generation = (uint32)(userData & 0xFFFFFFFF) };
	}

	/// Finds the RigidBodyComponent for an entity. Returns null if not found.
	private RigidBodyComponent FindComponentForEntity(EntityHandle entity)
	{
		if (!entity.IsAssigned) return null;
		return GetForEntity(entity);
	}

	bool IContactListener.OnContactAdded(BodyHandle body1, BodyHandle body2, ContactEvent event)
	{
		using (mContactLock.Enter())
		{
			mContactBuffer.Add(.()
			{
				Type = .Added,
				Entity1 = DecodeEntityHandle(body1),
				Entity2 = DecodeEntityHandle(body2),
				Event = event
			});
		}
		return true; // accept contact by default
	}

	void IContactListener.OnContactPersisted(BodyHandle body1, BodyHandle body2, ContactEvent event)
	{
		using (mContactLock.Enter())
		{
			mContactBuffer.Add(.()
			{
				Type = .Persisted,
				Entity1 = DecodeEntityHandle(body1),
				Entity2 = DecodeEntityHandle(body2),
				Event = event
			});
		}
	}

	void IContactListener.OnContactRemoved(BodyHandle body1, BodyHandle body2)
	{
		using (mContactLock.Enter())
		{
			mContactBuffer.Add(.()
			{
				Type = .Removed,
				Entity1 = DecodeEntityHandle(body1),
				Entity2 = DecodeEntityHandle(body2),
				Event = default
			});
		}
	}

	/// Dispatches buffered contact events to components. Called on the main
	/// thread after the physics step completes.
	private void DispatchContactEvents()
	{
		List<BufferedContact> contacts = scope .();
		using (mContactLock.Enter())
		{
			contacts.AddRange(mContactBuffer);
			mContactBuffer.Clear();
		}

		for (let contact in contacts)
		{
			let comp1 = FindComponentForEntity(contact.Entity1);
			let comp2 = FindComponentForEntity(contact.Entity2);

			switch (contact.Type)
			{
			case .Added:
				if (comp1?.OnContactAdded != null)
				{
					let evt = PhysicsContactEvent()
					{
						OtherEntity = contact.Entity2,
						Position = contact.Event.Position,
						Normal = contact.Event.Normal,
						PenetrationDepth = contact.Event.PenetrationDepth,
						RelativeVelocity = contact.Event.RelativeVelocity,
						CombinedFriction = contact.Event.CombinedFriction,
						CombinedRestitution = contact.Event.CombinedRestitution
					};
					comp1.OnContactAdded(comp1, evt);
				}
				if (comp2?.OnContactAdded != null)
				{
					let evt = PhysicsContactEvent()
					{
						OtherEntity = contact.Entity1,
						Position = contact.Event.Position,
						Normal = -contact.Event.Normal, // flip normal for body2's perspective
						PenetrationDepth = contact.Event.PenetrationDepth,
						RelativeVelocity = -contact.Event.RelativeVelocity,
						CombinedFriction = contact.Event.CombinedFriction,
						CombinedRestitution = contact.Event.CombinedRestitution
					};
					comp2.OnContactAdded(comp2, evt);
				}

			case .Persisted:
				if (comp1?.OnContactPersisted != null)
				{
					let evt = PhysicsContactEvent()
					{
						OtherEntity = contact.Entity2,
						Position = contact.Event.Position,
						Normal = contact.Event.Normal,
						PenetrationDepth = contact.Event.PenetrationDepth,
						RelativeVelocity = contact.Event.RelativeVelocity,
						CombinedFriction = contact.Event.CombinedFriction,
						CombinedRestitution = contact.Event.CombinedRestitution
					};
					comp1.OnContactPersisted(comp1, evt);
				}
				if (comp2?.OnContactPersisted != null)
				{
					let evt = PhysicsContactEvent()
					{
						OtherEntity = contact.Entity1,
						Position = contact.Event.Position,
						Normal = -contact.Event.Normal,
						PenetrationDepth = contact.Event.PenetrationDepth,
						RelativeVelocity = -contact.Event.RelativeVelocity,
						CombinedFriction = contact.Event.CombinedFriction,
						CombinedRestitution = contact.Event.CombinedRestitution
					};
					comp2.OnContactPersisted(comp2, evt);
				}

			case .Removed:
				if (comp1?.OnContactRemoved != null)
					comp1.OnContactRemoved(comp1, contact.Entity2);
				if (comp2?.OnContactRemoved != null)
					comp2.OnContactRemoved(comp2, contact.Entity1);
			}
		}
	}
}
