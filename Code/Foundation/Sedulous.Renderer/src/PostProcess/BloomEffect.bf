namespace Sedulous.Renderer;

using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;
using Sedulous.Profiler;

/// HDR bloom via progressive downsample/upsample chain.
///
/// Extracts bright pixels from the HDR scene color, builds a 5-level gaussian
/// pyramid (downsample with 13-tap filter), then upsamples back with a 9-tap
/// tent filter, blending each level with the corresponding downsample level.
/// The final full-res bloom texture is published as the "BloomTexture" auxiliary
/// for TonemapEffect to composite.
///
/// This effect does NOT modify the main color chain - it passes input -> output
/// unchanged (blit copy) and only produces the auxiliary bloom texture on the
/// side. TonemapEffect reads it via ctx.GetAux("BloomTexture").
class BloomEffect : PostProcessEffect
{
	private const int32 MipCount = 5;

	// GPU resources
	private IDevice mDevice;
	private Sedulous.RHI.IRenderPipeline mDownsamplePipeline;
	private Sedulous.RHI.IRenderPipeline mUpsamplePipeline;
	private Sedulous.RHI.IRenderPipeline mBlitPipeline;
	private IPipelineLayout mDownsampleLayout;
	private IPipelineLayout mUpsampleLayout;
	private IPipelineLayout mBlitLayout;
	private IBindGroupLayout mDownsampleBGL;  // b0 params, t0 source, s0 sampler
	private IBindGroupLayout mUpsampleBGL;    // b0 params, t0 lower, t1 current, s0 sampler
	private IBindGroupLayout mBlitBGL;        // t0 source, s0 sampler
	private ISampler mLinearSampler;
	/// Two param buffers: [0] has MipLevel=0 (threshold active, first downsample),
	/// [1] has MipLevel=1 (threshold skipped, all other downsample/upsample passes).
	/// Written once per frame in AddPasses BEFORE graph.Execute so all GPU draws
	/// read stable data (avoids the shared-buffer-overwrite race).
	private IBuffer[2] mParamsBuffers;

	// Per-frame bind groups (rebuilt each frame because source textures are transients).
	private const int MaxFrames = 2;

	// Tracks bind groups created during AddPasses so we can destroy them next frame.
	private List<IBindGroup>[MaxFrames] mFrameBindGroups;

	/// Brightness threshold for the extract pass. Pixels below this luminance
	/// don't contribute to bloom. Lower = more glow on dimmer surfaces.
	public float Threshold = 1.0f;

	/// Bloom strength multiplier applied when TonemapEffect composites the bloom
	/// texture. Stored in the params buffer but actually used by the tonemap shader.
	public float Intensity = 0.5f;

	public override StringView Name => "Bloom";

	public this()
	{
		for (int32 i = 0; i < MaxFrames; i++)
			mFrameBindGroups[i] = new .();
	}

	public ~this()
	{
		for (int32 i = 0; i < MaxFrames; i++)
		{
			CleanupFrameBindGroups(i);
			delete mFrameBindGroups[i];
		}
	}

	public override Result<void> OnInitialize(RenderContext renderContext)
	{
		mDevice = renderContext.Device;
		let shaderSystem = renderContext.ShaderSystem;
		if (shaderSystem == null) return .Err;

		// --- Sampler ---
		SamplerDesc samplerDesc = .()
		{
			Label = "Bloom Linear Sampler",
			MinFilter = .Linear,
			MagFilter = .Linear,
			MipmapFilter = .Nearest,
			AddressU = .ClampToEdge,
			AddressV = .ClampToEdge,
			AddressW = .ClampToEdge
		};
		if (mDevice.CreateSampler(samplerDesc) case .Ok(let s))
			mLinearSampler = s;
		else return .Err;

		// --- Params buffers (two: threshold-active + threshold-inactive) ---
		for (int32 i = 0; i < 2; i++)
		{
			BufferDesc bufDesc = .()
			{
				Label = "Bloom Params",
				Size = BloomParams.Size,
				Usage = .Uniform,
				Memory = .CpuToGpu
			};
			if (mDevice.CreateBuffer(bufDesc) case .Ok(let buf))
				mParamsBuffers[i] = buf;
			else return .Err;
		}

		// --- Downsample pipeline: b0 params, t0 source, s0 sampler ---
		{
			BindGroupLayoutEntry[3] entries = .(
				.UniformBuffer(0, .Fragment),
				.SampledTexture(0, .Fragment),
				.Sampler(0, .Fragment)
			);
			if (CreateSingleTexturePipeline(shaderSystem, "bloom_downsample",
				entries, out mDownsampleBGL, out mDownsampleLayout, out mDownsamplePipeline) case .Err)
				return .Err;
		}

		// --- Upsample pipeline: b0 params, t0 lower, t1 current, s0 sampler ---
		{
			BindGroupLayoutEntry[4] entries = .(
				.UniformBuffer(0, .Fragment),
				.SampledTexture(0, .Fragment),
				.SampledTexture(1, .Fragment),
				.Sampler(0, .Fragment)
			);
			if (CreateSingleTexturePipeline(shaderSystem, "bloom_upsample",
				entries, out mUpsampleBGL, out mUpsampleLayout, out mUpsamplePipeline) case .Err)
				return .Err;
		}

		// --- Blit pipeline (pass-through copy): t0 source, s0 sampler ---
		{
			BindGroupLayoutEntry[2] entries = .(
				.SampledTexture(0, .Fragment),
				.Sampler(0, .Fragment)
			);
			if (CreateSingleTexturePipeline(shaderSystem, "blit",
				entries, out mBlitBGL, out mBlitLayout, out mBlitPipeline) case .Err)
				return .Err;
		}

		return .Ok;
	}

	public override void DeclareOutputs(RenderGraph graph, PostProcessContext ctx)
	{
		// The bloom texture is full-res, same format as the scene HDR.
		let desc = RGTextureDesc(.RGBA16Float) { Usage = .RenderTarget | .Sampled };
		let handle = graph.CreateTransient("BloomTexture", desc);
		ctx.SetAux("BloomTexture", handle);
	}

	public override void AddPasses(RenderGraph graph, RenderView view, RenderContext renderContext, PostProcessContext ctx)
	{
		using (Profiler.Begin("Bloom"))
		{
		let frameSlot = view.FrameIndex % MaxFrames;
		CleanupFrameBindGroups(frameSlot);

		// Write both param buffers ONCE before adding graph passes. The GPU reads
		// them later during graph.Execute - by then the data is stable.
		BloomParams thresholdParams = .() { Threshold = Threshold, Intensity = Intensity, MipLevel = 0 };
		TransferHelper.WriteMappedBuffer(mParamsBuffers[0], 0,
			Span<uint8>((uint8*)&thresholdParams, BloomParams.Size));

		BloomParams noThresholdParams = .() { Threshold = Threshold, Intensity = Intensity, MipLevel = 1 };
		TransferHelper.WriteMappedBuffer(mParamsBuffers[1], 0,
			Span<uint8>((uint8*)&noThresholdParams, BloomParams.Size));

		let input = ctx.Input;
		let bloomOutput = ctx.GetAux("BloomTexture");

		// Bloom doesn't modify the main color chain - it only produces the
		// auxiliary BloomTexture. Skip the blit copy and tell the stack to
		// pass the input through directly. The unused transient the stack
		// created for ctx.Output is harmless (graph culls unused resources).
		ctx.Output = ctx.Input;

		// 2. Downsample chain: input -> half -> quarter -> ... -> 1/32.
		RGHandle[MipCount] downMips = ?;
		var prevHandle = input;
		for (int32 mip = 0; mip < MipCount; mip++)
		{
			let w = Math.Max(1, (int32)view.Width >> (mip + 1));
			let h = Math.Max(1, (int32)view.Height >> (mip + 1));
			let desc = RGTextureDesc(.RGBA16Float, (uint32)w, (uint32)h) { Usage = .RenderTarget | .Sampled };
			let mipHandle = graph.CreateTransient(scope $"BloomDown{mip}", desc);
			downMips[mip] = mipHandle;

			AddDownsamplePass(graph, view, prevHandle, mipHandle, mip, frameSlot);
			prevHandle = mipHandle;
		}

		// 3. Upsample chain: smallest -> ... -> full-res bloom texture.
		// Start from the second-smallest and blend upward. The very bottom
		// downsample level IS the initial upsample input.
		var upHandle = downMips[MipCount - 1]; // smallest downsample mip
		for (int32 mip = MipCount - 2; mip >= 0; mip--)
		{
			let w = Math.Max(1, (int32)view.Width >> (mip + 1));
			let h = Math.Max(1, (int32)view.Height >> (mip + 1));
			let isLast = (mip == 0);

			// Last upsample writes to the bloomOutput (full-res aux texture);
			// intermediate upsample steps write to transient intermediates.
			RGHandle outHandle;
			if (isLast)
			{
				outHandle = bloomOutput;
			}
			else
			{
				let desc = RGTextureDesc(.RGBA16Float, (uint32)w, (uint32)h) { Usage = .RenderTarget | .Sampled };
				outHandle = graph.CreateTransient(scope $"BloomUp{mip}", desc);
			}

			AddUpsamplePass(graph, view, upHandle, downMips[mip], outHandle, mip, frameSlot);
			upHandle = outHandle;
		}

		} // Profiler scope
	}

	public override void OnShutdown()
	{
		if (mDevice == null) return;

		for (int32 i = 0; i < MaxFrames; i++)
			CleanupFrameBindGroups(i);

		if (mDownsamplePipeline != null) mDevice.DestroyRenderPipeline(ref mDownsamplePipeline);
		if (mUpsamplePipeline != null) mDevice.DestroyRenderPipeline(ref mUpsamplePipeline);
		if (mBlitPipeline != null) mDevice.DestroyRenderPipeline(ref mBlitPipeline);
		if (mDownsampleLayout != null) mDevice.DestroyPipelineLayout(ref mDownsampleLayout);
		if (mUpsampleLayout != null) mDevice.DestroyPipelineLayout(ref mUpsampleLayout);
		if (mBlitLayout != null) mDevice.DestroyPipelineLayout(ref mBlitLayout);
		if (mDownsampleBGL != null) mDevice.DestroyBindGroupLayout(ref mDownsampleBGL);
		if (mUpsampleBGL != null) mDevice.DestroyBindGroupLayout(ref mUpsampleBGL);
		if (mBlitBGL != null) mDevice.DestroyBindGroupLayout(ref mBlitBGL);
		if (mLinearSampler != null) mDevice.DestroySampler(ref mLinearSampler);
		for (int32 i = 0; i < 2; i++)
			if (mParamsBuffers[i] != null) mDevice.DestroyBuffer(ref mParamsBuffers[i]);
	}

	// ==================== Pass Helpers ====================

	private void AddBlitPass(RenderGraph graph, RenderView view, RGHandle input, RGHandle output, int32 frameSlot)
	{
		graph.AddRenderPass("BloomBlit", scope (builder) => {
			builder
				.ReadTexture(input)
				.SetColorTarget(0, output, .DontCare, .Store)
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					let inputView = graph.GetTextureView(input);
					if (inputView == null) return;

					BindGroupEntry[2] blitEntries = .(
						BindGroupEntry.Texture(inputView),
						BindGroupEntry.Sampler(mLinearSampler)
					);
					let bg = CreateBindGroup(mBlitBGL, blitEntries, frameSlot);
					if (bg == null) return;

					encoder.SetViewport(0, 0, (float)view.Width, (float)view.Height, 0, 1);
					encoder.SetScissor(0, 0, view.Width, view.Height);
					encoder.SetPipeline(mBlitPipeline);
					encoder.SetBindGroup(0, bg, default);
					encoder.Draw(3, 1, 0, 0);
				});
		});
	}

	private void AddDownsamplePass(RenderGraph graph, RenderView view, RGHandle source, RGHandle dest, int32 mipLevel, int32 frameSlot)
	{
		// First downsample (mip 0) uses the threshold-active params buffer;
		// all subsequent ones use the no-threshold buffer.
		let paramsBuffer = mParamsBuffers[mipLevel == 0 ? 0 : 1];

		graph.AddRenderPass(scope $"BloomDown{mipLevel}", scope (builder) => {
			builder
				.ReadTexture(source)
				.SetColorTarget(0, dest, .DontCare, .Store)
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					let srcView = graph.GetTextureView(source);
					if (srcView == null) return;

					BindGroupEntry[3] downEntries = .(
						BindGroupEntry.Buffer(paramsBuffer, 0, BloomParams.Size),
						BindGroupEntry.Texture(srcView),
						BindGroupEntry.Sampler(mLinearSampler)
					);
					let bg = CreateBindGroup(mDownsampleBGL, downEntries, frameSlot);
					if (bg == null) return;

					let w = Math.Max(1, view.Width >> (uint32)(mipLevel + 1));
					let h = Math.Max(1, view.Height >> (uint32)(mipLevel + 1));
					encoder.SetViewport(0, 0, (float)w, (float)h, 0, 1);
					encoder.SetScissor(0, 0, w, h);
					encoder.SetPipeline(mDownsamplePipeline);
					encoder.SetBindGroup(0, bg, default);
					encoder.Draw(3, 1, 0, 0);
				});
		});
	}

	private void AddUpsamplePass(RenderGraph graph, RenderView view, RGHandle lowerMip, RGHandle currentDown, RGHandle dest, int32 mipLevel, int32 frameSlot)
	{
		// Upsample always uses the no-threshold params buffer.
		let paramsBuffer = mParamsBuffers[1];

		graph.AddRenderPass(scope $"BloomUp{mipLevel}", scope (builder) => {
			builder
				.ReadTexture(lowerMip)
				.ReadTexture(currentDown)
				.SetColorTarget(0, dest, .DontCare, .Store)
				.NeverCull()
				.SetExecute(new [=] (encoder) => {
					let lowerView = graph.GetTextureView(lowerMip);
					let currentView = graph.GetTextureView(currentDown);
					if (lowerView == null || currentView == null) return;

					BindGroupEntry[4] upEntries = .(
						BindGroupEntry.Buffer(paramsBuffer, 0, BloomParams.Size),
						BindGroupEntry.Texture(lowerView),
						BindGroupEntry.Texture(currentView),
						BindGroupEntry.Sampler(mLinearSampler)
					);
					let bg = CreateBindGroup(mUpsampleBGL, upEntries, frameSlot);
					if (bg == null) return;

					let w = Math.Max(1, view.Width >> (uint32)(mipLevel + 1));
					let h = Math.Max(1, view.Height >> (uint32)(mipLevel + 1));
					// Last upsample (mipLevel == 0) writes to full-res bloom texture.
					let outW = (mipLevel == 0) ? view.Width : w;
					let outH = (mipLevel == 0) ? view.Height : h;
					encoder.SetViewport(0, 0, (float)outW, (float)outH, 0, 1);
					encoder.SetScissor(0, 0, outW, outH);
					encoder.SetPipeline(mUpsamplePipeline);
					encoder.SetBindGroup(0, bg, default);
					encoder.Draw(3, 1, 0, 0);
				});
		});
	}

	// ==================== Bind Group Management ====================

	/// Creates a bind group and tracks it for cleanup at the end of this frame slot.
	private IBindGroup CreateBindGroup(IBindGroupLayout layout, Span<BindGroupEntry> entries, int32 frameSlot)
	{
		BindGroupDesc desc = .()
		{
			Label = "Bloom BG",
			Layout = layout,
			Entries = entries
		};
		if (mDevice.CreateBindGroup(desc) case .Ok(let bg))
		{
			mFrameBindGroups[frameSlot].Add(bg);
			return bg;
		}
		return null;
	}

	/// Destroys all bind groups created during a previous frame slot's AddPasses.
	private void CleanupFrameBindGroups(int32 slot)
	{
		let list = mFrameBindGroups[slot];
		for (var bg in list)
		{
			if (bg != null)
				mDevice.DestroyBindGroup(ref bg);
		}
		list.Clear();
	}

	// ==================== Pipeline Creation ====================

	private Result<void> CreateSingleTexturePipeline(
		ShaderSystem shaderSystem,
		StringView shaderName,
		Span<BindGroupLayoutEntry> layoutEntries,
		out IBindGroupLayout outBGL,
		out IPipelineLayout outLayout,
		out Sedulous.RHI.IRenderPipeline outPipeline)
	{
		outBGL = null;
		outLayout = null;
		outPipeline = null;

		// Bind group layout
		BindGroupLayoutDesc bglDesc = .() { Label = scope $"Bloom {shaderName} BGL", Entries = layoutEntries };
		if (mDevice.CreateBindGroupLayout(bglDesc) case .Ok(let bgl))
			outBGL = bgl;
		else return .Err;

		// Pipeline layout (single set)
		IBindGroupLayout[1] layouts = .(outBGL);
		if (mDevice.CreatePipelineLayout(.(layouts)) case .Ok(let pl))
			outLayout = pl;
		else return .Err;

		// Reuse the shared fullscreen triangle vertex shader for all post-process passes.
		let vertResult = shaderSystem.GetShader("fullscreen", .Vertex);
		if (vertResult case .Err) return .Err;
		let vertModule = vertResult.Value;

		// Fragment shader specific to this pass (bloom_downsample, bloom_upsample, or blit).
		let fragResult = shaderSystem.GetShader(shaderName, .Fragment);
		if (fragResult case .Err) return .Err;
		let fragModule = fragResult.Value;

		ColorTargetState[1] colorTargets = .(.() { Format = .RGBA16Float });

		RenderPipelineDesc rpDesc = .()
		{
			Label = scope $"Bloom {shaderName} Pipeline",
			Layout = outLayout,
			Vertex = .() { Shader = .(vertModule.Module, "main"), Buffers = default },
			Fragment = .() { Shader = .(fragModule.Module, "main"), Targets = colorTargets },
			Primitive = .() { Topology = .TriangleList, FrontFace = .CCW, CullMode = .None },
			DepthStencil = null,
			Multisample = .() { Count = 1, Mask = uint32.MaxValue }
		};

		if (mDevice.CreateRenderPipeline(rpDesc) case .Ok(let pipe))
			outPipeline = pipe;
		else return .Err;

		return .Ok;
	}

	[CRepr]
	private struct BloomParams
	{
		public float Threshold;
		public float Intensity;
		public int32 MipLevel;
		public float _Pad;
		public const uint64 Size = 16;
	}
}
