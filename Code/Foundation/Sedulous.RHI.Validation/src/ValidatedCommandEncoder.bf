using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Validation;

/// Watches a command encoder: its recording state, that passes are closed before it
/// finishes, that debug labels balance, and what the copy and query calls are handed.
class ValidatedCommandEncoder : ICommandEncoder, IRayTracingEncoderExt
{
	private ICommandEncoder mInner;
	private IRayTracingEncoderExt mInnerRayTracing;

	private EncoderState mState = .Recording;
	private ValidatedRenderPassEncoder mRenderPass ~ delete _;
	private ValidatedComputePassEncoder mComputePass ~ delete _;
	private ValidatedRenderBundleEncoder mBundleEncoder ~ delete _;

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
		if (NotRecording("BeginRenderPass"))
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

		mState = .InRenderPass;
		delete mRenderPass;
		mRenderPass = new ValidatedRenderPassEncoder(inner, this);
		return mRenderPass;
	}

	public IComputePassEncoder BeginComputePass(StringView label)
	{
		if (NotRecording("BeginComputePass"))
			return null;

		let inner = mInner.BeginComputePass(label);
		if (inner == null)
			return null;

		mState = .InComputePass;
		delete mComputePass;
		mComputePass = new ValidatedComputePassEncoder(inner, this);
		return mComputePass;
	}

	public IRenderBundleEncoder CreateRenderBundleEncoder(RenderBundleDesc desc)
	{
		if (NotRecording("CreateRenderBundleEncoder"))
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
		if (NotRecording("Barrier"))
			return;
		mInner.Barrier(group);
	}

	public void CopyBufferToBuffer(IBuffer src, uint64 srcOffset, IBuffer dst, uint64 dstOffset,
		uint64 size)
	{
		if (NotRecording("CopyBufferToBuffer"))
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
		if (NotRecording("CopyBufferToTexture"))
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
		if (NotRecording("CopyTextureToBuffer"))
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
		if (NotRecording("CopyTextureToTexture"))
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
		if (NotRecording("Blit"))
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
		if (NotRecording("GenerateMipmaps"))
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
		if (NotRecording("ResolveTexture"))
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
		if (NotRecording("ResetQuerySet"))
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
		if (NotRecording("WriteTimestamp"))
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
		if (NotRecording("ResolveQuerySet"))
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
		if (mState == .Finished)
		{
			ValidationLog.Error("CommandEncoder.Finish: already finished");
			return null;
		}
		if (mState == .InRenderPass)
		{
			ValidationLog.Error("CommandEncoder.Finish: a render pass is still open");
			return null;
		}
		if (mState == .InComputePass)
		{
			ValidationLog.Error("CommandEncoder.Finish: a compute pass is still open");
			return null;
		}
		if (mOpenDebugLabels > 0)
			ValidationLog.Warn(scope $"CommandEncoder.Finish: {mOpenDebugLabels} debug label(s) were not closed");

		mState = .Finished;
		return mInner.Finish();
	}

	// ---- IRayTracingEncoderExt ----

	public void BuildBottomLevelAccelStruct(IAccelStruct dst, IBuffer scratchBuffer,
		uint64 scratchOffset, Span<AccelStructGeometryTriangles> triangles,
		Span<AccelStructGeometryAABBs> aabbs)
	{
		if (NotRecording("BuildBottomLevelAccelStruct"))
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
		if (NotRecording("BuildTopLevelAccelStruct"))
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
		if (NotRecording("SetRayTracingPipeline"))
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
		if (NotRecording("TraceRays"))
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

	private bool Finished(StringView operation)
	{
		if (mState != .Finished)
			return false;
		ValidationLog.Error(scope $"CommandEncoder.{operation}: the encoder is already finished");
		return true;
	}

	/// True when the operation must NOT go ahead.
	///
	/// Most of the encoder's surface is legal only while plainly recording: a copy, a
	/// barrier or a second pass begun while a pass is open is invalid, and naming which
	/// state it is actually in is what makes the mistake findable.
	private bool NotRecording(StringView operation)
	{
		if (mState == .Finished)
		{
			ValidationLog.Error(scope $"CommandEncoder.{operation}: the encoder is already finished");
			return true;
		}
		if (mState != .Recording)
		{
			let openPass = (mState == .InRenderPass) ? "a render pass is open"
				: "a compute pass is open";
			ValidationLog.Error(scope $"CommandEncoder.{operation}: expected to be recording, but {openPass}");
			return true;
		}
		return false;
	}

	/// Called by a pass encoder when it ends, which returns the encoder to recording.
	public void OnPassEnded()
	{
		if (mState != .Finished)
			mState = .Recording;
	}

	private bool RayTracingAvailable(StringView operation)
	{
		if (mInnerRayTracing != null)
			return true;
		ValidationLog.Error(scope $"CommandEncoder.{operation}: the inner encoder does not support ray tracing");
		return false;
	}
}
