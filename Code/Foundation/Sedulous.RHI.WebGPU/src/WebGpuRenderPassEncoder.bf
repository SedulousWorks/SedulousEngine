using System;
using System.Collections;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// A render pass.
sealed class WebGpuRenderPassEncoder : IRenderPassEncoder
{
	/// How many bundles go per execute call. Batched rather than one at a time, and
	/// flushed when full, so a long list costs a bounded number of calls.
	private const int cBundleBatch = 16;

	private WGPURenderPassEncoder mEncoder;
	private PushConstantEmulator mPushConstants = new .() ~ delete _;

	public void Begin(WGPUDevice device, WGPURenderPassEncoder encoder)
	{
		mEncoder = encoder;
		mPushConstants.Begin(device);
	}

	public void SetPipeline(IRenderPipeline pipeline)
	{
		let wgpuPipeline = pipeline as WebGpuRenderPipeline;
		if (wgpuPipeline == null)
			return;

		wgpuRenderPassEncoderSetPipeline(mEncoder, wgpuPipeline.Handle);
		mPushConstants.SetPipeline(wgpuPipeline.PushConstants);
	}

	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets = default)
	{
		let wgpuGroup = group as WebGpuBindGroup;
		if (wgpuGroup == null)
			return;

		wgpuRenderPassEncoderSetBindGroup(mEncoder, index, wgpuGroup.Handle,
			(uint)dynamicOffsets.Length, dynamicOffsets.Ptr);
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		// An emulating pipeline folds this into the shadow, to be bound before the next
		// draw. Otherwise the pipeline declared native immediates, so issue them.
		if (!mPushConstants.Write(offset, size, data))
			WebGpuApi.NativeOnly.RenderSetImmediates(mEncoder, offset, data, size);
	}

	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset = 0)
	{
		let wgpuBuffer = buffer as WebGpuBuffer;
		if (wgpuBuffer == null)
			return;

		wgpuRenderPassEncoderSetVertexBuffer(mEncoder, slot, wgpuBuffer.Handle, offset,
			WGPU_WHOLE_SIZE);
	}

	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset = 0)
	{
		let wgpuBuffer = buffer as WebGpuBuffer;
		if (wgpuBuffer == null)
			return;

		wgpuRenderPassEncoderSetIndexBuffer(mEncoder, wgpuBuffer.Handle,
			(format == .UInt16) ? .WGPUIndexFormat_Uint16 : .WGPUIndexFormat_Uint32,
			offset, WGPU_WHOLE_SIZE);
	}

	public void SetViewport(float x, float y, float width, float height,
		float minDepth = 0.0f, float maxDepth = 1.0f)
	{
		wgpuRenderPassEncoderSetViewport(mEncoder, x, y, width, height, minDepth, maxDepth);
	}

	public void SetScissor(int32 x, int32 y, uint32 width, uint32 height)
	{
		wgpuRenderPassEncoderSetScissorRect(mEncoder, (uint32)x, (uint32)y, width, height);
	}

	public void SetBlendConstant(float r, float g, float b, float a)
	{
		WGPUColor color = .() { r = r, g = g, b = b, a = a };
		wgpuRenderPassEncoderSetBlendConstant(mEncoder, &color);
	}

	public void SetStencilReference(uint32 reference)
	{
		wgpuRenderPassEncoderSetStencilReference(mEncoder, reference);
	}

	public void Draw(uint32 vertexCount, uint32 instanceCount = 1, uint32 firstVertex = 0,
		uint32 firstInstance = 0)
	{
		FlushPushConstants();
		wgpuRenderPassEncoderDraw(mEncoder, vertexCount, instanceCount, firstVertex,
			firstInstance);
	}

	public void DrawIndexed(uint32 indexCount, uint32 instanceCount = 1, uint32 firstIndex = 0,
		int32 baseVertex = 0, uint32 firstInstance = 0)
	{
		FlushPushConstants();
		wgpuRenderPassEncoderDrawIndexed(mEncoder, indexCount, instanceCount, firstIndex,
			baseVertex, firstInstance);
	}

	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1,
		uint32 stride = 0)
	{
		let wgpuBuffer = buffer as WebGpuBuffer;
		if (wgpuBuffer == null)
			return;

		FlushPushConstants();
		// Core WebGPU issues ONE draw per indirect call, having no multi draw, so a
		// requested count becomes that many calls walking the stride.
		for (uint32 i = 0; i < drawCount; i++)
			wgpuRenderPassEncoderDrawIndirect(mEncoder, wgpuBuffer.Handle,
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
			wgpuRenderPassEncoderDrawIndexedIndirect(mEncoder, wgpuBuffer.Handle,
				offset + (uint64)i * stride);
	}

	public void ExecuteBundles(Span<IRenderBundle> bundles)
	{
		WGPURenderBundle[cBundleBatch] handles = .();
		var count = 0;

		for (let bundle in bundles)
		{
			if (count == cBundleBatch)
			{
				wgpuRenderPassEncoderExecuteBundles(mEncoder, (uint)count, &handles[0]);
				count = 0;
			}

			if (let wgpuBundle = bundle as WebGpuRenderBundle)
			{
				handles[count] = wgpuBundle.Handle;
				count++;
			}
		}

		if (count > 0)
			wgpuRenderPassEncoderExecuteBundles(mEncoder, (uint)count, &handles[0]);
	}

	/// Nothing to do: a timestamp INSIDE a pass has no WebGPU shape. Begin and end of
	/// pass writes ride the pass descriptor instead.
	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
	}

	/// The SET was declared when the pass began, so WebGPU only takes the index here.
	public void BeginOcclusionQuery(IQuerySet querySet, uint32 index)
	{
		wgpuRenderPassEncoderBeginOcclusionQuery(mEncoder, index);
	}

	public void EndOcclusionQuery(IQuerySet querySet, uint32 index)
	{
		wgpuRenderPassEncoderEndOcclusionQuery(mEncoder);
	}

	public void End()
	{
		wgpuRenderPassEncoderEnd(mEncoder);
		// AFTER End: the pass commands hold their own references now, so the emulated
		// uniform buffers and bind groups can go.
		mPushConstants.Release();
		wgpuRenderPassEncoderRelease(mEncoder);
		mEncoder = null;
	}

	/// Uploads and binds any pending emulated block before a draw. A no-op for a
	/// pipeline using native immediates.
	private void FlushPushConstants()
	{
		if (mPushConstants.FlushBeforeDraw(let group, let bindGroup))
			wgpuRenderPassEncoderSetBindGroup(mEncoder, (uint32)group, bindGroup, 0, null);
	}
}
