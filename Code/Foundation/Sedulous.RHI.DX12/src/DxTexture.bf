using System;
using System.Collections;
using Sedulous.Core.Logging;
using Sedulous.RHI;
using Win32;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;

namespace Sedulous.RHI.DX12;

/// One committed texture resource, and the resource states of its subresources.
///
/// STATE TRACKING is the substance here. A texture is usually in ONE state, which is a single
/// value and one barrier. Once part of it moves on its own, it goes per subresource, and the
/// two modes are not interchangeable: see HasUniformState before reading CurrentState.
///
/// The resource is owned unless it came from a swap chain, and either way this holds a
/// reference it gives up in Cleanup.
class DxTexture : ITexture
{
	private TextureDesc mDesc = .();
	private ID3D12Resource* mResource = null;
	private D3D12_RESOURCE_STATES mState = .D3D12_RESOURCE_STATE_COMMON;
	private List<D3D12_RESOURCE_STATES> mSubresourceStates = new .() ~ delete _;
	private bool mOwnsResource = true;

	public TextureDesc Desc => mDesc;
	public ResourceState InitialState { get; set; } = .Undefined;
	public ID3D12Resource* Handle => mResource;
	public bool OwnsResource => mOwnsResource;

	public Result<void> Initialize(ID3D12Device* device, TextureDesc d)
	{
		mDesc = d;

		// A depth texture is created TYPELESS, so a view can read it as depth and another as
		// stencil. The clear value still names the real format.
		let format = TextureFormats.IsDepthFormat(d.Format)
			? DxConversions.ToTypelessDepthFormat(d.Format)
			: DxConversions.ToDxgiFormat(d.Format);

		D3D12_RESOURCE_DESC rd = .();
		rd.Dimension = DxConversions.ToResourceDimension(d.Dimension);
		rd.Width = (uint64)d.Width;
		rd.Height = d.Height;
		rd.DepthOrArraySize = (uint16)((d.Dimension == .Texture3D) ? d.Depth : d.ArrayLayerCount);
		rd.MipLevels = (uint16)d.MipLevelCount;
		rd.Format = format;
		rd.SampleDesc.Count = d.SampleCount;
		rd.SampleDesc.Quality = 0;
		rd.Layout = .D3D12_TEXTURE_LAYOUT_UNKNOWN;
		rd.Flags = DxConversions.ToTextureResourceFlags(d.Usage);

		D3D12_HEAP_PROPERTIES heapProps = .();
		heapProps.Type = .D3D12_HEAP_TYPE_DEFAULT;

		mState = .D3D12_RESOURCE_STATE_COMMON;

		// An OPTIMISED CLEAR VALUE, which a render target or depth buffer wants: creating one
		// without it and then clearing to this costs a slow path on some drivers.
		D3D12_CLEAR_VALUE clearVal = .();
		D3D12_CLEAR_VALUE* pClearVal = null;

		if (d.Usage.HasFlag(.DepthStencil))
		{
			clearVal.Format = DxConversions.ToDxgiFormat(d.Format);
			clearVal.DepthStencil.Depth = 1.0f;
			clearVal.DepthStencil.Stencil = 0;
			pClearVal = &clearVal;
			mState = .D3D12_RESOURCE_STATE_DEPTH_WRITE;
		}
		else if (d.Usage.HasFlag(.RenderTarget))
		{
			clearVal.Format = format;
			clearVal.Color = .(0, 0, 0, 1);
			pClearVal = &clearVal;
			mState = .D3D12_RESOURCE_STATE_RENDER_TARGET;
		}

		let hr = device.CreateCommittedResource(&heapProps, .D3D12_HEAP_FLAG_NONE, &rd, mState,
			pClearVal, ID3D12Resource.IID, (void**)&mResource);
		if (FAILED(hr))
		{
			GlobalLog(.Error, "DxTexture: CreateCommittedResource failed (0x{0:X8})", (uint32)hr);
			return .Err;
		}

		mOwnsResource = true;
		return .Ok;
	}

	/// Describe a resource this did NOT create, which is what a swap chain back buffer is.
	///
	/// A reference is TAKEN here and given up in Cleanup, so the buffer cannot go out from
	/// under the texture; the swap chain keeps its own.
	public void InitializeFromExisting(ID3D12Resource* resource, TextureDesc d)
	{
		mResource = resource;
		mResource.AddRef();
		mDesc = d;
		mOwnsResource = false;
		mState = .D3D12_RESOURCE_STATE_PRESENT;
	}

	public void Cleanup()
	{
		mSubresourceStates.Clear();

		if (mResource != null)
		{
			mResource.Release();
			mResource = null;
		}
	}

	/// Whether every subresource shares one state.
	///
	/// READ THIS BEFORE CurrentState. In per subresource mode mState is a leftover, NOT the
	/// resource's state, so CurrentState lies and SetState would additionally erase the per
	/// subresource truth. A caller that wants to move the WHOLE resource must either check
	/// this first or go through TransitionWhole, which handles both modes.
	public bool HasUniformState => mSubresourceStates.IsEmpty;

	/// Subresource grid, matching the indexing the state accessors use.
	public uint32 StateLayerCount =>
		Math.Max((mDesc.Dimension == .Texture3D) ? mDesc.Depth : mDesc.ArrayLayerCount, 1);

	/// Only meaningful when HasUniformState.
	public D3D12_RESOURCE_STATES CurrentState => mState;

	/// Declares the WHOLE resource to be in `s`, dropping any per subresource tracking, so
	/// only call it when every subresource really was transitioned.
	public void SetState(D3D12_RESOURCE_STATES s)
	{
		mState = s;
		mSubresourceStates.Clear();
	}

	public D3D12_RESOURCE_STATES GetSubresourceState(uint32 mip, uint32 layer)
	{
		if (mSubresourceStates.IsEmpty)
			return mState;

		let idx = (int)(mip + layer * mDesc.MipLevelCount);
		return (idx < mSubresourceStates.Count) ? mSubresourceStates[idx] : mState;
	}

	public void SetSubresourceState(uint32 baseMip, uint32 mipCount, uint32 baseLayer,
		uint32 layerCount, D3D12_RESOURCE_STATES s)
	{
		let totalMips = mDesc.MipLevelCount;
		let totalLayers = StateLayerCount;
		let mipEnd = (mipCount == uint32.MaxValue)
			? totalMips
			: Math.Min(baseMip + mipCount, totalMips);
		let layerEnd = (layerCount == uint32.MaxValue)
			? totalLayers
			: Math.Min(baseLayer + layerCount, totalLayers);

		// All of it? Collapse back to uniform.
		if ((baseMip == 0) && (mipEnd >= totalMips) && (baseLayer == 0) && (layerEnd >= totalLayers))
		{
			mState = s;
			mSubresourceStates.Clear();
			return;
		}

		// Promote to per subresource.
		if (mSubresourceStates.IsEmpty)
		{
			if (s == mState)
				return;
			mSubresourceStates.Resize((int)(totalMips * totalLayers), mState);
		}

		for (uint32 l = baseLayer; l < layerEnd; l++)
			for (uint32 m = baseMip; m < mipEnd; m++)
				mSubresourceStates[(int)(m + l * totalMips)] = s;

		// And collapse again if that happened to make it uniform.
		let first = mSubresourceStates[0];
		for (int i = 1; i < mSubresourceStates.Count; i++)
		{
			if (mSubresourceStates[i] != first)
				return;
		}

		mState = first;
		mSubresourceStates.Clear();
	}

	/// Move an ENTIRE texture to `after`, from whatever its subresources are actually in, and
	/// leave the tracker uniform.
	///
	/// The obvious spelling, one ALL_SUBRESOURCES barrier from CurrentState, is only correct
	/// while the texture is uniform. In per subresource mode it reads a stale state and the
	/// debug layer rejects the barrier: "Before state does not match with the state specified
	/// in the previous call to ResourceBarrier". Every caller that wants whole resource
	/// movement should come through here rather than re-deriving it.
	public static void TransitionWhole(ID3D12GraphicsCommandList* cmdList, DxTexture tex,
		D3D12_RESOURCE_STATES after)
	{
		if ((cmdList == null) || (tex == null))
			return;

		D3D12_RESOURCE_BARRIER b = .();
		b.Type = .D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
		b.Transition.pResource = tex.Handle;
		b.Transition.StateAfter = after;

		if (tex.HasUniformState)
		{
			let before = tex.CurrentState;
			if (before == after)
				return;

			b.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
			b.Transition.StateBefore = before;
			cmdList.ResourceBarrier(1, &b);
			tex.SetState(after);
			return;
		}

		// Mixed: one barrier per subresource that is not already there, then collapse.
		let mips = tex.Desc.MipLevelCount;
		let layers = tex.StateLayerCount;
		for (uint32 layer = 0; layer < layers; layer++)
		{
			for (uint32 mip = 0; mip < mips; mip++)
			{
				let before = tex.GetSubresourceState(mip, layer);
				if (before == after)
					continue;

				b.Transition.Subresource = mip + layer * mips;
				b.Transition.StateBefore = before;
				cmdList.ResourceBarrier(1, &b);
			}
		}

		tex.SetState(after); // every subresource is now `after`, so uniform is the truth
	}
}
