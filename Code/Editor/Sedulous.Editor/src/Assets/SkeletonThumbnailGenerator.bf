namespace Sedulous.Editor;

using System;
using Sedulous.Animation;
using Sedulous.Animation.Resources;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Core.Mathematics;
using Sedulous.Editor.Core;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Images;
using Sedulous.Resources;

/// Generates thumbnails for `.skeleton` assets by drawing a stick-figure
/// of the bind pose using the thumbnail scene's per-pipeline DebugDraw.
/// Mirrors the rendering used by SkeletonEditorPage so the thumbnail
/// matches what you see when you open the asset.
///
/// No entities are spawned in the thumbnail scene - the DebugGeometryPass
/// reads queued lines directly from the pipeline's DebugDraw, and the
/// renderer clears them at frame start. That makes cleanup trivial:
/// the ready closure has nothing to undo on the scene side.
class SkeletonThumbnailGenerator : IAssetThumbnailGenerator, IAsyncAssetThumbnailGenerator
{
	private ResourceSystem mResourceSystem;
	private ThumbnailRenderer mThumbnailRenderer;
	private ILogger mLogger;

	private ResourceHandle<SkeletonResource> mLoadedSkeleton;

	// Visual tuning matched to SkeletonEditorPage.
	private const float JointMarkerSize = 0.04f;

	public this(ResourceSystem resourceSystem, ThumbnailRenderer thumbnailRenderer, ILogger logger = null)
	{
		mResourceSystem = resourceSystem;
		mThumbnailRenderer = thumbnailRenderer;
		mLogger = logger;
	}

	public Result<OwnedImageData> GenerateThumbnail(StringView assetPath, int32 width, int32 height)
	{
		return .Err;
	}

	public bool GenerateThumbnailAsync(StringView assetPath, int32 width, int32 height,
		delegate void(OwnedImageData data) onComplete)
	{
		if (!mThumbnailRenderer.IsIdle)
			return false;

		if (mResourceSystem.LoadResource<SkeletonResource>(assetPath) case .Ok(let handle))
			mLoadedSkeleton = handle;
		else
		{
			mLogger?.LogWarning("[SkeletonThumbnail] LoadResource failed: {}", assetPath);
			onComplete(null);
			return true;
		}

		let skelRes = mLoadedSkeleton.Resource;
		let skeleton = skelRes?.Skeleton;
		if (skeleton == null || skeleton.BoneCount == 0)
		{
			mLogger?.LogWarning("[SkeletonThumbnail] skeleton resource is empty: {}", assetPath);
			mLoadedSkeleton.Release();
			onComplete(null);
			return true;
		}

		// Pre-compute world bind-pose positions for camera framing.
		// The build closure recomputes inside the DebugDraw walk because
		// owning the position array across the closure-Submit boundary
		// adds lifecycle complexity for no payoff (this is fast).
		let positions = new Vector3[skeleton.BoneCount];
		ComputeBoneWorldPositions(skeleton, positions);

		// Pad the AABB so a single-bone (degenerate) skeleton still has
		// visible extent, matching SkeletonEditorPage.ComputeBounds.
		var bounds = ComputeBoundsFromPositions(positions);
		let pad = Vector3(0.25f, 0.25f, 0.25f);
		bounds = .(bounds.Min - pad, bounds.Max + pad);
		let camera = FrameBoundingBox(bounds);

		let thumbnailRenderer = mThumbnailRenderer;

		// Build closure runs at Submit-time (during OnUpdate) - just sets
		// camera + clears the persistent entity. Lines CAN'T be pushed
		// here because RenderSubsystem.OnUpdate runs later in the same
		// frame and clears every pipeline's DebugDraw.
		ThumbnailBuildFn build = new (scene, cam) => {
			cam = camera;
			thumbnailRenderer.ResetAssetEntity();
		};

		// Pre-render closure runs from inside RenderPending, AFTER the
		// DebugDraw clear and JUST BEFORE the actual RenderScene. This
		// is when our lines have to be pushed.
		ThumbnailPreRenderFn preRender = new (scene) => {
			let debug = thumbnailRenderer.DebugDraw;
			if (debug == null)
			{
				delete positions;
				return;
			}

			let boneColor   = Color(220, 220, 100, 255);
			let jointColor  = Color(255, 180, 80, 255);

			for (int i = 0; i < skeleton.Bones.Count; i++)
			{
				let bone = skeleton.Bones[i];
				if (bone == null) continue;
				let pos = positions[i];

				// Joint cross marker so isolated joints (skeleton tips)
				// still register at the thumbnail scale.
				let s = JointMarkerSize;
				debug.DrawLine(pos - Vector3(s, 0, 0), pos + Vector3(s, 0, 0), jointColor);
				debug.DrawLine(pos - Vector3(0, s, 0), pos + Vector3(0, s, 0), jointColor);
				debug.DrawLine(pos - Vector3(0, 0, s), pos + Vector3(0, 0, s), jointColor);

				// Bone segment from parent to this joint.
				if (bone.ParentIndex >= 0 && bone.ParentIndex < positions.Count)
					debug.DrawLine(positions[bone.ParentIndex], pos, boneColor);
			}

			delete positions;
		};

		ThumbnailReadyFn ready = new (rgba, w, h) => {
			mLoadedSkeleton.Release();
			let data = new OwnedImageData(w, h, .RGBA8, rgba);
			onComplete(data);
		};

		if (!mThumbnailRenderer.Submit(build, ready, preRender))
		{
			mLoadedSkeleton.Release();
			delete positions;
			delete build;
			delete ready;
			delete preRender;
			return false;
		}
		return true;
	}

	/// Computes world bind-pose position for every bone using the same
	/// multiplication order as SkeletonEditorPage:
	///   root:    world = RootCorrection * local
	///   non-root: world = local * parentWorld
	/// Uses a fixed-point loop so bones whose parent index isn't strictly
	/// less than their own index (rare but possible in odd imports)
	/// still resolve in subsequent passes.
	private void ComputeBoneWorldPositions(Skeleton skeleton, Vector3[] outPositions)
	{
		let count = (int)skeleton.BoneCount;
		let worldMats = scope Matrix[count];
		let resolved = scope bool[count];
		int resolvedCount = 0;
		int safetyPasses = 0;

		while (resolvedCount < count && safetyPasses < count + 2)
		{
			for (int i = 0; i < count; i++)
			{
				if (resolved[i]) continue;
				let bone = skeleton.Bones[i];
				if (bone == null)
				{
					resolved[i] = true;
					resolvedCount++;
					continue;
				}

				let local = bone.LocalBindPose.ToMatrix();
				if (bone.ParentIndex < 0)
				{
					worldMats[i] = bone.RootCorrection * local;
					resolved[i] = true;
					resolvedCount++;
				}
				else if (resolved[bone.ParentIndex])
				{
					worldMats[i] = local * worldMats[bone.ParentIndex];
					resolved[i] = true;
					resolvedCount++;
				}
			}
			safetyPasses++;
		}

		for (int i = 0; i < count; i++)
			outPositions[i] = worldMats[i].Translation;
	}

	private BoundingBox ComputeBoundsFromPositions(Vector3[] positions)
	{
		if (positions.Count == 0)
			return .(.(-1, -1, -1), .(1, 1, 1));

		var min = positions[0];
		var max = positions[0];
		for (int i = 1; i < positions.Count; i++)
		{
			min = Vector3.Min(min, positions[i]);
			max = Vector3.Max(max, positions[i]);
		}
		return .(min, max);
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
