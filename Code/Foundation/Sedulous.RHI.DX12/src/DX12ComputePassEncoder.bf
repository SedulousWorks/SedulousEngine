namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Sedulous.RHI;

/// DX12 implementation of IComputePassEncoder.
/// Records compute dispatch commands into the parent command encoder's command list.
class DX12ComputePassEncoder : IComputePassEncoder
{
	private DX12CommandEncoder mEncoder;
	private DX12ComputePipeline mCurrentPipeline;

	public this(DX12CommandEncoder encoder)
	{
		mEncoder = encoder;
	}

	public void Begin()
	{
		mCurrentPipeline = null;
	}

	public void SetPipeline(IComputePipeline pipeline)
	{
		let dxPipeline = pipeline as DX12ComputePipeline;
		if (dxPipeline == null) return;
		mCurrentPipeline = dxPipeline;

		let cmdList = mEncoder.CmdList;
		cmdList.SetPipelineState(dxPipeline.Handle);
		cmdList.SetComputeRootSignature((dxPipeline.Layout as DX12PipelineLayout).Handle);
	}

	public void SetBindGroup(uint32 index, IBindGroup bindGroup, Span<uint32> dynamicOffsets)
	{
		let dxGroup = bindGroup as DX12BindGroup;
		if (dxGroup == null || mCurrentPipeline == null) return;

		let layout = mCurrentPipeline.Layout as DX12PipelineLayout;
		if (layout == null) return;

		let cmdList = mEncoder.CmdList;
		let dxLayout = dxGroup.Layout as DX12BindGroupLayout;

		// Copy-on-bind: copy into encoder's staging region, bind from staging offset.
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
					cmdList.SetComputeRootDescriptorTable((uint32)rootIdx, gpuHandle);
				}
			}
		}

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
					cmdList.SetComputeRootDescriptorTable((uint32)rootIdx, gpuHandle);
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
				cmdList.SetComputeRootConstantBufferView((uint32)entry.RootParamIndex, gpuAddr);
			case .D3D12_ROOT_PARAMETER_TYPE_SRV:
				cmdList.SetComputeRootShaderResourceView((uint32)entry.RootParamIndex, gpuAddr);
			case .D3D12_ROOT_PARAMETER_TYPE_UAV:
				cmdList.SetComputeRootUnorderedAccessView((uint32)entry.RootParamIndex, gpuAddr);
			default:
			}
		}
	}

	public void SetPushConstants(ShaderStage stages, uint32 offset, uint32 size, void* data)
	{
		if (mCurrentPipeline == null) return;
		let layout = mCurrentPipeline.Layout as DX12PipelineLayout;
		if (layout == null || layout.PushConstantRootIndex < 0) return;

		mEncoder.CmdList.SetComputeRoot32BitConstants(
			(uint32)layout.PushConstantRootIndex,
			size / 4, data, offset / 4);
	}

	public void Dispatch(uint32 x, uint32 y, uint32 z)
	{
		mEncoder.CmdList.Dispatch(x, y, z);
	}

	public void DispatchIndirect(IBuffer buffer, uint64 offset)
	{
		let dxBuf = buffer as DX12Buffer;
		if (dxBuf == null) return;

		let sig = mEncoder.Device.DispatchSignature;
		if (sig == null) return;

		mEncoder.CmdList.ExecuteIndirect(sig, 1, dxBuf.Handle, offset, null, 0);
	}

	public void ComputeBarrier()
	{
		D3D12_RESOURCE_BARRIER barrier = default;
		barrier.Type = .D3D12_RESOURCE_BARRIER_TYPE_UAV;
		barrier.Flags = .D3D12_RESOURCE_BARRIER_FLAG_NONE;
		barrier.UAV.pResource = null; // Global UAV barrier
		mEncoder.CmdList.ResourceBarrier(1, &barrier);
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		if (let qs = querySet as DX12QuerySet)
			mEncoder.CmdList.EndQuery(qs.Handle, .D3D12_QUERY_TYPE_TIMESTAMP, index);
	}

	public void End()
	{
		mCurrentPipeline = null;
	}
}
