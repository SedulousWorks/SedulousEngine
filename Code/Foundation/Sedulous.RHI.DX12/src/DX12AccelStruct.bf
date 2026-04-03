namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Sedulous.RHI;

/// DX12 implementation of IAccelStruct.
/// In DX12, acceleration structures are simply buffers in the
/// D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE state.
class DX12AccelStruct : IAccelStruct
{
	private ID3D12Resource* mResource;
	private AccelStructType mType;
	private uint64 mGpuAddress;
	private uint64 mSize;

	public AccelStructType Type => mType;
	public uint64 DeviceAddress => mGpuAddress;

	public this() { }

	public Result<void> Init(DX12Device device, AccelStructDesc desc, uint64 size)
	{
		mType = desc.Type;
		mSize = size;

		D3D12_HEAP_PROPERTIES heapProps = .()
		{
			Type = .D3D12_HEAP_TYPE_DEFAULT,
			CPUPageProperty = .D3D12_CPU_PAGE_PROPERTY_UNKNOWN,
			MemoryPoolPreference = .D3D12_MEMORY_POOL_UNKNOWN,
			CreationNodeMask = 0,
			VisibleNodeMask = 0
		};

		D3D12_RESOURCE_DESC resourceDesc = .()
		{
			Dimension = .D3D12_RESOURCE_DIMENSION_BUFFER,
			Alignment = 0,
			Width = size,
			Height = 1,
			DepthOrArraySize = 1,
			MipLevels = 1,
			Format = .DXGI_FORMAT_UNKNOWN,
			SampleDesc = .() { Count = 1, Quality = 0 },
			Layout = .D3D12_TEXTURE_LAYOUT_ROW_MAJOR,
			Flags = .D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS
		};

		HRESULT hr = device.Handle.CreateCommittedResource(
			&heapProps, .D3D12_HEAP_FLAG_NONE,
			&resourceDesc,
			.D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE,
			null,
			ID3D12Resource.IID, (void**)&mResource);

		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12AccelStruct: CreateCommittedResource failed (0x{hr:X})");
			return .Err;
		}

		mGpuAddress = mResource.GetGPUVirtualAddress();
		return .Ok;
	}

	public void Cleanup(DX12Device device)
	{
		if (mResource != null)
		{
			mResource.Release();
			mResource = null;
		}
	}

	// --- Internal ---
	public ID3D12Resource* Handle => mResource;
	public uint64 GpuAddress => mGpuAddress;
	public uint64 Size => mSize;
}
