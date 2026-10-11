using System;
using Sedulous.Core;

namespace Sedulous.Scene;

/// What a ray found on an entity's drawn surface (world space): the entity, where, and the
/// corner of the triangle it met nearest the hit (a vertex to snap to).
struct SceneSurfaceHit
{
	public EntityHandle Entity = .Invalid;
	public float Distance = 0.0f;
	public Float3 Position = .Zero;
	public Float3 Normal = .(0.0f, 1.0f, 0.0f);
	public Float3 Vertex = .Zero;
}

/// A system that can answer a ray against what it draws (render: its meshes' triangles), for
/// one that wants the visible surface rather than the solid one: the editor snapping a dragged
/// entity onto a vertex. Neither names the other's components; Scene.RaycastSurface asks every
/// system that answers.
interface ISceneSurfaceQuery
{
	/// The closest hit along unit `direction` from `origin` within `maxDistance`, on the
	/// entities `accept` takes (null takes all). False on a miss.
	bool RaycastSurface(Scene scene, Float3 origin, Float3 direction, float maxDistance, delegate bool(EntityHandle entity) accept, out SceneSurfaceHit outHit);
}
