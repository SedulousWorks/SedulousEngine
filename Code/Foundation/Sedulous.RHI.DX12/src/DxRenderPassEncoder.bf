#if BF_PLATFORM_WINDOWS
using System;
using Sedulous.RHI;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;

namespace Sedulous.RHI.DX12;

/// Recording inside a render pass, including the mesh shading path.
///
/// Holds the pass description because End needs it again: the end of pass timestamp and the
/// MSAA resolves are both driven from what Begin was given.
class DxRenderPassEncoder : IRenderPassEncoder, IMeshShaderPassExt
{
	private DxRenderPassContext mCtx = .();
	private RenderPassDesc mDesc = .();
	private DxRenderPipeline mCurrentPipeline = null; // NOT owned
	private DxMeshPipeline mCurrentMeshPipeline = null; // NOT owned

	/// Vertex buffer views, kept so they can be re-applied when the pipeline changes. A DX12
	/// view carries its STRIDE, and the stride comes from the pipeline, so a buffer bound
	/// before a pipeline was set went down with a stride of zero.
	private D3D12_VERTEX_BUFFER_VIEW[8] mCachedVbs = .();
	private uint32 mCachedVbCount = 0;

	public this(DxRenderPassContext ctx) => mCtx = ctx;

	public void Begin(RenderPassDesc desc)
	{
		mDesc = desc;
		mCurrentPipeline = null;
		mCurrentMeshPipeline = null;
	}

	/// The last pipeline state set here, which a bundle recorded against this encoder has to
	/// replay onto the parent list.
	public ID3D12PipelineState* CurrentPso =>
		(mCurrentPipeline != null) ? mCurrentPipeline.Handle : null;

	public ID3D12RootSignature* CurrentRootSig
	{
		get
		{
			let l = (mCurrentPipeline != null) ? mCurrentPipeline.PipelineLayout : null;
			return (l != null) ? l.Handle : null;
		}
	}

	private DxPipelineLayout GetCurrentLayout()
	{
		if (mCurrentPipeline != null)
			return mCurrentPipeline.PipelineLayout;
		if (mCurrentMeshPipeline != null)
			return mCurrentMeshPipeline.PipelineLayout;
		return null;
	}

	public void SetPipeline(IRenderPipeline pipeline)
	{
		let dxPipeline = pipeline as DxRenderPipeline;
		if (dxPipeline == null)
			return;

		mCurrentPipeline = dxPipeline;
		mCurrentMeshPipeline = null;

		let cmdList = mCtx.CmdList;
		cmdList.SetPipelineState(dxPipeline.Handle);
		cmdList.SetGraphicsRootSignature(dxPipeline.PipelineLayout.Handle);
		cmdList.IASetPrimitiveTopology(dxPipeline.Topology);

		// Re-apply the cached vertex buffers with the strides this pipeline names.
		for (uint32 slot = 0; slot < mCachedVbCount; slot++)
		{
			if (mCachedVbs[(int)slot].BufferLocation != 0)
			{
				mCachedVbs[(int)slot].StrideInBytes = dxPipeline.GetVertexStride(slot);
				cmdList.IASetVertexBuffers(slot, 1, &mCachedVbs[(int)slot]);
			}
		}
	}

	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets = default)
	{
		let dxGroup = group as DxBindGroup;
		if (dxGroup == null)
			return;

		let layout = GetCurrentLayout();
		if (layout == null)
			return;

		let cmdList = mCtx.CmdList;
		let dxLayout = dxGroup.Layout as DxBindGroupLayout;

		// COPY ON BIND, which is also what makes destroying a bind group safe while recording:
		// the GPU only ever references the staged copy.
		if ((dxGroup.CbvSrvUavOffset >= 0) && (dxLayout != null) && (dxLayout.CbvSrvUavCount > 0))
		{
			let rootIdx = layout.GetCbvSrvUavRootIndex(index);
			if (rootIdx >= 0)
			{
				let stagedOffset = mCtx.SrvStaging.CopyFrom((uint32)dxGroup.CbvSrvUavOffset,
					dxLayout.CbvSrvUavCount);
				if (stagedOffset >= 0)
				{
					cmdList.SetGraphicsRootDescriptorTable((uint32)rootIdx,
						mCtx.GpuSrvHeap.GetGpuHandle((uint32)stagedOffset));
				}
			}
		}

		// Baked at bind group creation, so it binds directly: the 2048 cap sampler heap
		// cannot fit per draw copies.
		if ((dxGroup.GpuSamplerOffset >= 0) && (dxLayout != null) && (dxLayout.SamplerCount > 0))
		{
			let rootIdx = layout.GetSamplerRootIndex(index);
			if (rootIdx >= 0)
			{
				cmdList.SetGraphicsRootDescriptorTable((uint32)rootIdx,
					mCtx.GpuSamplerHeap.GetGpuHandle((uint32)dxGroup.GpuSamplerOffset));
			}
		}

		let dynAddrs = dxGroup.DynamicGpuAddresses;
		int dynOffsetIdx = 0;

		for (let entry in layout.DynamicRootEntries)
		{
			if (entry.GroupIndex != index)
				continue;
			if (entry.DynamicIndex >= (uint32)dynAddrs.Length)
				continue;

			var gpuAddr = dynAddrs[(int)entry.DynamicIndex];
			if (dynOffsetIdx < dynamicOffsets.Length)
				gpuAddr += (uint64)dynamicOffsets[dynOffsetIdx];
			dynOffsetIdx++;

			switch (entry.ParamType)
			{
			case .D3D12_ROOT_PARAMETER_TYPE_CBV:
				cmdList.SetGraphicsRootConstantBufferView((uint32)entry.RootParamIndex, gpuAddr);
			case .D3D12_ROOT_PARAMETER_TYPE_SRV:
				cmdList.SetGraphicsRootShaderResourceView((uint32)entry.RootParamIndex, gpuAddr);
			case .D3D12_ROOT_PARAMETER_TYPE_UAV:
				cmdList.SetGraphicsRootUnorderedAccessView((uint32)entry.RootParamIndex, gpuAddr);
			default:
			}
		}
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		let layout = GetCurrentLayout();
		if ((layout == null) || (layout.PushConstantRootIndex < 0))
			return;

		mCtx.CmdList.SetGraphicsRoot32BitConstants((uint32)layout.PushConstantRootIndex, size / 4,
			data, offset / 4);
	}

	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset = 0)
	{
		let dxBuf = buffer as DxBuffer;
		if ((dxBuf == null) || (slot >= 8))
			return;

		let stride = (mCurrentPipeline != null) ? mCurrentPipeline.GetVertexStride(slot) : 0;

		D3D12_VERTEX_BUFFER_VIEW view = .();
		view.BufferLocation = dxBuf.GpuAddress + offset;
		view.SizeInBytes = (uint32)(dxBuf.Desc.Size - offset);
		view.StrideInBytes = stride;

		mCachedVbs[(int)slot] = view;
		if (slot >= mCachedVbCount)
			mCachedVbCount = slot + 1;

		mCtx.CmdList.IASetVertexBuffers(slot, 1, &view);
	}

	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset = 0)
	{
		let dxBuf = buffer as DxBuffer;
		if (dxBuf == null)
			return;

		D3D12_INDEX_BUFFER_VIEW view = .();
		view.BufferLocation = dxBuf.GpuAddress + offset;
		view.SizeInBytes = (uint32)(dxBuf.Desc.Size - offset);
		view.Format = DxConversions.ToDxgiIndexFormat(format);

		mCtx.CmdList.IASetIndexBuffer(&view);
	}

	public void SetViewport(float x, float y, float width, float height, float minDepth = 0.0f,
		float maxDepth = 1.0f)
	{
		D3D12_VIEWPORT viewport = .();
		viewport.TopLeftX = x;
		viewport.TopLeftY = y;
		viewport.Width = width;
		viewport.Height = height;
		viewport.MinDepth = minDepth;
		viewport.MaxDepth = maxDepth;
		mCtx.CmdList.RSSetViewports(1, &viewport);
	}

	public void SetScissor(int32 x, int32 y, uint32 width, uint32 height)
	{
		D3D12_RECT rect = .();
		rect.left = x;
		rect.top = y;
		rect.right = x + (int32)width;
		rect.bottom = y + (int32)height;
		mCtx.CmdList.RSSetScissorRects(1, &rect);
	}

	public void SetBlendConstant(float r, float g, float b, float a)
	{
		float[4] color = .(r, g, b, a);
		mCtx.CmdList.OMSetBlendFactor(&color[0]);
	}

	public void SetStencilReference(uint32 reference) => mCtx.CmdList.OMSetStencilRef(reference);

	public void Draw(uint32 vertexCount, uint32 instanceCount = 1, uint32 firstVertex = 0,
		uint32 firstInstance = 0)
	{
		mCtx.CmdList.DrawInstanced(vertexCount, instanceCount, firstVertex, firstInstance);
	}

	public void DrawIndexed(uint32 indexCount, uint32 instanceCount = 1, uint32 firstIndex = 0,
		int32 baseVertex = 0, uint32 firstInstance = 0)
	{
		mCtx.CmdList.DrawIndexedInstanced(indexCount, instanceCount, firstIndex, baseVertex,
			firstInstance);
	}

	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1,
		uint32 stride = 0)
	{
		let dxBuf = buffer as DxBuffer;
		if ((dxBuf == null) || (mCtx.DrawSig == null))
			return;

		// One ExecuteIndirect PER DRAW rather than a single batched call: the signature is
		// built for one argument, so a caller supplied stride is walked here.
		let actualStride = (stride > 0) ? stride : 16; // D3D12_DRAW_ARGUMENTS
		for (uint32 i = 0; i < drawCount; i++)
		{
			mCtx.CmdList.ExecuteIndirect(mCtx.DrawSig, 1, dxBuf.Handle,
				offset + (uint64)i * actualStride, null, 0);
		}
	}

	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1,
		uint32 stride = 0)
	{
		let dxBuf = buffer as DxBuffer;
		if ((dxBuf == null) || (mCtx.DrawIndexedSig == null))
			return;

		let actualStride = (stride > 0) ? stride : 20; // D3D12_DRAW_INDEXED_ARGUMENTS
		for (uint32 i = 0; i < drawCount; i++)
		{
			mCtx.CmdList.ExecuteIndirect(mCtx.DrawIndexedSig, 1, dxBuf.Handle,
				offset + (uint64)i * actualStride, null, 0);
		}
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		if (let qs = querySet as DxQuerySet)
			mCtx.CmdList.EndQuery(qs.Handle, .D3D12_QUERY_TYPE_TIMESTAMP, index);
	}

	public void BeginOcclusionQuery(IQuerySet querySet, uint32 index)
	{
		if (let qs = querySet as DxQuerySet)
			mCtx.CmdList.BeginQuery(qs.Handle, .D3D12_QUERY_TYPE_OCCLUSION, index);
	}

	public void EndOcclusionQuery(IQuerySet querySet, uint32 index)
	{
		if (let qs = querySet as DxQuerySet)
			mCtx.CmdList.EndQuery(qs.Handle, .D3D12_QUERY_TYPE_OCCLUSION, index);
	}

	// ---- mesh shading ----

	public void SetMeshPipeline(IMeshPipeline pipeline)
	{
		let dxPipeline = pipeline as DxMeshPipeline;
		if (dxPipeline == null)
			return;

		mCurrentMeshPipeline = dxPipeline;
		mCurrentPipeline = null; // the two are mutually exclusive

		mCtx.CmdList.SetPipelineState(dxPipeline.Handle);
		mCtx.CmdList.SetGraphicsRootSignature(dxPipeline.PipelineLayout.Handle);
	}

	public void DrawMeshTasks(uint32 groupCountX, uint32 groupCountY = 1, uint32 groupCountZ = 1)
	{
		// DispatchMesh is only on ID3D12GraphicsCommandList6, so the list is queried per call
		// and the reference given straight back.
		ID3D12GraphicsCommandList6* cmdList6 = null;
		if (SUCCEEDED(mCtx.CmdList.QueryInterface(ID3D12GraphicsCommandList6.IID,
			(void**)&cmdList6)) && (cmdList6 != null))
		{
			cmdList6.DispatchMesh(groupCountX, groupCountY, groupCountZ);
			cmdList6.Release();
		}
	}

	public void DrawMeshTasksIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1,
		uint32 stride = 0)
	{
		let dxBuf = buffer as DxBuffer;
		if ((dxBuf == null) || (mCtx.DispatchMeshSig == null))
			return;

		let actualStride = (stride > 0) ? stride : 12; // D3D12_DISPATCH_MESH_ARGUMENTS
		for (uint32 i = 0; i < drawCount; i++)
		{
			mCtx.CmdList.ExecuteIndirect(mCtx.DispatchMeshSig, 1, dxBuf.Handle,
				offset + (uint64)i * actualStride, null, 0);
		}
	}

	public void DrawMeshTasksIndirectCount(IBuffer buffer, uint64 offset, IBuffer countBuffer,
		uint64 countOffset, uint32 maxDrawCount, uint32 stride)
	{
		let dxBuf = buffer as DxBuffer;
		let dxCountBuf = countBuffer as DxBuffer;
		if ((dxBuf == null) || (dxCountBuf == null) || (mCtx.DispatchMeshSig == null))
			return;

		// A count buffer is what ExecuteIndirect takes natively, so this one IS a single call.
		mCtx.CmdList.ExecuteIndirect(mCtx.DispatchMeshSig, maxDrawCount, dxBuf.Handle, offset,
			dxCountBuf.Handle, countOffset);
	}

	public void ExecuteBundles(Span<IRenderBundle> bundles)
	{
		for (let b in bundles)
		{
			if (let dxBundle = b as DxRenderBundle)
			{
				// D3D12 requires the PARENT list to carry the same root signature and pipeline
				// state before a bundle runs; a bundle does not carry its own.
				if (dxBundle.RootSig != null)
					mCtx.CmdList.SetGraphicsRootSignature(dxBundle.RootSig);
				if (dxBundle.Pso != null)
					mCtx.CmdList.SetPipelineState(dxBundle.Pso);
				mCtx.CmdList.ExecuteBundle(dxBundle.Handle);
			}
		}
	}

	public void End()
	{
		if (mDesc.TimestampQuerySet != null)
		{
			if (let qs = mDesc.TimestampQuerySet as DxQuerySet)
			{
				mCtx.CmdList.EndQuery(qs.Handle, .D3D12_QUERY_TYPE_TIMESTAMP,
					mDesc.EndTimestampIndex);
			}
		}

		// MSAA resolve, which D3D12 does as an explicit copy rather than as part of the pass.
		for (let ca in ref mDesc.ColorAttachments)
		{
			if (ca.ResolveTarget == null)
				continue;

			let srcView = ca.View as DxTextureView;
			let dstView = ca.ResolveTarget as DxTextureView;
			if ((srcView == null) || (dstView == null))
				continue;

			let srcTex = srcView.DxTextureHandle;
			let dstTex = dstView.DxTextureHandle;

			var format = srcView.Format;
			if (format == .Undefined)
				format = srcTex.Desc.Format;

			D3D12_RESOURCE_BARRIER[2] barriers = .();
			barriers[0].Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
			barriers[0].Transition.pResource = srcTex.Handle;
			barriers[0].Transition.StateBefore = .D3D12_RESOURCE_STATE_RENDER_TARGET;
			barriers[0].Transition.StateAfter = .D3D12_RESOURCE_STATE_RESOLVE_SOURCE;
			barriers[0].Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
			barriers[1].Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
			barriers[1].Transition.pResource = dstTex.Handle;
			barriers[1].Transition.StateBefore = .D3D12_RESOURCE_STATE_RENDER_TARGET;
			barriers[1].Transition.StateAfter = .D3D12_RESOURCE_STATE_RESOLVE_DEST;
			barriers[1].Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
			mCtx.CmdList.ResourceBarrier(2, &barriers[0]);

			mCtx.CmdList.ResolveSubresource(dstTex.Handle, 0, srcTex.Handle, 0,
				DxConversions.ToDxgiFormat(format));

			// And straight back, so the pass leaves both where it found them.
			barriers[0].Transition.StateBefore = .D3D12_RESOURCE_STATE_RESOLVE_SOURCE;
			barriers[0].Transition.StateAfter = .D3D12_RESOURCE_STATE_RENDER_TARGET;
			barriers[1].Transition.StateBefore = .D3D12_RESOURCE_STATE_RESOLVE_DEST;
			barriers[1].Transition.StateAfter = .D3D12_RESOURCE_STATE_RENDER_TARGET;
			mCtx.CmdList.ResourceBarrier(2, &barriers[0]);
		}

		mCurrentPipeline = null;
		mCurrentMeshPipeline = null;
	}
}

#endif // BF_PLATFORM_WINDOWS
