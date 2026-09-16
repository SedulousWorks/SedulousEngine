using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// Records commands once, for a pass to replay many times.
///
/// It OWNS every bundle it finishes, until the encoder itself goes.
class WebGpuRenderBundleEncoder : IRenderBundleEncoder
{
	private WGPURenderBundleEncoder mEncoder;
	private PushConstantEmulator mPushConstants = new .() ~ delete _;
	private List<WebGpuRenderBundle> mBundles = new .() ~ DeleteContainerAndItems!(_);

	public Result<void> Initialize(WGPUDevice device, RenderBundleDesc desc)
	{
		WGPUTextureFormat[RhiLimits.MaxColorAttachments] colorFormats = .();
		for (uint32 i = 0; i < desc.ColorFormatCount; i++)
			colorFormats[i] = WebGpuConversions.ToWgpuTextureFormat(desc.ColorFormats[i]);

		WGPURenderBundleEncoderDescriptor wgpu = .();
		wgpu.label = WebGpuConversions.ToWgpuStringView(desc.Label);
		wgpu.colorFormatCount = desc.ColorFormatCount;
		wgpu.colorFormats = &colorFormats[0];
		wgpu.depthStencilFormat =
			WebGpuConversions.ToWgpuTextureFormat(desc.DepthStencilFormat);
		wgpu.depthReadOnly = desc.DepthReadOnly ? 1 : 0;
		wgpu.stencilReadOnly = desc.StencilReadOnly ? 1 : 0;
		wgpu.sampleCount = desc.SampleCount;

		mEncoder = wgpuDeviceCreateRenderBundleEncoder(device, &wgpu);
		mPushConstants.Begin(device);
		return (mEncoder != null) ? .Ok : .Err;
	}

	public ~this()
	{
		// LAST, and deliberately: the emulated buffers and bind groups outlive every
		// bundle this encoder made, a finished bundle holding its own references, so
		// they are freed only once the bundles have gone.
		mPushConstants.Release();
	}

	public void SetPipeline(IRenderPipeline pipeline)
	{
		let wgpuPipeline = pipeline as WebGpuRenderPipeline;
		if (wgpuPipeline == null)
			return;

		wgpuRenderBundleEncoderSetPipeline(mEncoder, wgpuPipeline.Handle);
		mPushConstants.SetPipeline(wgpuPipeline.PushConstants);
	}

	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets = default)
	{
		let wgpuGroup = group as WebGpuBindGroup;
		if (wgpuGroup == null)
			return;

		wgpuRenderBundleEncoderSetBindGroup(mEncoder, index, wgpuGroup.Handle,
			(uint)dynamicOffsets.Length, dynamicOffsets.Ptr);
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (!mPushConstants.Write(offset, size, data))
			WebGpuApi.NativeOnly.BundleSetImmediates(mEncoder, offset, data, size);
	}

	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset = 0)
	{
		let wgpuBuffer = buffer as WebGpuBuffer;
		if (wgpuBuffer == null)
			return;

		wgpuRenderBundleEncoderSetVertexBuffer(mEncoder, slot, wgpuBuffer.Handle, offset,
			WGPU_WHOLE_SIZE);
	}

	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset = 0)
	{
		let wgpuBuffer = buffer as WebGpuBuffer;
		if (wgpuBuffer == null)
			return;

		wgpuRenderBundleEncoderSetIndexBuffer(mEncoder, wgpuBuffer.Handle,
			(format == .UInt16) ? .WGPUIndexFormat_Uint16 : .WGPUIndexFormat_Uint32,
			offset, WGPU_WHOLE_SIZE);
	}

	public void Draw(uint32 vertexCount, uint32 instanceCount = 1, uint32 firstVertex = 0,
		uint32 firstInstance = 0)
	{
		FlushPushConstants();
		wgpuRenderBundleEncoderDraw(mEncoder, vertexCount, instanceCount, firstVertex,
			firstInstance);
	}

	public void DrawIndexed(uint32 indexCount, uint32 instanceCount = 1, uint32 firstIndex = 0,
		int32 baseVertex = 0, uint32 firstInstance = 0)
	{
		FlushPushConstants();
		wgpuRenderBundleEncoderDrawIndexed(mEncoder, indexCount, instanceCount, firstIndex,
			baseVertex, firstInstance);
	}

	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1,
		uint32 stride = 0)
	{
		let wgpuBuffer = buffer as WebGpuBuffer;
		if (wgpuBuffer == null)
			return;

		FlushPushConstants();
		// One draw per indirect call, core WebGPU having no multi draw.
		for (uint32 i = 0; i < drawCount; i++)
			wgpuRenderBundleEncoderDrawIndirect(mEncoder, wgpuBuffer.Handle,
				offset + (uint64)i * stride);
	}

	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1,
		uint32 stride = 0)
	{
		let wgpuBuffer = buffer as WebGpuBuffer;
		if (wgpuBuffer == null)
			return;

		FlushPushConstants();
		for (uint32 i = 0; i < drawCount; i++)
			wgpuRenderBundleEncoderDrawIndexedIndirect(mEncoder, wgpuBuffer.Handle,
				offset + (uint64)i * stride);
	}

	public IRenderBundle Finish()
	{
		WGPURenderBundleDescriptor wgpu = .();
		let handle = wgpuRenderBundleEncoderFinish(mEncoder, &wgpu);
		wgpuRenderBundleEncoderRelease(mEncoder);
		mEncoder = null;

		let bundle = new WebGpuRenderBundle();
		bundle.Adopt(handle);
		mBundles.Add(bundle); // owned until this encoder goes
		return bundle;
	}

	/// Uploads and binds any pending emulated block before a bundle draw. The value is
	/// captured ONCE here, at record time, bundles being static.
	private void FlushPushConstants()
	{
		if (mPushConstants.FlushBeforeDraw(let group, let bindGroup))
			wgpuRenderBundleEncoderSetBindGroup(mEncoder, (uint32)group, bindGroup, 0, null);
	}
}
