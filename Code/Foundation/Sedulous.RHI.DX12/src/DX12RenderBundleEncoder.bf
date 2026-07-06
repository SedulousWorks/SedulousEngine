#if BF_PLATFORM_WINDOWS
namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;
using Sedulous.RHI;

/// An immutable, replayable DX12 bundle command list. Valid until freed.
class DX12RenderBundle : IRenderBundle
{
	public ID3D12GraphicsCommandList* CmdList;
	public ID3D12CommandAllocator* Allocator;
	public ID3D12RootSignature* RootSig;
	public ID3D12PipelineState* PSO;

	public this(ID3D12GraphicsCommandList* cmdList, ID3D12CommandAllocator* alloc,
		ID3D12RootSignature* rootSig, ID3D12PipelineState* pso)
	{
		CmdList = cmdList;
		Allocator = alloc;
		RootSig = rootSig;
		PSO = pso;
	}

	public ~this()
	{
		if (CmdList != null) CmdList.Release();
		if (Allocator != null) Allocator.Release();
	}
}

/// Records draws into a DX12 bundle command list (D3D12_COMMAND_LIST_TYPE_BUNDLE).
class DX12RenderBundleEncoder : IRenderBundleEncoder
{
	private ID3D12GraphicsCommandList* mCmdList;
	private ID3D12CommandAllocator* mAllocator;
	private DX12Device mDevice;
	private DX12RenderBundle mBundle ~ delete _;
	private DX12RenderPipeline mCurrentPipeline;
	private bool mFinished;

	public this(DX12Device device, ID3D12GraphicsCommandList* cmdList, ID3D12CommandAllocator* alloc)
	{
		mDevice = device;
		mCmdList = cmdList;
		mAllocator = alloc;
	}

	public void SetPipeline(IRenderPipeline pipeline)
	{
		let dxPipeline = pipeline as DX12RenderPipeline;
		if (dxPipeline == null) return;
		mCurrentPipeline = dxPipeline;
		mCmdList.SetPipelineState(dxPipeline.Handle);
		mCmdList.SetGraphicsRootSignature((dxPipeline.Layout as DX12PipelineLayout).Handle);
		mCmdList.IASetPrimitiveTopology(dxPipeline.Topology);
	}

	public void SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets)
	{
		let dxGroup = bindGroup as DX12BindGroup;
		if (dxGroup == null || mCurrentPipeline == null) return;

		let layout = mCurrentPipeline.Layout as DX12PipelineLayout;
		if (layout == null) return;

		let dxLayout = dxGroup.Layout as DX12BindGroupLayout;

		// Copy-on-bind staging for SRV/UAV descriptors
		if (dxGroup.CbvSrvUavOffset >= 0 && dxLayout != null && dxLayout.CbvSrvUavCount > 0)
		{
			let rootIdx = layout.GetCbvSrvUavRootIndex(index);
			if (rootIdx >= 0)
			{
				// Bundle shares parent's staging pool - descriptors already staged
				// by the parent encoder. Just bind the GPU handle.
				let gpuHandle = mDevice.GpuSrvHeap.GetGpuHandle((uint32)dxGroup.CbvSrvUavOffset);
				mCmdList.SetGraphicsRootDescriptorTable((uint32)rootIdx, gpuHandle);
			}
		}

		if (dxGroup.SamplerOffset >= 0 && dxLayout != null && dxLayout.SamplerCount > 0)
		{
			let rootIdx = layout.GetSamplerRootIndex(index);
			if (rootIdx >= 0)
			{
				let gpuHandle = mDevice.GpuSamplerHeap.GetGpuHandle((uint32)dxGroup.SamplerOffset);
				mCmdList.SetGraphicsRootDescriptorTable((uint32)rootIdx, gpuHandle);
			}
		}

		// Dynamic offset root CBVs
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
				mCmdList.SetGraphicsRootConstantBufferView((uint32)entry.RootParamIndex, gpuAddr);
			case .D3D12_ROOT_PARAMETER_TYPE_SRV:
				mCmdList.SetGraphicsRootShaderResourceView((uint32)entry.RootParamIndex, gpuAddr);
			case .D3D12_ROOT_PARAMETER_TYPE_UAV:
				mCmdList.SetGraphicsRootUnorderedAccessView((uint32)entry.RootParamIndex, gpuAddr);
			default:
			}
		}
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (mCurrentPipeline == null) return;
		let layout = mCurrentPipeline.Layout as DX12PipelineLayout;
		if (layout == null || layout.PushConstantRootIndex < 0) return;

		mCmdList.SetGraphicsRoot32BitConstants(
			(uint32)layout.PushConstantRootIndex,
			size / 4, data, offset / 4);
	}

	public void SetVertexBuffer(uint32 slot, IBuffer buffer, uint64 offset)
	{
		let dxBuf = buffer as DX12Buffer;
		if (dxBuf == null) return;

		uint32 stride = (mCurrentPipeline != null) ? mCurrentPipeline.GetVertexStride(slot) : 0;

		D3D12_VERTEX_BUFFER_VIEW vbv = .()
		{
			BufferLocation = dxBuf.Handle.GetGPUVirtualAddress() + offset,
			SizeInBytes = (uint32)(dxBuf.Size - offset),
			StrideInBytes = stride
		};
		mCmdList.IASetVertexBuffers(slot, 1, &vbv);
	}

	public void SetIndexBuffer(IBuffer buffer, IndexFormat format, uint64 offset)
	{
		let dxBuf = buffer as DX12Buffer;
		if (dxBuf == null) return;

		D3D12_INDEX_BUFFER_VIEW ibv = .()
		{
			BufferLocation = dxBuf.Handle.GetGPUVirtualAddress() + offset,
			SizeInBytes = (uint32)(dxBuf.Size - offset),
			Format = DX12Conversions.ToDxgiIndexFormat(format)
		};
		mCmdList.IASetIndexBuffer(&ibv);
	}

	public void Draw(uint32 vertexCount, uint32 instanceCount, uint32 firstVertex, uint32 firstInstance)
	{
		mCmdList.DrawInstanced(vertexCount, instanceCount, firstVertex, firstInstance);
	}

	public void DrawIndexed(uint32 indexCount, uint32 instanceCount, uint32 firstIndex, int32 baseVertex, uint32 firstInstance)
	{
		mCmdList.DrawIndexedInstanced(indexCount, instanceCount, firstIndex, baseVertex, firstInstance);
	}

	public void DrawIndirect(IBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride)
	{
		let dxBuf = buffer as DX12Buffer;
		if (dxBuf == null) return;
		// DX12 indirect requires a command signature; for now single-draw fallback
		mCmdList.DrawInstanced(0, 0, 0, 0); // placeholder
	}

	public void DrawIndexedIndirect(IBuffer buffer, uint64 offset, uint32 drawCount, uint32 stride)
	{
		let dxBuf = buffer as DX12Buffer;
		if (dxBuf == null) return;
		// DX12 indirect requires a command signature; for now single-draw fallback
		mCmdList.DrawIndexedInstanced(0, 0, 0, 0, 0); // placeholder
	}

	public IRenderBundle Finish()
	{
		if (mFinished)
			return mBundle;
		mFinished = true;
		mCmdList.Close();

		ID3D12RootSignature* rootSig = null;
		ID3D12PipelineState* pso = null;
		if (mCurrentPipeline != null)
		{
			if (let layout = mCurrentPipeline.Layout as DX12PipelineLayout)
				rootSig = layout.Handle;
			pso = mCurrentPipeline.Handle;
		}

		mBundle = new DX12RenderBundle(mCmdList, mAllocator, rootSig, pso);
		return mBundle;
	}
}

#endif // BF_PLATFORM_WINDOWS
