namespace Sedulous.Editor.App;

using System;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Core.Mathematics;
using Sedulous.Editor.Core;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Engine.Renderer;
using Sedulous.Images;
using Sedulous.Materials.Resources;
using Sedulous.Resources;

/// Generates thumbnails for `.material` assets by binding the material to
/// a built-in sphere (owned by `ThumbnailRenderer`) and rendering the
/// scene through the same async pipeline the mesh generator uses.
///
/// The sphere is registered with the resource system at thumbnail-renderer
/// startup, so the standard MeshComponentManager + RenderResourceResolver
/// pipeline resolves both the sphere mesh and this generator's material
/// ref without any per-render bypass logic.
class MaterialThumbnailGenerator : IAssetThumbnailGenerator, IAsyncAssetThumbnailGenerator
{
	private ResourceSystem mResourceSystem;
	private ThumbnailRenderer mThumbnailRenderer;
	private ILogger mLogger;

	// Held across the async dispatch to keep the material alive between
	// Submit (when we capture the ID) and the GPU's consumption.
	private ResourceHandle<MaterialResource> mLoadedMaterial;

	public this(ResourceSystem resourceSystem, ThumbnailRenderer thumbnailRenderer, ILogger logger = null)
	{
		mResourceSystem = resourceSystem;
		mThumbnailRenderer = thumbnailRenderer;
		mLogger = logger;
	}

	/// Synchronous interface entry - unused for async generators, but the
	/// interface contract requires it. Returns Err so the service falls
	/// back to the async path.
	public Result<OwnedImageData> GenerateThumbnail(StringView assetPath, int32 width, int32 height)
	{
		return .Err;
	}

	public bool GenerateThumbnailAsync(StringView assetPath, int32 width, int32 height,
		delegate void(OwnedImageData data) onComplete)
	{
		// Decline early when the renderer is busy - no point loading the
		// material just to drop it. ThumbnailService re-queues us.
		if (!mThumbnailRenderer.IsIdle)
			return false;

		if (mResourceSystem.LoadResource<MaterialResource>(assetPath) case .Ok(let handle))
			mLoadedMaterial = handle;
		else
		{
			mLogger?.LogWarning("[MaterialThumbnail] LoadResource failed: {}", assetPath);
			onComplete(null);
			return true;
		}

		let matRes = mLoadedMaterial.Resource;
		if (matRes == null)
		{
			mLogger?.LogWarning("[MaterialThumbnail] material resource is null: {}", assetPath);
			mLoadedMaterial.Release();
			onComplete(null);
			return true;
		}

		// Sphere bounds are constant (radius 0.5 → unit cube), so the
		// camera framing is fixed across every material thumbnail.
		let camera = FrameSphere();
		let materialId = matRes.Id;
		let sphereId = mThumbnailRenderer.SphereMeshId;

		// Capture the URI for the resolver's URI-keyed cache lookup.
		// Heap-allocated copy so the closure can survive past this stack
		// frame; the closure frees it after first use (build runs once).
		let assetPathCopy = new String(assetPath);

		let assetEntity = mThumbnailRenderer.AssetEntity;
		ThumbnailBuildFn build = new (scene, cam) => {
			cam = camera;
			let meshMgr = scene.GetModule<MeshComponentManager>();
			if (meshMgr == null)
			{
				delete assetPathCopy;
				return;
			}
			if (let comp = meshMgr.GetForEntity(assetEntity))
			{
				// Sphere mesh ref: GUID-only (no URI since it's in-memory).
				// MeshResolveResolver's LoadByRef falls back to GUID lookup
				// in the resource cache when the URI is empty.
				var sphereRef = ResourceRef(sphereId, "");
				comp.SetMeshRef(sphereRef);
				sphereRef.Dispose();

				// Material on slot 0 - the only slot a single-submesh
				// sphere has.
				var matRef = ResourceRef(materialId, assetPathCopy);
				comp.SetMaterialRef(0, matRef);
				matRef.Dispose();
			}
			delete assetPathCopy;
		};

		ThumbnailReadyFn ready = new (rgba, w, h) => {
			mLoadedMaterial.Release();
			let data = new OwnedImageData(w, h, .RGBA8, rgba);
			onComplete(data);
		};

		if (!mThumbnailRenderer.Submit(build, ready))
		{
			// Race: another caller claimed the renderer between our
			// IsIdle check and Submit. Release everything; service retries.
			mLoadedMaterial.Release();
			delete assetPathCopy;
			delete build;
			delete ready;
			return false;
		}
		return true;
	}

	/// Fixed framing for the built-in sphere (radius 0.5, centered at
	/// origin). Mirrors `MeshThumbnailGenerator.FrameBoundingBox` so
	/// material previews and mesh previews share visual scale.
	private CameraOverride FrameSphere()
	{
		const float radius = 0.5f;
		const float fovDeg = 45.0f;
		const float marginFactor = 1.3f;
		let fov = fovDeg * (Math.PI_f / 180.0f);

		let halfFovSin = (float)Math.Sin(fov * 0.5f);
		let distance = (radius / Math.Max(halfFovSin, 0.01f)) * marginFactor;

		let dir = Vector3.Normalize(.(1.0f, 0.6f, 1.0f));
		let eye = Vector3.Zero + dir * distance;
		let viewMatrix = Matrix.CreateLookAt(eye, .Zero, .(0, 1, 0));

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
