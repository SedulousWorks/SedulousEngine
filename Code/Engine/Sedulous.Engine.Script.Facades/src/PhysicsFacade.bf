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
}
