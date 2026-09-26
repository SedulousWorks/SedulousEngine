using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Engine.Physics;

namespace Sedulous.Engine.Script.Facades;

/// `scene.Physics`: the queries and the world, in script shape.
[Scriptable, SceneFacade("Physics")]
class PhysicsFacade : SceneFacade
{
	private PhysicsSceneSystem System => Scene.GetSystem<PhysicsSceneSystem>();
	private CharacterComponentManager Characters => Scene.GetSystem<CharacterComponentManager>();

	/// The entity's character controller, or null when it has none.
	private CharacterComponent* CharacterOf(EntityHandle entity) => Characters?.Get(entity);

	[Scriptable]
	public Float3 Gravity => System?.Gravity ?? .(0, 0, 0);
	[Scriptable]
	public void SetGravity(Float3 gravity) => System?.SetGravity(gravity);
	[Scriptable]
	public int BodyCount => System?.BodyCount ?? 0;

	/// The nearest hit along a ray, or a miss.
	[Scriptable]
	public PhysicsHit RayCast(Float3 from, Float3 direction, float maxDistance, uint32 groupMask = 0xFFFFFFFF)
		=> System?.RayCast(from, direction, maxDistance, groupMask) ?? .();
	[Scriptable]
	public PhysicsHit SphereCast(Float3 from, Float3 direction, float maxDistance, float radius, uint32 groupMask = 0xFFFFFFFF)
		=> System?.SphereCast(from, direction, maxDistance, radius, groupMask) ?? .();
	[Scriptable]
	public PhysicsHit NearestOverlap(Float3 center, float radius, uint32 groupMask = 0xFFFFFFFF)
		=> System?.NearestOverlap(center, radius, groupMask) ?? .();
	/// Every body a sphere overlaps, into the caller's list.
	[Scriptable]
	public void OverlapSphere(Float3 center, float radius, List<EntityHandle> outEntities, uint32 groupMask = 0xFFFFFFFF)
		=> System?.OverlapSphere(center, radius, outEntities, groupMask);

	/// An impulse on the entity's body: `entity.ApplyImpulse(...)` too.
	[Scriptable, ScriptOnEntity]
	public void ApplyImpulse(EntityHandle entity, Float3 impulse) => System?.ApplyImpulse(entity, impulse);

	// ---- character controllers ----
	// A character is kinematic: the scene's physics step moves it from the intent written
	// here, so these request motion rather than set a transform the step would overwrite.

	/// Steers the entity's character along the ground at a world space velocity; the
	/// vertical is left to gravity and the jump. Held until changed, so a script that stops
	/// steering writes zero.
	[Scriptable]
	public void MoveCharacter(EntityHandle entity, float velocityX, float velocityZ)
	{
		if (let character = CharacterOf(entity))
			character.Move(velocityX, velocityZ);
	}

	/// A jump at this upward speed, taken at the next grounded step.
	[Scriptable]
	public void JumpCharacter(EntityHandle entity, float speed)
	{
		if (let character = CharacterOf(entity))
			character.Jump(speed);
	}

	/// Snaps the character to a world position at the next step, dropping its momentum:
	/// what a respawn is. Setting the entity's transform does not move a live character.
	[Scriptable]
	public void SetCharacterPosition(EntityHandle entity, Float3 position)
	{
		if (let character = CharacterOf(entity))
			character.SetPosition(position);
	}

	/// Whether the character is standing on ground; false for an entity with none.
	[Scriptable]
	public bool IsCharacterGrounded(EntityHandle entity)
	{
		let character = CharacterOf(entity);
		return (character != null) && character.Grounded;
	}
}
