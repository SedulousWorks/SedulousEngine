namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;
using Sedulous.RHI;

/// DX12 implementation of IRenderPassEncoder and IMeshShaderPassExt.
/// Records render pass commands into the parent command encoder's command list.
class DX12RenderPassEncoder : IRenderPassEncoder, IMeshShaderPassExt
{
	private DX12CommandEncoder mEncoder;
	private RenderPassDesc mDesc;
	private DX12RenderPipeline mCurrentPipeline;
	private DX12MeshPipeline mCurrentMeshPipeline;

	public this(DX12CommandEncoder encoder)
	{
		mEncoder = encoder;
	}

	public void Begin(RenderPassDesc desc)
	{
		mDesc = desc;
		mCurrentPipeline = null;
		mCurrentMeshPipeline = null;
	}

	// ===== Pipeline & Binding =====

	public void SetPipeline(IRenderPipeline pipeline)
	{
		let dxPipeline = pipeline as DX12RenderPipeline;
		if (dxPipeline == null) return;
		mCurrentPipeline = dxPipeline;

		let cmdList = mEncoder.CmdList;
		cmdList.SetPipelineState(dxPipeline.Handle);
		cmdList.SetGraphicsRootSignature((dxPipeline.Layout as DX12PipelineLayout).Handle);
		cmdList.IASetPrimitiveTopology(dxPipeline.Topology);
	}

	public void SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets)
	{
		let dxGroup = bindGroup as DX12BindGroup;
		if (dxGroup == null) return;

		let layout = GetCurrentLayout();
		if (layout == null) return;

		let cmdList = mEncoder.CmdList;
		let dxLayout = dxGroup.Layout as DX12BindGroupLayout;

		// Copy-on-bind: copy bind group's descriptors into encoder's staging region,
		// then bind from the staging offset. This makes bind group destruction safe
		// during command recording — the GPU only references the staging copy.

		// Bind CBV/SRV/UAV table (staged)
		if (dxGroup.CbvSrvUavOffset >= 0 && dxLayout != null && dxLayout.CbvSrvUavCount > 0)
		{
			let rootIdx = layout.GetCbvSrvUavRootIndex(index);
			if (rootIdx >= 0)
			{
				let stagedOffset = mEncoder.SrvStaging.CopyFrom(
					(uint32)dxGroup.CbvSrvUavOffset, dxLayout.CbvSrvUavCount);
				if (stagedOffset >= 0)
				{
					let gpuHandle = mEncoder.Device.GpuSrvHeap.GetGpuHandle((uint32)stagedOffset);
					cmdList.SetGraphicsRootDescriptorTable((uint32)rootIdx, gpuHandle);
				}
			}
		}

		// Bind sampler table (staged)
		if (dxGroup.SamplerOffset >= 0 && dxLayout != null && dxLayout.SamplerCount > 0)
		{
			let rootIdx = layout.GetSamplerRootIndex(index);
			if (rootIdx >= 0)
			{
				let stagedOffset = mEncoder.SamplerStaging.CopyFrom(
					(uint32)dxGroup.SamplerOffset, dxLayout.SamplerCount);
				if (stagedOffset >= 0)
				{
					let gpuHandle = mEncoder.Device.GpuSamplerHeap.GetGpuHandle((uint32)stagedOffset);
					cmdList.SetGraphicsRootDescriptorTable((uint32)rootIdx, gpuHandle);
				}
			}
		}

		// Bind dynamic offset root descriptors (not staged — uses GPU virtual addresses)
		int dynOffsetIdx = 0;
		for (let entry in layout.DynamicRootEntries)
		{
			if (entry.GroupIndex != index) continue;
			if ((int)entry.DynamicIndex >= dxGroup.DynamicGpuAddresses.Count) continue;

			uint64 gpuAddr = dxGroup.DynamicGpuAddresses[(int)entry.DynamicIndex];
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
		if (layout == null || layout.PushConstantRootIndex < 0) return;

		mEncoder.CmdList.SetGraphicsRoot32BitConstants(
			(uint32)layout.PushConstantRootIndex,
			size / 4, data, offset / 4);
	}

	private DX12PipelineLayout GetCurrentLayout()
	{
		if (mCurrentPipeline != null)
			return mCurrentPipeline.Layout as DX12PipelineLayout;
		if (mCurrentMeshPipeline != null)
			return mCurrentMeshPipeline.Layout as DX12PipelineLayout;
		return null;
	}

	// ===== Vertex & Index Buffers =====

	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset)
	{
		let dxBuf = buffer as DX12Buffer;
		if (dxBuf == null) return;

		uint32 stride = (mCurrentPipeline != null) ? mCurrentPipeline.GetVertexStride(slot) : 0;

		D3D12_VERTEX_BUFFER_VIEW view = .()
		{
			BufferLocation = dxBuf.Handle.GetGPUVirtualAddress() + offset,
			SizeInBytes = (uint32)(dxBuf.Size - offset),
			StrideInBytes = stride
		};

		mEncoder.CmdList.IASetVertexBuffers(slot, 1, &view);
	}

	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset)
	{
		let dxBuf = buffer as DX12Buffer;
		if (dxBuf == null) return;

		D3D12_INDEX_BUFFER_VIEW view = .()
		{
			BufferLocation = dxBuf.Handle.GetGPUVirtualAddress() + offset,
			SizeInBytes = (uint32)(dxBuf.Size - offset),
			Format = DX12Conversions.ToDxgiIndexFormat(format)
		};

		mEncoder.CmdList.IASetIndexBuffer(&view);
	}

	// ===== Dynamic State =====

	public void SetViewport(float x, float y, float w, float h, float minDepth, float maxDepth)
	{
		D3D12_VIEWPORT viewport = .()
		{
			TopLeftX = x,
			TopLeftY = y,
			Width = w,
			Height = h,
			MinDepth = minDepth,
			MaxDepth = maxDepth
		};

		mEncoder.CmdList.RSSetViewports(1, &viewport);
	}

	public void SetScissor(int32 x, int32 y, uint32 w, uint32 h)
	{
		RECT rect = .()
		{
			left = x,
			top = y,
			right = x + (int32)w,
			bottom = y + (int32)h
		};

		mEncoder.CmdList.RSSetScissorRects(1, &rect);
	}

	public void SetBlendConstant(float r, float g, float b, float a)
	{
		float[4] color = .(r, g, b, a);
		mEncoder.CmdList.OMSetBlendFactor(&color[0]);
	}

	public void SetStencilReference(uint32 reference)
	{
		mEncoder.CmdList.OMSetStencilRef(reference);
	}

	// ===== Draw Commands =====

	public void Draw(uint32 vertexCount, uint32 instanceCount, uint32 firstVertex, uint32 firstInstance)
	{
		mEncoder.CmdList.DrawInstanced(vertexCount, instanceCount, firstVertex, firstInstance);
	}

	public void DrawIndexed(uint32 indexCount, uint32 instanceCount, uint32 firstIndex, int32 baseVertex, uint32 firstInstance)
	{
		mEncoder.CmdList.DrawIndexedInstanced(indexCount, instanceCount, firstIndex, baseVertex, firstInstance);
	}

	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride)
	{
		let dxBuf = buffer as DX12Buffer;
		if (dxBuf == null) return;

		let sig = mEncoder.Device.DrawSignature;
		if (sig == null) return;

		let actualStride = (stride > 0) ? stride : 16; // sizeof(D3D12_DRAW_ARGUMENTS)
		for (uint32 i = 0; i < drawCount; i++)
		{
			mEncoder.CmdList.ExecuteIndirect(sig, 1, dxBuf.Handle,
				offset + (uint64)i * actualStride, null, 0);
		}
	}

	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride)
	{
		let dxBuf = buffer as DX12Buffer;
		if (dxBuf == null) return;

		let sig = mEncoder.Device.DrawIndexedSignature;
		if (sig == null) return;

		let actualStride = (stride > 0) ? stride : 20; // sizeof(D3D12_DRAW_INDEXED_ARGUMENTS)
		for (uint32 i = 0; i < drawCount; i++)
		{
			mEncoder.CmdList.ExecuteIndirect(sig, 1, dxBuf.Handle,
				offset + (uint64)i * actualStride, null, 0);
		}
	}

	// ===== Queries =====

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		if (let qs = querySet as DX12QuerySet)
			mEncoder.CmdList.EndQuery(qs.Handle, .D3D12_QUERY_TYPE_TIMESTAMP, index);
	}

	public void BeginOcclusionQuery(IQuerySet querySet, uint32 index)
	{
		if (let qs = querySet as DX12QuerySet)
			mEncoder.CmdList.BeginQuery(qs.Handle, .D3D12_QUERY_TYPE_OCCLUSION, index);
	}

	public void EndOcclusionQuery(IQuerySet querySet, uint32 index)
	{
		if (let qs = querySet as DX12QuerySet)
			mEncoder.CmdList.EndQuery(qs.Handle, .D3D12_QUERY_TYPE_OCCLUSION, index);
	}

	// ===== IMeshShaderPassExt =====

	public void SetMeshPipeline(IMeshPipeline pipeline)
	{
		let dxPipeline = pipeline as DX12MeshPipeline;
		if (dxPipeline == null) return;
		mCurrentMeshPipeline = dxPipeline;
		mCurrentPipeline = null; // Clear regular pipeline

		let cmdList = mEncoder.CmdList;
		cmdList.SetPipelineState(dxPipeline.Handle);
		cmdList.SetGraphicsRootSignature((dxPipeline.Layout as DX12PipelineLayout).Handle);
	}

	public void DrawMeshTasks(uint32 groupCountX, uint32 groupCountY = 1, uint32 groupCountZ = 1)
	{
		// Need ID3D12GraphicsCommandList6 for DispatchMesh
		ID3D12GraphicsCommandList6* cmdList6 = null;
		HRESULT hr = mEncoder.CmdList.QueryInterface(ID3D12GraphicsCommandList6.IID, (void**)&cmdList6);
		if (SUCCEEDED(hr) && cmdList6 != null)
		{
			cmdList6.DispatchMesh(groupCountX, groupCountY, groupCountZ);
			cmdList6.Release();
		}
	}

	public void DrawMeshTasksIndirect(IBuffer buffer, uint64 offset, uint32 drawCount = 1, uint32 stride = 0)
	{
		let dxBuf = buffer as DX12Buffer;
		if (dxBuf == null) return;

		let sig = mEncoder.Device.DispatchMeshSignature;
		if (sig == null) return;

		let actualStride = (stride > 0) ? stride : 12; // sizeof(D3D12_DISPATCH_MESH_ARGUMENTS): 3 x uint32
		for (uint32 i = 0; i < drawCount; i++)
		{
			mEncoder.CmdList.ExecuteIndirect(sig, 1, dxBuf.Handle,
				offset + (uint64)i * actualStride, null, 0);
		}
	}

	public void DrawMeshTasksIndirectCount(IBuffer buffer, uint64 offset,
		IBuffer countBuffer, uint64 countOffset, uint32 maxDrawCount, uint32 stride)
	{
		let dxBuf = buffer as DX12Buffer;
		let dxCountBuf = countBuffer as DX12Buffer;
		if (dxBuf == null || dxCountBuf == null) return;

		let sig = mEncoder.Device.DispatchMeshSignature;
		if (sig == null) return;

		mEncoder.CmdList.ExecuteIndirect(sig, maxDrawCount, dxBuf.Handle,
			offset, dxCountBuf.Handle, countOffset);
	}

	// ===== End =====

	public void End()
	{
		// Timestamp at pass end
		if (mDesc.TimestampQuerySet != null)
		{
			if (let qs = mDesc.TimestampQuerySet as DX12QuerySet)
				mEncoder.CmdList.EndQuery(qs.Handle, .D3D12_QUERY_TYPE_TIMESTAMP, mDesc.EndTimestampIndex);
		}

		// MSAA resolve: resolve multisampled color attachments to their resolve targets
		for (let ca in mDesc.ColorAttachments)
		{
			if (ca.ResolveTarget == null) continue;

			let srcView = ca.View as DX12TextureView;
			let dstView = ca.ResolveTarget as DX12TextureView;
			if (srcView == null || dstView == null) continue;

			let srcTex = srcView.DX12Texture;
			let dstTex = dstView.DX12Texture;

			let format = (ca.View as DX12TextureView).Desc.Format;
			let dxgiFormat = DX12Conversions.ToDxgiFormat(
				(format == .Undefined) ? srcTex.Desc.Format : format);

			// Transition src to resolve source, dst to resolve dest
			D3D12_RESOURCE_BARRIER[2] barriers = default;
			barriers[0].Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
			barriers[0].Transition.pResource = srcTex.Handle;
			barriers[0].Transition.StateBefore = .D3D12_RESOURCE_STATE_RENDER_TARGET;
			barriers[0].Transition.StateAfter = .D3D12_RESOURCE_STATE_RESOLVE_SOURCE;
			barriers[0].Transition.Subresource = 0xFFFFFFFF;

			barriers[1].Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
			barriers[1].Transition.pResource = dstTex.Handle;
			barriers[1].Transition.StateBefore = .D3D12_RESOURCE_STATE_RENDER_TARGET;
			barriers[1].Transition.StateAfter = .D3D12_RESOURCE_STATE_RESOLVE_DEST;
			barriers[1].Transition.Subresource = 0xFFFFFFFF;

			mEncoder.CmdList.ResourceBarrier(2, &barriers[0]);

			mEncoder.CmdList.ResolveSubresource(dstTex.Handle, 0, srcTex.Handle, 0, dxgiFormat);

			// Transition back
			barriers[0].Transition.StateBefore = .D3D12_RESOURCE_STATE_RESOLVE_SOURCE;
			barriers[0].Transition.StateAfter = .D3D12_RESOURCE_STATE_RENDER_TARGET;
			barriers[1].Transition.StateBefore = .D3D12_RESOURCE_STATE_RESOLVE_DEST;
			barriers[1].Transition.StateAfter = .D3D12_RESOURCE_STATE_RENDER_TARGET;

			mEncoder.CmdList.ResourceBarrier(2, &barriers[0]);
		}

		mCurrentPipeline = null;
		mCurrentMeshPipeline = null;
	}
}
