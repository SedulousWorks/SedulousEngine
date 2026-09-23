using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Engine.Terrain;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Terrain;

/// Where a terrain brush's ray met a terrain: the grid it hit, in heightfield local space.
///
/// BOTH the sculpt and the hole brush resolve through this: they ask the same question of the
/// same managers, and one answer is easier to keep honest than two.
struct SculptPick
{
	/// The heightfield reference as the terrain holds it: the live grid plus the SOURCE
	/// asset guid the stroke persists back to, which may be nil for an in memory grid.
	public Ref<Heightfield> Grid = default;
	public float LocalX = 0.0f;
	public float LocalZ = 0.0f;
	/// The local surface height at the hit, the Ctrl+click flatten target.
	public float LocalY = 0.0f;
	public Float3 WorldHit = .Zero;
	public Float3 WorldNormal = .(0.0f, 1.0f, 0.0f);
	public bool Valid = false;

	public this() {}

	/// The NEAREST terrain the ray hits, in that terrain's own local space.
	///
	/// `ignoreHoles` takes the cut samples as SURFACE, which is what a brush working ON the
	/// hole plane wants: fill lands inside a cut rather than only from its rim. The sculpt
	/// brush leaves it off, a cut having no surface to raise or lower.
	public static SculptPick Resolve(Scene scene, in ViewportToolInput input,
		bool ignoreHoles = false)
	{
		var best = SculptPick();
		let manager = (scene != null) ? scene.GetSystem<TerrainComponentManager>() : null;
		if (manager == null)
			return best;

		let rayOrigin = input.Ray.Origin;
		let rayDirection = input.Ray.Direction;
		var bestDistance = float.MaxValue;
		manager.ForEach(scope [&] (component, owner) =>
			{
				let resource = component.Terrain.Get;
				if (resource == null)
					return;
				let grid = resource.Heightfield.Get;
				if ((grid == null) || grid.IsEmpty)
					return;

				let world = scene.GetWorldMatrix(owner);
				let inverse = Inverse(world);
				let localOrigin = TransformPoint(rayOrigin, inverse);
				let localDirection = TransformDirection(rayDirection, inverse);
				float t = 0.0f;
				let hit = ignoreHoles
					? grid.QueryRayIgnoringHoles(localOrigin, localDirection, out t)
					: grid.QueryRay(localOrigin, localDirection, out t);
				if (!hit)
					return;

				let localHit = localOrigin + Normalized(localDirection) * t;
				let worldHit = TransformPoint(localHit, world);
				let distance = Length(worldHit - rayOrigin);
				if (distance >= bestDistance)
					return;

				bestDistance = distance;
				best.Grid = resource.Heightfield;
				best.LocalX = localHit.X;
				best.LocalZ = localHit.Z;
				best.LocalY = localHit.Y;
				best.WorldHit = worldHit;
				best.WorldNormal = Normalized(TransformDirection(
					grid.GetNormalAt(localHit.X, localHit.Z), world));
				best.Valid = true;
			});
		return best;
	}

	/// Whether the scene holds ANY terrain with a heightfield, which is what a terrain
	/// brush's relevance turns on.
	public static bool AnyTerrain(Scene scene)
	{
		let manager = (scene != null) ? scene.GetSystem<TerrainComponentManager>() : null;
		if (manager == null)
			return false;

		var any = false;
		manager.ForEach(scope [&] (component, owner) =>
			{
				if (any)
					return;
				let resource = component.Terrain.Get;
				let grid = (resource != null) ? resource.Heightfield.Get : null;
				if ((grid != null) && !grid.IsEmpty)
					any = true;
			});
		return any;
	}
}
