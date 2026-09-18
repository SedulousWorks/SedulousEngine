#if BF_PLATFORM_WINDOWS
using System;
using Sedulous.RHI;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;

namespace Sedulous.RHI.DX12;

/// The pipeline cache, which on D3D12 is a PIPELINE LIBRARY.
///
/// Unlike Vulkan's opaque blob, a library is a named collection the driver can serialise and
/// reload, so a later run skips recompilation. Reached through ID3D12Device1, which is why
/// this queries for the newer interface rather than using the device it was handed.
class DxPipelineCache : IPipelineCache
{
	private ID3D12PipelineLibrary* mLibrary = null; // owned, released in Cleanup

	public ID3D12PipelineLibrary* Handle => mLibrary;

	public Result<void> Initialize(ID3D12Device* device, PipelineCacheDesc d)
	{
		ID3D12Device1* device1 = null;
		if (FAILED(device.QueryInterface(ID3D12Device1.IID, (void**)&device1)))
			return .Err;
		// QueryInterface takes a reference; the library keeps its own once created.
		defer device1.Release();

		HRESULT hr;
		if (d.InitialData.Length > 0)
		{
			hr = device1.CreatePipelineLibrary(d.InitialData.Ptr, (uint)d.InitialData.Length,
				ID3D12PipelineLibrary.IID, (void**)&mLibrary);
		}
		else
		{
			hr = device1.CreatePipelineLibrary(null, 0, ID3D12PipelineLibrary.IID,
				(void**)&mLibrary);
		}

		return SUCCEEDED(hr) ? .Ok : .Err;
	}

	public uint32 GetDataSize()
	{
		if (mLibrary == null)
			return 0;
		return (uint32)mLibrary.GetSerializedSize();
	}

	public Result<void> GetData(Span<uint8> outData)
	{
		if (mLibrary == null)
			return .Err;

		let size = mLibrary.GetSerializedSize();
		if ((uint)outData.Length < size)
			return .Err;

		return SUCCEEDED(mLibrary.Serialize(outData.Ptr, size)) ? .Ok : .Err;
	}

	public void Cleanup()
	{
		if (mLibrary != null)
		{
			mLibrary.Release();
			mLibrary = null;
		}
	}
}

#endif // BF_PLATFORM_WINDOWS
