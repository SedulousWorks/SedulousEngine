using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Runtime.Client;
using Sedulous.Graphics;
using Sedulous.RHI;
using Sedulous.Image;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Engine.Scene;
using Sedulous.Render;
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Preview;

/// The GPU half of asset thumbnails: a persistent hidden preview scene plus an offscreen
/// render-and-readback pipeline that turns the ThumbnailService's queued scene jobs into
/// 128x128 pixels. The service owns generators, queueing and publication; this stage owns
/// everything GPU: the scene the generators populate, an ortho camera framed from the
/// generator's bounds (eye along (1,1,1), half-extent radius * 1.1, so framing is rotation
/// invariant), a 4x supersampled target box-downscaled to the tile, and a copy-to-buffer
/// readback retired by frame-ring round trip: the copy rides the frame encoder, so it is
/// ordered after the render, and when the same frame index comes around again the
/// submission has retired and the buffer maps without a stall.
///
/// One job is in flight at a time (TakeSceneJob enforces it); a generator whose resources
/// are still resolving returns Pending and is retried each frame under a bounded budget.
/// One per open project, app-owned beside the ThumbnailService; construct after the
/// project's runtime context exists, Shutdown before the render subsystem goes away.
class ThumbnailStage
{
	/// Render at cSupersample * cThumbnailSize and box-downscale, so edges land antialiased
	/// without MSAA machinery.
	public const uint32 cSupersample = 4;
	/// Frames a Pending generator may retry before the job fails; a missing product never
	/// resolves and the negative cache stops the rescheduling loop.
	public const uint32 cMaxStagingFrames = 600;

	private const uint32 cTileSize = ThumbnailService.cThumbnailSize;
	private const uint32 cRenderSize = cTileSize * cSupersample;

	private IApplicationHost mHost;
	private ThumbnailService mService;
	private ResourceManager mResources;
	private SceneSubsystem mScenes = null;
	private RenderSubsystem mRender = null;
	/// The stage's own scene group, never simulated.
	private SceneManager mSceneManager = new .() ~ delete _;
	private Scene mScene = null;

	// GPU objects, created lazily on the first Render with a live device.
	private IDevice mDevice = null;
	private ITexture mTarget = null;
	private ITextureView mTargetView = null;
	private IBuffer mReadback = null;
	private Sedulous.RHI.ResourceState mTargetState = .Undefined;

	private ThumbnailStageState mState = .Idle;
	private SceneThumbnailJob mJob = .();
	/// The shared stage, or a per-job private scene.
	private Scene mJobScene = null;
	private bool mJobSceneIsPrivate = false;
	private ThumbnailFraming mFraming = .();
	private uint32 mStagingFrames = 0;
	private uint32 mSubmittedIndex = 0;
	/// The ring must leave the submitted slot before the readback retires.
	private bool mSawOtherIndex = false;
	/// One-shot wiring-bug warning (see Update).
	private bool mWarnedDisabled = false;

	public this(IApplicationHost host, ThumbnailService service, ResourceManager resources)
	{
		mHost = host;
		mService = service;
		mResources = resources;
		mScenes = host.Context.GetSubsystem<SceneSubsystem>();
		mRender = host.Context.GetSubsystem<RenderSubsystem>();
		if (mScenes != null)
		{
			mScenes.RegisterManager(mSceneManager);
			mScene = mSceneManager.CreateScene("thumbnails.stage");
			mScene.SetSimulationEnabled(false);
		}
	}

	public ~this()
	{
		Shutdown();
	}

	/// True while a job is staged, rendering, or awaiting readback.
	public bool IsBusy => mState != .Idle;

	/// Main thread, once per frame before rendering: takes and stages the next job.
	public void Update()
	{
		if ((mScene == null) || (mRender == null) || (mResources == null))
		{
			// A disabled stage with queued work is a wiring bug (a null resource manager at
			// construction stalled every job, silently, once): say so exactly once.
			if (!mWarnedDisabled && (mService.QueuedSceneJobs > 0))
			{
				mWarnedDisabled = true;
				GlobalLog(.Warning, "Thumbnails: stage disabled (scene {} / renderer {} / resources {}) with {} queued jobs, GPU thumbnails will not generate",
					mScene != null, mRender != null, mResources != null, mService.QueuedSceneJobs);
			}
			return;
		}

		if (mState == .Idle)
		{
			let job = mService.TakeSceneJob();
			if (job.IsEmpty || (job.Generator == null))
				return;
			mJob = job;
			mJobSceneIsPrivate = job.Generator.NeedsPrivateScene;
			if (mJobSceneIsPrivate)
			{
				// Inactive: never manager-ticked; the stage renders and, for prewarm, ticks it
				// by hand.
				mJobScene = mSceneManager.CreateScene("thumbnails.job", false);
				if (mJobScene == null)
				{
					mJobSceneIsPrivate = false;
					FailJob();
					return;
				}
				mJobScene.SetSimulationEnabled(false);
			}
			else
			{
				mJobScene = mScene;
			}
			mStagingFrames = 0;
			mState = .Staging;
		}

		if (mState == .Staging)
		{
			var framing = ThumbnailFraming();
			switch (mJob.Generator.Stage(mJob.Id, mJobScene, mResources, ref framing))
			{
			case .Ready:
				mFraming = framing;
				mFraming.Radius = Math.Max(framing.Radius, 0.001f);
				mState = .RenderPending;
			case .Failed:
				FailJob();
			case .Pending:
				if (++mStagingFrames > cMaxStagingFrames)
				{
					GlobalLog(.Warning, "Thumbnails: stage timed out waiting on resources for {}", mJob.Id);
					FailJob();
				}
			}
		}
	}

	/// Inside the app's scene-render bracket, between BeginRendering and EndRendering on
	/// main-window frames: renders a staged job, encodes its readback, retires a pending
	/// readback whose ring slot came back around.
	public void Render(ref FrameContext frame)
	{
		if (!frame.Valid || (frame.Encoder == null) || (mRender == null) || !mRender.IsReady || (mScene == null))
			return;

		if (mState == .AwaitReadback)
		{
			// Retire when the device ring has left and returned to the submission's slot:
			// the submission and its copy have then provably completed, so the map cannot
			// stall the frame.
			if (frame.FrameIndex != mSubmittedIndex)
			{
				mSawOtherIndex = true;
				return;
			}
			if (!mSawOtherIndex)
				return;
			let mapped = (uint8*)mReadback.Map();
			if (mapped != null)
			{
				let pixels = new Image(cTileSize, cTileSize, .RGBA8);
				Downscale(mapped, cRenderSize * 8, pixels);
				mReadback.Unmap();
				ReleaseJobScene();
				mService.AcceptSceneResult(mJob.Id, pixels, true);
				mJob = .();
				mState = .Idle;
			}
			else
			{
				FailJob();
			}
			return;
		}

		if (mState == .CopyPending)
		{
			// Last frame's EndRendering executed the graph and left the target in CopySrc;
			// this frame's encoder is ordered after that submission, so the copy sees the
			// finished render.
			var region = BufferTextureCopyRegion();
			region.BytesPerRow = cRenderSize * 8;
			region.RowsPerImage = cRenderSize;
			region.TextureExtent = .(cRenderSize, cRenderSize, 1);
			frame.Encoder.CopyTextureToBuffer(mTarget, mReadback, region);
			mSubmittedIndex = frame.FrameIndex;
			mSawOtherIndex = false;
			mState = .AwaitReadback;
			return;
		}
		if (mState != .RenderPending)
			return;
		if (!EnsureGpuObjects())
			return; // no device yet; retry next frame

		// Content that is empty at t=0 (particles) asks for simulation ticks before its one
		// render. Only ever a private scene: sim on for the burst, off again after.
		if ((mFraming.PrewarmSteps > 0) && mJobSceneIsPrivate)
		{
			mJobScene.SetSimulationEnabled(true);
			let steps = Math.Min(mFraming.PrewarmSteps, 600);
			for (uint32 i = 0; i < steps; i++)
				mJobScene.Update(1.0f / 60.0f);
			mJobScene.SetSimulationEnabled(false);
		}

		// The stage never ticks a simulation otherwise, but transforms must be current for
		// extraction: generators set entity transforms during Stage.
		mJobScene.UpdateTransforms();

		// Ortho along (1,1,1) aimed at the framing centre, sized from the staged bounds.
		let direction = Normalized(Float3(1.0f, 1.0f, 1.0f));
		let distance = mFraming.Radius * 4.0f;
		let halfExtent = mFraming.Radius * 1.1f;
		let eye = mFraming.Center + direction * distance;
		var camera = ViewCamera();
		camera.View = Float4x4.LookAtRH(eye, mFraming.Center, .(0.0f, 1.0f, 0.0f));
		camera.Projection = Float4x4.OrthographicRH(halfExtent * 2.0f, halfExtent * 2.0f, 0.05f, distance + mFraming.Radius * 4.0f);
		camera.Position = eye;
		camera.FarZ = distance + mFraming.Radius * 4.0f;

		var cameraOverride = CameraOverride();
		cameraOverride.Camera = camera;
		cameraOverride.ClearColor = .(0.10f, 0.11f, 0.13f, 1.0f);

		// Scene documents look like themselves: their own primary camera and clear colour
		// when one exists (RenderScene extracts both when no override is passed).
		var sceneCamera = ViewCamera();
		let useSceneCamera = mFraming.PreferSceneCamera && RenderExtract.ExtractPrimaryCamera(mJobScene, ref sceneCamera);

		let targetState = TargetState(mTarget, mTargetState, .CopySrc);
		mRender.RenderScene(mJobScene, mTargetView, .RGBA16Float, cRenderSize, cRenderSize,
			.(0, 0, cRenderSize, cRenderSize), useSceneCamera ? null : &cameraOverride, targetState);
		mTargetState = .CopySrc;
		mState = .CopyPending;
	}

	/// Drops the GPU objects and the preview scene; the destructor calls it too.
	public void Shutdown()
	{
		if (mState != .Idle)
			ReleaseJobScene();
		mJob = .();
		mState = .Idle;

		if (mDevice != null)
		{
			mDevice.WaitIdle(); // an in-flight readback copy may still reference these
			if (mReadback != null)
				mDevice.DestroyBuffer(ref mReadback);
			if (mTargetView != null)
				mDevice.DestroyTextureView(ref mTargetView);
			if (mTarget != null)
				mDevice.DestroyTexture(ref mTarget);
			mDevice = null;
		}

		if ((mScene != null) && (mScenes != null))
		{
			mSceneManager.Clear();
			mScenes.UnregisterManager(mSceneManager);
			mScene = null;
		}
	}

	private bool EnsureGpuObjects()
	{
		if (mTarget != null)
			return true;
		if (mHost.Graphics == null)
			return false;
		mDevice = mHost.Graphics.Raw;
		if (mDevice == null)
			return false;
		var desc = TextureDesc();
		desc.Width = cRenderSize;
		desc.Height = cRenderSize;
		desc.Format = .RGBA16Float;
		desc.Usage = .RenderTarget | .CopySrc;
		if (!(mDevice.CreateTexture(desc) case .Ok(out mTarget)) || (mTarget == null))
		{
			mTarget = null;
			return false;
		}
		if (!(mDevice.CreateTextureView(mTarget, .()) case .Ok(out mTargetView)) || (mTargetView == null))
		{
			mDevice.DestroyTexture(ref mTarget);
			mTarget = null;
			return false;
		}
		var bufferDesc = BufferDesc();
		bufferDesc.Size = (uint64)cRenderSize * cRenderSize * 8;
		bufferDesc.Usage = .CopyDst;
		bufferDesc.Memory = .GpuToCpu;
		if (!(mDevice.CreateBuffer(bufferDesc) case .Ok(out mReadback)) || (mReadback == null))
		{
			mDevice.DestroyTextureView(ref mTargetView);
			mDevice.DestroyTexture(ref mTarget);
			mTargetView = null;
			mTarget = null;
			mReadback = null;
			return false;
		}
		mTargetState = .Undefined;
		return true;
	}

	/// Unstages and drops the job's scene, destroying a private one. Every job-end path
	/// funnels through here so a private scene can never outlive its job.
	private void ReleaseJobScene()
	{
		if ((mJob.Generator != null) && (mJobScene != null))
			mJob.Generator.Unstage(mJobScene);
		if (mJobSceneIsPrivate && (mJobScene != null))
			mSceneManager.DestroyScene(mJobScene);
		mJobScene = null;
		mJobSceneIsPrivate = false;
	}

	private void FailJob()
	{
		ReleaseJobScene();
		mService.AcceptSceneResult(mJob.Id, null, false);
		mJob = .();
		mState = .Idle;
	}

	/// IEEE half to float: the render target is RGBA16Float, matching every viewport view so
	/// no pass rebuilds pipelines per format.
	private static float HalfToFloat(uint16 h)
	{
		let sign = (uint32)(h >> 15) & 1;
		let exponent = (uint32)(h >> 10) & 0x1F;
		let mantissa = (uint32)h & 0x3FF;
		uint32 bits;
		if (exponent == 0)
		{
			if (mantissa == 0)
			{
				bits = sign << 31; // signed zero
			}
			else
			{
				// A subnormal half: normalise into a float exponent.
				uint32 e = 127 - 15 + 1;
				var m = mantissa;
				while ((m & 0x400) == 0)
				{
					m <<= 1;
					e--;
				}
				bits = (sign << 31) | (e << 23) | ((m & 0x3FF) << 13);
			}
		}
		else if (exponent == 0x1F)
		{
			bits = (sign << 31) | 0x7F800000 | (mantissa << 13); // inf / nan
		}
		else
		{
			bits = (sign << 31) | ((exponent - 15 + 127) << 23) | (mantissa << 13);
		}
		return *(float*)&bits;
	}

	/// An exact integer box downscale (cSupersample squared samples per output texel) over
	/// RGBA16Float rows. The tonemap pass already applied the sRGB OETF, so the values
	/// quantise to bytes directly; encoding again would double-gamma the image.
	private static void Downscale(uint8* src, uint32 srcRowBytes, Image tile)
	{
		let dst = tile.PixelData.Ptr;
		const float cInvSamples = 1.0f / (cSupersample * cSupersample);
		for (uint32 y = 0; y < cTileSize; y++)
		{
			for (uint32 x = 0; x < cTileSize; x++)
			{
				float[4] sum = .(0, 0, 0, 0);
				for (uint32 sy = 0; sy < cSupersample; sy++)
				{
					let row = src + (int)(y * cSupersample + sy) * (int)srcRowBytes + (int)(x * cSupersample) * 8;
					for (uint32 sx = 0; sx < cSupersample; sx++)
					{
						let texel = (uint16*)(row + sx * 8);
						sum[0] += HalfToFloat(texel[0]);
						sum[1] += HalfToFloat(texel[1]);
						sum[2] += HalfToFloat(texel[2]);
						sum[3] += HalfToFloat(texel[3]);
					}
				}
				let texel = dst + ((int)y * (int)cTileSize + (int)x) * 4;
				for (int c < 4)
					texel[c] = (uint8)(Math.Clamp(sum[c] * cInvSamples, 0.0f, 1.0f) * 255.0f + 0.5f);
			}
		}
	}
}
