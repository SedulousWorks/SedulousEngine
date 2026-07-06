#if BF_PLATFORM_WINDOWS
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
	/// Per-subresource states, indexed as [mip + layer * mipCount]. Null when uniform.
	private D3D12_RESOURCE_STATES[] mSubresourceStates ~ delete _;
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

	/// Whole-resource state (uniform fast path). Setting this clears per-subresource state.
	public D3D12_RESOURCE_STATES State
	{
		get => mState;
		set
		{
			mState = value;
			DeleteAndNullify!(mSubresourceStates);
		}
	}

	/// Get the state for a specific subresource
	public D3D12_RESOURCE_STATES GetSubresourceState(uint32 mip, uint32 layer)
	{
		if (mSubresourceStates == null)
			return mState;
		let idx = mip + layer * mDesc.MipLevelCount;
		if (idx >= (uint32)mSubresourceStates.Count)
			return mState;
		return mSubresourceStates[idx];
	}

	/// Update state for a subresource range. Promotes to per-subresource tracking when needed.
	public void SetSubresourceState(uint32 baseMip, uint32 mipCount, uint32 baseLayer, uint32 layerCount, D3D12_RESOURCE_STATES state)
	{
		let totalMips = mDesc.MipLevelCount;
		let totalLayers = Math.Max((mDesc.Dimension == .Texture3D) ? mDesc.Depth : mDesc.ArrayLayerCount, 1);
		let resolvedMipEnd = (mipCount == uint32.MaxValue) ? totalMips : Math.Min(baseMip + mipCount, totalMips);
		let resolvedLayerEnd = (layerCount == uint32.MaxValue) ? totalLayers : Math.Min(baseLayer + layerCount, totalLayers);

		// All subresources? Collapse to uniform.
		if (baseMip == 0 && resolvedMipEnd >= totalMips && baseLayer == 0 && resolvedLayerEnd >= totalLayers)
		{
			mState = state;
			DeleteAndNullify!(mSubresourceStates);
			return;
		}

		// Promote to per-subresource
		if (mSubresourceStates == null)
		{
			if (state == mState) return;
			mSubresourceStates = new D3D12_RESOURCE_STATES[totalMips * totalLayers];
			for (int idx = 0; idx < mSubresourceStates.Count; idx++)
				mSubresourceStates[idx] = mState;
		}

		for (uint32 l = baseLayer; l < resolvedLayerEnd; l++)
			for (uint32 m = baseMip; m < resolvedMipEnd; m++)
				mSubresourceStates[m + l * totalMips] = state;

		// Try to collapse back to uniform
		let first = mSubresourceStates[0];
		for (int idx = 1; idx < mSubresourceStates.Count; idx++)
		{
			if (mSubresourceStates[idx] != first)
				return;
		}
		mState = first;
		DeleteAndNullify!(mSubresourceStates);
	}
}

#endif // BF_PLATFORM_WINDOWS
