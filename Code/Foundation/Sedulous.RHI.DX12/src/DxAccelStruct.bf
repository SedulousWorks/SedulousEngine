#if BF_PLATFORM_WINDOWS
using System;
using Sedulous.RHI;
using Win32;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;

namespace Sedulous.RHI.DX12;

/// One acceleration structure's backing buffer.
///
/// Created at a DEFAULT SIZE and grown when a build needs more, so nothing has to know the
/// final size before the geometry is known. It is created directly in the raytracing
/// acceleration structure state, which is the only state it is ever in: D3D12 forbids
/// transitioning one.
class DxAccelStruct : IAccelStruct
{
	private AccelStructType mType = .BottomLevel;
	private uint64 mGpuAddr = 0;
	private ID3D12Resource* mResource = null; // owned, released in Cleanup

	public AccelStructType Type => mType;
	public uint64 DeviceAddress => mGpuAddr;
	public ID3D12Resource* Handle => mResource;

	public Result<void> Initialize(ID3D12Device* device, AccelStructDesc d)
	{
		mType = d.Type;

		D3D12_HEAP_PROPERTIES hp = .();
		hp.Type = .D3D12_HEAP_TYPE_DEFAULT;

		D3D12_RESOURCE_DESC rd = .();
		rd.Dimension = .D3D12_RESOURCE_DIMENSION_BUFFER;
		rd.Width = 256 * 1024; // 256 KB default, grown at build time
		rd.Height = 1;
		rd.DepthOrArraySize = 1;
		rd.MipLevels = 1;
		rd.Format = .DXGI_FORMAT_UNKNOWN;
		rd.SampleDesc.Count = 1;
		rd.SampleDesc.Quality = 0;
		rd.Layout = .D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
		rd.Flags = .D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;

		let hr = device.CreateCommittedResource(&hp, .D3D12_HEAP_FLAG_NONE, &rd,
			.D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE, null, ID3D12Resource.IID,
			(void**)&mResource);
		if (FAILED(hr))
			return .Err;

		mGpuAddr = mResource.GetGPUVirtualAddress();
		return .Ok;
	}

	public void Cleanup()
	{
		if (mResource != null)
		{
			mResource.Release();
			mResource = null;
		}
		mGpuAddr = 0;
	}
}

#endif // BF_PLATFORM_WINDOWS
