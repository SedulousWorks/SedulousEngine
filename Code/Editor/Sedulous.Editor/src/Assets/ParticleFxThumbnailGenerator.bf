namespace Sedulous.Editor;

using System;
using Sedulous.Core.Logging.Abstractions;
using Sedulous.Core.Mathematics;
using Sedulous.Editor.Core;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Images;
using Sedulous.Particles.Resources;
using Sedulous.Resources;

/// Generates thumbnails for `.particlefx` assets. Sets the effect ref on
/// the persistent asset entity's ParticleComponent, fast-forwards the
/// thumbnail scene through ~0.5s of simulation so enough particles have
/// emitted to look interesting, then renders.
///
/// Fast-forwarding works because `Scene.Update(dt)` is public and runs
/// the same phases SceneSubsystem.Update would. The thumbnail scene's
/// SimulationEnabled is forced true by ThumbnailRenderer, so the
/// `simulationOnly` particle update runs. SceneSubsystem also ticks
/// the scene once more later in the frame; that extra tick is one
/// additional dt of simulation, negligible for a thumbnail.
class ParticleFxThumbnailGenerator : IAssetThumbnailGenerator, IAsyncAssetThumbnailGenerator
{
	private ResourceSystem mResourceSystem;
	private ThumbnailRenderer mThumbnailRenderer;
	private ILogger mLogger;

	private ResourceHandle<ParticleEffectResource> mLoadedEffect;

	/// Fast-forward configuration. 30 steps × 1/60s = 0.5s of warmup,
	/// enough for short-burst effects to have most of their particles
	/// emitted and for longer-lifetime emitters to have populated the
	/// near-field of their volume. Tuning per-effect would mean reading
	/// from effect metadata - revisit if specific effects look empty.
	private const int32 WarmupSteps = 30;
	private const float WarmupStepDt = 1.0f / 60.0f;

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

		if (mResourceSystem.LoadResource<ParticleEffectResource>(assetPath) case .Ok(let handle))
			mLoadedEffect = handle;
		else
		{
			mLogger?.LogWarning("[ParticleFxThumbnail] LoadResource failed: {}", assetPath);
			onComplete(null);
			return true;
		}

		let effectRes = mLoadedEffect.Resource;
		if (effectRes == null)
		{
			mLogger?.LogWarning("[ParticleFxThumbnail] effect resource is null: {}", assetPath);
			mLoadedEffect.Release();
			onComplete(null);
			return true;
		}

		// Fixed camera framing - particles don't have stable bounds
		// (they spread/contract over the effect's lifetime). v1 looks
		// at the origin from a standard front-right angle assuming the
		// effect sits in roughly a unit volume; revisit per-effect
		// framing if real effects come out off-frame.
		let camera = FrameDefault();
		let effectId = effectRes.Id;

		let assetEntity = mThumbnailRenderer.AssetEntity;
		let thumbnailRenderer = mThumbnailRenderer;
		ThumbnailBuildFn build = new (scene, cam) => {
			cam = camera;
			thumbnailRenderer.ResetAssetEntity();

			let particleMgr = scene.GetModule<ParticleComponentManager>();
			if (particleMgr == null) return;
			if (let comp = particleMgr.GetForEntity(assetEntity))
			{
				var effectRef = ResourceRef(effectId, assetPath);
				comp.SetEffectRef(effectRef);
				effectRef.Dispose();
			}

			// Fast-forward the scene so particles have emitted by the
			// time we render. The first tick resolves the effect ref
			// and creates the runtime instance; subsequent ticks
			// actually simulate it. We pre-step ~0.5s of wall-clock
			// to seed the visual.
			for (int32 i = 0; i < WarmupSteps; i++)
				scene.Update(WarmupStepDt);
		};

		ThumbnailReadyFn ready = new (rgba, w, h) => {
			mLoadedEffect.Release();
			let data = new OwnedImageData(w, h, .RGBA8, rgba);
			onComplete(data);
		};

		if (!mThumbnailRenderer.Submit(build, ready))
		{
			mLoadedEffect.Release();
			delete build;
			delete ready;
			return false;
		}
		return true;
	}

	/// Default camera for particle effects: looks down-and-from-front-
	/// right at the origin, frustum sized for a ~1.5-unit-radius
	/// bounding sphere. Matches the angle the other generators use so
	/// previews share an aesthetic, just at a fixed scale rather than
	/// auto-fit.
	private CameraOverride FrameDefault()
	{
		const float radius = 1.5f;
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
