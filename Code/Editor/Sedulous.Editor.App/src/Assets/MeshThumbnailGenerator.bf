namespace Sedulous.Editor.App;

using System;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Core.Mathematics;
using Sedulous.Editor.Core;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Engine.Renderer;
using Sedulous.Geometry.Resources;
using Sedulous.Images;
using Sedulous.Resources;

/// Generates thumbnails for `.mesh` static-mesh assets. Loads the
/// `StaticMeshResource`, instantiates a single entity with a
/// MeshComponent pointing at it in the ThumbnailRenderer's persistent
/// scene, auto-frames the camera from the mesh's bounding box, and
/// hands the result back through the async generator contract.
///
/// Models the same scene-setup pattern as the ModelViewer tool (entity
/// + MeshComponent.SetMeshRef + MeshComponentManager), just with a
/// throwaway entity that the ThumbnailRenderer cleans up after readback.
class MeshThumbnailGenerator : IAssetThumbnailGenerator, IAsyncAssetThumbnailGenerator
{
	private ResourceSystem mResourceSystem;
	private ThumbnailRenderer mThumbnailRenderer;
	private ILogger mLogger;

	// Held across the async dispatch so the resource doesn't get unloaded
	// between Submit (which captures the ID) and the GPU consuming it.
	// The renderer serializes one job at a time, so a single field is
	// sufficient; if we raise that limit this becomes per-job state.
	private ResourceHandle<StaticMeshResource> mLoadedMesh;

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
		// Decline early if the renderer is already busy - no point
		// loading the resource just to release it again. The service
		// will retry next frame.
		if (!mThumbnailRenderer.IsIdle)
			return false;

		if (mResourceSystem.LoadResource<StaticMeshResource>(assetPath) case .Ok(let handle))
			mLoadedMesh = handle;
		else
		{
			mLogger?.LogWarning("[MeshThumbnail] LoadResource failed: {}", assetPath);
			onComplete(null);
			return true;
		}

		let meshRes = mLoadedMesh.Resource;
		if (meshRes == null || meshRes.Mesh == null)
		{
			mLogger?.LogWarning("[MeshThumbnail] meshRes or meshRes.Mesh is null: {}", assetPath);
			mLoadedMesh.Release();
			onComplete(null);
			return true;
		}

		// Compute the camera that frames the bounding box. Captured by
		// value into the build closure - CameraOverride is a value type.
		let camera = FrameBoundingBox(meshRes.Mesh.GetBounds());
		let meshId = meshRes.Id;

		// Build closure: update the renderer's persistent asset entity
		// for this request. Runs synchronously inside
		// ThumbnailRenderer.Submit (during OnUpdate), so the scene's
		// component-manager tick has a frame to resolve the new
		// MeshRef before the render fires.
		let assetEntity = mThumbnailRenderer.AssetEntity;
		ThumbnailBuildFn build = new (scene, cam) => {
			cam = camera;
			let meshMgr = scene.GetModule<MeshComponentManager>();
			if (meshMgr == null) return;
			if (let comp = meshMgr.GetForEntity(assetEntity))
			{
				// Pass both id AND the URI path so RenderResourceResolver
				// hits the URI-keyed resource cache directly. id-only
				// refs require ResolveUriFromId to walk the project
				// index; sidestep that until we know the index is loaded.
				var meshRef = ResourceRef(meshId, assetPath);
				comp.SetMeshRef(meshRef);
				meshRef.Dispose();

				// Clear any material ref left over from a prior material
				// thumbnail render. Without this, .mesh previews would
				// inherit the last-rendered .material when the persistent
				// entity is shared between generators.
				var emptyMatRef = ResourceRef();
				comp.SetMaterialRef(0, emptyMatRef);
				emptyMatRef.Dispose();
			}
		};

		// Ready closure: wrap the readback pixels in OwnedImageData and
		// release the resource handle (GPU no longer needs the mesh).
		ThumbnailReadyFn ready = new (rgba, w, h) => {
			mLoadedMesh.Release();
			let data = new OwnedImageData(w, h, .RGBA8, rgba);
			onComplete(data);
		};

		if (!mThumbnailRenderer.Submit(build, ready))
		{
			// Race: another request slipped in between our IsIdle check
			// and Submit. Release everything and tell the service to
			// retry this request next frame.
			mLoadedMesh.Release();
			delete build;
			delete ready;
			return false;
		}
		return true;
	}

	/// Returns a CameraOverride that frames `bounds` at a fixed angle.
	/// Direction looks down-and-from-front-right; distance is chosen so
	/// the mesh's bounding sphere fits the frame at the chosen FOV with
	/// a margin factor so meshes near the edge of the frustum aren't
	/// clipped by subpixel slop / depth-pass culling.
	private CameraOverride FrameBoundingBox(BoundingBox bounds)
	{
		let center = bounds.Center;
		let extent = bounds.Max - bounds.Min;
		let radius = Math.Max(0.001f, extent.Length() * 0.5f);

		const float fovDeg = 45.0f;
		const float marginFactor = 1.3f; // leave headroom around the sphere
		let fov = fovDeg * (Math.PI_f / 180.0f);

		// Distance so that the bounding sphere fits the half-FOV with
		// the chosen margin. distance = radius / sin(halfFov) * margin.
		let halfFovSin = (float)Math.Sin(fov * 0.5f);
		let distance = (radius / Math.Max(halfFovSin, 0.01f)) * marginFactor;

		let dir = Vector3.Normalize(.(1.0f, 0.6f, 1.0f));
		let eye = center + dir * distance;
		let viewMatrix = Matrix.CreateLookAt(eye, center, .(0, 1, 0));

		const float aspect = 1.0f; // thumbnail RT is square.
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
