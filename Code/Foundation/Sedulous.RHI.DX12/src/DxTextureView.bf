#if BF_PLATFORM_WINDOWS
using System;
using Sedulous.RHI;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;

namespace Sedulous.RHI.DX12;

/// One view onto a texture, as up to four D3D12 descriptors.
///
/// Unlike Vulkan, where a view IS an object, D3D12 has a different descriptor per USE: a
/// shader resource, a render target, a depth stencil and an unordered access view are four
/// different writes into three different heaps. So this holds the description and cuts each
/// descriptor LAZILY, the first time that use is asked for, rather than making four up front
/// and wasting three slots on every view.
///
/// None of the heaps are owned; they belong to the device. Cleanup gives back only the slots
/// actually taken.
class DxTextureView : ITextureView
{
	private ID3D12Device* mDevice = null; // NOT owned, the device's
	private DxTexture mTexture = null; // NOT owned, the texture outlives its views
	private TextureViewDesc mViewDesc = .();
	private readonly uint64 mUniqueId = TextureViewIds.Next();

	private DxDescriptorHeapAllocator mSrvHeap = null; // none owned, all the device's
	private DxDescriptorHeapAllocator mRtvHeap = null;
	private DxDescriptorHeapAllocator mDsvHeap = null;

	private D3D12_CPU_DESCRIPTOR_HANDLE mSrv = .();
	private D3D12_CPU_DESCRIPTOR_HANDLE mRtv = .();
	private D3D12_CPU_DESCRIPTOR_HANDLE mDsv = .();
	private D3D12_CPU_DESCRIPTOR_HANDLE mUav = .();
	private bool mHasSrv = false;
	private bool mHasRtv = false;
	private bool mHasDsv = false;
	private bool mHasUav = false;

	public TextureViewDesc Desc => mViewDesc;
	public ITexture Texture => mTexture;
	public uint64 UniqueId => mUniqueId;
	public DxTexture DxTextureHandle => mTexture;

	/// The view's format, which falls back to the texture's when the view named none.
	public TextureFormat Format =>
		(mViewDesc.Format == .Undefined) ? mTexture.Desc.Format : mViewDesc.Format;

	/// BASE MIP extent: a view onto mip N is half sized per level. DX12 has no Vulkan style
	/// render area validation, so a stale base size here would not fault, but callers such as
	/// the render graph's viewport default expect the view's true dimensions. Keep it correct
	/// and consistent with Vulkan.
	public uint32 Width
	{
		get
		{
			let w = mTexture.Desc.Width >> mViewDesc.BaseMipLevel;
			return (w != 0) ? w : 1;
		}
	}

	public uint32 Height
	{
		get
		{
			let h = mTexture.Desc.Height >> mViewDesc.BaseMipLevel;
			return (h != 0) ? h : 1;
		}
	}

	public Result<void> Initialize(ID3D12Device* device, DxTexture tex, TextureViewDesc d,
		DxDescriptorHeapAllocator srvHeap, DxDescriptorHeapAllocator rtvHeap,
		DxDescriptorHeapAllocator dsvHeap)
	{
		mDevice = device;
		mTexture = tex;
		mViewDesc = d;
		mSrvHeap = srvHeap;
		mRtvHeap = rtvHeap;
		mDsvHeap = dsvHeap;
		return .Ok;
	}

	public D3D12_CPU_DESCRIPTOR_HANDLE GetSrv()
	{
		if (mHasSrv)
			return mSrv;

		let fmt = Format;
		// A depth texture is stored typeless, so reading it as a shader resource names the
		// readable form rather than the depth one.
		let srvFmt = TextureFormats.IsDepthFormat(fmt)
			? DxConversions.ToDepthSrvFormat(fmt)
			: DxConversions.ToDxgiFormat(fmt);

		D3D12_SHADER_RESOURCE_VIEW_DESC sd = .();
		sd.Format = srvFmt;
		sd.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;

		var mips = mViewDesc.MipLevelCount;
		if (mips == 0)
			mips = mTexture.Desc.MipLevelCount - mViewDesc.BaseMipLevel;

		switch (mViewDesc.Dimension)
		{
		case .Texture1D:
			sd.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE1D;
			sd.Texture1D.MostDetailedMip = mViewDesc.BaseMipLevel;
			sd.Texture1D.MipLevels = mips;
		case .Texture1DArray:
			sd.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE1DARRAY;
			sd.Texture1DArray.MostDetailedMip = mViewDesc.BaseMipLevel;
			sd.Texture1DArray.MipLevels = mips;
			sd.Texture1DArray.FirstArraySlice = mViewDesc.BaseArrayLayer;
			sd.Texture1DArray.ArraySize = mViewDesc.ArrayLayerCount;
		case .Texture2D:
			if (mTexture.Desc.SampleCount > 1)
			{
				sd.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE2DMS;
			}
			else
			{
				sd.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE2D;
				sd.Texture2D.MostDetailedMip = mViewDesc.BaseMipLevel;
				sd.Texture2D.MipLevels = mips;
			}
		case .Texture2DArray:
			if (mTexture.Desc.SampleCount > 1)
			{
				sd.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE2DMSARRAY;
				sd.Texture2DMSArray.FirstArraySlice = mViewDesc.BaseArrayLayer;
				sd.Texture2DMSArray.ArraySize = mViewDesc.ArrayLayerCount;
			}
			else
			{
				sd.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE2DARRAY;
				sd.Texture2DArray.MostDetailedMip = mViewDesc.BaseMipLevel;
				sd.Texture2DArray.MipLevels = mips;
				sd.Texture2DArray.FirstArraySlice = mViewDesc.BaseArrayLayer;
				sd.Texture2DArray.ArraySize = mViewDesc.ArrayLayerCount;
			}
		case .TextureCube:
			sd.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURECUBE;
			sd.TextureCube.MostDetailedMip = mViewDesc.BaseMipLevel;
			sd.TextureCube.MipLevels = mips;
		case .TextureCubeArray:
			sd.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURECUBEARRAY;
			sd.TextureCubeArray.MostDetailedMip = mViewDesc.BaseMipLevel;
			sd.TextureCubeArray.MipLevels = mips;
			sd.TextureCubeArray.First2DArrayFace = mViewDesc.BaseArrayLayer;
			sd.TextureCubeArray.NumCubes = mViewDesc.ArrayLayerCount / 6;
		case .Texture3D:
			sd.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE3D;
			sd.Texture3D.MostDetailedMip = mViewDesc.BaseMipLevel;
			sd.Texture3D.MipLevels = mips;
		}

		mSrv = mSrvHeap.Allocate();
		mDevice.CreateShaderResourceView(mTexture.Handle, &sd, mSrv);
		mHasSrv = true;
		return mSrv;
	}

	public D3D12_CPU_DESCRIPTOR_HANDLE GetRtv()
	{
		if (mHasRtv)
			return mRtv;

		let isArray = mTexture.Desc.ArrayLayerCount > 1;

		D3D12_RENDER_TARGET_VIEW_DESC rd = .();
		rd.Format = DxConversions.ToDxgiFormat(Format);

		if (mViewDesc.Dimension == .Texture2D)
		{
			if (isArray)
			{
				if (mTexture.Desc.SampleCount > 1)
				{
					rd.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2DMSARRAY;
					rd.Texture2DMSArray.FirstArraySlice = mViewDesc.BaseArrayLayer;
					rd.Texture2DMSArray.ArraySize = mViewDesc.ArrayLayerCount;
				}
				else
				{
					rd.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2DARRAY;
					rd.Texture2DArray.MipSlice = mViewDesc.BaseMipLevel;
					rd.Texture2DArray.FirstArraySlice = mViewDesc.BaseArrayLayer;
					rd.Texture2DArray.ArraySize = mViewDesc.ArrayLayerCount;
				}
			}
			else if (mTexture.Desc.SampleCount > 1)
			{
				rd.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2DMS;
			}
			else
			{
				rd.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2D;
				rd.Texture2D.MipSlice = mViewDesc.BaseMipLevel;
			}
		}
		else if (mViewDesc.Dimension == .Texture3D)
		{
			rd.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE3D;
			rd.Texture3D.MipSlice = mViewDesc.BaseMipLevel;
			rd.Texture3D.WSize = mViewDesc.ArrayLayerCount;
		}
		else
		{
			// 2DArray, Cube, CubeArray
			if (mTexture.Desc.SampleCount > 1)
			{
				rd.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2DMSARRAY;
				rd.Texture2DMSArray.FirstArraySlice = mViewDesc.BaseArrayLayer;
				rd.Texture2DMSArray.ArraySize = mViewDesc.ArrayLayerCount;
			}
			else
			{
				rd.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2DARRAY;
				rd.Texture2DArray.MipSlice = mViewDesc.BaseMipLevel;
				rd.Texture2DArray.FirstArraySlice = mViewDesc.BaseArrayLayer;
				rd.Texture2DArray.ArraySize = mViewDesc.ArrayLayerCount;
			}
		}

		mRtv = mRtvHeap.Allocate();
		mDevice.CreateRenderTargetView(mTexture.Handle, &rd, mRtv);
		mHasRtv = true;
		return mRtv;
	}

	public D3D12_CPU_DESCRIPTOR_HANDLE GetDsv()
	{
		if (mHasDsv)
			return mDsv;

		let isArray = mTexture.Desc.ArrayLayerCount > 1;

		D3D12_DEPTH_STENCIL_VIEW_DESC dd = .();
		dd.Format = DxConversions.ToDxgiFormat(Format);

		if (mViewDesc.Dimension == .Texture2D)
		{
			if (isArray)
			{
				if (mTexture.Desc.SampleCount > 1)
				{
					dd.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE2DMSARRAY;
					dd.Texture2DMSArray.FirstArraySlice = mViewDesc.BaseArrayLayer;
					dd.Texture2DMSArray.ArraySize = mViewDesc.ArrayLayerCount;
				}
				else
				{
					dd.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE2DARRAY;
					dd.Texture2DArray.MipSlice = mViewDesc.BaseMipLevel;
					dd.Texture2DArray.FirstArraySlice = mViewDesc.BaseArrayLayer;
					dd.Texture2DArray.ArraySize = mViewDesc.ArrayLayerCount;
				}
			}
			else if (mTexture.Desc.SampleCount > 1)
			{
				dd.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE2DMS;
			}
			else
			{
				dd.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE2D;
				dd.Texture2D.MipSlice = mViewDesc.BaseMipLevel;
			}
		}
		else
		{
			if (mTexture.Desc.SampleCount > 1)
			{
				dd.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE2DMSARRAY;
				dd.Texture2DMSArray.FirstArraySlice = mViewDesc.BaseArrayLayer;
				dd.Texture2DMSArray.ArraySize = mViewDesc.ArrayLayerCount;
			}
			else
			{
				dd.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE2DARRAY;
				dd.Texture2DArray.MipSlice = mViewDesc.BaseMipLevel;
				dd.Texture2DArray.FirstArraySlice = mViewDesc.BaseArrayLayer;
				dd.Texture2DArray.ArraySize = mViewDesc.ArrayLayerCount;
			}
		}

		mDsv = mDsvHeap.Allocate();
		mDevice.CreateDepthStencilView(mTexture.Handle, &dd, mDsv);
		mHasDsv = true;
		return mDsv;
	}

	public D3D12_CPU_DESCRIPTOR_HANDLE GetUav()
	{
		if (mHasUav)
			return mUav;

		D3D12_UNORDERED_ACCESS_VIEW_DESC ud = .();
		ud.Format = DxConversions.ToDxgiFormat(Format);

		switch (mViewDesc.Dimension)
		{
		case .Texture1D:
			ud.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE1D;
			ud.Texture1D.MipSlice = mViewDesc.BaseMipLevel;
		case .Texture1DArray:
			ud.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE1DARRAY;
			ud.Texture1DArray.MipSlice = mViewDesc.BaseMipLevel;
			ud.Texture1DArray.FirstArraySlice = mViewDesc.BaseArrayLayer;
			ud.Texture1DArray.ArraySize = mViewDesc.ArrayLayerCount;
		case .Texture2D:
			ud.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE2D;
			ud.Texture2D.MipSlice = mViewDesc.BaseMipLevel;
		case .Texture2DArray, .TextureCube, .TextureCubeArray:
			ud.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE2DARRAY;
			ud.Texture2DArray.MipSlice = mViewDesc.BaseMipLevel;
			ud.Texture2DArray.FirstArraySlice = mViewDesc.BaseArrayLayer;
			ud.Texture2DArray.ArraySize = mViewDesc.ArrayLayerCount;
		case .Texture3D:
			ud.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE3D;
			ud.Texture3D.MipSlice = mViewDesc.BaseMipLevel;
			ud.Texture3D.FirstWSlice = mViewDesc.BaseArrayLayer;
			ud.Texture3D.WSize = mViewDesc.ArrayLayerCount;
		}

		// A UAV comes out of the SHADER VISIBLE heap, the same one SRVs do.
		mUav = mSrvHeap.Allocate();
		mDevice.CreateUnorderedAccessView(mTexture.Handle, null, &ud, mUav);
		mHasUav = true;
		return mUav;
	}

	public void Cleanup()
	{
		// Only the slots actually cut are given back.
		if (mHasSrv)
		{
			mSrvHeap.Free(mSrv);
			mHasSrv = false;
		}
		if (mHasRtv)
		{
			mRtvHeap.Free(mRtv);
			mHasRtv = false;
		}
		if (mHasDsv)
		{
			mDsvHeap.Free(mDsv);
			mHasDsv = false;
		}
		if (mHasUav)
		{
			mSrvHeap.Free(mUav);
			mHasUav = false;
		}
	}
}

#endif // BF_PLATFORM_WINDOWS
