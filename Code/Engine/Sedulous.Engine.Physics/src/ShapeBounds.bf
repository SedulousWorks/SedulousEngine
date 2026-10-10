using System;
using Sedulous.Core;
using Sedulous.Physics;
using Sedulous.Physics.Resource;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics;

/// What a body's or a collider's shape fills, for the managers measuring their entities for
/// the scene (ISceneEntityBounds).
static class ShapeBounds
{
	/// The box a shape fills in its entity's own space, before the entity's world matrix: a
	/// box by its half extents, a sphere by its radius, a capsule along Y, a cooked shape by its
	/// outline's points. A plane is endless and a heightfield is the terrain's to measure, so
	/// neither answers.
	public static bool Local(ShapeKind kind, Float3 halfExtents, float radius, float halfHeight,
		CollisionShape cooked, out AABB outBounds)
	{
		outBounds = AABB.Empty();
		switch (kind)
		{
		case .Box:
			outBounds = AABB.FromCenterExtents(.Zero, halfExtents);
			return true;
		case .Sphere:
			outBounds = AABB.FromCenterExtents(.Zero, .(radius, radius, radius));
			return true;
		case .Capsule:
			outBounds = AABB.FromCenterExtents(.Zero, .(radius, halfHeight + radius, radius));
			return true;
		case .Cooked:
			if ((cooked == null) || cooked.Outline.IsEmpty)
				return false;
			for (let point in cooked.Outline)
				outBounds.Expand(point);
			return true;
		default:
			return false;
		}
	}

	/// The local box through the entity's world matrix.
	public static bool World(Scene scene, EntityHandle entity, ShapeKind kind, Float3 halfExtents,
		float radius, float halfHeight, CollisionShape cooked, out AABB outBounds)
	{
		outBounds = AABB.Empty();
		if (!Local(kind, halfExtents, radius, halfHeight, cooked, let local))
			return false;
		outBounds = TransformAABB(local, scene.GetWorldMatrix(entity));
		return true;
	}
}
