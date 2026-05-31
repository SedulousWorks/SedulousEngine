namespace Sedulous.Renderer.IBL;

using System;
using Sedulous.RHI;
using Sedulous.Shaders;

/// Projects a probe's captured cubemap onto 9 spherical-harmonic coefficients
/// per RGB channel, pre-convolved with the Lambertian cosine kernel so the
/// runtime irradiance lookup is `sum(coeff[j] * Y_j(N))` without per-fragment
/// band weights.
///
/// One workgroup per probe; the shader samples a high-mip (coarse) face of the
/// cubemap (SH9 captures only the low-frequency content anyway) and reduces
/// into the 9 RGB coefficients via groupshared parallel reduction. Output is
/// the same `RenderContext.SH9Buffer` that the forward fragment shader binds
/// at set 0 t4.
class IBLSH9System : IDisposable
{
	private IDevice mDevice;
	private IComputePipeline mPipeline;
	private IPipelineLayout mPipelineLayout;
	private IBindGroupLayout mBindGroupLayout;

	private ITextureView mSourceCubemapView;
	private IBuffer mSH9Buffer;
	private ISampler mSampler;

	private const uint64 ParamsBufferSize = 16;
	// Sampling mip is 0 because the source view restricts to mip 0 (Vulkan
	// layout-tracking requirement: prefilter writes mips 1..N as General in
	// the same dispatch series, so the SH9 source view can't span those).
	// SamplingFaceSize is the virtual grid the shader iterates over - the
	// bilinear sampler at LOD 0 effectively averages 16x16 mip-0 texels per
	// virtual texel (128/8 = 16). 6 faces * 8 * 8 = 384 samples per probe,
	// reduced across 64 threads in one workgroup.
	private const uint32 SamplingMipLevel = 0;
	private const uint32 SamplingFaceSize = 8;

	[CRepr]
	private struct SlotResources
	{
		public IBuffer ParamsBuffer;
		public IBindGroup BindGroup;
		public bool Initialized;
	}

	private SlotResources[Sedulous.Renderer.RenderContext.MaxIBLProbes] mSlots;

	[CRepr]
	private struct SH9Params
	{
		public uint32 ProbeSlot;
		public uint32 MipLevel;
		public uint32 MipFaceSize;
		public uint32 _Pad;
	}

	public Result<void> Initialize(IDevice device, ShaderSystem shaderSystem,
		ITextureView sourceCubemapView, IBuffer sh9Buffer, ISampler sampler)
	{
		mDevice = device;
		mSourceCubemapView = sourceCubemapView;
		mSH9Buffer = sh9Buffer;
		mSampler = sampler;

		if (shaderSystem == null) return .Err;

		let shaderResult = shaderSystem.GetShader("ibl_sh9_project", .Compute);
		if (shaderResult case .Err) return .Err;

		let computeModule = shaderResult.Value;

		// Bind group layout matches ibl_sh9_project.comp.hlsl set 0:
		//   b0: SH9Params (uniform)
		//   t0: SourceCubemap (TextureCubeArray sampled)
		//   u0: OutputSH9 (StructuredBuffer<float4>, RW, stride 16)
		//   s0: LinearSampler
		BindGroupLayoutEntry[4] entries = .(
			.UniformBuffer(0, .Compute),
			.SampledTexture(0, .Compute, .TextureCubeArray),
			.() { Binding = 0, Visibility = .Compute, Type = .StorageBufferReadWrite, StorageBufferStride = 16 },
			.Sampler(0, .Compute)
		);

		BindGroupLayoutDesc layoutDesc = .() { Label = "IBLSH9 BindGroup Layout", Entries = entries };
		if (device.CreateBindGroupLayout(layoutDesc) case .Ok(let layout))
			mBindGroupLayout = layout;
		else
			return .Err;

		IBindGroupLayout[1] layouts = .(mBindGroupLayout);
		if (device.CreatePipelineLayout(.(layouts)) case .Ok(let plLayout))
			mPipelineLayout = plLayout;
		else
			return .Err;

		ComputePipelineDesc pipelineDesc = .()
		{
			Label = "IBLSH9 Compute Pipeline",
			Layout = mPipelineLayout,
			Compute = .(computeModule.Module, "main")
		};
		if (device.CreateComputePipeline(pipelineDesc) case .Ok(let pipe))
			mPipeline = pipe;
		else
			return .Err;

		return .Ok;
	}

	/// Dispatches the SH9 projection compute for one probe. One workgroup
	/// (1, 1, 1); the shader handles all 6 faces internally with a parallel
	/// reduction. Lazily allocates the per-probe params buffer + bind group
	/// on first use.
	public void DispatchProject(IComputePassEncoder encoder, int32 probeSlot)
	{
		if (mPipeline == null) return;
		if (probeSlot < 0 || probeSlot >= Sedulous.Renderer.RenderContext.MaxIBLProbes) return;

		if (!EnsureSlot(probeSlot)) return;

		let slot = mSlots[probeSlot];
		encoder.SetPipeline(mPipeline);
		encoder.SetBindGroup(0, slot.BindGroup, default);
		encoder.Dispatch(1, 1, 1);
	}

	private bool EnsureSlot(int32 probeSlot)
	{
		var slot = ref mSlots[probeSlot];
		if (slot.Initialized) return true;

		BufferDesc bufDesc = .()
		{
			Label = "IBLSH9 Params",
			Size = ParamsBufferSize,
			Usage = .Uniform,
			Memory = .CpuToGpu
		};
		if (mDevice.CreateBuffer(bufDesc) case .Ok(let buf))
			slot.ParamsBuffer = buf;
		else
			return false;

		SH9Params @params = .()
		{
			ProbeSlot = (uint32)probeSlot,
			MipLevel = SamplingMipLevel,
			MipFaceSize = SamplingFaceSize
		};
		TransferHelper.WriteMappedBuffer(slot.ParamsBuffer, 0,
			Span<uint8>((uint8*)&@params, (.)sizeof(SH9Params)));

		let sh9BufferSize = (uint64)(Sedulous.Renderer.RenderContext.MaxIBLProbes
			* Sedulous.Renderer.RenderContext.IBLSH9CoeffPerProbe * 16);

		BindGroupEntry[4] bgEntries = .(
			BindGroupEntry.Buffer(slot.ParamsBuffer, 0, ParamsBufferSize),
			BindGroupEntry.Texture(mSourceCubemapView),
			BindGroupEntry.Buffer(mSH9Buffer, 0, sh9BufferSize),
			BindGroupEntry.Sampler(mSampler)
		);
		BindGroupDesc bgDesc = .()
		{
			Label = "IBLSH9 BindGroup",
			Layout = mBindGroupLayout,
			Entries = bgEntries
		};
		if (mDevice.CreateBindGroup(bgDesc) case .Ok(let bg))
			slot.BindGroup = bg;
		else
		{
			mDevice.DestroyBuffer(ref slot.ParamsBuffer);
			return false;
		}

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
			slot.Initialized = false;
		}

		if (mPipeline != null) mDevice.DestroyComputePipeline(ref mPipeline);
		if (mPipelineLayout != null) mDevice.DestroyPipelineLayout(ref mPipelineLayout);
		if (mBindGroupLayout != null) mDevice.DestroyBindGroupLayout(ref mBindGroupLayout);
	}
}
