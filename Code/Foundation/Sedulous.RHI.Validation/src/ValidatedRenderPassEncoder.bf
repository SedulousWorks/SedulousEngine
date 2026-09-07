using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Validation;

/// Watches a render pass: that it is still open, that something is bound before a draw,
/// and that the pass level state a draw depends on was actually set.
class ValidatedRenderPassEncoder : IRenderPassEncoder, IMeshShaderPassExt
{
	private IRenderPassEncoder mInner;
	private IMeshShaderPassExt mInnerMeshShaders;
	/// The encoder that opened this pass, so ending it returns that encoder to recording.
	private ValidatedCommandEncoder mOwner;

	private bool mEnded = false;
	private bool mPipelineBound = false;
	private bool mMeshPipelineBound = false;
	private bool mViewportSet = false;
	private bool mScissorSet = false;

	public this(IRenderPassEncoder inner, ValidatedCommandEncoder owner = null)
	{
		mInner = inner;
		mOwner = owner;
		// Asked ONCE at construction: the answer cannot change, and a cast per call would
		// pay for the question on every draw.
		mInnerMeshShaders = inner as IMeshShaderPassExt;
	}

	public IRenderPassEncoder Inner => mInner;

	public void SetPipeline(IRenderPipeline pipeline)
	{
		if (Ended("SetPipeline"))
			return;
		if (pipeline == null)
		{
			ValidationLog.Error("RenderPass.SetPipeline: pipeline is null");
			return;
		}
		mPipelineBound = true;
		mInner.SetPipeline(pipeline);
	}

	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets)
	{
		if (Ended("SetBindGroup"))
			return;
		if (group == null)
		{
			ValidationLog.Error("RenderPass.SetBindGroup: group is null");
			return;
		}
		mInner.SetBindGroup(index, group, dynamicOffsets);
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (Ended("SetPushConstants"))
			return;
		// Bound first, because the range is part of the LAYOUT: pushing before a pipeline
		// is bound writes into whatever layout was last in effect.
		if (!mPipelineBound && !mMeshPipelineBound)
			ValidationLog.Warn("RenderPass.SetPushConstants: no pipeline is bound");
		if ((data == null) && (size > 0))
		{
			ValidationLog.Error("RenderPass.SetPushConstants: data is null but size is not zero");
			return;
		}
		if (size == 0)
			ValidationLog.Warn("RenderPass.SetPushConstants: size is zero");
		// Both backends address push constants in 32 bit words.
		if ((offset % 4) != 0)
		{
			ValidationLog.Error("RenderPass.SetPushConstants: offset must be 4 byte aligned");
			return;
		}
		if ((size % 4) != 0)
		{
			ValidationLog.Error("RenderPass.SetPushConstants: size must be 4 byte aligned");
			return;
		}
		mInner.SetPushConstants(stages, offset, size, data);
	}

	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset)
	{
		if (Ended("SetVertexBuffer"))
			return;
		if (buffer == null)
		{
			ValidationLog.Error("RenderPass.SetVertexBuffer: buffer is null");
			return;
		}
		mInner.SetVertexBuffer(slot, buffer, offset);
	}

	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset)
	{
		if (Ended("SetIndexBuffer"))
			return;
		if (buffer == null)
		{
			ValidationLog.Error("RenderPass.SetIndexBuffer: buffer is null");
			return;
		}
		mInner.SetIndexBuffer(buffer, format, offset);
	}

	public void SetViewport(float x, float y, float width, float height, float minDepth,
		float maxDepth)
	{
		if (Ended("SetViewport"))
			return;
		mViewportSet = true;
		mInner.SetViewport(x, y, width, height, minDepth, maxDepth);
	}

	public void SetScissor(int32 x, int32 y, uint32 width, uint32 height)
	{
		if (Ended("SetScissor"))
			return;
		mScissorSet = true;
		mInner.SetScissor(x, y, width, height);
	}

	public void SetBlendConstant(float r, float g, float b, float a)
	{
		if (Ended("SetBlendConstant"))
			return;
		mInner.SetBlendConstant(r, g, b, a);
	}

	public void SetStencilReference(uint32 reference)
	{
		if (Ended("SetStencilReference"))
			return;
		mInner.SetStencilReference(reference);
	}

	public void Draw(uint32 vertexCount, uint32 instanceCount, uint32 firstVertex,
		uint32 firstInstance)
	{
		if (!ReadyToDraw("Draw"))
			return;
		if (vertexCount == 0)
			ValidationLog.Warn("RenderPass.Draw: vertexCount is zero");
		mInner.Draw(vertexCount, instanceCount, firstVertex, firstInstance);
	}

	public void DrawIndexed(uint32 indexCount, uint32 instanceCount, uint32 firstIndex,
		int32 baseVertex, uint32 firstInstance)
	{
		if (!ReadyToDraw("DrawIndexed"))
			return;
		if (indexCount == 0)
			ValidationLog.Warn("RenderPass.DrawIndexed: indexCount is zero");
		mInner.DrawIndexed(indexCount, instanceCount, firstIndex, baseVertex, firstInstance);
	}

	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride)
	{
		if (!ReadyToDraw("DrawIndirect"))
			return;
		if (buffer == null)
		{
			ValidationLog.Error("RenderPass.DrawIndirect: buffer is null");
			return;
		}
		mInner.DrawIndirect(buffer, offset, drawCount, stride);
	}

	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount,
		uint32 stride)
	{
		if (!ReadyToDraw("DrawIndexedIndirect"))
			return;
		if (buffer == null)
		{
			ValidationLog.Error("RenderPass.DrawIndexedIndirect: buffer is null");
			return;
		}
		mInner.DrawIndexedIndirect(buffer, offset, drawCount, stride);
	}

	/// A bundle inherits the pass's viewport and scissor rather than carrying its own, so
	/// executing one before they are set draws through whatever the last pass left.
	public void ExecuteBundles(Span<IRenderBundle> bundles)
	{
		if (Ended("ExecuteBundles"))
			return;
		if (!mViewportSet)
			ValidationLog.Warn("RenderPass.ExecuteBundles: no viewport set, bundles inherit the pass's");
		if (!mScissorSet)
			ValidationLog.Warn("RenderPass.ExecuteBundles: no scissor set, bundles inherit the pass's");
		for (int i < bundles.Length)
		{
			if (bundles[i] == null)
			{
				ValidationLog.Error(scope $"RenderPass.ExecuteBundles: bundle {i} is null");
				return;
			}
		}
		mInner.ExecuteBundles(bundles);
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		if (Ended("WriteTimestamp"))
			return;
		if (querySet == null)
		{
			ValidationLog.Error("RenderPass.WriteTimestamp: querySet is null");
			return;
		}
		mInner.WriteTimestamp(querySet, index);
	}

	public void BeginOcclusionQuery(IQuerySet querySet, uint32 index)
	{
		if (Ended("BeginOcclusionQuery"))
			return;
		if (querySet == null)
		{
			ValidationLog.Error("RenderPass.BeginOcclusionQuery: querySet is null");
			return;
		}
		mInner.BeginOcclusionQuery(querySet, index);
	}

	public void EndOcclusionQuery(IQuerySet querySet, uint32 index)
	{
		if (Ended("EndOcclusionQuery"))
			return;
		if (querySet == null)
		{
			ValidationLog.Error("RenderPass.EndOcclusionQuery: querySet is null");
			return;
		}
		mInner.EndOcclusionQuery(querySet, index);
	}

	public void End()
	{
		if (mEnded)
		{
			ValidationLog.Error("RenderPass.End: the pass has already ended");
			return;
		}
		mEnded = true;
		mInner.End();
		if (mOwner != null)
			mOwner.OnPassEnded();
	}

	// ---- IMeshShaderPassExt ----

	public void SetMeshPipeline(IMeshPipeline pipeline)
	{
		if (Ended("SetMeshPipeline"))
			return;
		if (pipeline == null)
		{
			ValidationLog.Error("RenderPass.SetMeshPipeline: pipeline is null");
			return;
		}
		if (mInnerMeshShaders == null)
		{
			ValidationLog.Error("RenderPass.SetMeshPipeline: the inner encoder does not support mesh shaders");
			return;
		}
		mMeshPipelineBound = true;
		mInnerMeshShaders.SetMeshPipeline(pipeline);
	}

	public void DrawMeshTasks(uint32 groupCountX, uint32 groupCountY, uint32 groupCountZ)
	{
		if (!ReadyToDrawMesh("DrawMeshTasks"))
			return;
		mInnerMeshShaders.DrawMeshTasks(groupCountX, groupCountY, groupCountZ);
	}

	public void DrawMeshTasksIndirect(IBuffer buffer, uint64 offset, uint32 drawCount,
		uint32 stride)
	{
		if (!ReadyToDrawMesh("DrawMeshTasksIndirect"))
			return;
		if (buffer == null)
		{
			ValidationLog.Error("RenderPass.DrawMeshTasksIndirect: buffer is null");
			return;
		}
		mInnerMeshShaders.DrawMeshTasksIndirect(buffer, offset, drawCount, stride);
	}

	public void DrawMeshTasksIndirectCount(IBuffer buffer, uint64 offset, IBuffer countBuffer,
		uint64 countOffset, uint32 maxDrawCount, uint32 stride)
	{
		if (!ReadyToDrawMesh("DrawMeshTasksIndirectCount"))
			return;
		if ((buffer == null) || (countBuffer == null))
		{
			ValidationLog.Error("RenderPass.DrawMeshTasksIndirectCount: buffer is null");
			return;
		}
		mInnerMeshShaders.DrawMeshTasksIndirectCount(buffer, offset, countBuffer, countOffset,
			maxDrawCount, stride);
	}

	// ---- guards ----

	private bool Ended(StringView operation)
	{
		if (!mEnded)
			return false;
		ValidationLog.Error(scope $"RenderPass.{operation}: the render pass has ended");
		return true;
	}

	/// Everything a draw needs: an open pass, a pipeline, and the pass level state the
	/// rasterizer reads. A viewport that was never set is whatever the last pass left, so
	/// the draw lands somewhere unrelated rather than not at all.
	private bool ReadyToDraw(StringView operation)
	{
		if (Ended(operation))
			return false;
		if (!mPipelineBound)
		{
			ValidationLog.Error(scope $"RenderPass.{operation}: no pipeline is bound");
			return false;
		}
		if (!mViewportSet)
		{
			ValidationLog.Error(scope $"RenderPass.{operation}: no viewport is set");
			return false;
		}
		if (!mScissorSet)
		{
			ValidationLog.Error(scope $"RenderPass.{operation}: no scissor is set");
			return false;
		}
		return true;
	}

	private bool ReadyToDrawMesh(StringView operation)
	{
		if (Ended(operation))
			return false;
		if (!mMeshPipelineBound)
		{
			ValidationLog.Error(scope $"RenderPass.{operation}: no mesh pipeline is bound");
			return false;
		}
		if (mInnerMeshShaders == null)
		{
			ValidationLog.Error(scope $"RenderPass.{operation}: the inner encoder does not support mesh shaders");
			return false;
		}
		return true;
	}
}
