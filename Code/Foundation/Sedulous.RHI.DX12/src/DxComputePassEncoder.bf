using System;
using Sedulous.RHI;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// Recording inside a compute pass.
///
/// D3D12 has no pass object for compute, so this is a recording MODE over the command
/// encoder's list rather than something the driver knows about. It exists to keep the
/// compute root bindings, which are a separate set from the graphics ones, off the render
/// path.
class DxComputePassEncoder : IComputePassEncoder
{
	private DxComputePassContext mCtx = .();
	private DxComputePipeline mCurrentPipeline = null; // NOT owned

	public this(DxComputePassContext ctx) => mCtx = ctx;

	public void Begin() => mCurrentPipeline = null;

	public void SetPipeline(IComputePipeline pipeline)
	{
		let dxPipeline = pipeline as DxComputePipeline;
		if (dxPipeline == null)
			return;

		mCurrentPipeline = dxPipeline;
		mCtx.CmdList.SetPipelineState(dxPipeline.Handle);
		mCtx.CmdList.SetComputeRootSignature(dxPipeline.PipelineLayout.Handle);
	}

	public void SetBindGroup(uint32 index, IBindGroup group, Span<uint32> dynamicOffsets = default)
	{
		let dxGroup = group as DxBindGroup;
		if ((dxGroup == null) || (mCurrentPipeline == null))
			return;

		let layout = mCurrentPipeline.PipelineLayout;
		if (layout == null)
			return;

		let cmdList = mCtx.CmdList;
		let dxLayout = dxGroup.Layout as DxBindGroupLayout;

		// COPY ON BIND: the group's descriptors live in a CPU heap, so they are staged into
		// the shader visible one and the table is bound at the staged offset.
		if ((dxGroup.CbvSrvUavOffset >= 0) && (dxLayout != null) && (dxLayout.CbvSrvUavCount > 0))
		{
			let rootIdx = layout.GetCbvSrvUavRootIndex(index);
			if (rootIdx >= 0)
			{
				let stagedOffset = mCtx.SrvStaging.CopyFrom((uint32)dxGroup.CbvSrvUavOffset,
					dxLayout.CbvSrvUavCount);
				if (stagedOffset >= 0)
				{
					cmdList.SetComputeRootDescriptorTable((uint32)rootIdx,
						mCtx.GpuSrvHeap.GetGpuHandle((uint32)stagedOffset));
				}
			}
		}

		// The sampler table was baked into the shader visible heap when the group was made,
		// so it binds directly with no staging.
		if ((dxGroup.GpuSamplerOffset >= 0) && (dxLayout != null) && (dxLayout.SamplerCount > 0))
		{
			let rootIdx = layout.GetSamplerRootIndex(index);
			if (rootIdx >= 0)
			{
				cmdList.SetComputeRootDescriptorTable((uint32)rootIdx,
					mCtx.GpuSamplerHeap.GetGpuHandle((uint32)dxGroup.GpuSamplerOffset));
			}
		}

		// Dynamic offsets are root descriptors, so they take a GPU ADDRESS rather than a
		// table slot and are never staged.
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
		if (mCurrentPipeline == null)
			return;

		let layout = mCurrentPipeline.PipelineLayout;
		if ((layout == null) || (layout.PushConstantRootIndex < 0))
			return;

		// Both offset and size are in BYTES here and in 32 bit words there.
		mCtx.CmdList.SetComputeRoot32BitConstants((uint32)layout.PushConstantRootIndex, size / 4,
			data, offset / 4);
	}

	public void Dispatch(uint32 x, uint32 y = 1, uint32 z = 1) => mCtx.CmdList.Dispatch(x, y, z);

	public void DispatchIndirect(IBuffer buffer, uint64 offset)
	{
		let dxBuf = buffer as DxBuffer;
		if ((dxBuf == null) || (mCtx.DispatchSig == null))
			return;

		mCtx.CmdList.ExecuteIndirect(mCtx.DispatchSig, 1, dxBuf.Handle, offset, null, 0);
	}

	public void ComputeBarrier()
	{
		// A null resource makes this a GLOBAL UAV barrier: every unordered access completes
		// before any that follow.
		D3D12_RESOURCE_BARRIER barrier = .();
		barrier.Type = .D3D12_RESOURCE_BARRIER_TYPE_UAV;
		barrier.Flags = .D3D12_RESOURCE_BARRIER_FLAG_NONE;
		barrier.UAV.pResource = null;
		mCtx.CmdList.ResourceBarrier(1, &barrier);
	}

	public void WriteTimestamp(IQuerySet querySet, uint32 index)
	{
		if (let qs = querySet as DxQuerySet)
			mCtx.CmdList.EndQuery(qs.Handle, .D3D12_QUERY_TYPE_TIMESTAMP, index);
	}

	public void End() => mCurrentPipeline = null;
}
