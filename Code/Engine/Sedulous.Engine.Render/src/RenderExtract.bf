using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.RHI;
using Sedulous.Render;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Texture.Resource;

namespace Sedulous.Engine.Render;

/// Reading a scene's render components into the snapshot the renderer consumes.
///
/// THE one way seam: this layer knows about both the scene and the renderer, and the renderer
/// knows about neither. Everything here runs AFTER the scene's transforms are current.
static class RenderExtract
{
	/// Below this many meshes the parallel path costs more than it saves. The win is at
	/// thousands of renderables, so the threshold is set conservatively.
	public const uint32 ParallelExtractThreshold = 256;

	/// Packs an entity into the opaque id the renderer carries for picking. Opaque to the
	/// renderer, which never takes it apart.
	public static uint64 PackEntity(EntityHandle entity) =>
		((uint64)entity.Generation << 32) | (uint64)entity.Index;

	/// Maps a material's blend preset onto the category that decides dispatch and sort order.
	public static uint16 CategoryForMaterial(Material material)
	{
		if (material == null)
			return RenderCategories.Opaque;

		switch (material.Pipeline.BlendMode)
		{
		case .Opaque: return RenderCategories.Opaque;
		case .Masked: return RenderCategories.Masked;
		default: return RenderCategories.Transparent;
		}
	}

	/// The world space bounding sphere radius of a local box under a transform.
	///
	/// The diagonal half extent scaled by the LARGEST axis scale, read off the basis rows
	/// under the row vector convention. Conservative, and cheap enough to do per renderable.
	public static float WorldBoundsRadius(AABB local, Float4x4 world)
	{
		let sx = Length(Float3(world.M[0][0], world.M[0][1], world.M[0][2]));
		let sy = Length(Float3(world.M[1][0], world.M[1][1], world.M[1][2]));
		let sz = Length(Float3(world.M[2][0], world.M[2][1], world.M[2][2]));
		return Length(local.Extents()) * Max(sx, Max(sy, sz));
	}

	/// Fills one mesh record from a component.
	///
	/// A pure read of transforms already computed and of borrowed pointers, which is what
	/// makes it safe to run across components at once once the transforms are current.
	public static void FillMeshRenderData(Scene scene, MeshComponent* component,
		EntityHandle entity, MeshRenderData data)
	{
		// The raw cache is refreshed from the proxies EVERY frame: a few pointer loads, and a
		// late cook or a hot reload heals live rather than pinning whatever was null at
		// resolve time.
		//
		// BORROWED, where Raptor's cache holds a strong reference per entry. Material is not
		// reference counted here, and the render data beside it already borrows the primary
		// material the same way, so this follows the port rather than introducing a second
		// rule. It IS a weaker guarantee: Raptor keeps each material alive from extract until
		// the snapshot is recorded, and this relies on the material system outliving the
		// frame. Whoever makes materials individually releasable has to revisit it.
		component.MaterialCache.Clear();
		for (int i < component.Materials.Count)
			component.MaterialCache.Add(component.Materials[i].Get);

		let primary = component.MaterialCache.IsEmpty ? null : component.MaterialCache[0];

		data.World = scene.GetWorldMatrix(entity);
		let localBounds = (component.Mesh.Get != null)
			? component.Mesh.Get.Bounds
			: AABB(.(0, 0, 0), .(0, 0, 0));
		data.WorldCenter = TransformPoint(localBounds.Center(), data.World);
		data.WorldRadius = WorldBoundsRadius(localBounds, data.World);
		data.Color = component.Color;
		data.Mesh = component.Mesh.Get;
		data.Material = primary;
		data.EntityId = PackEntity(entity);
		data.Category = CategoryForMaterial(primary);
		// The batch key keeps opaque draws contiguous by mesh and material. The renderer id
		// keeps its default, because the mesh renderer registers first.
		data.SortBatchKey = SortKeys.BatchKey(Internal.UnsafeCastToPtr(component.Mesh.Get),
			Internal.UnsafeCastToPtr(primary));
		data.BoneMatrices = component.BoneMatrices;
		data.PreviousBoneMatrices = component.PrevBoneMatrices;
		data.BoneCount = component.BoneCount;
		// Per view level selection happens in the renderer: ONE snapshot, many views.
		data.LodBias = component.LodBias;
		data.ForceLod = component.ForceLod;

		// Submesh routing ONLY when the mesh is genuinely multi material. A single entry is
		// the whole mesh path, where slot zero is the material above, and taking it keeps the
		// batching intact.
		let multiMaterial = component.MaterialCache.Count > 1;
		data.SubmeshMaterials = multiMaterial ? component.MaterialCache.Ptr : null;
		data.SubmeshMaterialCount = multiMaterial ? (uint32)component.MaterialCache.Count : 0;
	}

	// ---- scene extractors ------------------------------------------------------------------

	/// Fills the snapshot with one record per VISIBLE mesh, serially.
	///
	/// Assumes the transforms are current, and that the snapshot was reset beforehand.
	public static void ExtractSceneInto(Scene scene, ExtractedScene outScene)
	{
		let meshes = scene.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return;

		meshes.ForEach(scope (component, entity) =>
			{
				// An entity that is not effectively active renders nothing.
				if (!scene.IsEffectivelyActive(entity) || !component.Visible
					|| (component.Mesh.Get == null))
					return;

				if (let data = outScene.Add<MeshRenderData>())
					FillMeshRenderData(scene, component, entity, data);
			});
	}

	/// The same, spread across the job system when there is one and the scene is big enough.
	///
	/// Each worker fills its OWN arena and item list, so nothing contends, and a single
	/// threaded merge gathers them afterwards. Falls back to the serial path through slot
	/// zero when there is no job system or too little to gain.
	///
	/// The snapshot is reset here; the context's arenas accumulate across the frame, which
	/// is why the caller begins it once per frame rather than per extract.
	public static void ExtractSceneInto(Scene scene, ExtractedScene outScene, RenderContext context)
	{
		outScene.Reset();

		let meshes = scene.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return;

		let count = meshes.Count;
		if (count == 0)
			return;

		context.ResetItems();
		let components = meshes.Dense;
		let owners = meshes.Owners;

		if (HasGlobalJobSystem() && (count >= ParallelExtractThreshold))
		{
			let jobs = GlobalJobs();
			jobs.ParallelFor((int32)count, scope (i) =>
				{
					// The fill REFRESHES the component's per frame material cache, so this
					// writes. Safe here because each component is touched by exactly one job.
					let component = &components[i];
					if (!scene.IsEffectivelyActive(owners[i]) || !component.Visible
						|| (component.Mesh.Get == null))
						return;

					let slot = (uint32)jobs.CurrentSlot;
					let arena = context.Arena(slot);
					let data = new:arena MeshRenderData();
					if (data == null)
						return;

					FillMeshRenderData(scene, component, owners[i], data);
					context.Items(slot).Add(data);
				});
		}
		else
		{
			let arena = context.Arena(0);
			let items = context.Items(0);
			for (int32 i < (int32)count)
			{
				let component = &components[i];
				if (!scene.IsEffectivelyActive(owners[i]) || !component.Visible
					|| (component.Mesh.Get == null))
					continue;

				let data = new:arena MeshRenderData();
				if (data == null)
					continue;

				FillMeshRenderData(scene, component, owners[i], data);
				items.Add(data);
			}
		}

		context.MergeInto(outScene);
	}

	/// Fills the snapshot with ONE record per visible instanced set: the set, not its
	/// instances.
	///
	/// Per frame cost is constant in the instance count, because the renderer holds the
	/// transforms in a persistent buffer keyed by the entity and the whole set culls against
	/// one merged bounds.
	public static void ExtractInstancedMeshesInto(Scene scene, ExtractedScene outScene)
	{
		let sets = scene.GetSystem<InstancedMeshComponentManager>();
		if (sets == null)
			return;

		sets.ForEach(scope (component, entity) =>
			{
				// Gated BEFORE the caches below: an inactive set is simply absent from the
				// snapshot. The renderer draws from the snapshot, and its buffer is only a
				// cache that revalidates by version when the set comes back.
				if (!scene.IsEffectivelyActive(entity) || !component.Visible
					|| (component.Mesh.Get == null) || (component.Count == 0))
					return;

				// The entity relative instances are composed into world space and CACHED,
				// rebuilt only when the authored set changed or the entity moved. The
				// renderer keys its upload on the composed version, so either kind of change
				// re uploads.
				let entityWorld = scene.GetWorldMatrix(entity);
				if ((component.ComposedFromVersion != component.Version)
					|| !(component.ComposedEntityWorld == entityWorld))
				{
					component.WorldTransforms.Clear();
					for (int i < component.Instances.Count)
						component.WorldTransforms.Add(component.Instances[i] * entityWorld);

					component.ComposedEntityWorld = entityWorld;
					component.ComposedFromVersion = component.Version;
					component.ComposedVersion++;
				}

				// The merged bounds are the union of the mesh's local box under every composed
				// instance, cached the same way and rebuilt only when that set changed.
				if (component.BoundsVersion != component.ComposedVersion)
				{
					let localBounds = component.Mesh.Get.Bounds;
					var merged = AABB.Empty();
					for (let transform in component.WorldTransforms)
					{
						let center = TransformPoint(localBounds.Center(), transform);
						let radius = WorldBoundsRadius(localBounds, transform);
						merged.Expand(center - Float3(radius, radius, radius));
						merged.Expand(center + Float3(radius, radius, radius));
					}
					component.CachedCenter = merged.Center();
					component.CachedRadius = Length(merged.Extents());
					component.BoundsVersion = component.ComposedVersion;
				}

				let data = outScene.Add<MultiMeshRenderData>();
				if (data == null)
					return;

				data.MultiMesh = true;
				data.Key = PackEntity(entity);
				// BORROWED for the frame, which the snapshot being immutable is what makes safe.
				data.Transforms = component.WorldTransforms.Ptr;
				let tintsMatch = !component.Tints.IsEmpty
					&& (component.Tints.Count == component.Instances.Count);
				data.Tints = tintsMatch ? component.Tints.Ptr : null;
				data.InstanceCount = component.Count;
				data.Version = component.ComposedVersion;
				data.Mesh = component.Mesh.Get;
				data.Material = component.Material.Get;
				data.SubmeshMaterials = component.SubmeshMaterials.IsEmpty
					? null : component.SubmeshMaterials.Ptr;
				data.SubmeshMaterialCount = (uint32)component.SubmeshMaterials.Count;
				data.Color = component.Color;
				// The merged bounds are what let the whole set cull and depth sort as one.
				data.WorldCenter = component.CachedCenter;
				data.WorldRadius = component.CachedRadius;
				data.EntityId = PackEntity(entity);
				data.Category = CategoryForMaterial(component.Material.Get);
				data.SortBatchKey = SortKeys.BatchKey(
					Internal.UnsafeCastToPtr(component.Mesh.Get),
					Internal.UnsafeCastToPtr(component.Material.Get));

				data.PosePool = component.PosePool;
				data.PreviousPosePool = component.PrevPosePool;
				data.PoseCount = component.PoseCount;
				data.PoseBoneCount = component.BoneCount;
				data.PoseAssignment = component.PoseAssignment;
				// The explicit indices are borrowed ONLY when the policy asks for them and the
				// list is the right length; otherwise null leaves the renderer on its hashed
				// default rather than reading a mismatched array.
				let explicitPoses = (component.PoseAssignment == .Explicit)
					&& (component.PoseIndices.Count == component.Instances.Count);
				data.PoseIndices = explicitPoses ? component.PoseIndices.Ptr : null;

				// The renderer id stays nought, since the mesh renderer draws these too, and
				// the world matrix stays identity: the per instance transforms ride above.
			});
	}

	/// The view a sprite or decal draws with: the runtime override WINS, and otherwise the
	/// cooked product behind the reference. Null means there is nothing to draw yet.
	private static ITextureView ResolveView(ITextureView over, Ref<Texture> asset)
	{
		if (over != null)
			return over;

		let product = asset.Get;
		return (product != null) ? product.View : null;
	}

	/// Fills the snapshot with one record per visible sprite. Serial, because sprites are few.
	///
	/// Stamps the sprite renderer's id so emission routes them there, and files them as
	/// transparent so they sort back to front alongside transparent meshes.
	public static void ExtractSpritesInto(Scene scene, ExtractedScene outScene,
		uint16 spriteRendererId)
	{
		let sprites = scene.GetSystem<SpriteComponentManager>();
		if (sprites == null)
			return;

		sprites.ForEach(scope (component, entity) =>
			{
				if (!scene.IsEffectivelyActive(entity) || !component.Visible)
					return;

				let view = ResolveView(component.Texture, component.TextureAsset);
				if (view == null)
					return;

				let data = outScene.Add<SpriteRenderData>();
				if (data == null)
					return;

				// Drawn after tonemap means world UI, which keeps the colours as authored.
				data.Category = component.PostTonemap
					? RenderCategories.WorldUI : RenderCategories.Transparent;
				data.RendererId = spriteRendererId;
				data.WorldCenter = TransformPoint(Float3(0, 0, 0), scene.GetWorldMatrix(entity));
				// Half the billboard's diagonal, for frustum culling. The size is already in
				// world units, since the sprite renderer sizes the quad directly, so the
				// entity's scale is deliberately not folded in.
				data.WorldRadius = 0.5f * Length(component.Size);
				data.Size = component.Size;
				data.UvRect = component.UvRect;
				data.Tint = component.Tint;
				data.Orientation = (uint32)component.Orientation;
				data.Additive = component.Additive;
				data.PostTonemap = component.PostTonemap;

				if (component.Orientation == .EntityOriented)
				{
					// The entity's own right and up span the quad. NORMALISED, so the size
					// alone sets the extent, which is the contract every other orientation
					// keeps.
					let world = scene.GetWorldMatrix(entity);
					data.AxisRight = Normalized(Float3(world.M[0][0], world.M[0][1], world.M[0][2]));
					data.AxisUp = Normalized(Float3(world.M[1][0], world.M[1][1], world.M[1][2]));
				}

				data.Texture = view;
			});
	}

	/// Fills the snapshot's decal list. Serial, because decals are few.
	public static void ExtractDecalsInto(Scene scene, ExtractedScene outScene)
	{
		let decals = scene.GetSystem<DecalComponentManager>();
		if (decals == null)
			return;

		decals.ForEach(scope (component, entity) =>
			{
				if (!scene.IsEffectivelyActive(entity) || !component.Visible)
					return;

				let view = ResolveView(component.Texture, component.TextureAsset);
				if (view == null)
					return;

				var instance = DecalInstance();
				// The size is baked in as an EXTRA scale under the entity transform, in row
				// vector order, so the entity's rotation aims the projection axis while the
				// size sets the box extents.
				instance.World = Float4x4.Scale(component.Size) * scene.GetWorldMatrix(entity);
				instance.Color = component.Color;
				instance.FadeStart = component.FadeStart;
				instance.FadeEnd = component.FadeEnd;
				instance.Texture = view;
				outScene.AddDecal(instance);
			});
	}

	/// Reads the scene's primary camera. False when there is none.
	///
	/// The view is the INVERSE of the entity's world matrix, and the projection comes from the
	/// component's own fields.
	public static bool ExtractPrimaryCamera(Scene scene, ref ViewCamera outCamera,
		Color* outClear = null)
	{
		let cameras = scene.GetSystem<CameraComponentManager>();
		if (cameras == null)
			return false;

		var found = false;
		var camera = ViewCamera();
		var clear = Color(0, 0, 0, 1);

		cameras.ForEach(scope [&] (component, entity) =>
			{
				// An INACTIVE primary is skipped, so the choice falls through to the next one
				// rather than the scene losing its camera.
				if (found || !component.Primary || !scene.IsEffectivelyActive(entity))
					return;

				found = true;
				let world = scene.GetWorldMatrix(entity);
				camera.View = Inverse(world);
				camera.Projection = Float4x4.PerspectiveFovRH(component.FovYRadians,
					component.Aspect, component.NearZ, component.FarZ);
				camera.Position = TransformPoint(Float3(0, 0, 0), world);
				camera.FarZ = component.FarZ;
				clear = component.ClearColor;
			});

		if (found)
		{
			outCamera = camera;
			if (outClear != null)
				*outClear = clear;
		}
		return found;
	}

	/// Packs every enabled light into the snapshot as a shading input.
	///
	/// The FIRST enabled directional light that casts becomes the scene's shadow caster; its
	/// cascades are fitted to the camera later, when the frame is built.
	public static void ExtractLightsInto(Scene scene, ExtractedScene outScene)
	{
		let lights = scene.GetSystem<LightComponentManager>();
		if (lights == null)
			return;

		var haveShadow = false;
		// Tiles spent per atlas layer, budgeted separately, and the running entry index that
		// becomes the next caster's shadow index.
		var realtimeTiles = 0u;
		var staticTiles = 0u;
		var flatEntries = 0u;

		lights.ForEach(scope [&] (component, entity) =>
			{
				if (!scene.IsEffectivelyActive(entity) || !component.Enabled)
					return;

				let world = scene.GetWorldMatrix(entity);
				var light = GpuLight();
				light.PositionWS = TransformPoint(Float3(0, 0, 0), world);
				// Forward is -Z, which is the third basis row negated under the row vector
				// convention.
				light.DirectionWS = Normalized(Float3(-world.M[2][0], -world.M[2][1],
					-world.M[2][2]));
				light.Range = component.Range;
				light.Color = .(component.Color.R, component.Color.G, component.Color.B);
				light.Intensity = component.Intensity;
				light.Type = (float)(uint32)component.Type;
				light.InnerCos = Math.Cos(component.InnerAngle);
				light.OuterCos = Math.Cos(component.OuterAngle);

				if (!haveShadow && component.CastsShadows && (component.Type == .Directional))
				{
					haveShadow = true;
					// Marks this light as shadowed for the forward shader.
					light.ShadowIndex = 0.0f;
					var directional = DirectionalShadow();
					directional.Direction = light.DirectionWS;
					directional.Valid = true;
					outScene.SetDirectionalShadow(directional);
				}

				// A local caster takes its BASE atlas tile as its shadow index and registers
				// itself; the shadow system builds the matrices at frame time. A spot needs one
				// tile and a point six, one per cube face, and each atlas layer has its own
				// budget.
				let localCaster = component.CastsShadows
					&& ((component.Type == .Spot) || (component.Type == .Point));
				let tilesNeeded = (component.Type == .Point) ? 6u : 1u;
				let isStatic = (component.ShadowUpdate == .Static);
				let layerTiles = isStatic ? staticTiles : realtimeTiles;

				if (localCaster && (layerTiles + tilesNeeded <= RenderLimits.MaxLocalShadowTiles))
				{
					light.ShadowIndex = (float)flatEntries;

					var caster = LocalShadowCaster();
					caster.Type = (uint32)component.Type;
					caster.PositionWS = light.PositionWS;
					caster.DirectionWS = light.DirectionWS;
					caster.Range = component.Range;
					caster.OuterAngle = component.OuterAngle;
					caster.IsStatic = isStatic;
					outScene.AddLocalShadowCaster(caster);

					if (isStatic)
						staticTiles += tilesNeeded;
					else
						realtimeTiles += tilesNeeded;
					flatEntries += tilesNeeded;
				}

				outScene.AddLight(light);
			});
	}

	/// Reads the scene's environment into the snapshot.
	///
	/// A scene with no environment system keeps the snapshot's own dim default, which is what
	/// makes a bare scene still visible rather than black.
	public static void ExtractEnvironmentInto(Scene scene, ExtractedScene outScene)
	{
		let system = scene.GetSystem<EnvironmentSystem>();
		if (system == null)
			return;

		let settings = system.Environment;
		// The flat fill is premultiplied here, so the snapshot carries one colour rather than
		// a colour and a scale that every reader has to remember to combine.
		outScene.SetAmbient(Float3(settings.AmbientColor.R, settings.AmbientColor.G,
			settings.AmbientColor.B) * settings.AmbientIntensity);

		var sky = SkySnapshot();
		sky.Mode = settings.SkyMode;
		sky.Intensity = settings.SkyIntensity;
		sky.BackgroundIntensity = settings.SkyBackgroundIntensity;
		sky.Rotation = settings.SkyRotation;
		sky.Horizon = .(settings.SkyHorizon.R, settings.SkyHorizon.G, settings.SkyHorizon.B);
		sky.Zenith = .(settings.SkyZenith.R, settings.SkyZenith.G, settings.SkyZenith.B);
		sky.Ground = .(settings.SkyGround.R, settings.SkyGround.G, settings.SkyGround.B);
		sky.SunIntensity = settings.SunIntensity;
		sky.SunAngularSize = settings.SunAngularSize;
		sky.Turbidity = settings.Turbidity;
		sky.IblDiffuseIntensity = settings.IblDiffuseIntensity;
		sky.IblSpecularIntensity = settings.IblSpecularIntensity;

		// The resolved product, for the textured modes. The uid is what the lighting watches:
		// it rebuilds its environment products when the texture swaps, whether that was a pick
		// or a hot reload.
		if (let skyTexture = settings.SkyTexture.Get)
		{
			sky.Texture = skyTexture.View;
			sky.TextureUid = skyTexture.Uid;
			sky.TextureIsCube = skyTexture.IsCube;
		}

		outScene.SetSky(sky);
	}

	/// Reads the scene's reflection probes into the snapshot, capped at what the renderer can
	/// bind. The probe system captures and prefilters them at frame time.
	public static void ExtractReflectionProbesInto(Scene scene, ExtractedScene outScene)
	{
		let probes = scene.GetSystem<ReflectionProbeComponentManager>();
		if (probes == null)
			return;

		var count = 0u;
		probes.ForEach(scope [&] (component, entity) =>
			{
				if (!scene.IsEffectivelyActive(entity) || !component.Enabled
					|| (count >= RenderLimits.MaxReflectionProbes))
					return;

				let world = scene.GetWorldMatrix(entity);
				var probe = ReflectionProbe();
				probe.Key = PackEntity(entity);
				probe.Center = TransformPoint(Float3(0, 0, 0), world);
				probe.HalfExtents = component.HalfExtents;
				probe.BlendDistance = component.BlendDistance;
				probe.Intensity = component.Intensity;
				probe.Resolution = component.Resolution;
				probe.Priority = component.Priority;
				probe.Update = component.Update;
				probe.Parallax = component.Parallax;
				outScene.AddReflectionProbe(probe);
				count++;
			});
	}
}
