namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Core.Mathematics;
using Sedulous.Editor.Core;
using Sedulous.Engine.Core;
using Sedulous.Engine.Core.Resources;
using Sedulous.Engine.Render;
using Sedulous.Engine.Renderer;
using Sedulous.Geometry.Resources;
using Sedulous.Images;
using Sedulous.Resources;

/// Generates thumbnails for `.prefab` assets by spawning the prefab as a
/// root entity tree in the thumbnail scene, auto-framing the combined
/// world bounds of its mesh content, and rendering through the same
/// async pipeline the other generators use.
///
/// Bounds are computed at submit time by walking the spawned entity tree
/// (NOT the PrefabResource itself - resource loads are "header-only" by
/// design and PrefabResource.Scene is null in that path). For each
/// MeshComponent we load the referenced StaticMeshResource (cached on
/// repeat thumbnails) and transform its local bounds by an entity world
/// matrix we compute by hand from local transforms + parent chain. The
/// thumbnail scene's transform cache isn't filled until its tick, which
/// hasn't happened yet at submit time.
class PrefabThumbnailGenerator : IAssetThumbnailGenerator, IAsyncAssetThumbnailGenerator
{
	private ResourceSystem mResourceSystem;
	private ThumbnailRenderer mThumbnailRenderer;
	private ComponentTypeRegistry mTypeRegistry;
	private ILogger mLogger;

	// Async dispatch state. Single in-flight job (the renderer enforces
	// this), so a single slot is sufficient.
	private ResourceHandle<PrefabResource> mLoadedPrefab;
	private EntityHandle mSpawnedRoot;
	private Dictionary<Guid, EntityHandle> mSpawnedGuidMap;
	private Scene mSpawnedScene; // not owned; set in build, used in ready

	public this(ResourceSystem resourceSystem, ThumbnailRenderer thumbnailRenderer,
		ComponentTypeRegistry typeRegistry, ILogger logger = null)
	{
		mResourceSystem = resourceSystem;
		mThumbnailRenderer = thumbnailRenderer;
		mTypeRegistry = typeRegistry;
		mLogger = logger;
	}

	/// Synchronous interface entry - unused; we always go through the
	/// async path. The service falls back to async when this returns Err.
	public Result<OwnedImageData> GenerateThumbnail(StringView assetPath, int32 width, int32 height)
	{
		return .Err;
	}

	public bool GenerateThumbnailAsync(StringView assetPath, int32 width, int32 height,
		delegate void(OwnedImageData data) onComplete)
	{
		if (!mThumbnailRenderer.IsIdle)
			return false;

		if (mResourceSystem.LoadResource<PrefabResource>(assetPath) case .Ok(let handle))
			mLoadedPrefab = handle;
		else
		{
			mLogger?.LogWarning("[PrefabThumbnail] LoadResource failed: {}", assetPath);
			onComplete(null);
			return true;
		}

		let prefabRes = mLoadedPrefab.Resource;
		if (prefabRes == null)
		{
			mLogger?.LogWarning("[PrefabThumbnail] prefab resource is null: {}", assetPath);
			mLoadedPrefab.Release();
			onComplete(null);
			return true;
		}

		// PrefabResource loads "header-only" via the resource system - its
		// Scene field is null in that path - so we can't pre-compute bounds
		// from the cached resource. Instead, spawn the prefab into the
		// thumbnail scene during the build closure and walk the spawned
		// tree to compute bounds before returning the camera.
		let prefabId = prefabRes.Id;
		let assetPathCopy = new String(assetPath);

		let assetEntity = mThumbnailRenderer.AssetEntity;
		ThumbnailBuildFn build = new (scene, cam) => {
			mSpawnedScene = scene;

			// Hide the persistent asset entity by clearing its MeshRef.
			// On the next resolver tick, MeshHandle becomes Invalid and
			// the extraction loop skips it. Prefab-spawned entities are
			// independent of this one.
			let meshMgr = scene.GetModule<MeshComponentManager>();
			if (meshMgr != null)
			{
				if (let comp = meshMgr.GetForEntity(assetEntity))
				{
					var emptyRef = ResourceRef();
					comp.SetMeshRef(emptyRef);
					emptyRef.Dispose();
				}
			}

			// Spawn the prefab as a root entity tree. The spawn pulls in
			// its meshes/materials through the resource system (cached
			// across thumbnail requests of the same prefab).
			var prefabRef = ResourceRef(prefabId, assetPathCopy);
			if (PrefabSpawner.Spawn(scene, prefabRef, prefabId, .Invalid,
				mTypeRegistry, mResourceSystem.SerializerProvider, mResourceSystem) case .Ok(let result))
			{
				mSpawnedRoot = result.RootEntity;
				mSpawnedGuidMap = result.GuidMap;

				// Frame the camera to the just-spawned content. MeshRefs are
				// already set by Spawn; we manually compute world matrices
				// since the scene tick hasn't run yet.
				let bounds = ComputeSpawnedBounds(scene, mSpawnedRoot);
				cam = FrameBoundingBox(bounds);
			}
			else
			{
				mLogger?.LogWarning("[PrefabThumbnail] PrefabSpawner.Spawn failed");
				cam = FrameBoundingBox(.(.(-1, -1, -1), .(1, 1, 1)));
			}
			prefabRef.Dispose();
			delete assetPathCopy;
		};

		ThumbnailReadyFn ready = new (rgba, w, h) => {
			// Tear the spawned entity tree down so the next thumbnail
			// starts from a clean thumbnail scene. DestroyEntity is
			// recursive across the prefab's children.
			if (mSpawnedRoot.IsAssigned && mSpawnedScene != null)
				mSpawnedScene.DestroyEntity(mSpawnedRoot);
			mSpawnedRoot = .Invalid;
			mSpawnedScene = null;

			if (mSpawnedGuidMap != null)
			{
				delete mSpawnedGuidMap;
				mSpawnedGuidMap = null;
			}

			mLoadedPrefab.Release();

			let data = new OwnedImageData(w, h, .RGBA8, rgba);
			onComplete(data);
		};

		if (!mThumbnailRenderer.Submit(build, ready))
		{
			// Race: another submit slipped in. Reclaim everything and
			// let the service retry next frame.
			mLoadedPrefab.Release();
			delete assetPathCopy;
			delete build;
			delete ready;
			return false;
		}
		return true;
	}

	/// Walks the just-spawned prefab tree (starting at `root`) to compute
	/// the AABB of every mesh component's world-space bounds. World
	/// matrices are computed manually from local transforms + parent
	/// chain because the scene tick hasn't run since Spawn populated
	/// transforms. Falls back to a unit cube when nothing is renderable.
	private BoundingBox ComputeSpawnedBounds(Scene scene, EntityHandle root)
	{
		let meshMgr = scene.GetModule<MeshComponentManager>();
		if (meshMgr == null || !root.IsAssigned)
			return .(.(-1, -1, -1), .(1, 1, 1));

		var result = BoundingBox(.Zero, .Zero);
		var hasAny = false;

		WalkSpawnedEntity(scene, root, meshMgr, .Identity, ref result, ref hasAny);

		if (!hasAny)
			return .(.(-1, -1, -1), .(1, 1, 1));

		return result;
	}

	private void WalkSpawnedEntity(Scene scene, EntityHandle entity, MeshComponentManager meshMgr,
		Matrix parentWorld, ref BoundingBox result, ref bool hasAny)
	{
		let local = scene.GetLocalTransform(entity);
		let world = local.ToMatrix() * parentWorld;

		if (let comp = meshMgr.GetForEntity(entity))
		{
			let meshRef = comp.MeshRef;
			if (meshRef.HasId || meshRef.HasPath)
			{
				if (mResourceSystem.LoadByRef<StaticMeshResource>(meshRef) case .Ok(var meshHandle))
				{
					let meshRes = meshHandle.Resource;
					if (meshRes?.Mesh != null)
					{
						let xfBounds = TransformBounds(meshRes.Mesh.GetBounds(), world);
						if (!hasAny)
						{
							result = xfBounds;
							hasAny = true;
						}
						else
						{
							BoundingBox.CreateMerged(result, xfBounds, out result);
						}
					}
					meshHandle.Release();
				}
			}
		}

		var child = scene.GetFirstChild(entity);
		while (child.IsAssigned)
		{
			WalkSpawnedEntity(scene, child, meshMgr, world, ref result, ref hasAny);
			child = scene.GetNextSibling(child);
		}
	}

	/// Returns the AABB enclosing the 8 transformed corners of `b`.
	/// Necessary because non-axis-aligned rotations turn a tight local
	/// AABB into a larger world-space one - we can't just transform min
	/// and max independently.
	private BoundingBox TransformBounds(BoundingBox b, Matrix m)
	{
		Vector3[8] corners = .(
			.(b.Min.X, b.Min.Y, b.Min.Z),
			.(b.Max.X, b.Min.Y, b.Min.Z),
			.(b.Min.X, b.Max.Y, b.Min.Z),
			.(b.Max.X, b.Max.Y, b.Min.Z),
			.(b.Min.X, b.Min.Y, b.Max.Z),
			.(b.Max.X, b.Min.Y, b.Max.Z),
			.(b.Min.X, b.Max.Y, b.Max.Z),
			.(b.Max.X, b.Max.Y, b.Max.Z));

		var first = Vector3.Transform(corners[0], m);
		var min = first;
		var max = first;
		for (int i = 1; i < 8; i++)
		{
			let p = Vector3.Transform(corners[i], m);
			min = Vector3.Min(min, p);
			max = Vector3.Max(max, p);
		}
		return BoundingBox(min, max);
	}

	/// Frames `bounds` at the standard down-and-from-front-right angle
	/// the other generators use. Distance fits the bounding sphere at
	/// the chosen FOV with a margin so the geometry doesn't graze the
	/// edge of the frustum.
	private CameraOverride FrameBoundingBox(BoundingBox bounds)
	{
		let center = bounds.Center;
		let extent = bounds.Max - bounds.Min;
		let radius = Math.Max(0.001f, extent.Length() * 0.5f);

		const float fovDeg = 45.0f;
		const float marginFactor = 1.3f;
		let fov = fovDeg * (Math.PI_f / 180.0f);

		let halfFovSin = (float)Math.Sin(fov * 0.5f);
		let distance = (radius / Math.Max(halfFovSin, 0.01f)) * marginFactor;

		let dir = Vector3.Normalize(.(1.0f, 0.6f, 1.0f));
		let eye = center + dir * distance;
		let viewMatrix = Matrix.CreateLookAt(eye, center, .(0, 1, 0));

		const float aspect = 1.0f;
		let nearP = Math.Max(0.001f, distance * 0.05f);
		let farP = Math.Max(distance * 4.0f, radius * 20.0f);
		let projMatrix = Matrix.CreatePerspectiveFieldOfView(fov, aspect, nearP, farP);

		return CameraOverride() {
			ViewMatrix = viewMatrix,
			ProjectionMatrix = projMatrix,
			CameraPosition = eye,
			NearPlane = nearP,
			FarPlane = farP
		};
	}
}
