namespace Sedulous.Editor;

using System;
using System.Collections;
using System.IO;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Core.Mathematics;
using Sedulous.Editor.Core;
using Sedulous.Engine.Core;
using Sedulous.Engine.Core.Resources;
using Sedulous.Engine.Render;
using Sedulous.Geometry.Resources;
using Sedulous.Images;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.VFS;

/// Generates thumbnails for `.scene` assets. Loads the scene's entities
/// into the persistent thumbnail scene, auto-frames the combined mesh
/// content (or uses the scene's authored camera if it has one), renders,
/// and tears down the spawned entities after readback.
///
/// Unlike PrefabResource, SceneResource loads "header-only" - its Scene
/// field is null after LoadResource. To get the entity content we open
/// the .scene file via the mount, build a SceneSerializer, and call
/// `tempResource.Serialize(reader)` with the thumbnail scene attached
/// (this is the same pattern SceneEditorPageFactory uses to open
/// scenes). Pre/post snapshot of root entities lets us identify which
/// roots came from the load so we can destroy exactly those on
/// cleanup, leaving the thumbnail renderer's persistent sun + asset
/// entity untouched.
class SceneThumbnailGenerator : IAssetThumbnailGenerator, IAsyncAssetThumbnailGenerator
{
	private ResourceSystem mResourceSystem;
	private ThumbnailRenderer mThumbnailRenderer;
	private ComponentTypeRegistry mTypeRegistry;
	private ILogger mLogger;

	private ResourceHandle<SceneResource> mLoadedScene;
	private List<EntityHandle> mSpawnedRoots = new .() ~ delete _;
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

		// Hold a handle so the resource system caches the scene's GUID
		// (header-only - we don't actually need its content because the
		// deserialize uses raw file bytes below).
		if (mResourceSystem.LoadResource<SceneResource>(assetPath) case .Ok(let handle))
			mLoadedScene = handle;
		else
		{
			mLogger?.LogWarning("[SceneThumbnail] LoadResource failed: {}", assetPath);
			onComplete(null);
			return true;
		}

		// Resolve the URI to (mount, locator) so we can open the raw
		// scene file. Same scheme://locator split PrefabSpawner uses.
		IMount mount = null;
		StringView locator = .();
		if (!TrySplitUri(assetPath, out mount, out locator))
		{
			mLogger?.LogWarning("[SceneThumbnail] could not resolve URI to a mount: {}", assetPath);
			mLoadedScene.Release();
			onComplete(null);
			return true;
		}

		// Slurp the scene file's text. SceneSerializer takes a reader
		// built from the full text.
		let text = new String();
		if (!ReadTextFromMount(mount, locator, text))
		{
			mLogger?.LogWarning("[SceneThumbnail] read failed: {}", assetPath);
			delete text;
			mLoadedScene.Release();
			onComplete(null);
			return true;
		}

		let thumbnailRenderer = mThumbnailRenderer;
		let typeRegistry = mTypeRegistry;
		let resourceSystem = mResourceSystem;
		let logger = mLogger;
		let spawnedRoots = mSpawnedRoots;

		ThumbnailBuildFn build = new (scene, cam) => {
			mSpawnedScene = scene;
			thumbnailRenderer.ResetAssetEntity();

			// Snapshot existing roots so we can diff after the load and
			// discover what the deserializer added. The thumbnail scene
			// always has the renderer's sun + asset entity here; any
			// other roots are from the loaded scene.
			let existingRoots = scope HashSet<EntityHandle>();
			{
				var cur = scene.FirstRoot;
				while (cur.IsAssigned)
				{
					existingRoots.Add(cur);
					cur = scene.GetNextSibling(cur);
				}
			}

			// Deserialize the scene file into our thumbnail scene.
			// Mirrors SceneEditorPageFactory.CreatePage's loading path.
			let provider = resourceSystem.SerializerProvider;
			let reader = provider?.CreateReader(text);
			if (reader == null)
			{
				logger?.LogWarning("[SceneThumbnail] SerializerProvider returned null reader");
				delete text;
				cam = FrameBoundingBox(.(.(-1, -1, -1), .(1, 1, 1)));
				return;
			}
			defer delete reader;

			let sceneSerializer = scope SceneSerializer(typeRegistry, provider, resourceSystem);
			let tempResource = scope SceneResource();
			tempResource.Scene = scene;
			tempResource.SceneSerializer = sceneSerializer;
			tempResource.Serialize(reader);

			// Discover the newly-added roots.
			{
				var cur = scene.FirstRoot;
				while (cur.IsAssigned)
				{
					if (!existingRoots.Contains(cur))
						spawnedRoots.Add(cur);
					cur = scene.GetNextSibling(cur);
				}
			}

			// Camera: if the loaded scene has an active CameraComponent
			// on one of the spawned entities, honor it. Else auto-frame
			// the combined mesh bounds.
			if (TryUseSceneCamera(scene, spawnedRoots, var sceneCam))
				cam = sceneCam;
			else
			{
				let bounds = ComputeSceneBounds(scene, spawnedRoots, resourceSystem);
				cam = FrameBoundingBox(bounds);
			}

			delete text;
		};

		ThumbnailReadyFn ready = new (rgba, w, h) => {
			// Destroy every root the load created. DestroyEntity is
			// recursive so each call cleans up the whole subtree
			// associated with that root.
			if (mSpawnedScene != null)
			{
				for (let handle in mSpawnedRoots)
				{
					if (handle.IsAssigned)
						mSpawnedScene.DestroyEntity(handle);
				}
			}
			mSpawnedRoots.Clear();
			mSpawnedScene = null;

			mLoadedScene.Release();

			let data = new OwnedImageData(w, h, .RGBA8, rgba);
			onComplete(data);
		};

		if (!mThumbnailRenderer.Submit(build, ready))
		{
			mLoadedScene.Release();
			delete text;
			delete build;
			delete ready;
			return false;
		}
		return true;
	}

	/// Splits `uri` into a registered mount and a locator. Returns false
	/// if the scheme isn't mapped to a mount.
	private bool TrySplitUri(StringView uri, out IMount mount, out StringView locator)
	{
		mount = null;
		locator = .();

		let schemeSep = uri.IndexOf("://");
		if (schemeSep <= 0) return false;
		let scheme = uri.Substring(0, schemeSep);
		locator = uri.Substring(schemeSep + 3);

		mount = mResourceSystem.GetMount(scheme);
		return mount != null;
	}

	/// Reads the full contents of `locator` from `mount` as UTF-8 text.
	private bool ReadTextFromMount(IMount mount, StringView locator, String outText)
	{
		let openResult = mount.Open(locator);
		if (openResult case .Err) return false;
		let stream = openResult.Value;
		defer delete stream;

		let len = (int)stream.Length;
		if (len <= 0) return true;

		let buf = scope uint8[len];
		switch (stream.TryRead(.(&buf[0], len)))
		{
		case .Ok(let n):
			if (n != len) return false;
			outText.Append((char8*)&buf[0], len);
			return true;
		case .Err:
			return false;
		}
	}

	/// Walks the spawned roots looking for an entity with an active
	/// CameraComponent. If found, builds a CameraOverride from its
	/// FOV/near/far + its world transform. Returns false if no usable
	/// camera was found, so the caller falls back to auto-framing.
	private bool TryUseSceneCamera(Scene scene, List<EntityHandle> roots, out CameraOverride camera)
	{
		camera = .();

		let cameraMgr = scene.GetModule<CameraComponentManager>();
		if (cameraMgr == null) return false;

		for (let root in roots)
		{
			let handle = FindCameraIn(scene, root, cameraMgr);
			if (handle.IsAssigned)
			{
				let comp = cameraMgr.GetForEntity(handle);
				if (comp == null) return false;

				// We're running in the build closure - the scene tick
				// hasn't fired yet for the just-deserialized entities,
				// so scene.GetWorldMatrix() returns a stale (Identity)
				// matrix. Compute the camera's world transform manually
				// by walking up the parent chain, then invert it to get
				// the view matrix (same as CameraComponent.GetViewMatrix
				// does internally, just on a freshly-computed world).
				let world = ComputeWorldMatrix(scene, handle);
				Matrix viewMatrix = .Identity;
				Matrix.Invert(world, out viewMatrix);

				// Thumbnails are square so aspect = 1. The component's
				// own GetProjectionMatrix handles FOV unit conversion +
				// AspectRatio override.
				let projMatrix = comp.GetProjectionMatrix(1.0f);

				camera = .() {
					ViewMatrix = viewMatrix,
					ProjectionMatrix = projMatrix,
					CameraPosition = world.Translation,
					NearPlane = comp.NearPlane,
					FarPlane = comp.FarPlane
				};
				return true;
			}
		}
		return false;
	}

	/// Computes the world matrix of `entity` by walking the parent
	/// chain, multiplying local transforms. Mirrors what
	/// Scene.UpdateTransforms() does internally - we need this because
	/// the cached WorldMatrix isn't populated until the scene ticks,
	/// and we run in the build closure before that happens.
	///
	/// The recursion formula in Scene is `world = local * parentWorld`,
	/// so walking child-to-root we accumulate `m = m * local`.
	private Matrix ComputeWorldMatrix(Scene scene, EntityHandle entity)
	{
		var m = Matrix.Identity;
		var cur = entity;
		while (cur.IsAssigned)
		{
			let local = scene.GetLocalTransform(cur);
			m = m * local.ToMatrix();
			cur = scene.GetParent(cur);
		}
		return m;
	}

	/// Recursively searches the subtree rooted at `entity` for an
	/// active CameraComponent. Returns .Invalid if none found.
	private EntityHandle FindCameraIn(Scene scene, EntityHandle entity, CameraComponentManager cameraMgr)
	{
		if (let comp = cameraMgr.GetForEntity(entity))
		{
			if (comp.IsActive && comp.IsActiveCamera)
				return entity;
		}

		var child = scene.GetFirstChild(entity);
		while (child.IsAssigned)
		{
			let found = FindCameraIn(scene, child, cameraMgr);
			if (found.IsAssigned) return found;
			child = scene.GetNextSibling(child);
		}
		return .Invalid;
	}

	/// Combined bounds of every MeshComponent reachable from any spawned
	/// root. Loads meshes by ref (cached on repeat thumbnails) and
	/// transforms local bounds through hand-computed world matrices,
	/// same as the prefab generator's walker.
	private BoundingBox ComputeSceneBounds(Scene scene, List<EntityHandle> roots, ResourceSystem resourceSystem)
	{
		let meshMgr = scene.GetModule<MeshComponentManager>();
		if (meshMgr == null)
			return .(.(-1, -1, -1), .(1, 1, 1));

		var result = BoundingBox(.Zero, .Zero);
		var hasAny = false;

		for (let root in roots)
			WalkEntity(scene, root, meshMgr, .Identity, ref result, ref hasAny, resourceSystem);

		if (!hasAny)
			return .(.(-1, -1, -1), .(1, 1, 1));

		return result;
	}

	private void WalkEntity(Scene scene, EntityHandle entity, MeshComponentManager meshMgr,
		Matrix parentWorld, ref BoundingBox result, ref bool hasAny, ResourceSystem resourceSystem)
	{
		let local = scene.GetLocalTransform(entity);
		let world = local.ToMatrix() * parentWorld;

		if (let comp = meshMgr.GetForEntity(entity))
		{
			let meshRef = comp.MeshRef;
			if (meshRef.HasId || meshRef.HasPath)
			{
				if (resourceSystem.LoadByRef<StaticMeshResource>(meshRef) case .Ok(var meshHandle))
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
			WalkEntity(scene, child, meshMgr, world, ref result, ref hasAny, resourceSystem);
			child = scene.GetNextSibling(child);
		}
	}

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
