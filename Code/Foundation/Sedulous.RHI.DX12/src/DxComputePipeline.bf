using System;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Win32;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// One compute pipeline state object.
///
/// The root signature comes from the layout and is NOT owned here: the layout outlives every
/// pipeline built against it.
class DxComputePipeline : IComputePipeline
{
	private ID3D12PipelineState* mPipelineState = null; // owned, released in Cleanup
	private DxPipelineLayout mLayout = null; // NOT owned

	public IPipelineLayout Layout => mLayout;
	public ID3D12PipelineState* Handle => mPipelineState;
	public DxPipelineLayout PipelineLayout => mLayout;

	public Result<void> Initialize(ID3D12Device* device, ComputePipelineDesc d)
	{
		mLayout = d.Layout as DxPipelineLayout;
		if (mLayout == null)
			return .Err;

		let csMod = d.Compute.Module as DxShaderModule;
		if (csMod == null)
			return .Err;

		let cs = csMod.Bytecode;

		D3D12_COMPUTE_PIPELINE_STATE_DESC pso = .();
		pso.pRootSignature = mLayout.Handle;
		pso.CS.pShaderBytecode = cs.Ptr;
		pso.CS.BytecodeLength = (uint)cs.Length;

		let hr = device.CreateComputePipelineState(&pso, ID3D12PipelineState.IID,
			(void**)&mPipelineState);
		if (FAILED(hr))
		{
			GlobalLog(.Error, "DxComputePipeline: CreateComputePipelineState failed (0x{0:X8})",
				(uint32)hr);
			return .Err;
		}

		return .Ok;
	}

	public void Cleanup()
	{
		if (mPipelineState != null)
		{
			mPipelineState.Release();
			mPipelineState = null;
		}
	}
}
