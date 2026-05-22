namespace Sedulous.Editor.App;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.RHI;
using Sedulous.Runtime;
using Sedulous.Engine;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Engine.Renderer;
using Sedulous.Renderer;
using Sedulous.Resources;
using Sedulous.Geometry.Resources;
using Sedulous.Images;
using Sedulous.Editor.Core;

/// Per-thumbnail build closure. Receives the persistent thumbnail
/// Scene and configures the persistent asset entity (read via
/// `renderer.AssetEntity`) for this request, returning the camera
/// matrices to use. Invoked synchronously from Submit so the scene's
/// component-manager tick has a frame to resolve resource refs before
/// the render pass.
typealias ThumbnailBuildFn = delegate void(Scene scene, out CameraOverride camera);

/// Completion callback fired with the RGBA8 readback pixels after the
/// GPU finishes the draw + copy. Caller takes ownership of the array.
typealias ThumbnailReadyFn = delegate void(uint8[] rgba, uint32 width, uint32 height);

/// Renders 3D-asset thumbnails into an offscreen RT and reads them back
/// to CPU pixels. Async: GPU work submitted on frame N completes on a
/// later frame and the callback fires from TickReadback.
///
/// Modeled on Lumix's tile-world pattern - one persistent Scene shared
/// across requests, one persistent render target, one job in flight at
/// a time. The Scene is registered with SceneSubsystem so RenderSubsystem's
/// OnSceneCreated populates it with the component-manager modules and
/// creates the per-scene Pipeline. We never tear it down until the editor
/// shuts down.
///
/// Owned by `EditorContext` (lifecycle: constructed after RuntimeContext
/// startup, destroyed before shutdown).
public class ThumbnailRenderer
{
	/// Color RT resolution. Matches the disk cache PNG size.
	public const uint32 TileSize = 256;

	private SceneSubsystem mSceneSubsystem; // not owned
	private ISceneRenderer mSceneRenderer; // not owned
	private IDevice mDevice; // not owned
	private ResourceSystem mResourceSystem; // not owned

	// Built-in sphere mesh registered with the resource system at startup.
	// AddResource returns a handle that the caller must retain and Release
	// on shutdown - otherwise the resource leaks (the cache holds a ref
	// but never drops it on its own). Released in Shutdown.
	private ResourceHandle<StaticMeshResource> mSphereMesh;

	// Persistent thumbnail Scene. Created via SceneSubsystem so the
	// renderer's per-scene modules and Pipeline get set up. We swap
	// asset entities in/out per request rather than spawning new scenes.
	private Scene mScene;

	// Offscreen color RT + readback buffer. Destroyed in Shutdown() while
	// the IDevice is still alive - field destructors run too late (the
	// base Application's Cleanup tears the device down before then).
	private ITexture mColorTex;
	private ITextureView mColorView;
	private IBuffer mReadback;

	/// One in-flight job. We accept new requests only when this is null,
	/// keeping fence/readback bookkeeping trivially correct.
	private Job mPending = null ~ if (_ != null) delete _;

	private class Job
	{
		public ThumbnailReadyFn OnReady ~ delete _;
		/// Camera matrices captured at Submit time. Passed to
		/// RenderScene when the draw fires.
		public CameraOverride Camera;
		/// Fence value that the editor will signal once GPU work for
		/// this frame completes. Set in RenderPending; checked in
		/// TickReadback. 0 means the job hasn't been rendered yet.
		public uint64 SubmittedFenceValue;
	}

	// Persistent sun light entity. Created once in AddDefaultLight, kept
	// alive for the lifetime of the renderer.
	private EntityHandle mSunLight;

	// Persistent asset entity. Created once at startup with a
	// MeshComponent; reused across requests by updating its MeshRef.
	// Exposed publicly so the MeshThumbnailGenerator can configure its
	// MeshComponent inside the build closure.
	public EntityHandle AssetEntity { get; private set; }

	/// GUID of the built-in unit sphere mesh registered with the resource
	/// system. Generators that want stock geometry (material previews,
	/// etc.) build a `ResourceRef(SphereMeshId, "")` and assign it to the
	/// asset entity's MeshComponent.
	public Guid SphereMeshId { get; private set; }

	public this(SceneSubsystem sceneSubsystem, ISceneRenderer sceneRenderer, IDevice device, ResourceSystem resourceSystem)
	{
		mSceneSubsystem = sceneSubsystem;
		mSceneRenderer = sceneRenderer;
		mDevice = device;
		mResourceSystem = resourceSystem;

		mScene = sceneSubsystem.CreateScene("__Thumbnails__");

		// Procedurally generate the built-in sphere mesh and register it
		// so generators can reference it via ResourceRef without shipping
		// a `.mesh` asset for primitives.
		CreateSphereMesh();

		// Add a default directional light entity to the thumbnail scene so
		// the rendered asset isn't a black silhouette. Light orientation is
		// fixed; intensity matches Lumix's tile-world defaults.
		AddDefaultLight();

		// Persistent asset entity. Pre-create MeshComponent and
		// SkinnedMeshComponent so generators only have to set MeshRef
		// per request - no per-thumbnail component creation/destruction.
		// Only one of the two components has a valid MeshRef at a time;
		// the unused one's MeshHandle stays Invalid and gets skipped by
		// the extraction loop.
		AssetEntity = mScene.CreateEntity("__ThumbnailAsset__");
		mScene.SetLocalTransform(AssetEntity, .() { Position = .Zero, Rotation = .Identity, Scale = .One });
		let meshMgr = mScene.GetModule<MeshComponentManager>();
		if (meshMgr != null)
			meshMgr.CreateComponent(AssetEntity);
		let skinnedMgr = mScene.GetModule<SkinnedMeshComponentManager>();
		if (skinnedMgr != null)
			skinnedMgr.CreateComponent(AssetEntity);

		CreateRenderTarget();
	}

	/// Clear every renderable ref on the persistent asset entity. Each
	/// generator's build closure should call this before setting the
	/// refs it cares about, so a previous thumbnail's MeshRef /
	/// SkinnedMeshRef / MaterialRef doesn't bleed into the new one
	/// when the asset type changes (e.g., mesh → skinned mesh, or
	/// material → mesh).
	public void ResetAssetEntity()
	{
		if (mScene == null) return;

		let meshMgr = mScene.GetModule<MeshComponentManager>();
		if (meshMgr != null)
		{
			if (let comp = meshMgr.GetForEntity(AssetEntity))
			{
				var emptyRef = ResourceRef();
				comp.SetMeshRef(emptyRef);
				comp.SetMaterialRef(0, emptyRef);
				emptyRef.Dispose();
			}
		}

		let skinnedMgr = mScene.GetModule<SkinnedMeshComponentManager>();
		if (skinnedMgr != null)
		{
			if (let comp = skinnedMgr.GetForEntity(AssetEntity))
			{
				var emptyRef = ResourceRef();
				comp.SetMeshRef(emptyRef);
				comp.SetMaterialRef(0, emptyRef);
				emptyRef.Dispose();
			}
		}
	}

	public ~this()
	{
		// Note: mSceneSubsystem may already be torn down by the runtime
		// context's shutdown by the time field destructors run. The
		// caller must invoke Shutdown() while the SceneSubsystem is
		// still alive so the thumbnail scene gets destroyed cleanly.
		// We do not touch mSceneSubsystem here defensively.
	}

	/// Tears down the persistent thumbnail Scene + GPU resources while
	/// both the SceneSubsystem AND the IDevice are still alive. Must be
	/// called by the editor BEFORE the runtime context and device shut
	/// down. After Shutdown returns the renderer must not be used.
	public void Shutdown()
	{
		// Drop the in-flight job (if any) so we don't try to map readback
		// buffer state we're about to free.
		if (mPending != null)
		{
			delete mPending;
			mPending = null;
		}

		// Destroy the persistent scene (and its entity contents) while
		// SceneSubsystem is still alive.
		if (mScene != null && mSceneSubsystem != null)
		{
			mSceneSubsystem.DestroyScene(mScene);
			mScene = null;
		}
		mSceneSubsystem = null;

		// Drop our reference to the built-in sphere resource. AddResource
		// returned a handle the caller must release; without this the
		// procedural sphere mesh + its vertex/index data leak on shutdown.
		mSphereMesh.Release();
		mResourceSystem = null;

		// Release GPU resources while IDevice is still alive.
		if (mColorView != null) mDevice.DestroyTextureView(ref mColorView);
		if (mColorTex != null) mDevice.DestroyTexture(ref mColorTex);
		if (mReadback != null) mDevice.DestroyBuffer(ref mReadback);
		mDevice = null;
	}

	/// Queue a render. Returns true if accepted, false if a job is
	/// already in flight (caller should retry on a later frame).
	///
	/// The `build` callback fires SYNCHRONOUSLY during this call so that
	/// the scene's component-manager updates (which run between OnUpdate
	/// and the render pass) have a frame to resolve resource refs set on
	/// the persistent asset entity. The build callback is freed after
	/// invocation.
	public bool Submit(ThumbnailBuildFn build, ThumbnailReadyFn onReady)
	{
		if (mPending != null) return false;
		mPending = new Job();
		mPending.OnReady = onReady;
		mPending.SubmittedFenceValue = 0;

		// Configure the persistent asset entity + compute camera. The
		// scene's tick (which happens this same frame, after OnUpdate
		// returns) sees the updated MeshRef and resolves it before the
		// render pass.
		CameraOverride camera = .();
		build(mScene, out camera);
		mPending.Camera = camera;

		// The build delegate has done its job - free it.
		delete build;
		return true;
	}

	/// Render the in-flight job (if any) into the offscreen RT and copy
	/// the result into the readback buffer. Called by EditorApplication
	/// between `BeginRendering` and `EndRendering`, sharing the editor's
	/// frame encoder. `nextFenceValue` is the value the editor's
	/// submission will signal - we record it so TickReadback can check
	/// completion.
	public void RenderPending(ICommandEncoder encoder, int32 frameIndex, uint64 nextFenceValue)
	{
		if (mPending == null || mPending.SubmittedFenceValue != 0) return;

		// RenderScene's contract: the color target must already be in
		// RenderTarget state and pre-cleared on entry. (`Undefined`
		// works as the source state since we don't care about previous
		// contents - we're about to clear anyway.)
		encoder.TransitionTexture(mColorTex, .Undefined, .RenderTarget);

		// Clear pass so RenderScene's LoadOp.Load picks up our color.
		// Black opaque background - tweak later if we want a different
		// thumbnail backdrop.
		ColorAttachment[1] clearAttachments = .(.()
		{
			View = mColorView,
			LoadOp = .Clear,
			StoreOp = .Store,
			ClearValue = .(0, 0, 0, 1)
		});
		RenderPassDesc clearDesc = .() { ColorAttachments = .(clearAttachments) };
		let clearPass = encoder.BeginRenderPass(clearDesc);
		clearPass?.End();

		// Render the thumbnail scene into the offscreen RT. The scene's
		// component-manager tick has run since Submit, so the persistent
		// entity's MeshComponent has its refs resolved. RenderScene
		// transitions mColorTex into ShaderRead on return.
		// viewportKey=null uses the scene-default Pipeline that
		// RenderSubsystem.OnSceneCreated set up for us.
		mSceneRenderer.RenderScene(
			mScene,
			encoder,
			mColorTex,
			mColorView,
			TileSize, TileSize,
			frameIndex,
			mPending.Camera,
			null);

		// Copy RT -> readback buffer. ShaderRead -> CopySrc; we don't
		// need to transition back since next frame uses Undefined ->
		// RenderTarget for the next thumbnail.
		// BytesPerRow = TileSize * 8 because the RT is RGBA16Float
		// (4 channels x 2 bytes per half-float = 8 bytes per texel).
		encoder.TransitionTexture(mColorTex, .ShaderRead, .CopySrc);
		BufferTextureCopyRegion region = .()
		{
			BufferOffset = 0,
			BytesPerRow = TileSize * 8,
			RowsPerImage = 0,
			TextureMipLevel = 0,
			TextureArrayLayer = 0,
			TextureExtent = .(TileSize, TileSize, 1)
		};
		encoder.CopyTextureToBuffer(mColorTex, mReadback, region);

		mPending.SubmittedFenceValue = nextFenceValue;
	}

	/// Check the in-flight job's fence; if the GPU has finished the
	/// frame that submitted the copy, map the readback buffer, deliver
	/// the pixels via OnReady, and clear the job. Called once per
	/// frame by EditorApplication.
	public void TickReadback(IFence frameFence)
	{
		if (mPending == null) return;
		if (mPending.SubmittedFenceValue == 0) return;
		if (frameFence.CompletedValue < mPending.SubmittedFenceValue) return;

		// GPU work is done. Map the readback buffer, copy out the
		// pixels, converting RGBA16Float -> RGBA8 sRGB on the CPU. The
		// HDR target is what the renderer's PostProcessStack tonemaps
		// into; for PNGs we need 8 bits per channel.
		let pixelCount = (int)(TileSize * TileSize);
		let rgba = new uint8[pixelCount * 4];

		let mappedPtr = mReadback.Map();
		if (mappedPtr != null)
		{
			let halfPtr = (uint16*)mappedPtr;
			for (int i = 0; i < pixelCount * 4; i++)
			{
				let f = HalfToFloat(halfPtr[i]);
				let clamped = Math.Clamp(f, 0.0f, 1.0f);
				rgba[i] = (uint8)(clamped * 255.0f + 0.5f);
			}
			mReadback.Unmap();
		}

		let job = mPending;
		mPending = null;
		job.OnReady(rgba, TileSize, TileSize);
		delete job;
	}

	/// Is the renderer currently idle? Used by the service-side throttle
	/// to decide whether to dispatch a new GPU thumbnail this frame.
	public bool IsIdle => mPending == null;

	// ==================== Internals ====================

	private void CreateRenderTarget()
	{
		// Color RT - RGBA16Float to match the renderer's HDR pipeline
		// output format. The PostProcessStack tonemaps into this target;
		// we then half-float -> uint8 convert on CPU when reading back.
		TextureDesc texDesc = .()
		{
			Width = TileSize,
			Height = TileSize,
			Format = .RGBA16Float,
			Usage = .RenderTarget | .Sampled | .CopySrc,
			Dimension = .Texture2D,
			MipLevelCount = 1,
			ArrayLayerCount = 1,
			SampleCount = 1,
			Label = "ThumbnailColorRT"
		};
		if (mDevice.CreateTexture(texDesc) case .Ok(let tex))
		{
			mColorTex = tex;

			TextureViewDesc viewDesc = .()
			{
				Format = .RGBA16Float,
				Dimension = .Texture2D,
				BaseMipLevel = 0,
				MipLevelCount = 1,
				BaseArrayLayer = 0,
				ArrayLayerCount = 1,
				Label = "ThumbnailColorRTView"
			};
			if (mDevice.CreateTextureView(tex, viewDesc) case .Ok(let view))
				mColorView = view;
		}

		// Readback buffer - GpuToCpu, sized for the full tile at 8
		// bytes per pixel (4 channels x 2 bytes per half-float).
		BufferDesc bufDesc = .()
		{
			Label = "ThumbnailReadback",
			Size = (uint64)(TileSize * TileSize * 8),
			Usage = .CopyDst,
			Memory = .GpuToCpu
		};
		if (mDevice.CreateBuffer(bufDesc) case .Ok(let buf))
			mReadback = buf;
	}

	/// IEEE 754 half-float (16-bit) -> 32-bit float. Used to decode the
	/// RGBA16Float readback into the byte-per-channel image we save as
	/// PNG. Handles denormals + infinities; we then clamp to [0,1].
	private static float HalfToFloat(uint16 h)
	{
		uint32 sign = (uint32)((h >> 15) & 0x1);
		uint32 exp  = (uint32)((h >> 10) & 0x1F);
		uint32 mant = (uint32)(h & 0x3FF);

		uint32 f;
		if (exp == 0)
		{
			if (mant == 0)
			{
				// Zero (positive or negative).
				f = sign << 31;
			}
			else
			{
				// Denormalized half - renormalize to a normal float.
				while ((mant & 0x400) == 0) { mant <<= 1; exp = (uint32)((int32)exp - 1); }
				exp = (uint32)((int32)exp + 1);
				mant &= ~(uint32)0x400;
				let expF = exp + (127 - 15);
				f = (sign << 31) | (expF << 23) | (mant << 13);
			}
		}
		else if (exp == 31)
		{
			// Infinity / NaN.
			f = (sign << 31) | (0xFF << 23) | (mant << 13);
		}
		else
		{
			// Normal: rebias exponent and shift mantissa.
			let expF = exp + (127 - 15);
			f = (sign << 31) | (expF << 23) | (mant << 13);
		}
		return *(float*)&f;
	}

	private void AddDefaultLight()
	{
		// Directional sun light pointing from upper-front-right toward the
		// origin. Same general intensity / color as the ModelViewer tool
		// uses, which gives a reasonable preview without IBL.
		mSunLight = mScene.CreateEntity("__ThumbnailSun__");
		mScene.SetLocalTransform(mSunLight, Transform.CreateLookAt(.(5, 8, 5), .Zero));
		let lightMgr = mScene.GetModule<LightComponentManager>();
		if (lightMgr != null)
		{
			let handle = lightMgr.CreateComponent(mSunLight);
			if (let light = lightMgr.Get(handle))
			{
				light.Type = .Directional;
				light.Color = .(1.0f, 0.95f, 0.85f);
				light.Intensity = 1.5f;
				// No shadows for thumbnails - extra GPU work without
				// adding meaningful info at 256px.
				light.CastsShadows = false;
			}
		}
	}

	private void CreateSphereMesh()
	{
		// Procedurally build a unit-diameter sphere (radius 0.5 → bounds
		// fit in the [-0.5, 0.5] cube, matching the framing math the mesh
		// generator already uses). AddResource caches by GUID with no
		// URI so a ResourceRef(SphereMeshId, "") resolves through the
		// usual RenderResourceResolver path.
		let sphere = StaticMeshResource.CreateSphere();
		SphereMeshId = sphere.Id;
		if (mResourceSystem.AddResource<StaticMeshResource>(sphere) case .Ok(let handle))
			mSphereMesh = handle;
	}
}
