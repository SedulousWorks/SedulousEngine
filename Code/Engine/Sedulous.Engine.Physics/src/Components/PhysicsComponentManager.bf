namespace Sedulous.Engine.Physics;

using System;
using Sedulous.Scenes;
using Sedulous.Physics;
using Sedulous.Core.Mathematics;

/// Manages rigid body components: creates/destroys physics bodies, syncs
/// transforms between the scene hierarchy and the physics world each fixed step.
///
/// FixedUpdate order:
///   1. Create bodies for new components
///   2. Sync kinematic entity transforms → physics (app moves entity, physics follows)
///   3. Step physics simulation
///   4. Sync dynamic physics results -> entity transforms (physics drives entity)
class PhysicsComponentManager : ComponentManager<RigidBodyComponent>
{
	/// The physics world for this scene (set by PhysicsSubsystem).
	public IPhysicsWorld PhysicsWorld { get; set; }

	/// Number of collision sub-steps per fixed update.
	public int32 CollisionSteps = 1;

	/// Whether to draw debug collision shapes.
	public bool DebugDrawEnabled = false;

	public override StringView SerializationTypeId => "Sedulous.RigidBodyComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterFixedUpdate(new => FixedUpdatePhysics);
	}

	private void FixedUpdatePhysics(float deltaTime)
	{
		if (PhysicsWorld == null) return;
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
			PhysicsWorld.SetBodyTransform(comp.PhysicsBody, position, rotation, true);
		}

		// 3. Step physics
		PhysicsWorld.Step(deltaTime, CollisionSteps);

		// 4. Sync dynamic bodies → entity transforms
		for (let comp in ActiveComponents)
		{
			if (!comp.IsActive || !comp.PhysicsBody.IsValid) continue;
			if (comp.BodyType != .Dynamic) continue;

			let position = PhysicsWorld.GetBodyPosition(comp.PhysicsBody);
			let rotation = PhysicsWorld.GetBodyRotation(comp.PhysicsBody);

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
		if (comp.NeedsBodyCreation && PhysicsWorld != null)
			CreatePhysicsBody(comp);
	}

	protected override void OnComponentDestroyed(RigidBodyComponent comp)
	{
		// PhysicsWorld may already be destroyed during scene teardown —
		// skip cleanup if the world is gone (bodies are already freed).
		if (PhysicsWorld != null && PhysicsWorld.IsInitialized)
			DestroyPhysicsBody(comp);
	}

	// ==================== Body Creation ====================

	private void CreatePhysicsBody(RigidBodyComponent comp)
	{
		if (PhysicsWorld == null) return;
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

		if (PhysicsWorld.CreateBody(desc) case .Ok(let bodyHandle))
			comp.PhysicsBody = bodyHandle;
	}

	private Result<ShapeHandle> CreateShape(ShapeConfig config)
	{
		switch (config.Type)
		{
		case .Box:
			return PhysicsWorld.CreateBoxShape(config.HalfExtents);
		case .Sphere:
			return PhysicsWorld.CreateSphereShape(config.Radius);
		case .Capsule:
			return PhysicsWorld.CreateCapsuleShape(config.HalfHeight, config.Radius);
		case .Cylinder:
			return PhysicsWorld.CreateCylinderShape(config.HalfHeight, config.Radius);
		case .Plane:
			return PhysicsWorld.CreatePlaneShape(.(0, 1, 0), 0);
		}
	}

	private void DestroyPhysicsBody(RigidBodyComponent comp)
	{
		if (PhysicsWorld == null) return;

		if (comp.PhysicsBody.IsValid)
		{
			PhysicsWorld.DestroyBody(comp.PhysicsBody);
			comp.PhysicsBody = .Invalid;
		}

		if (comp.PhysicsShape.IsValid)
		{
			PhysicsWorld.ReleaseShape(comp.PhysicsShape);
			comp.PhysicsShape = .Invalid;
		}
	}

	// ==================== Queries ====================

	/// Casts a ray into the physics world. Returns the hit entity handle and result.
	public bool RayCast(Vector3 origin, Vector3 direction, float maxDistance, out RayCastResult result, out EntityHandle hitEntity)
	{
		hitEntity = .Invalid;
		result = default;

		if (PhysicsWorld == null) return false;

		let query = RayCastQuery(origin, direction, maxDistance);
		if (PhysicsWorld.RayCast(query, out result))
		{
			// Decode entity handle from body user data
			let userData = result.UserData;
			hitEntity = .() { Index = (uint32)(userData >> 32), Generation = (uint32)(userData & 0xFFFFFFFF) };
			return true;
		}
		return false;
	}
}
