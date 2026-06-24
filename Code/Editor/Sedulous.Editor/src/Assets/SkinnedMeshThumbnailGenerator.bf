namespace Sedulous.Editor;

using System;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Core.Mathematics;
using Sedulous.Editor.Core;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Geometry.Resources;
using Sedulous.Images;
using Sedulous.Resources;

/// Generates thumbnails for `.skinnedmesh` assets. Mirrors the static
/// mesh path: load the SkinnedMeshResource, set MeshRef on the
/// persistent asset entity's SkinnedMeshComponent, frame the camera
/// from the mesh's bounds, render.
///
/// No animation component is attached. SkinnedMeshComponentManager
/// uploads identity bone matrices when the entity has no skeletal
/// animation source, so the mesh renders in its bind (T-) pose -
/// which is exactly what we want for an at-a-glance thumbnail.
class SkinnedMeshThumbnailGenerator : IAssetThumbnailGenerator, IAsyncAssetThumbnailGenerator
{
	private ResourceSystem mResourceSystem;
	private ThumbnailRenderer mThumbnailRenderer;
	private ILogger mLogger;

	// Held across the async dispatch so the resource doesn't unload
	// between Submit (which captures the ID) and the GPU consuming it.
	private ResourceHandle<SkinnedMeshResource> mLoadedMesh;

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
		if (!mThumbnailRenderer.IsIdle)
			return false;

		if (mResourceSystem.LoadResource<SkinnedMeshResource>(assetPath) case .Ok(let handle))
			mLoadedMesh = handle;
		else
		{
			mLogger?.LogWarning("[SkinnedMeshThumbnail] LoadResource failed: {}", assetPath);
			onComplete(null);
			return true;
		}

		let meshRes = mLoadedMesh.Resource;
		if (meshRes == null || meshRes.Mesh == null)
		{
			mLogger?.LogWarning("[SkinnedMeshThumbnail] meshRes or meshRes.Mesh is null: {}", assetPath);
			mLoadedMesh.Release();
			onComplete(null);
			return true;
		}

		let camera = FrameBoundingBox(meshRes.Mesh.Bounds);
		let meshId = meshRes.Id;

		let assetEntity = mThumbnailRenderer.AssetEntity;
		let thumbnailRenderer = mThumbnailRenderer;
		ThumbnailBuildFn build = new (scene, cam) => {
			cam = camera;
			thumbnailRenderer.ResetAssetEntity();
			let skinnedMgr = scene.GetModule<SkinnedMeshComponentManager>();
			if (skinnedMgr == null) return;
			if (let comp = skinnedMgr.GetForEntity(assetEntity))
			{
				// id + URI: id-keyed cache hit on repeat thumbnails,
				// URI fallback for cold loads.
				var meshRef = ResourceRef(meshId, assetPath);
				comp.SetMeshRef(meshRef);
				meshRef.Dispose();
			}
		};

		ThumbnailReadyFn ready = new (rgba, w, h) => {
			mLoadedMesh.Release();
			let data = new OwnedImageData(w, h, .RGBA8, rgba);
			onComplete(data);
		};

		if (!mThumbnailRenderer.Submit(build, ready))
		{
			mLoadedMesh.Release();
			delete build;
			delete ready;
			return false;
		}
		return true;
	}

	/// Same framing math as `MeshThumbnailGenerator.FrameBoundingBox` so
	/// static and skinned previews share visual scale across the asset
	/// browser.
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
