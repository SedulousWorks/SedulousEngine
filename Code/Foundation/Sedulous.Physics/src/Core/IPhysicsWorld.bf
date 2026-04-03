namespace Sedulous.Physics;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Main physics simulation interface.
/// Manages bodies, shapes, constraints, and simulation stepping.
interface IPhysicsWorld : IDisposable
{
	/// Returns true if the physics world initialized successfully.
	bool IsInitialized { get; }

	/// Gets or sets the gravity vector.
	Vector3 Gravity { get; set; }

	// === Body Management ===

	/// Creates a rigid body from a descriptor.
	Result<BodyHandle> CreateBody(PhysicsBodyDescriptor descriptor);

	/// Destroys a body and removes it from simulation.
	void DestroyBody(BodyHandle handle);

	/// Returns true if the body handle is valid.
	bool IsValidBody(BodyHandle handle);

	/// Gets the position of a body.
	Vector3 GetBodyPosition(BodyHandle handle);

	/// Gets the rotation of a body.
	Quaternion GetBodyRotation(BodyHandle handle);

	/// Sets the position and rotation of a body.
	void SetBodyTransform(BodyHandle handle, Vector3 position, Quaternion rotation, bool activate = true);

	/// Gets the linear velocity of a body.
	Vector3 GetLinearVelocity(BodyHandle handle);

	/// Sets the linear velocity of a body.
	void SetLinearVelocity(BodyHandle handle, Vector3 velocity);

	/// Gets the angular velocity of a body.
	Vector3 GetAngularVelocity(BodyHandle handle);

	/// Sets the angular velocity of a body.
	void SetAngularVelocity(BodyHandle handle, Vector3 velocity);

	/// Applies a force to a body at its center of mass.
	void AddForce(BodyHandle handle, Vector3 force);

	/// Applies a force at a world position.
	void AddForceAtPosition(BodyHandle handle, Vector3 force, Vector3 position);

	/// Applies torque to a body.
	void AddTorque(BodyHandle handle, Vector3 torque);

	/// Applies an impulse to a body at its center of mass.
	void AddImpulse(BodyHandle handle, Vector3 impulse);

	/// Applies an impulse at a world position.
	void AddImpulseAtPosition(BodyHandle handle, Vector3 impulse, Vector3 position);

	/// Activates a sleeping body.
	void ActivateBody(BodyHandle handle);

	/// Deactivates a body (puts it to sleep).
	void DeactivateBody(BodyHandle handle);

	/// Returns true if the body is currently active (not sleeping).
	bool IsBodyActive(BodyHandle handle);

	/// Sets the body type (Static/Kinematic/Dynamic).
	void SetBodyType(BodyHandle handle, BodyType bodyType);

	/// Gets the body type.
	BodyType GetBodyType(BodyHandle handle);

	/// Sets the mass of a dynamic body.
	void SetBodyMass(BodyHandle handle, float mass);

	/// Gets the mass of a body.
	float GetBodyMass(BodyHandle handle);

	/// Sets the linear damping of a body.
	void SetBodyLinearDamping(BodyHandle handle, float damping);

	/// Gets the linear damping of a body.
	float GetBodyLinearDamping(BodyHandle handle);

	/// Sets the angular damping of a body.
	void SetBodyAngularDamping(BodyHandle handle, float damping);

	/// Gets the angular damping of a body.
	float GetBodyAngularDamping(BodyHandle handle);

	/// Sets the friction of a body.
	void SetBodyFriction(BodyHandle handle, float friction);

	/// Gets the friction of a body.
	float GetBodyFriction(BodyHandle handle);

	/// Sets the restitution (bounciness) of a body.
	void SetBodyRestitution(BodyHandle handle, float restitution);

	/// Gets the restitution of a body.
	float GetBodyRestitution(BodyHandle handle);

	/// Sets the gravity factor for a body (0 = no gravity, 1 = normal).
	void SetBodyGravityFactor(BodyHandle handle, float factor);

	/// Gets the gravity factor of a body.
	float GetBodyGravityFactor(BodyHandle handle);

	/// Sets user data on a body for application use.
	void SetBodyUserData(BodyHandle handle, uint64 userData);

	/// Gets user data from a body.
	uint64 GetBodyUserData(BodyHandle handle);

	// === Shape Management ===

	/// Creates a sphere shape.
	Result<ShapeHandle> CreateSphereShape(float radius);

	/// Creates a box shape.
	Result<ShapeHandle> CreateBoxShape(Vector3 halfExtents);

	/// Creates a capsule shape (Y-axis aligned).
	Result<ShapeHandle> CreateCapsuleShape(float halfHeight, float radius);

	/// Creates a cylinder shape (Y-axis aligned).
	Result<ShapeHandle> CreateCylinderShape(float halfHeight, float radius);

	/// Creates a convex hull shape from points.
	Result<ShapeHandle> CreateConvexHullShape(Span<Vector3> points);

	/// Creates an infinite plane shape (half-space).
	/// @param normal The plane normal (should be normalized).
	/// @param distance Distance from origin along the normal.
	/// @param halfExtent Bounding half-extent for broad phase (default 1000).
	Result<ShapeHandle> CreatePlaneShape(Vector3 normal, float distance, float halfExtent = 1000.0f);

	/// Creates a mesh shape for static geometry.
	Result<ShapeHandle> CreateMeshShape(Span<Vector3> vertices, Span<uint32> indices);

	/// Releases a shape. Only deletes if not referenced by any bodies.
	void ReleaseShape(ShapeHandle handle);

	// === Queries ===

	/// Casts a ray and returns the closest hit.
	bool RayCast(RayCastQuery query, out RayCastResult result, IQueryFilter filter = null);

	/// Casts a ray and returns all hits.
	void RayCastAll(RayCastQuery query, List<RayCastResult> results, IQueryFilter filter = null);

	/// Casts a shape along a direction and returns the closest hit.
	bool ShapeCast(ShapeCastQuery query, out ShapeCastResult result, IQueryFilter filter = null);

	/// Casts a shape along a direction and returns all hits.
	void ShapeCastAll(ShapeCastQuery query, List<ShapeCastResult> results, IQueryFilter filter = null);

	// === Simulation ===

	/// Steps the physics simulation.
	/// @param deltaTime Time step in seconds.
	/// @param collisionSteps Number of collision sub-steps.
	void Step(float deltaTime, int32 collisionSteps = 1);

	/// Sets the contact listener for collision events.
	void SetContactListener(IContactListener listener);

	/// Sets the body activation listener for sleep/wake events.
	void SetBodyActivationListener(IBodyActivationListener listener);

	/// Optimizes the broad phase after adding many bodies.
	void OptimizeBroadPhase();

	// === Constraints ===

	/// Creates a fixed constraint between two bodies.
	Result<ConstraintHandle> CreateFixedConstraint(FixedConstraintDescriptor descriptor);

	/// Creates a point constraint (ball-and-socket joint) between two bodies.
	Result<ConstraintHandle> CreatePointConstraint(PointConstraintDescriptor descriptor);

	/// Creates a hinge constraint between two bodies.
	Result<ConstraintHandle> CreateHingeConstraint(HingeConstraintDescriptor descriptor);

	/// Creates a slider constraint between two bodies.
	Result<ConstraintHandle> CreateSliderConstraint(SliderConstraintDescriptor descriptor);

	/// Creates a distance constraint between two bodies.
	Result<ConstraintHandle> CreateDistanceConstraint(DistanceConstraintDescriptor descriptor);

	/// Destroys a constraint.
	void DestroyConstraint(ConstraintHandle handle);

	/// Returns true if the constraint handle is valid.
	bool IsValidConstraint(ConstraintHandle handle);

	/// Gets the number of constraints.
	uint32 ConstraintCount { get; }

	// === Character Controllers ===

	/// Creates a character controller.
	Result<CharacterHandle> CreateCharacter(CharacterDescriptor descriptor);

	/// Destroys a character controller.
	void DestroyCharacter(CharacterHandle handle);

	/// Returns true if the character handle is valid.
	bool IsValidCharacter(CharacterHandle handle);

	/// Gets the position of a character.
	Vector3 GetCharacterPosition(CharacterHandle handle);

	/// Gets the rotation of a character.
	Quaternion GetCharacterRotation(CharacterHandle handle);

	/// Sets the position and rotation of a character.
	void SetCharacterTransform(CharacterHandle handle, Vector3 position, Quaternion rotation);

	/// Gets the linear velocity of a character.
	Vector3 GetCharacterLinearVelocity(CharacterHandle handle);

	/// Sets the linear velocity of a character.
	void SetCharacterLinearVelocity(CharacterHandle handle, Vector3 velocity);

	/// Gets the ground state of a character.
	GroundState GetCharacterGroundState(CharacterHandle handle);

	/// Returns true if the character is supported (on ground or walkable slope).
	bool IsCharacterSupported(CharacterHandle handle);

	/// Gets the ground normal under the character.
	Vector3 GetCharacterGroundNormal(CharacterHandle handle);

	/// Gets the ground velocity under the character (for moving platforms).
	Vector3 GetCharacterGroundVelocity(CharacterHandle handle);

	/// Updates the character after simulation (call after Step).
	void UpdateCharacter(CharacterHandle handle, float maxSeparationDistance);

	// === Statistics ===

	/// Gets the total number of bodies in the world.
	uint32 BodyCount { get; }

	/// Gets the number of active (non-sleeping) bodies.
	uint32 ActiveBodyCount { get; }
}
