namespace Sedulous.RHI.Validation;

using System;
using Sedulous.RHI;

/// Encoder state machine states.
enum EncoderState
{
	/// Initial state, ready to record.
	Recording,
	/// Inside a render pass (BeginRenderPass called, End not yet called).
	InRenderPass,
	/// Inside a compute pass (BeginComputePass called, End not yet called).
	InComputePass,
	/// Finish() has been called. Encoder must not be used.
	Finished,
}

/// Validation wrapper for ICommandEncoder.
/// Enforces the state machine: Recording -> (RenderPass | ComputePass) -> Recording -> Finished.
class ValidatedCommandEncoder : ICommandEncoder, IRayTracingEncoderExt
{
	private ICommandEncoder mInner;
	private EncoderState mState = .Recording;
	private ValidatedRenderPassEncoder mRenderPassEncoder;
	private ValidatedComputePassEncoder mComputePassEncoder;
	private int mDebugLabelDepth;

	public this(ICommandEncoder inner)
	{
		mInner = inner;
		mRenderPassEncoder = new ValidatedRenderPassEncoder(this);
		mComputePassEncoder = new ValidatedComputePassEncoder(this);
	}

	public ~this()
	{
		delete mRenderPassEncoder;
		delete mComputePassEncoder;
		//delete mInner;
	}

	private bool CheckState(StringView method, EncoderState expected)
	{
		if (mState == .Finished)
		{
			let msg = scope String();
			msg.AppendF("{}: encoder has been finished, must not be used", method);
			ValidationLogger.Error(msg);
			return false;
		}

		if (mState != expected)
		{
			let msg = scope String();
			msg.AppendF("{}: encoder in wrong state (expected {}, got {})", method, expected, mState);
			ValidationLogger.Error(msg);
			return false;
		}
		return true;
	}

	// ===== Render Pass =====

	public IRenderPassEncoder BeginRenderPass(RenderPassDesc desc)
	{
		if (!CheckState("BeginRenderPass", .Recording)) return mRenderPassEncoder;

		if (desc.ColorAttachments.IsEmpty && desc.DepthStencilAttachment?.View == null)
		{
			ValidationLogger.Warn("BeginRenderPass: no color attachments and no depth/stencil attachment");
		}

		for (int i = 0; i < desc.ColorAttachments.Count; i++)
		{
			if (desc.ColorAttachments[i].View == null)
			{
				let msg = scope String();
				msg.AppendF("BeginRenderPass: color attachment {} view is null", i);
				ValidationLogger.Error(msg);
			}
		}

		mState = .InRenderPass;
		let inner = mInner.BeginRenderPass(desc);
		mRenderPassEncoder.Begin(inner);
		return mRenderPassEncoder;
	}

	// ===== Compute Pass =====

	public IComputePassEncoder BeginComputePass(StringView label = default)
	{
		if (!CheckState("BeginComputePass", .Recording)) return mComputePassEncoder;

		mState = .InComputePass;
		let inner = mInner.BeginComputePass(label);
		mComputePassEncoder.Begin(inner);
		return mComputePassEncoder;
	}

	/// Called by sub-pass encoders when End() is called.
	public void OnPassEnded()
	{
		mState = .Recording;
	}

	// ===== Barriers =====

	public void Barrier(BarrierGroup barriers)
	{
		if (!CheckState("Barrier", .Recording)) return;
		mInner.Barrier(barriers);
	}

	// ===== Copy Operations =====

	public void CopyBufferToBuffer(IBuffer src, uint64 srcOffset, IBuffer dst, uint64 dstOffset, uint64 size)
	{
		if (!CheckState("CopyBufferToBuffer", .Recording)) return;

		if (src == null) { ValidationLogger.Error("CopyBufferToBuffer: src is null"); return; }
		if (dst == null) { ValidationLogger.Error("CopyBufferToBuffer: dst is null"); return; }
		if (size == 0) { ValidationLogger.Warn("CopyBufferToBuffer: size is 0"); }
		if (src === dst && srcOffset < dstOffset + size && dstOffset < srcOffset + size)
		{
			ValidationLogger.Error("CopyBufferToBuffer: overlapping copy within same buffer");
		}

		mInner.CopyBufferToBuffer(src, srcOffset, dst, dstOffset, size);
	}

	public void CopyBufferToTexture(IBuffer src, ITexture dst, BufferTextureCopyRegion region)
	{
		if (!CheckState("CopyBufferToTexture", .Recording)) return;
		if (src == null) { ValidationLogger.Error("CopyBufferToTexture: src is null"); return; }
		if (dst == null) { ValidationLogger.Error("CopyBufferToTexture: dst is null"); return; }
		mInner.CopyBufferToTexture(src, dst, region);
	}

	public void CopyTextureToBuffer(ITexture src, IBuffer dst, BufferTextureCopyRegion region)
	{
		if (!CheckState("CopyTextureToBuffer", .Recording)) return;
		if (src == null) { ValidationLogger.Error("CopyTextureToBuffer: src is null"); return; }
		if (dst == null) { ValidationLogger.Error("CopyTextureToBuffer: dst is null"); return; }
		mInner.CopyTextureToBuffer(src, dst, region);
	}

	public void CopyTextureToTexture(ITexture src, ITexture dst, TextureCopyRegion region)
	{
		if (!CheckState("CopyTextureToTexture", .Recording)) return;
		if (src == null) { ValidationLogger.Error("CopyTextureToTexture: src is null"); return; }
		if (dst == null) { ValidationLogger.Error("CopyTextureToTexture: dst is null"); return; }
		mInner.CopyTextureToTexture(src, dst, region);
	}

	// ===== Blit & Mipmap Generation =====

	public void Blit(ITexture src, ITexture dst)
	{
		if (!CheckState("Blit", .Recording)) return;
		if (src == null) { ValidationLogger.Error("Blit: src is null"); return; }
		if (dst == null) { ValidationLogger.Error("Blit: dst is null"); return; }
		mInner.Blit(src, dst);
	}

	public void GenerateMipmaps(ITexture texture)
	{
		if (!CheckState("GenerateMipmaps", .Recording)) return;
		if (texture == null) { ValidationLogger.Error("GenerateMipmaps: texture is null"); return; }
		mInner.GenerateMipmaps(texture);
	}

	// ===== MSAA Resolve =====

	public void ResolveTexture(ITexture src, ITexture dst)
	{
		if (!CheckState("ResolveTexture", .Recording)) return;
		if (src == null) { ValidationLogger.Error("ResolveTexture: src is null"); return; }
		if (dst == null) { ValidationLogger.Error("ResolveTexture: dst is null"); return; }
		mInner.ResolveTexture(src, dst);
	}

	// ===== Queries =====

	public void ResetQuerySet(IQuerySet querySet, uint32 first, uint32 count)
	{
		if (!CheckState("ResetQuerySet", .Recording)) return;
		if (querySet == null) { ValidationLogger.Error("ResetQuerySet: querySet is null"); return; }
		mInner.ResetQuerySet(querySet, first, count);
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		if (!CheckState("WriteTimestamp", .Recording)) return;
		if (querySet == null) { ValidationLogger.Error("WriteTimestamp: querySet is null"); return; }
		mInner.WriteTimestamp(querySet, index);
	}

	public void ResolveQuerySet(IQuerySet querySet, uint32 first, uint32 count,
		IBuffer dst, uint64 dstOffset)
	{
		if (!CheckState("ResolveQuerySet", .Recording)) return;
		if (querySet == null) { ValidationLogger.Error("ResolveQuerySet: querySet is null"); return; }
		if (dst == null) { ValidationLogger.Error("ResolveQuerySet: dst buffer is null"); return; }
		mInner.ResolveQuerySet(querySet, first, count, dst, dstOffset);
	}

	// ===== Debug Markers =====

	public void BeginDebugLabel(StringView label, float r = 0, float g = 0, float b = 0, float a = 1)
	{
		if (mState == .Finished) { ValidationLogger.Error("BeginDebugLabel: encoder finished"); return; }
		mDebugLabelDepth++;
		mInner.BeginDebugLabel(label, r, g, b, a);
	}

	public void EndDebugLabel()
	{
		if (mState == .Finished) { ValidationLogger.Error("EndDebugLabel: encoder finished"); return; }
		if (mDebugLabelDepth <= 0)
		{
			ValidationLogger.Error("EndDebugLabel: no matching BeginDebugLabel");
			return;
		}
		mDebugLabelDepth--;
		mInner.EndDebugLabel();
	}

	public void InsertDebugLabel(StringView label, float r = 0, float g = 0, float b = 0, float a = 1)
	{
		if (mState == .Finished) { ValidationLogger.Error("InsertDebugLabel: encoder finished"); return; }
		mInner.InsertDebugLabel(label, r, g, b, a);
	}

	// ===== IRayTracingEncoderExt =====

	public void BuildBottomLevelAccelStruct(
		IAccelStruct dst, IBuffer scratchBuffer, uint64 scratchOffset,
		Span<AccelStructGeometryTriangles> triangleGeometries,
		Span<AccelStructGeometryAABBs> aabbGeometries)
	{
		if (!CheckState("BuildBottomLevelAccelStruct", .Recording)) return;
		if (dst == null) { ValidationLogger.Error("BuildBottomLevelAccelStruct: dst is null"); return; }
		if (scratchBuffer == null) { ValidationLogger.Error("BuildBottomLevelAccelStruct: scratchBuffer is null"); return; }
		if (let rt = mInner as IRayTracingEncoderExt)
			rt.BuildBottomLevelAccelStruct(dst, scratchBuffer, scratchOffset, triangleGeometries, aabbGeometries);
		else
			ValidationLogger.Error("BuildBottomLevelAccelStruct: inner encoder does not support ray tracing");
	}

	public void BuildTopLevelAccelStruct(
		IAccelStruct dst, IBuffer scratchBuffer, uint64 scratchOffset,
		IBuffer instanceBuffer, uint64 instanceOffset, uint32 instanceCount)
	{
		if (!CheckState("BuildTopLevelAccelStruct", .Recording)) return;
		if (dst == null) { ValidationLogger.Error("BuildTopLevelAccelStruct: dst is null"); return; }
		if (instanceBuffer == null) { ValidationLogger.Error("BuildTopLevelAccelStruct: instanceBuffer is null"); return; }
		if (let rt = mInner as IRayTracingEncoderExt)
			rt.BuildTopLevelAccelStruct(dst, scratchBuffer, scratchOffset, instanceBuffer, instanceOffset, instanceCount);
		else
			ValidationLogger.Error("BuildTopLevelAccelStruct: inner encoder does not support ray tracing");
	}

	public void SetRayTracingPipeline(IRayTracingPipeline pipeline)
	{
		if (!CheckState("SetRayTracingPipeline", .Recording)) return;
		if (pipeline == null) { ValidationLogger.Error("SetRayTracingPipeline: pipeline is null"); return; }
		if (let rt = mInner as IRayTracingEncoderExt)
			rt.SetRayTracingPipeline(pipeline);
		else
			ValidationLogger.Error("SetRayTracingPipeline: inner encoder does not support ray tracing");
	}

	void IRayTracingEncoderExt.SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets)
	{
		if (!CheckState("SetBindGroup(RT)", .Recording)) return;
		if (bindGroup == null) { ValidationLogger.Error("SetBindGroup(RT): bindGroup is null"); return; }
		if (let rt = mInner as IRayTracingEncoderExt)
			rt.SetBindGroup(index, bindGroup, dynamicOffsets);
		else
			ValidationLogger.Error("SetBindGroup(RT): inner encoder does not support ray tracing");
	}

	void IRayTracingEncoderExt.SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (!CheckState("SetPushConstants(RT)", .Recording)) return;
		if (data == null && size > 0) { ValidationLogger.Error("SetPushConstants(RT): data is null"); return; }
		if (let rt = mInner as IRayTracingEncoderExt)
			rt.SetPushConstants(stages, offset, size, data);
		else
			ValidationLogger.Error("SetPushConstants(RT): inner encoder does not support ray tracing");
	}

	public void TraceRays(
		IBuffer raygenSBT, uint64 raygenOffset, uint64 raygenStride,
		IBuffer missSBT, uint64 missOffset, uint64 missStride,
		IBuffer hitSBT, uint64 hitOffset, uint64 hitStride,
		uint32 width, uint32 height, uint32 depth = 1)
	{
		if (!CheckState("TraceRays", .Recording)) return;
		if (raygenSBT == null) { ValidationLogger.Error("TraceRays: raygenSBT is null"); return; }
		if (width == 0 || height == 0) { ValidationLogger.Warn("TraceRays: zero-sized dispatch"); }
		if (let rt = mInner as IRayTracingEncoderExt)
			rt.TraceRays(raygenSBT, raygenOffset, raygenStride, missSBT, missOffset, missStride, hitSBT, hitOffset, hitStride, width, height, depth);
		else
			ValidationLogger.Error("TraceRays: inner encoder does not support ray tracing");
	}

	// ===== Finish =====

	public ICommandBuffer Finish()
	{
		if (mState == .Finished)
		{
			ValidationLogger.Error("Finish: encoder already finished");
			return null;
		}

		if (mState == .InRenderPass)
		{
			ValidationLogger.Error("Finish: render pass still open (call End() on the render pass encoder first)");
		}
		else if (mState == .InComputePass)
		{
			ValidationLogger.Error("Finish: compute pass still open (call End() on the compute pass encoder first)");
		}

		if (mDebugLabelDepth > 0)
		{
			let msg = scope String();
			msg.AppendF("Finish: {} debug label(s) not closed", mDebugLabelDepth);
			ValidationLogger.Warn(msg);
		}

		mState = .Finished;
		return mInner.Finish();
	}

	public EncoderState State => mState;
	public ICommandEncoder Inner => mInner;
}
