using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Validation;

/// Watches a command encoder: its recording state, that passes are closed before it
/// finishes, that debug labels balance, and what the copy and query calls are handed.
class ValidatedCommandEncoder : ICommandEncoder, IRayTracingEncoderExt
{
	private ICommandEncoder mInner;
	private IRayTracingEncoderExt mInnerRayTracing;

	private bool mFinished = false;
	private ValidatedRenderPassEncoder mRenderPass ~ delete _;
	private ValidatedComputePassEncoder mComputePass ~ delete _;
	private ValidatedRenderBundleEncoder mBundleEncoder ~ delete _;

	private bool mRenderPassOpen = false;
	private bool mComputePassOpen = false;
	private int mOpenDebugLabels = 0;
	private bool mRayTracingPipelineBound = false;

	public this(ICommandEncoder inner)
	{
		mInner = inner;
		mInnerRayTracing = inner as IRayTracingEncoderExt;
	}

	public ICommandEncoder Inner => mInner;

	public IRenderPassEncoder BeginRenderPass(RenderPassDesc desc)
	{
		if (Finished("BeginRenderPass"))
			return null;

		// A pass with nothing attached renders nowhere, which is almost always a descriptor
		// that was built but never filled in.
		if (desc.ColorAttachments.IsEmpty && (desc.DepthStencilAttachment == null))
			ValidationLog.Warn("CommandEncoder.BeginRenderPass: no colour or depth attachment");

		var attachments = desc.ColorAttachments;
		for (int i < attachments.Count)
		{
			if (attachments[i].View == null)
			{
				ValidationLog.Error(scope $"CommandEncoder.BeginRenderPass: colour attachment {i} view is null");
				return null;
			}
		}

		let inner = mInner.BeginRenderPass(desc);
		if (inner == null)
			return null;

		mRenderPassOpen = true;
		delete mRenderPass;
		mRenderPass = new ValidatedRenderPassEncoder(inner);
		return mRenderPass;
	}

	public IComputePassEncoder BeginComputePass(StringView label)
	{
		if (Finished("BeginComputePass"))
			return null;

		let inner = mInner.BeginComputePass(label);
		if (inner == null)
			return null;

		mComputePassOpen = true;
		delete mComputePass;
		mComputePass = new ValidatedComputePassEncoder(inner);
		return mComputePass;
	}

	public IRenderBundleEncoder CreateRenderBundleEncoder(RenderBundleDesc desc)
	{
		if (Finished("CreateRenderBundleEncoder"))
			return null;

		let inner = mInner.CreateRenderBundleEncoder(desc);
		if (inner == null)
			return null;

		delete mBundleEncoder;
		mBundleEncoder = new ValidatedRenderBundleEncoder(inner);
		return mBundleEncoder;
	}

	public void Barrier(BarrierGroup group)
	{
		if (Finished("Barrier"))
			return;
		mInner.Barrier(group);
	}

	public void CopyBufferToBuffer(IBuffer src, uint64 srcOffset, IBuffer dst, uint64 dstOffset,
		uint64 size)
	{
		if (Finished("CopyBufferToBuffer"))
			return;
		if (src == null)
		{
			ValidationLog.Error("CommandEncoder.CopyBufferToBuffer: src is null");
			return;
		}
		if (dst == null)
		{
			ValidationLog.Error("CommandEncoder.CopyBufferToBuffer: dst is null");
			return;
		}
		if (size == 0)
			ValidationLog.Warn("CommandEncoder.CopyBufferToBuffer: size is zero");
		mInner.CopyBufferToBuffer(src, srcOffset, dst, dstOffset, size);
	}

	public void CopyBufferToTexture(IBuffer src, ITexture dst, BufferTextureCopyRegion region)
	{
		if (Finished("CopyBufferToTexture"))
			return;
		if (src == null)
		{
			ValidationLog.Error("CommandEncoder.CopyBufferToTexture: src is null");
			return;
		}
		if (dst == null)
		{
			ValidationLog.Error("CommandEncoder.CopyBufferToTexture: dst is null");
			return;
		}
		mInner.CopyBufferToTexture(src, dst, region);
	}

	public void CopyTextureToBuffer(ITexture src, IBuffer dst, BufferTextureCopyRegion region)
	{
		if (Finished("CopyTextureToBuffer"))
			return;
		if (src == null)
		{
			ValidationLog.Error("CommandEncoder.CopyTextureToBuffer: src is null");
			return;
		}
		if (dst == null)
		{
			ValidationLog.Error("CommandEncoder.CopyTextureToBuffer: dst is null");
			return;
		}
		mInner.CopyTextureToBuffer(src, dst, region);
	}

	public void CopyTextureToTexture(ITexture src, ITexture dst, TextureCopyRegion region)
	{
		if (Finished("CopyTextureToTexture"))
			return;
		if (src == null)
		{
			ValidationLog.Error("CommandEncoder.CopyTextureToTexture: src is null");
			return;
		}
		if (dst == null)
		{
			ValidationLog.Error("CommandEncoder.CopyTextureToTexture: dst is null");
			return;
		}
		mInner.CopyTextureToTexture(src, dst, region);
	}

	public void Blit(ITexture src, ITexture dst)
	{
		if (Finished("Blit"))
			return;
		if ((src == null) || (dst == null))
		{
			ValidationLog.Error("CommandEncoder.Blit: src or dst is null");
			return;
		}
		mInner.Blit(src, dst);
	}

	public void GenerateMipmaps(ITexture texture)
	{
		if (Finished("GenerateMipmaps"))
			return;
		if (texture == null)
		{
			ValidationLog.Error("CommandEncoder.GenerateMipmaps: texture is null");
			return;
		}
		mInner.GenerateMipmaps(texture);
	}

	public void ResolveTexture(ITexture src, ITexture dst)
	{
		if (Finished("ResolveTexture"))
			return;
		if ((src == null) || (dst == null))
		{
			ValidationLog.Error("CommandEncoder.ResolveTexture: src or dst is null");
			return;
		}
		mInner.ResolveTexture(src, dst);
	}

	public void ResetQuerySet(IQuerySet querySet, uint32 first, uint32 count)
	{
		if (Finished("ResetQuerySet"))
			return;
		if (querySet == null)
		{
			ValidationLog.Error("CommandEncoder.ResetQuerySet: querySet is null");
			return;
		}
		mInner.ResetQuerySet(querySet, first, count);
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		if (Finished("WriteTimestamp"))
			return;
		if (querySet == null)
		{
			ValidationLog.Error("CommandEncoder.WriteTimestamp: querySet is null");
			return;
		}
		mInner.WriteTimestamp(querySet, index);
	}

	public void ResolveQuerySet(IQuerySet querySet, uint32 first, uint32 count, IBuffer dst,
		uint64 dstOffset)
	{
		if (Finished("ResolveQuerySet"))
			return;
		if (querySet == null)
		{
			ValidationLog.Error("CommandEncoder.ResolveQuerySet: querySet is null");
			return;
		}
		if (dst == null)
		{
			ValidationLog.Error("CommandEncoder.ResolveQuerySet: dst is null");
			return;
		}
		mInner.ResolveQuerySet(querySet, first, count, dst, dstOffset);
	}

	public void BeginDebugLabel(StringView label, float r, float g, float b, float a)
	{
		if (Finished("BeginDebugLabel"))
			return;
		mOpenDebugLabels++;
		mInner.BeginDebugLabel(label, r, g, b, a);
	}

	/// Labels NEST, so an unmatched end pops something the caller did not open, and every
	/// label after it is attributed to the wrong scope in a capture.
	public void EndDebugLabel()
	{
		if (Finished("EndDebugLabel"))
			return;
		if (mOpenDebugLabels == 0)
		{
			ValidationLog.Error("CommandEncoder.EndDebugLabel: no matching begin");
			return;
		}
		mOpenDebugLabels--;
		mInner.EndDebugLabel();
	}

	public void InsertDebugLabel(StringView label, float r, float g, float b, float a)
	{
		if (Finished("InsertDebugLabel"))
			return;
		mInner.InsertDebugLabel(label, r, g, b, a);
	}

	/// Finishing with a pass still open produces a command buffer a backend will reject, or
	/// worse accept: the checks here name which pass rather than leaving a driver error.
	public ICommandBuffer Finish()
	{
		if (mFinished)
		{
			ValidationLog.Error("CommandEncoder.Finish: already finished");
			return null;
		}
		if (mRenderPassOpen && !RenderPassEnded)
		{
			ValidationLog.Error("CommandEncoder.Finish: a render pass is still open");
			return null;
		}
		if (mComputePassOpen && !ComputePassEnded)
		{
			ValidationLog.Error("CommandEncoder.Finish: a compute pass is still open");
			return null;
		}
		if (mOpenDebugLabels > 0)
			ValidationLog.Warn(scope $"CommandEncoder.Finish: {mOpenDebugLabels} debug label(s) were not closed");

		mFinished = true;
		return mInner.Finish();
	}

	// ---- IRayTracingEncoderExt ----

	public void BuildBottomLevelAccelStruct(IAccelStruct dst, IBuffer scratchBuffer,
		uint64 scratchOffset, Span<AccelStructGeometryTriangles> triangles,
		Span<AccelStructGeometryAABBs> aabbs)
	{
		if (Finished("BuildBottomLevelAccelStruct"))
			return;
		if (dst == null)
		{
			ValidationLog.Error("CommandEncoder.BuildBottomLevelAccelStruct: dst is null");
			return;
		}
		if (scratchBuffer == null)
		{
			ValidationLog.Error("CommandEncoder.BuildBottomLevelAccelStruct: scratch buffer is null");
			return;
		}
		if (!RayTracingAvailable("BuildBottomLevelAccelStruct"))
			return;
		mInnerRayTracing.BuildBottomLevelAccelStruct(dst, scratchBuffer, scratchOffset,
			triangles, aabbs);
	}

	public void BuildTopLevelAccelStruct(IAccelStruct dst, IBuffer scratchBuffer,
		uint64 scratchOffset, IBuffer instanceBuffer, uint64 instanceOffset,
		uint32 instanceCount)
	{
		if (Finished("BuildTopLevelAccelStruct"))
			return;
		if ((dst == null) || (scratchBuffer == null) || (instanceBuffer == null))
		{
			ValidationLog.Error("CommandEncoder.BuildTopLevelAccelStruct: a required argument is null");
			return;
		}
		if (!RayTracingAvailable("BuildTopLevelAccelStruct"))
			return;
		mInnerRayTracing.BuildTopLevelAccelStruct(dst, scratchBuffer, scratchOffset,
			instanceBuffer, instanceOffset, instanceCount);
	}

	public void SetRayTracingPipeline(IRayTracingPipeline pipeline)
	{
		if (Finished("SetRayTracingPipeline"))
			return;
		if (pipeline == null)
		{
			ValidationLog.Error("CommandEncoder.SetRayTracingPipeline: pipeline is null");
			return;
		}
		if (!RayTracingAvailable("SetRayTracingPipeline"))
			return;
		mRayTracingPipelineBound = true;
		mInnerRayTracing.SetRayTracingPipeline(pipeline);
	}

	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets)
	{
		if (Finished("SetBindGroup"))
			return;
		if (group == null)
		{
			ValidationLog.Error("CommandEncoder.SetBindGroup: group is null");
			return;
		}
		if (!mRayTracingPipelineBound)
			ValidationLog.Warn("CommandEncoder.SetBindGroup: no ray tracing pipeline is bound");
		if (!RayTracingAvailable("SetBindGroup"))
			return;
		mInnerRayTracing.SetBindGroup(index, group, dynamicOffsets);
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (Finished("SetPushConstants"))
			return;
		if (!mRayTracingPipelineBound)
			ValidationLog.Warn("CommandEncoder.SetPushConstants: no ray tracing pipeline is bound");
		if (data == null)
		{
			ValidationLog.Error("CommandEncoder.SetPushConstants: data is null");
			return;
		}
		if (!RayTracingAvailable("SetPushConstants"))
			return;
		mInnerRayTracing.SetPushConstants(stages, offset, size, data);
	}

	public void TraceRays(IBuffer raygenSBT, uint64 raygenOffset, uint64 raygenStride,
		IBuffer missSBT, uint64 missOffset, uint64 missStride,
		IBuffer hitSBT, uint64 hitOffset, uint64 hitStride,
		uint32 width, uint32 height, uint32 depth)
	{
		if (Finished("TraceRays"))
			return;
		if (!mRayTracingPipelineBound)
		{
			ValidationLog.Error("CommandEncoder.TraceRays: no ray tracing pipeline is bound");
			return;
		}
		if (raygenSBT == null)
		{
			ValidationLog.Error("CommandEncoder.TraceRays: the ray generation table is null");
			return;
		}
		if (!RayTracingAvailable("TraceRays"))
			return;
		mInnerRayTracing.TraceRays(raygenSBT, raygenOffset, raygenStride, missSBT, missOffset,
			missStride, hitSBT, hitOffset, hitStride, width, height, depth);
	}

	// ---- guards ----

	private bool RenderPassEnded => (mRenderPass == null) || mRenderPass.[Friend]mEnded;
	private bool ComputePassEnded => (mComputePass == null) || mComputePass.[Friend]mEnded;

	private bool Finished(StringView operation)
	{
		if (!mFinished)
			return false;
		ValidationLog.Error(scope $"CommandEncoder.{operation}: the encoder is already finished");
		return true;
	}

	private bool RayTracingAvailable(StringView operation)
	{
		if (mInnerRayTracing != null)
			return true;
		ValidationLog.Error(scope $"CommandEncoder.{operation}: the inner encoder does not support ray tracing");
		return false;
	}
}
