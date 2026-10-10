using Sedulous.Core;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// The pool of extra collider shapes. It measures its entities as the body pool does.
class ColliderComponentManager : ResourceBindingComponentManager<ColliderComponent>, ISceneEntityBounds
{
	public override ISceneEntityBounds AsEntityBounds => this;

	public bool EntityBounds(Scene scene, EntityHandle entity, out AABB outBounds)
	{
		outBounds = AABB.Empty();
		let c = Get(entity);
		return (c != null)
			&& ShapeBounds.World(scene, entity, c.Shape, c.HalfExtents, c.Radius, c.HalfHeight, c.CollisionShape.Get, out outBounds);
	}
}
