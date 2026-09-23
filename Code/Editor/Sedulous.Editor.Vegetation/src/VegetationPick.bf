using System;
using Sedulous.Core;
using Sedulous.Heightfield;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Vegetation.Resource;
using Sedulous.Engine.Terrain;
using Sedulous.Engine.Vegetation;

namespace Sedulous.Editor.Vegetation;

/// What a brush ray found: the vegetation footprint under the cursor, where on it, and the
/// terrain it belongs to.
///
/// BOTH vegetation brushes resolve through this. The mask brush asks for a component whose
/// mask resolves; the prop brush takes any component over a terrain, since it paints the
/// layer's instances rather than a mask.
struct VegetationPick
{
	public bool Valid = false;
	/// BORROWED from the manager's pool, so it is re-resolved rather than held across frames.
	public TerrainVegetationComponent* Component = null;
	public TerrainVegetationComponentManager Manager = null;
	/// The entity carrying the vegetation component, so a stamp can scope its regrow.
	public EntityHandle Owner = .();
	/// The entity carrying the terrain, whose world matrix places the heightfield.
	public EntityHandle TerrainEntity = .();
	/// BORROWED: the terrain resource owns it.
	public Heightfield Heightfield = null;
	public Ref<VegetationMask> Mask = default;
	/// The footprint uv the ray hit.
	public float UvX = 0.0f;
	public float UvY = 0.0f;
	/// The terrain's world span, which turns a world radius into a uv one.
	public float WorldSizeX = 1.0f;
	public float WorldSizeY = 1.0f;
	/// The heightfield's sample grid side, for mapping a footprint rect onto it.
	public int32 GridSize = 0;
	/// The hit in TERRAIN LOCAL space, which is the space the authored instances live in.
	public Float3 LocalHit = .Zero;
	public Float3 WorldHit = .Zero;
	public Float3 WorldNormal = .(0.0f, 1.0f, 0.0f);
	public Float4x4 TerrainWorld = .Identity();

	public this() {}

	/// The heightfield an entity's terrain resolves, walking the ancestry the way the
	/// vegetation manager does, or null when there is none.
	private static Heightfield GridFor(Scene scene, EntityHandle entity,
		ref EntityHandle outTerrainEntity)
	{
		let terrains = (scene != null) ? scene.GetSystem<TerrainComponentManager>() : null;
		if (terrains == null)
			return null;

		var e = entity;
		for (uint32 depth = 0; (depth < 64) && e.IsAssigned; depth++)
		{
			let tc = terrains.Get(e);
			if (tc != null)
			{
				let resource = tc.Terrain.Get;
				let grid = (resource != null) ? resource.Heightfield.Get : null;
				if ((grid == null) || grid.IsEmpty)
					return null;
				outTerrainEntity = e;
				return grid;
			}
			e = scene.GetParent(e);
		}
		return null;
	}

	/// Whether the scene holds any vegetation footprint at all, which is what a brush's
	/// relevance turns on.
	public static bool AnyFootprint(Scene scene, bool requireMask)
	{
		let manager = (scene != null) ? scene.GetSystem<TerrainVegetationComponentManager>() : null;
		if (manager == null)
			return false;

		var any = false;
		manager.ForEach(scope [&] (component, owner) =>
			{
				if (any)
					return;
				let mask = component.Mask.Get;
				if (requireMask && ((mask == null) || mask.IsEmpty))
					return;
				var terrainEntity = EntityHandle();
				any = GridFor(scene, owner, ref terrainEntity) != null;
			});
		return any;
	}

	/// The nearest vegetation footprint under the ray.
	///
	/// `requireMask` takes only components whose mask resolves, which is the mask brush;
	/// without it any component over a terrain answers, which is the prop brush.
	///
	/// `ignoreHoles` picks the terrain plane THROUGH a cut, which the prop brush wants so
	/// that what stands over a hole can still be erased. The mask brush keeps the surface
	/// rule, a cut having no surface to paint.
	public static VegetationPick Resolve(Scene scene, Float3 rayOrigin, Float3 rayDirection,
		bool requireMask, bool ignoreHoles = false)
	{
		var best = VegetationPick();
		let manager = (scene != null) ? scene.GetSystem<TerrainVegetationComponentManager>() : null;
		if (manager == null)
			return best;

		var bestDistance = float.MaxValue;
		manager.ForEach(scope [&] (component, owner) =>
			{
				let mask = component.Mask.Get;
				if (requireMask && ((mask == null) || mask.IsEmpty))
					return;

				var terrainEntity = EntityHandle();
				let grid = GridFor(scene, owner, ref terrainEntity);
				if (grid == null)
					return;

				// The TERRAIN's matrix, not the component's: the heightfield is the terrain's,
				// and the component may sit on a child of it.
				let world = scene.GetWorldMatrix(terrainEntity);
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

				let ws = grid.WorldSize;
				let sizeX = (ws.X != 0.0f) ? ws.X : 1.0f;
				let sizeY = (ws.Y != 0.0f) ? ws.Y : 1.0f;
				bestDistance = distance;
				best.Component = component;
				best.Manager = manager;
				best.Owner = owner;
				best.TerrainEntity = terrainEntity;
				best.Heightfield = grid;
				best.Mask = component.Mask;
				best.UvX = localHit.X / sizeX + 0.5f;
				best.UvY = localHit.Z / sizeY + 0.5f;
				best.WorldSizeX = sizeX;
				best.WorldSizeY = sizeY;
				best.GridSize = grid.Size;
				best.LocalHit = localHit;
				best.WorldHit = worldHit;
				best.WorldNormal = Normalized(TransformDirection(
					grid.GetNormalAt(localHit.X, localHit.Z), world));
				best.TerrainWorld = world;
				best.Valid = true;
			});
		return best;
	}
}
