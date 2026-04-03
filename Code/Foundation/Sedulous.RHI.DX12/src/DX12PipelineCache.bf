namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Sedulous.RHI;

/// DX12 implementation of IPipelineCache.
/// Wraps ID3D12PipelineLibrary for caching compiled pipeline state.
class DX12PipelineCache : IPipelineCache
{
	private ID3D12PipelineLibrary* mLibrary;

	public this() { }

	public Result<void> Init(DX12Device device, PipelineCacheDesc desc)
	{
		// QueryInterface for ID3D12Device1 which has CreatePipelineLibrary
		ID3D12Device1* device1 = null;
		HRESULT hr = device.Handle.QueryInterface(ID3D12Device1.IID, (void**)&device1);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12PipelineCache: QueryInterface for ID3D12Device1 failed (0x{hr:X})");
			return .Err;
		}

		if (desc.InitialData.Length > 0)
		{
			hr = device1.CreatePipelineLibrary(
				desc.InitialData.Ptr, (uint)desc.InitialData.Length,
				ID3D12PipelineLibrary.IID, (void**)&mLibrary);
		}
		else
		{
			hr = device1.CreatePipelineLibrary(
				null, 0,
				ID3D12PipelineLibrary.IID, (void**)&mLibrary);
		}

		device1.Release();

		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12PipelineCache: CreatePipelineLibrary failed (0x{hr:X})");
			return .Err;
		}
		return .Ok;
	}

	public uint GetDataSize()
	{
		if (mLibrary == null) return 0;
		return (uint)mLibrary.GetSerializedSize();
	}

	public Result<int> GetData(Span<uint8> outData)
	{
		if (mLibrary == null)
		{
			System.Diagnostics.Debug.WriteLine("DX12PipelineCache: pipeline library is null");
			return .Err;
		}

		let size = mLibrary.GetSerializedSize();
		if ((uint)outData.Length < size)
		{
			System.Diagnostics.Debug.WriteLine("DX12PipelineCache: output buffer too small for serialized data");
			return .Err;
		}

		HRESULT hr = mLibrary.Serialize(outData.Ptr, size);
		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12PipelineCache: Serialize failed (0x{hr:X})");
			return .Err;
		}
		return .Ok((int)size);
	}

	public void Cleanup(DX12Device device)
	{
		if (mLibrary != null)
		{
			mLibrary.Release();
			mLibrary = null;
		}
	}

	// --- Internal ---
	public ID3D12PipelineLibrary* Handle => mLibrary;
}
