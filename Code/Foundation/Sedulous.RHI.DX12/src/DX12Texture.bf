namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;
using Sedulous.RHI;

using static Sedulous.RHI.TextureFormatExt;

/// DX12 implementation of ITexture.
class DX12Texture : ITexture
{
	private ID3D12Resource* mResource;
	private TextureDesc mDesc;
	private D3D12_RESOURCE_STATES mState;
	private ResourceState mInitialState = .Undefined;
	private bool mOwnsResource = true;

	public TextureDesc Desc => mDesc;
	public ResourceState InitialState => mInitialState;

	public this() { }

	/// Initialize from a TextureDesc (creates committed resource).
	public Result<void> Init(DX12Device device, TextureDesc desc)
	{
		mDesc = desc;

		DXGI_FORMAT format = desc.Format.IsDepthStencil()
			? DX12Conversions.ToTypelessDepthFormat(desc.Format)
			: DX12Conversions.ToDxgiFormat(desc.Format);

		D3D12_RESOURCE_DESC resourceDesc = .()
		{
			Dimension = DX12Conversions.ToResourceDimension(desc.Dimension),
			Alignment = 0,
			Width = (uint64)desc.Width,
			Height = desc.Height,
			DepthOrArraySize = (uint16)((desc.Dimension == .Texture3D) ? desc.Depth : desc.ArrayLayerCount),
			MipLevels = (uint16)desc.MipLevelCount,
			Format = format,
			SampleDesc = .() { Count = desc.SampleCount, Quality = 0 },
			Layout = .D3D12_TEXTURE_LAYOUT_UNKNOWN,
			Flags = DX12Conversions.ToResourceFlags(desc.Usage)
		};

		D3D12_HEAP_PROPERTIES heapProps = .()
		{
			Type = .D3D12_HEAP_TYPE_DEFAULT,
			CPUPageProperty = .D3D12_CPU_PAGE_PROPERTY_UNKNOWN,
			MemoryPoolPreference = .D3D12_MEMORY_POOL_UNKNOWN,
			CreationNodeMask = 0,
			VisibleNodeMask = 0
		};

		// Determine initial state
		mState = .D3D12_RESOURCE_STATE_COMMON;

		// Set clear value for render targets / depth stencil
		D3D12_CLEAR_VALUE* clearValue = null;
		D3D12_CLEAR_VALUE clearVal = default;
		if (desc.Usage.HasFlag(.DepthStencil))
		{
			clearVal.Format = DX12Conversions.ToDxgiFormat(desc.Format);
			clearVal.DepthStencil.Depth = 1.0f;
			clearVal.DepthStencil.Stencil = 0;
			clearValue = &clearVal;
			mState = .D3D12_RESOURCE_STATE_DEPTH_WRITE;
			mInitialState = .DepthStencilWrite;
		}
		else if (desc.Usage.HasFlag(.RenderTarget))
		{
			clearVal.Format = format;
			clearVal.Color = .(0, 0, 0, 1);
			clearValue = &clearVal;
			mState = .D3D12_RESOURCE_STATE_RENDER_TARGET;
			mInitialState = .RenderTarget;
		}

		HRESULT hr = device.Handle.CreateCommittedResource(
			&heapProps, .D3D12_HEAP_FLAG_NONE,
			&resourceDesc, mState, clearValue,
			ID3D12Resource.IID, (void**)&mResource);

		if (!SUCCEEDED(hr))
		{
			System.Diagnostics.Debug.WriteLine(scope $"DX12Texture: CreateCommittedResource failed (0x{hr:X})");
			return .Err;
		}

		return .Ok;
	}

	/// Initialize from an existing ID3D12Resource (e.g. swap chain buffer). Does not own.
	public void InitFromExisting(ID3D12Resource* resource, TextureDesc desc)
	{
		mResource = resource;
		mDesc = desc;
		mOwnsResource = false;
		mState = .D3D12_RESOURCE_STATE_PRESENT;
		mInitialState = .Present;
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
	public D3D12_RESOURCE_STATES State { get => mState; set => mState = value; }
}
