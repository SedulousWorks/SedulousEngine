namespace Sedulous.Renderer.IBL;

using System;
using Sedulous.RHI;
using Sedulous.RenderGraph;
using Sedulous.Shaders;

/// Builds the prefiltered specular mip chain for reflection probes via render
/// passes (one per probe-face-mip slice). A fragment shader runs the GGX
/// importance-sample convolution into a single-(mip, face) slice of the
/// shared `RenderContext.PrefilteredCubemapTexture`.
///
/// Render-pass rather than compute because HLSL has no portable way to declare
/// the SPIR-V storage-image format DXC defaults `RWTexture2D<float4>` to
/// rgba32f, mismatching the rgba16f view, and the only documented override is
/// a Vulkan-specific `[[vk::image_format]]` annotation we'd rather avoid as a
/// codebase convention. Color-target writes go through the normal render
/// pipeline and inherit the view's format with no annotation needed.
///
/// Mip 0 is captured directly by ProbeCapturePass; this system writes mips
/// 1..MipCount-1 with roughness = mip / (mipCount - 1). 6 faces *
/// (MipCount - 1) render passes per probe per frame, scheduled by the
/// `AddPrefilterPasses` call below.
///
/// Per-slot resources (color-target view + params buffer + bind group) are
/// created lazily on first dispatch and live for the system's lifetime. Total
/// slot count is bounded by MaxIBLProbes * 6 * (PrefilterMipCount - 1).
class IBLPrefilterSystem : IDisposable
{
	private IDevice mDevice;
	private IRenderPipeline mPipeline;
	private IPipelineLayout mPipelineLayout;
	private IBindGroupLayout mBindGroupLayout;

	// Source cubemap view (mip-0-only, TextureCubeArray) and the sampler are
	// shared by every dispatch and supplied by RenderContext at init.
	private ITextureView mSourceCubemapView;
	private ITexture mCubemapTexture;
	private ISampler mSampler;

	private const uint64 ParamsBufferSize = 32;

	[CRepr]
	private struct SlotResources
	{
		public ITextureView ColorTargetView;
		public IBuffer ParamsBuffer;
		public IBindGroup BindGroup;
		public uint32 MipSize;
		public bool Initialized;
	}

	private SlotResources[Sedulous.Renderer.RenderContext.MaxIBLProbes *
		6 * Sedulous.Renderer.RenderContext.IBLPrefilterMipCount] mSlots;

	[CRepr]
	private struct PrefilterParams
	{
		public uint32 ProbeSlot;
		public uint32 FaceIndex;
		public uint32 MipLevel;
		public uint32 MipCount;
		public uint32 FaceSize;
		public uint32 MipSize;
		public float Roughness;
		public uint32 _Pad;
	}

	public Result<void> Initialize(IDevice device, ShaderSystem shaderSystem,
		ITexture cubemapTexture, ITextureView sourceCubemapView, ISampler sampler)
	{
		mDevice = device;
		mCubemapTexture = cubemapTexture;
		mSourceCubemapView = sourceCubemapView;
		mSampler = sampler;

		if (shaderSystem == null) return .Err;

		// Shared fullscreen-triangle vertex shader; tonemap/bloom/fxaa use the
		// same one. The prefilter fragment shader does the GGX integration.
		let vertResult = shaderSystem.GetShader("fullscreen", .Vertex);
		if (vertResult case .Err) return .Err;
		let vertModule = vertResult.Value;

		let fragResult = shaderSystem.GetShader("ibl_prefilter", .Fragment);
		if (fragResult case .Err) return .Err;
		let fragModule = fragResult.Value;

		// Bind group layout (set 0):
		//   b0: PrefilterParams (uniform)
		//   t0: SourceCubemap (TextureCubeArray sampled)
		//   s0: LinearSampler
		// Output is the color attachment - not a bind-group entry.
		BindGroupLayoutEntry[3] entries = .(
			.UniformBuffer(0, .Fragment),
			.SampledTexture(0, .Fragment, .TextureCubeArray),
			.Sampler(0, .Fragment)
		);

		BindGroupLayoutDesc layoutDesc = .() { Label = "IBLPrefilter BindGroup Layout", Entries = entries };
		if (device.CreateBindGroupLayout(layoutDesc) case .Ok(let layout))
			mBindGroupLayout = layout;
		else
			return .Err;

		IBindGroupLayout[1] layouts = .(mBindGroupLayout);
		if (device.CreatePipelineLayout(.(layouts)) case .Ok(let plLayout))
			mPipelineLayout = plLayout;
		else
			return .Err;

		ColorTargetState[1] colorTargets = .(.() { Format = .RGBA16Float });

		RenderPipelineDesc pipelineDesc = .()
		{
			Label = "IBLPrefilter Pipeline",
			Layout = mPipelineLayout,
			Vertex = .() { Shader = .(vertModule.Module, "main"), Buffers = default },
			Fragment = .() { Shader = .(fragModule.Module, "main"), Targets = colorTargets },
			Primitive = .() { Topology = .TriangleList, FrontFace = .CCW, CullMode = .None },
			DepthStencil = null,
			Multisample = .() { Count = 1, Mask = uint32.MaxValue }
		};
		if (device.CreateRenderPipeline(pipelineDesc) case .Ok(let pipe))
			mPipeline = pipe;
		else
			return .Err;

		return .Ok;
	}

	/// Adds the prefilter render passes for one probe's mip chain to the
	/// graph. Called by ProbeCapturePass after the face-capture render pass
	/// for the same probe. Adds (mipCount - 1) * 6 passes - mip 0 is the
	/// captured face itself and is not written here. Re-filtering all 6
	/// faces every frame keeps the chain internally consistent while the
	/// per-frame face capture cycles through them.
	public void AddPrefilterPasses(Sedulous.RenderGraph.RenderGraph graph, RGHandle cubeHandle, int32 probeSlot)
	{
		if (mPipeline == null) return;
		if (probeSlot < 0 || probeSlot >= Sedulous.Renderer.RenderContext.MaxIBLProbes) return;

		let mipCount = (uint32)Sedulous.Renderer.RenderContext.IBLPrefilterMipCount;
		let faceSize = (uint32)Sedulous.Renderer.RenderContext.IBLProbeFaceSize;

		for (uint32 face = 0; face < 6; face++)
		{
			// Mip 0 is the captured face - skip.
			for (uint32 mip = 1; mip < mipCount; mip++)
			{
				let slotIdx = SlotIndex(probeSlot, (int32)face, (int32)mip);
				if (!EnsureSlot(slotIdx, probeSlot, face, mip, mipCount, faceSize))
					continue;

				let slot = mSlots[slotIdx];
				let cubemapLayer = (uint32)(probeSlot * 6) + face;
				let colorSubres = RGSubresourceRange(mip, 1, cubemapLayer, 1);

				graph.AddRenderPass("ProbePrefilterSlice", scope (builder) => {
					builder
						.ReadTexture(cubeHandle, RGSubresourceRange(0, 1, 0, 0))  // sample mip 0, all layers
						.SetColorTarget(0, cubeHandle, .DontCare, .Store, ClearColor(0, 0, 0, 1), colorSubres)
						.NeverCull()
						.SetExecute(new [=] (encoder) => {
							ExecuteSlice(encoder, slot);
						});
				});
			}
		}
	}

	private void ExecuteSlice(IRenderPassEncoder encoder, SlotResources slot)
	{
		let mipSize = (float)slot.MipSize;
		encoder.SetViewport(0, 0, mipSize, mipSize, 0, 1);
		encoder.SetScissor(0, 0, slot.MipSize, slot.MipSize);
		encoder.SetPipeline(mPipeline);
		encoder.SetBindGroup(0, slot.BindGroup, default);
		encoder.Draw(3, 1, 0, 0);
	}

	private static int32 SlotIndex(int32 probe, int32 face, int32 mip)
	{
		return ((probe * 6) + face) * Sedulous.Renderer.RenderContext.IBLPrefilterMipCount + mip;
	}

	/// Lazily allocates the color-target view + params buffer + bind group for
	/// one (probe, face, mip) dispatch slot. Returns false on allocation failure.
	private bool EnsureSlot(int32 slotIdx, int32 probe, uint32 face, uint32 mip, uint32 mipCount, uint32 faceSize)
	{
		var slot = ref mSlots[slotIdx];
		if (slot.Initialized) return true;

		// Color-target view: single (mip, layer) slice of the cubemap array.
		let cubemapLayer = (uint32)(probe * 6) + face;
		if (mDevice.CreateTextureView(mCubemapTexture, .()
			{
				Format = .RGBA16Float,
				Dimension = .Texture2D,
				BaseMipLevel = mip,
				MipLevelCount = 1,
				BaseArrayLayer = cubemapLayer,
				ArrayLayerCount = 1,
				Label = "IBLPrefilter Output Slice"
			}) case .Ok(let view))
			slot.ColorTargetView = view;
		else
			return false;

		BufferDesc bufDesc = .()
		{
			Label = "IBLPrefilter Params",
			Size = ParamsBufferSize,
			Usage = .Uniform,
			Memory = .CpuToGpu
		};
		if (mDevice.CreateBuffer(bufDesc) case .Ok(let buf))
			slot.ParamsBuffer = buf;
		else
		{
			mDevice.DestroyTextureView(ref slot.ColorTargetView);
			return false;
		}

		let mipSize = Math.Max(faceSize >> mip, 1U);
		float roughness = (float)mip / (float)Math.Max(mipCount - 1, 1);
		PrefilterParams @params = .()
		{
			ProbeSlot = (uint32)probe,
			FaceIndex = face,
			MipLevel = mip,
			MipCount = mipCount,
			FaceSize = faceSize,
			MipSize = mipSize,
			Roughness = roughness
		};
		TransferHelper.WriteMappedBuffer(slot.ParamsBuffer, 0,
			Span<uint8>((uint8*)&@params, (.)sizeof(PrefilterParams)));

		BindGroupEntry[3] bgEntries = .(
			BindGroupEntry.Buffer(slot.ParamsBuffer, 0, ParamsBufferSize),
			BindGroupEntry.Texture(mSourceCubemapView),
			BindGroupEntry.Sampler(mSampler)
		);
		BindGroupDesc bgDesc = .()
		{
			Label = "IBLPrefilter BindGroup",
			Layout = mBindGroupLayout,
			Entries = bgEntries
		};
		if (mDevice.CreateBindGroup(bgDesc) case .Ok(let bg))
			slot.BindGroup = bg;
		else
		{
			mDevice.DestroyBuffer(ref slot.ParamsBuffer);
			mDevice.DestroyTextureView(ref slot.ColorTargetView);
			return false;
		}

		slot.MipSize = mipSize;
		slot.Initialized = true;
		return true;
	}

	public void Dispose()
	{
		if (mDevice == null) return;

		for (int i = 0; i < mSlots.Count; i++)
		{
			var slot = ref mSlots[i];
			if (slot.BindGroup != null) mDevice.DestroyBindGroup(ref slot.BindGroup);
			if (slot.ParamsBuffer != null) mDevice.DestroyBuffer(ref slot.ParamsBuffer);
			if (slot.ColorTargetView != null) mDevice.DestroyTextureView(ref slot.ColorTargetView);
			slot.Initialized = false;
		}

		if (mPipeline != null) mDevice.DestroyRenderPipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
	}
}
