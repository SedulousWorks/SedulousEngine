namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Sedulous.RHI;

/// DX12 implementation of IComputePipeline.
/// Wraps a D3D12 compute pipeline state object.
class DX12ComputePipeline : IComputePipeline
{
	private ID3D12PipelineState* mPipelineState;
	private DX12PipelineLayout mLayout;

	public IPipelineLayout Layout => mLayout;

	public this() { }

	public Result<void> Init(DX12Device device, ComputePipelineDesc desc)
	{
		mLayout = desc.Layout as DX12PipelineLayout;
		if (mLayout == null)
		{
			System.Diagnostics.Debug.WriteLine("DX12ComputePipeline: pipeline layout is null");
			return .Err;
		}

		let csMod = desc.Compute.Module as DX12ShaderModule;
		if (csMod == null)
		{
			System.Diagnostics.Debug.WriteLine("DX12ComputePipeline: compute shader module is null");
			return .Err;
		}

		D3D12_COMPUTE_PIPELINE_STATE_DESC psoDesc = default;
		psoDesc.pRootSignature = mLayout.Handle;
		psoDesc.CS.pShaderBytecode = csMod.Bytecode.Ptr;
		psoDesc.CS.BytecodeLength = (uint)csMod.Bytecode.Length;

		// Try loading from pipeline library first
		let dxCache = desc.Cache as DX12PipelineCache;
		if (dxCache != null && dxCache.Handle != null && desc.Label.Length > 0)
		{
			let nameStr = scope String();
			nameStr.Append(desc.Label);
			let wideName = nameStr.ToScopedNativeWChar!();
			HRESULT hr = dxCache.Handle.LoadComputePipeline(wideName, &psoDesc,
				ID3D12PipelineState.IID, (void**)&mPipelineState);
			if (SUCCEEDED(hr))
				return .Ok;
		}

		// Create PSO
		HRESULT hr = device.Handle.CreateComputePipelineState(&psoDesc,
			ID3D12PipelineState.IID, (void**)&mPipelineState);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12ComputePipeline: CreateComputePipelineState failed (0x{hr:X})");
			return .Err;
		}

		// Store in pipeline library for future loads
		if (dxCache != null && dxCache.Handle != null && desc.Label.Length > 0)
		{
			let nameStr = scope String();
			nameStr.Append(desc.Label);
			let wideName = nameStr.ToScopedNativeWChar!();
			dxCache.Handle.StorePipeline(wideName, mPipelineState);
		}

		return .Ok;
	}

	public void Cleanup(DX12Device device)
	{
		if (mPipelineState != null)
		{
			mPipelineState.Release();
			mPipelineState = null;
		}
	}

	// --- Internal ---
	public ID3D12PipelineState* Handle => mPipelineState;
}
