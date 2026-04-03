namespace Sedulous.RHI.Validation;

using System;
using Sedulous.RHI;

/// Validation wrapper for IRenderPassEncoder.
/// Checks: pipeline bound before draw, viewport/scissor set, etc.
class ValidatedRenderPassEncoder : IRenderPassEncoder, IMeshShaderPassExt
{
	private ValidatedCommandEncoder mParent;
	private IRenderPassEncoder mInner;
	private bool mPipelineBound;
	private bool mPushConstantsSet;
	private bool mViewportSet;
	private bool mScissorSet;
	private bool mEnded;

	public this(ValidatedCommandEncoder parent)
	{
		mParent = parent;
	}

	public void Begin(IRenderPassEncoder inner)
	{
		mInner = inner;
		mPipelineBound = false;
		mPushConstantsSet = false;
		mViewportSet = false;
		mScissorSet = false;
		mEnded = false;
	}

	private bool CheckActive(StringView method)
	{
		if (mEnded)
		{
			let msg = scope String();
			msg.AppendF("{}: render pass has ended", method);
			ValidationLogger.Error(msg);
			return false;
		}
		return true;
	}

	private bool CheckDrawReady(StringView method)
	{
		if (!CheckActive(method)) return false;

		bool ok = true;
		if (!mPipelineBound)
		{
			let msg = scope String();
			msg.AppendF("{}: no render pipeline bound (call SetPipeline first)", method);
			ValidationLogger.Error(msg);
			ok = false;
		}
		if (!mViewportSet)
		{
			let msg = scope String();
			msg.AppendF("{}: viewport not set (call SetViewport first)", method);
			ValidationLogger.Error(msg);
			ok = false;
		}
		if (!mScissorSet)
		{
			let msg = scope String();
			msg.AppendF("{}: scissor not set (call SetScissor first)", method);
			ValidationLogger.Error(msg);
			ok = false;
		}
		return ok;
	}

	// ===== Pipeline & Binding =====

	public void SetPipeline(IRenderPipeline pipeline)
	{
		if (!CheckActive("SetPipeline")) return;
		if (pipeline == null)
		{
			ValidationLogger.Error("SetPipeline: pipeline is null");
			return;
		}
		mPipelineBound = true;
		mInner.SetPipeline(pipeline);
	}

	public void SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets = default)
	{
		if (!CheckActive("SetBindGroup")) return;
		if (bindGroup == null)
		{
			ValidationLogger.Error("SetBindGroup: bindGroup is null");
			return;
		}
		if (!mPipelineBound)
		{
			ValidationLogger.Warn("SetBindGroup: no pipeline bound yet");
		}
		mInner.SetBindGroup(index, bindGroup, dynamicOffsets);
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (!CheckActive("SetPushConstants")) return;
		if (!mPipelineBound)
		{
			ValidationLogger.Error("SetPushConstants: no pipeline bound (call SetPipeline or SetMeshPipeline first)");
			return;
		}
		if (data == null && size > 0)
		{
			ValidationLogger.Error("SetPushConstants: data is null but size > 0");
			return;
		}
		if (size == 0)
		{
			ValidationLogger.Warn("SetPushConstants: size is 0");
			return;
		}
		if (offset % 4 != 0)
		{
			ValidationLogger.Error("SetPushConstants: offset must be 4-byte aligned");
		}
		if (size % 4 != 0)
		{
			ValidationLogger.Error("SetPushConstants: size must be 4-byte aligned");
		}
		mPushConstantsSet = true;
		mInner.SetPushConstants(stages, offset, size, data);
	}

	// ===== Vertex & Index Buffers =====

	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset = 0)
	{
		if (!CheckActive("SetVertexBuffer")) return;
		if (buffer == null)
		{
			ValidationLogger.Error("SetVertexBuffer: buffer is null");
			return;
		}
		if (!mPipelineBound)
		{
			ValidationLogger.Error("SetVertexBuffer: no pipeline bound — call SetPipeline before SetVertexBuffer (DX12 needs pipeline to determine vertex stride)");
		}
		mInner.SetVertexBuffer(slot, buffer, offset);
	}

	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset = 0)
	{
		if (!CheckActive("SetIndexBuffer")) return;
		if (buffer == null)
		{
			ValidationLogger.Error("SetIndexBuffer: buffer is null");
			return;
		}
		mInner.SetIndexBuffer(buffer, format, offset);
	}

	// ===== Dynamic State =====

	public void SetViewport(float x, float y, float w, float h, float minDepth, float maxDepth)
	{
		if (!CheckActive("SetViewport")) return;
		if (w <= 0 || h <= 0)
		{
			ValidationLogger.Warn("SetViewport: width or height is <= 0");
		}
		mViewportSet = true;
		mInner.SetViewport(x, y, w, h, minDepth, maxDepth);
	}

	public void SetScissor(int32 x, int32 y, uint32 w, uint32 h)
	{
		if (!CheckActive("SetScissor")) return;
		mScissorSet = true;
		mInner.SetScissor(x, y, w, h);
	}

	public void SetBlendConstant(float r, float g, float b, float a)
	{
		if (!CheckActive("SetBlendConstant")) return;
		mInner.SetBlendConstant(r, g, b, a);
	}

	public void SetStencilReference(uint32 reference)
	{
		if (!CheckActive("SetStencilReference")) return;
		mInner.SetStencilReference(reference);
	}

	// ===== Draw Commands =====

	public void Draw(uint32 vertexCount, uint32 instanceCount = 1, uint32 firstVertex = 0, uint32 firstInstance = 0)
	{
		if (!CheckDrawReady("Draw")) return;
		if (vertexCount == 0)
		{
			ValidationLogger.Warn("Draw: vertexCount is 0");
		}
		mInner.Draw(vertexCount, instanceCount, firstVertex, firstInstance);
	}

	public void DrawIndexed(uint32 indexCount, uint32 instanceCount = 1, uint32 firstIndex = 0, int32 baseVertex = 0, uint32 firstInstance = 0)
	{
		if (!CheckDrawReady("DrawIndexed")) return;
		if (indexCount == 0)
		{
			ValidationLogger.Warn("DrawIndexed: indexCount is 0");
		}
		mInner.DrawIndexed(indexCount, instanceCount, firstIndex, baseVertex, firstInstance);
	}

	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1, uint32 stride = 0)
	{
		if (!CheckDrawReady("DrawIndirect")) return;
		if (buffer == null) { ValidationLogger.Error("DrawIndirect: buffer is null"); return; }
		mInner.DrawIndirect(buffer, offset, drawCount, stride);
	}

	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1, uint32 stride = 0)
	{
		if (!CheckDrawReady("DrawIndexedIndirect")) return;
		if (buffer == null) { ValidationLogger.Error("DrawIndexedIndirect: buffer is null"); return; }
		mInner.DrawIndexedIndirect(buffer, offset, drawCount, stride);
	}

	// ===== Queries =====

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		if (!CheckActive("WriteTimestamp")) return;
		if (querySet == null) { ValidationLogger.Error("WriteTimestamp: querySet is null"); return; }
		mInner.WriteTimestamp(querySet, index);
	}

	public void BeginOcclusionQuery(IQuerySet querySet, uint32 index)
	{
		if (!CheckActive("BeginOcclusionQuery")) return;
		if (querySet == null) { ValidationLogger.Error("BeginOcclusionQuery: querySet is null"); return; }
		mInner.BeginOcclusionQuery(querySet, index);
	}

	public void EndOcclusionQuery(IQuerySet querySet, uint32 index)
	{
		if (!CheckActive("EndOcclusionQuery")) return;
		if (querySet == null) { ValidationLogger.Error("EndOcclusionQuery: querySet is null"); return; }
		mInner.EndOcclusionQuery(querySet, index);
	}

	// ===== IMeshShaderPassExt =====

	public void SetMeshPipeline(IMeshPipeline pipeline)
	{
		if (!CheckActive("SetMeshPipeline")) return;
		if (pipeline == null) { ValidationLogger.Error("SetMeshPipeline: pipeline is null"); return; }
		mPipelineBound = true;
		if (let mesh = mInner as IMeshShaderPassExt)
			mesh.SetMeshPipeline(pipeline);
		else
			ValidationLogger.Error("SetMeshPipeline: inner encoder does not support mesh shaders");
	}

	public void DrawMeshTasks(uint32 groupCountX, uint32 groupCountY = 1, uint32 groupCountZ = 1)
	{
		if (!CheckActive("DrawMeshTasks")) return;
		if (!mPipelineBound) { ValidationLogger.Error("DrawMeshTasks: no pipeline bound"); return; }
		if (let mesh = mInner as IMeshShaderPassExt)
			mesh.DrawMeshTasks(groupCountX, groupCountY, groupCountZ);
		else
			ValidationLogger.Error("DrawMeshTasks: inner encoder does not support mesh shaders");
	}

	public void DrawMeshTasksIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1, uint32 stride = 0)
	{
		if (!CheckActive("DrawMeshTasksIndirect")) return;
		if (!mPipelineBound) { ValidationLogger.Error("DrawMeshTasksIndirect: no pipeline bound"); return; }
		if (buffer == null) { ValidationLogger.Error("DrawMeshTasksIndirect: buffer is null"); return; }
		if (let mesh = mInner as IMeshShaderPassExt)
			mesh.DrawMeshTasksIndirect(buffer, offset, drawCount, stride);
		else
			ValidationLogger.Error("DrawMeshTasksIndirect: inner encoder does not support mesh shaders");
	}

	public void DrawMeshTasksIndirectCount(IBuffer buffer, uint64 offset,
		IBuffer countBuffer, uint64 countOffset, uint32 maxDrawCount, uint32 stride)
	{
		if (!CheckActive("DrawMeshTasksIndirectCount")) return;
		if (!mPipelineBound) { ValidationLogger.Error("DrawMeshTasksIndirectCount: no pipeline bound"); return; }
		if (buffer == null) { ValidationLogger.Error("DrawMeshTasksIndirectCount: buffer is null"); return; }
		if (countBuffer == null) { ValidationLogger.Error("DrawMeshTasksIndirectCount: countBuffer is null"); return; }
		if (let mesh = mInner as IMeshShaderPassExt)
			mesh.DrawMeshTasksIndirectCount(buffer, offset, countBuffer, countOffset, maxDrawCount, stride);
		else
			ValidationLogger.Error("DrawMeshTasksIndirectCount: inner encoder does not support mesh shaders");
	}

	// ===== End =====

	public void End()
	{
		if (mEnded)
		{
			ValidationLogger.Error("RenderPass.End: already ended");
			return;
		}
		mEnded = true;
		mInner.End();
		mParent.OnPassEnded();
	}
}
