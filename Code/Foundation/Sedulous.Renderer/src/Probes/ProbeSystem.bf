namespace Sedulous.Renderer.Probes;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Core.Mathematics;
using Sedulous.Renderer;
using Sedulous.Renderer.IBL;
using Sedulous.Renderer.Passes;

/// Owns reflection probe GPU resources and orchestrates capture + convolution.
/// Lives in Sedulous.Renderer so the probe system can be used without the engine
/// layer — any code that supplies ReflectionProbeRenderData can drive probes.
///
/// RenderSubsystem (engine layer) calls CaptureProbes() each frame, passing the
/// probe batch from the main view's render data. ProbeSystem handles everything
/// else: resource lifecycle, face scheduling, cubemap transitions, convolution,
/// and closest-probe IBL activation.
public class ProbeSystem
{
	private RenderContext mRenderContext;
	private ProbePipeline mProbePipeline;

	// Per-probe GPU resources keyed by probe identifier
	private Dictionary<uint64, ProbeResources> mProbeResources = new .() ~ {
		for (let kv in _) { kv.value.Destroy(mRenderContext?.Device); delete kv.value; }
		delete _;
	};

	// Deferred bind group destruction for probe convolution bind groups.
	// Double-buffered: bind groups must survive 2 frames (MaxFramesInFlight).
	private List<IBindGroup>[2] mStaleConvolutionBindGroups = .(new .(), new .()) ~ { delete _[0]; delete _[1]; };

	public ProbePipeline ProbePipeline => mProbePipeline;

	public Result<void> Initialize(RenderContext renderContext)
	{
		mRenderContext = renderContext;

		mProbePipeline = new ProbePipeline();
		if (mProbePipeline.Initialize(renderContext) case .Err)
		{
			delete mProbePipeline;
			mProbePipeline = null;
			return .Err;
		}

		return .Ok;
	}

	public void Shutdown()
	{
		let device = mRenderContext?.Device;

		// Wait for GPU before destroying anything
		if (device != null)
			device.WaitIdle();

		// Flush all deferred convolution bind groups
		for (int s = 0; s < 2; s++)
		{
			for (var bg in mStaleConvolutionBindGroups[s])
				device?.DestroyBindGroup(ref bg);
			mStaleConvolutionBindGroups[s].Clear();
		}

		// Destroy all probe resources
		for (let kv in mProbeResources)
		{
			kv.value.Destroy(device);
			delete kv.value;
		}
		mProbeResources.Clear();

		// Shut down the capture pipeline
		if (mProbePipeline != null)
		{
			mProbePipeline.Shutdown();
			delete mProbePipeline;
			mProbePipeline = null;
		}
	}

	/// Captures dirty reflection probes and sets the closest probe's IBL as active.
	/// Called by the engine layer (RenderSubsystem) or any custom renderer that
	/// extracts ReflectionProbeRenderData into its RenderView.
	public void CaptureProbes(ICommandEncoder encoder, RenderView mainView, Pipeline pipeline, int32 frameIndex)
	{
		let probes = mainView.RenderData.GetBatch(RenderCategories.ReflectionProbe);
		if (probes == null || probes.Count == 0)
			return;

		// Flush deferred convolution bind groups (2+ frames old, safe to destroy)
		FlushStaleBindGroups();

		// Get SkyPass from the main pipeline for probe sky rendering
		let skyPass = pipeline.GetPass<SkyPass>();

		mProbePipeline.BeginFrame(frameIndex);

		for (let entry in probes)
		{
			let probe = entry as ReflectionProbeRenderData;
			if (probe == null) continue;

			// Get or create per-probe GPU resources
			let key = probe.ProbeKey;
			ProbeResources res = null;
			if (mProbeResources.TryGetValue(key, let existing))
			{
				res = existing;
			}
			else
			{
				res = new ProbeResources();
				if (res.Create(mRenderContext.Device, (uint32)probe.CaptureResolution) case .Err)
				{
					delete res;
					continue;
				}
				mProbeResources[key] = res;
			}

			// Check update mode
			if (res.IsCaptured && probe.UpdateMode == .OnLoad) continue;
			if (probe.UpdateMode == .Manual && !res.NeedsCapture) continue;

			// Determine which faces to capture this frame.
			// OnLoad/Manual: all 6 faces at once (one-time cost).
			// EveryFrame: 1 face per frame (round-robin, full cubemap every 6 frames).
			int32 startFace = 0;
			int32 faceCount = 6;

			if (probe.UpdateMode == .EveryFrame && res.IsCaptured)
			{
				startFace = res.NextFace;
				faceCount = 1;
			}

			// Transition captured cubemap to RenderTarget before blit writes
			if (!res.IsCaptured)
				encoder.TransitionTexture(res.CapturedCubemap, .Undefined, .RenderTarget);
			else
				encoder.TransitionTexture(res.CapturedCubemap, .ShaderRead, .RenderTarget);

			for (int32 i = 0; i < faceCount; i++)
			{
				let faceIdx = (startFace + i) % 6;
				mProbePipeline.CaptureFace(
					encoder, probe.ProbePosition, probe.NearClip, probe.FarClip,
					(uint32)probe.CaptureResolution, (int32)faceIdx, res.CapturedFaceViews[faceIdx],
					frameIndex, pipeline.LightBuffer, pipeline.ClusterSystem, mainView, skyPass);
			}

			// Advance round-robin counter
			res.NextFace = (int32)((startFace + faceCount) % 6);
			res.FacesCaptured += faceCount;

			// Transition captured cubemap to ShaderRead for convolution input
			encoder.TransitionTexture(res.CapturedCubemap, .RenderTarget, .ShaderRead);

			// Convolve only when all 6 faces are complete (or on first full capture)
			if (res.FacesCaptured >= 6)
			{
				if (probe.UpdateMode == .EveryFrame && res.IsCaptured)
				{
					// EveryFrame: fast mipmap-based filter (hardware bilinear downsample).
					// Skips the 36-pass importance-sampled GGX convolution — generates
					// a simple mip chain that approximates roughness-dependent blurring.
					FastConvolveProbe(encoder, res);
				}
				else
				{
					// OnLoad/Manual/first capture: full quality GGX importance sampling.
					ConvolveProbe(encoder, res);
				}
				res.FacesCaptured = 0;
			}

			res.IsCaptured = true;
			if (probe.UpdateMode != .EveryFrame)
				res.NeedsCapture = false;
		}

		// Set the closest probe's IBL as active for the main render
		ActivateClosestProbeIBL(probes, mainView);
	}

	/// Destroys all probe resources. Call on scene teardown (after WaitIdle).
	public void DestroyAllProbes()
	{
		let device = mRenderContext?.Device;

		// Flush all deferred convolution bind groups
		for (int s = 0; s < 2; s++)
		{
			for (var bg in mStaleConvolutionBindGroups[s])
				device?.DestroyBindGroup(ref bg);
			mStaleConvolutionBindGroups[s].Clear();
		}

		// Destroy probe resources
		for (let kv in mProbeResources)
		{
			kv.value.Destroy(device);
			delete kv.value;
		}
		mProbeResources.Clear();
	}

	// ==================== Private ====================

	private void FlushStaleBindGroups()
	{
		let device = mRenderContext.Device;
		for (var bg in mStaleConvolutionBindGroups[0])
			device.DestroyBindGroup(ref bg);
		mStaleConvolutionBindGroups[0].Clear();

		// Rotate: last frame's deferred list becomes the old list
		let temp = mStaleConvolutionBindGroups[0];
		mStaleConvolutionBindGroups[0] = mStaleConvolutionBindGroups[1];
		mStaleConvolutionBindGroups[1] = temp;
	}

	/// Finds the closest captured probe and sets its IBL as active.
	private void ActivateClosestProbeIBL(List<RenderData> probes, RenderView mainView)
	{
		ReflectionProbeRenderData closestProbe = null;
		float closestDist = float.MaxValue;
		for (let entry in probes)
		{
			let probe = entry as ReflectionProbeRenderData;
			if (probe == null) continue;
			let dist = Vector3.DistanceSquared(probe.ProbePosition, mainView.CameraPosition);
			if (dist < closestDist)
			{
				closestDist = dist;
				closestProbe = probe;
			}
		}

		if (closestProbe != null)
		{
			if (mProbeResources.TryGetValue(closestProbe.ProbeKey, let res))
			{
				if (res.IsCaptured)
				{
					// EveryFrame probes use captured cubemap directly as prefilter
					// (no mip chain -> maxLod=0, sharp reflections only).
					// OnLoad/Manual probes use the full GGX-convolved prefilter cubemap.
					let useRawCapture = (closestProbe.UpdateMode == .EveryFrame);
					let prefilterView = useRawCapture ? res.CapturedCubemapView : res.PrefilterCubemapView;
					let maxLod = useRawCapture ? 0.0f : res.PrefilterMaxLod;
					mRenderContext.IBLSystem.SetProbeIBL(
						res.IrradianceCubemapView, prefilterView, maxLod);
				}
			}
		}
	}

	/// Fast convolution for EveryFrame probes. Skips the expensive 30-pass
	/// GGX importance-sampled prefilter. Uses the captured cubemap directly as
	/// the prefilter source (mip 0 only -> sharp reflections at all roughness
	/// levels). Still runs the 6-pass irradiance convolution for correct diffuse.
	private void FastConvolveProbe(ICommandEncoder encoder, ProbeResources res)
	{
		let ibl = mRenderContext.IBLSystem;
		if (ibl == null || ibl.IrradiancePipeline == null) return;

		let device = mRenderContext.Device;

		// Transition irradiance cubemap for rendering
		if (!res.IrradianceInitialized)
		{
			encoder.TransitionTexture(res.IrradianceCubemap, .Undefined, .RenderTarget);
			res.IrradianceInitialized = true;
		}
		else
		{
			encoder.TransitionTexture(res.IrradianceCubemap, .ShaderRead, .RenderTarget);
		}

		// Irradiance: cosine-weighted convolution (6 passes) from captured cubemap.
		// This is cheap (32x32 output) and the quality difference matters for diffuse.
		for (int i = 0; i < 6; i++)
		{
			BindGroupEntry[3] entries = .(
				BindGroupEntry.Buffer(res.IrradianceParamsBuffers[i], 0, 16),
				BindGroupEntry.Texture(res.CapturedCubemapView),
				BindGroupEntry.Sampler(ibl.EnvironmentSampler)
			);

			IBindGroup bg = null;
			if (device.CreateBindGroup(.() { Label = "Probe Irradiance BG", Layout = ibl.IrradianceBGLayout, Entries = entries }) case .Ok(let created))
				bg = created;
			else
				continue;

			ColorAttachment[1] colorAttachments = .(.()
			{
				View = res.IrradianceFaceViews[i],
				LoadOp = .DontCare,
				StoreOp = .Store
			});

			let irradSize = IBLSystem.IrradianceFaceSize;
			let rp = encoder.BeginRenderPass(.() { Label = "ProbeIrradiance", ColorAttachments = .(colorAttachments) });
			rp.SetPipeline(ibl.IrradiancePipeline);
			rp.SetBindGroup(0, bg, default);
			rp.SetViewport(0, 0, irradSize, irradSize, 0, 1);
			rp.SetScissor(0, 0, irradSize, irradSize);
			rp.Draw(3, 1, 0, 0);
			rp.End();

			mStaleConvolutionBindGroups[1].Add(bg);
		}

		encoder.TransitionTexture(res.IrradianceCubemap, .RenderTarget, .ShaderRead);

		// Prefilter: skip entirely. Use the captured cubemap directly as the
		// specular source. Since it has no mip chain (1 mip level), the shader's
		// SampleLevel(R, roughness * maxLod) always samples mip 0 -> sharp
		// reflections regardless of roughness. Acceptable for real-time probes.
	}

	/// Full quality convolution for OnLoad/Manual probes. Runs irradiance (6 passes)
	/// + GGX importance-sampled prefilter (30 passes) using IBLSystem's render pipelines.
	private void ConvolveProbe(ICommandEncoder encoder, ProbeResources res)
	{
		let ibl = mRenderContext.IBLSystem;
		if (ibl == null || ibl.IrradiancePipeline == null || ibl.PrefilterPipeline == null)
			return;

		let device = mRenderContext.Device;

		// Transition irradiance and prefilter cubemaps from Undefined to RenderTarget
		// on first use (they start in Undefined layout after creation).
		if (!res.IrradianceInitialized)
		{
			encoder.TransitionTexture(res.IrradianceCubemap, .Undefined, .RenderTarget);
			res.IrradianceInitialized = true;
		}
		else
		{
			encoder.TransitionTexture(res.IrradianceCubemap, .ShaderRead, .RenderTarget);
		}

		if (!res.PrefilterInitialized)
		{
			encoder.TransitionTexture(res.PrefilterCubemap, .Undefined, .RenderTarget);
			res.PrefilterInitialized = true;
		}
		else
		{
			encoder.TransitionTexture(res.PrefilterCubemap, .ShaderRead, .RenderTarget);
		}

		// --- Irradiance convolution (6 face passes) ---
		for (int i = 0; i < 6; i++)
		{
			BindGroupEntry[3] entries = .(
				BindGroupEntry.Buffer(res.IrradianceParamsBuffers[i], 0, 16),
				BindGroupEntry.Texture(res.CapturedCubemapView),
				BindGroupEntry.Sampler(ibl.EnvironmentSampler)
			);

			IBindGroup bg = null;
			if (device.CreateBindGroup(.() { Label = "Probe Irradiance BG", Layout = ibl.IrradianceBGLayout, Entries = entries }) case .Ok(let created))
				bg = created;
			else
				continue;

			ColorAttachment[1] colorAttachments = .(.()
			{
				View = res.IrradianceFaceViews[i],
				LoadOp = .DontCare,
				StoreOp = .Store
			});

			let irradSize = IBLSystem.IrradianceFaceSize;
			let rp = encoder.BeginRenderPass(.() { Label = "ProbeIrradiance", ColorAttachments = .(colorAttachments) });
			rp.SetPipeline(ibl.IrradiancePipeline);
			rp.SetBindGroup(0, bg, default);
			rp.SetViewport(0, 0, irradSize, irradSize, 0, 1);
			rp.SetScissor(0, 0, irradSize, irradSize);
			rp.Draw(3, 1, 0, 0);
			rp.End();

			mStaleConvolutionBindGroups[1].Add(bg);
		}

		encoder.TransitionTexture(res.IrradianceCubemap, .RenderTarget, .ShaderRead);

		// --- Prefilter convolution (mipCount * 6 face passes) ---
		let mipCount = IBLSystem.PrefilterMipLevels;

		for (int mip = 0; mip < mipCount; mip++)
		{
			uint32 mipSize = IBLSystem.PrefilterFaceSize >> (uint32)mip;

			for (int face = 0; face < 6; face++)
			{
				int idx = mip * 6 + face;

				BindGroupEntry[3] entries = .(
					BindGroupEntry.Buffer(res.PrefilterParamsBuffers[idx], 0, 16),
					BindGroupEntry.Texture(res.CapturedCubemapView),
					BindGroupEntry.Sampler(ibl.EnvironmentSampler)
				);

				IBindGroup bg = null;
				if (device.CreateBindGroup(.() { Label = "Probe Prefilter BG", Layout = ibl.PrefilterBGLayout, Entries = entries }) case .Ok(let created))
					bg = created;
				else
					continue;

				ColorAttachment[1] colorAttachments = .(.()
				{
					View = res.PrefilterFaceViews[idx],
					LoadOp = .DontCare,
					StoreOp = .Store
				});

				let rp = encoder.BeginRenderPass(.() { Label = "ProbePrefilter", ColorAttachments = .(colorAttachments) });
				rp.SetPipeline(ibl.PrefilterPipeline);
				rp.SetBindGroup(0, bg, default);
				rp.SetViewport(0, 0, mipSize, mipSize, 0, 1);
				rp.SetScissor(0, 0, mipSize, mipSize);
				rp.Draw(3, 1, 0, 0);
				rp.End();

				mStaleConvolutionBindGroups[1].Add(bg);
			}
		}

		encoder.TransitionTexture(res.PrefilterCubemap, .RenderTarget, .ShaderRead);
	}
}
