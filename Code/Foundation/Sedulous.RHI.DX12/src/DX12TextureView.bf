namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;
using Sedulous.RHI;

using static Sedulous.RHI.TextureFormatExt;

/// DX12 implementation of ITextureView.
/// In DX12, views are CPU descriptor handles (SRV/UAV/RTV/DSV).
/// This class lazily creates the appropriate view on demand.
class DX12TextureView : ITextureView
{
	private DX12Texture mTexture;
	private TextureViewDesc mDesc;
	private DX12Device mDevice;

	// Lazily created descriptors
	private D3D12_CPU_DESCRIPTOR_HANDLE mSrv;
	private D3D12_CPU_DESCRIPTOR_HANDLE mRtv;
	private D3D12_CPU_DESCRIPTOR_HANDLE mDsv;
	private D3D12_CPU_DESCRIPTOR_HANDLE mUav;
	private bool mHasSrv;
	private bool mHasRtv;
	private bool mHasDsv;
	private bool mHasUav;

	public this() { }

	public Result<void> Init(DX12Device device, DX12Texture texture, TextureViewDesc desc)
	{
		mDevice = device;
		mTexture = texture;
		mDesc = desc;
		return .Ok;
	}

	/// Gets or creates a SRV for this view.
	public D3D12_CPU_DESCRIPTOR_HANDLE GetSrv()
	{
		if (mHasSrv) return mSrv;

		let format = (mDesc.Format == .Undefined) ? mTexture.Desc.Format : mDesc.Format;
		DXGI_FORMAT srvFormat;
		if (format.IsDepthStencil())
		{
			if (mDesc.Aspect == .StencilOnly)
				srvFormat = DX12Conversions.ToStencilSrvFormat(format);
			else
				srvFormat = DX12Conversions.ToDepthSrvFormat(format);
		}
		else
			srvFormat = DX12Conversions.ToDxgiFormat(format);

		D3D12_SHADER_RESOURCE_VIEW_DESC srvDesc = default;
		srvDesc.Format = srvFormat;
		srvDesc.Shader4ComponentMapping = 5768; // D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING

		uint32 mipCount = mDesc.MipLevelCount;
		if (mipCount == 0) mipCount = mTexture.Desc.MipLevelCount - mDesc.BaseMipLevel;

		switch (mDesc.Dimension)
		{
		case .Texture1D:
			srvDesc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE1D;
			srvDesc.Texture1D.MostDetailedMip = mDesc.BaseMipLevel;
			srvDesc.Texture1D.MipLevels = mipCount;
		case .Texture1DArray:
			srvDesc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE1DARRAY;
			srvDesc.Texture1DArray.MostDetailedMip = mDesc.BaseMipLevel;
			srvDesc.Texture1DArray.MipLevels = mipCount;
			srvDesc.Texture1DArray.FirstArraySlice = mDesc.BaseArrayLayer;
			srvDesc.Texture1DArray.ArraySize = mDesc.ArrayLayerCount;
		case .Texture2D:
			if (mTexture.Desc.SampleCount > 1)
			{
				srvDesc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE2DMS;
			}
			else
			{
				srvDesc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE2D;
				srvDesc.Texture2D.MostDetailedMip = mDesc.BaseMipLevel;
				srvDesc.Texture2D.MipLevels = mipCount;
				if (mDesc.Aspect == .StencilOnly)
					srvDesc.Texture2D.PlaneSlice = 1;
			}
		case .Texture2DArray:
			if (mTexture.Desc.SampleCount > 1)
			{
				srvDesc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE2DMSARRAY;
				srvDesc.Texture2DMSArray.FirstArraySlice = mDesc.BaseArrayLayer;
				srvDesc.Texture2DMSArray.ArraySize = mDesc.ArrayLayerCount;
			}
			else
			{
				srvDesc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE2DARRAY;
				srvDesc.Texture2DArray.MostDetailedMip = mDesc.BaseMipLevel;
				srvDesc.Texture2DArray.MipLevels = mipCount;
				srvDesc.Texture2DArray.FirstArraySlice = mDesc.BaseArrayLayer;
				srvDesc.Texture2DArray.ArraySize = mDesc.ArrayLayerCount;
				if (mDesc.Aspect == .StencilOnly)
					srvDesc.Texture2DArray.PlaneSlice = 1;
			}
		case .TextureCube:
			srvDesc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURECUBE;
			srvDesc.TextureCube.MostDetailedMip = mDesc.BaseMipLevel;
			srvDesc.TextureCube.MipLevels = mipCount;
		case .TextureCubeArray:
			srvDesc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURECUBEARRAY;
			srvDesc.TextureCubeArray.MostDetailedMip = mDesc.BaseMipLevel;
			srvDesc.TextureCubeArray.MipLevels = mipCount;
			srvDesc.TextureCubeArray.First2DArrayFace = mDesc.BaseArrayLayer;
			srvDesc.TextureCubeArray.NumCubes = mDesc.ArrayLayerCount / 6;
		case .Texture3D:
			srvDesc.ViewDimension = .D3D12_SRV_DIMENSION_TEXTURE3D;
			srvDesc.Texture3D.MostDetailedMip = mDesc.BaseMipLevel;
			srvDesc.Texture3D.MipLevels = mipCount;
		}

		mSrv = mDevice.SrvHeap.Allocate();
		mDevice.Handle.CreateShaderResourceView(mTexture.Handle, &srvDesc, mSrv);
		mHasSrv = true;
		return mSrv;
	}

	/// Gets or creates a RTV for this view.
	public D3D12_CPU_DESCRIPTOR_HANDLE GetRtv()
	{
		if (mHasRtv) return mRtv;

		let format = (mDesc.Format == .Undefined) ? mTexture.Desc.Format : mDesc.Format;

		D3D12_RENDER_TARGET_VIEW_DESC rtvDesc = default;
		rtvDesc.Format = DX12Conversions.ToDxgiFormat(format);

		// DX12 requires Texture2DArray RTV dimension for array resources,
		// even when viewing a single layer. Texture2D RTV ignores BaseArrayLayer.
		bool isArrayResource = mTexture.Desc.ArrayLayerCount > 1;

		switch (mDesc.Dimension)
		{
		case .Texture2D:
			if (isArrayResource)
			{
				// Single layer of an array texture — must use Array RTV dimension
				if (mTexture.Desc.SampleCount > 1)
				{
					rtvDesc.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2DMSARRAY;
					rtvDesc.Texture2DMSArray.FirstArraySlice = mDesc.BaseArrayLayer;
					rtvDesc.Texture2DMSArray.ArraySize = mDesc.ArrayLayerCount;
				}
				else
				{
					rtvDesc.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2DARRAY;
					rtvDesc.Texture2DArray.MipSlice = mDesc.BaseMipLevel;
					rtvDesc.Texture2DArray.FirstArraySlice = mDesc.BaseArrayLayer;
					rtvDesc.Texture2DArray.ArraySize = mDesc.ArrayLayerCount;
				}
			}
			else if (mTexture.Desc.SampleCount > 1)
			{
				rtvDesc.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2DMS;
			}
			else
			{
				rtvDesc.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2D;
				rtvDesc.Texture2D.MipSlice = mDesc.BaseMipLevel;
			}
		case .Texture2DArray, .TextureCube, .TextureCubeArray:
			if (mTexture.Desc.SampleCount > 1)
			{
				rtvDesc.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2DMSARRAY;
				rtvDesc.Texture2DMSArray.FirstArraySlice = mDesc.BaseArrayLayer;
				rtvDesc.Texture2DMSArray.ArraySize = mDesc.ArrayLayerCount;
			}
			else
			{
				rtvDesc.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2DARRAY;
				rtvDesc.Texture2DArray.MipSlice = mDesc.BaseMipLevel;
				rtvDesc.Texture2DArray.FirstArraySlice = mDesc.BaseArrayLayer;
				rtvDesc.Texture2DArray.ArraySize = mDesc.ArrayLayerCount;
			}
		case .Texture3D:
			rtvDesc.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE3D;
			rtvDesc.Texture3D.MipSlice = mDesc.BaseMipLevel;
			rtvDesc.Texture3D.WSize = mDesc.ArrayLayerCount;
		default:
			if (mTexture.Desc.SampleCount > 1)
			{
				rtvDesc.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2DMS;
			}
			else
			{
				rtvDesc.ViewDimension = .D3D12_RTV_DIMENSION_TEXTURE2D;
				rtvDesc.Texture2D.MipSlice = mDesc.BaseMipLevel;
			}
		}

		mRtv = mDevice.RtvHeap.Allocate();
		mDevice.Handle.CreateRenderTargetView(mTexture.Handle, &rtvDesc, mRtv);
		mHasRtv = true;
		return mRtv;
	}

	/// Gets or creates a DSV for this view.
	public D3D12_CPU_DESCRIPTOR_HANDLE GetDsv()
	{
		if (mHasDsv) return mDsv;

		let format = (mDesc.Format == .Undefined) ? mTexture.Desc.Format : mDesc.Format;

		D3D12_DEPTH_STENCIL_VIEW_DESC dsvDesc = default;
		dsvDesc.Format = DX12Conversions.ToDxgiFormat(format);

		// DX12 requires Texture2DArray DSV dimension for array resources,
		// even when viewing a single layer. Texture2D DSV ignores BaseArrayLayer.
		bool isArrayResource = mTexture.Desc.ArrayLayerCount > 1;

		switch (mDesc.Dimension)
		{
		case .Texture2D:
			if (isArrayResource)
			{
				// Single layer of an array texture — must use Array DSV dimension
				if (mTexture.Desc.SampleCount > 1)
				{
					dsvDesc.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE2DMSARRAY;
					dsvDesc.Texture2DMSArray.FirstArraySlice = mDesc.BaseArrayLayer;
					dsvDesc.Texture2DMSArray.ArraySize = mDesc.ArrayLayerCount;
				}
				else
				{
					dsvDesc.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE2DARRAY;
					dsvDesc.Texture2DArray.MipSlice = mDesc.BaseMipLevel;
					dsvDesc.Texture2DArray.FirstArraySlice = mDesc.BaseArrayLayer;
					dsvDesc.Texture2DArray.ArraySize = mDesc.ArrayLayerCount;
				}
			}
			else if (mTexture.Desc.SampleCount > 1)
			{
				dsvDesc.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE2DMS;
			}
			else
			{
				dsvDesc.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE2D;
				dsvDesc.Texture2D.MipSlice = mDesc.BaseMipLevel;
			}
		case .Texture2DArray:
			if (mTexture.Desc.SampleCount > 1)
			{
				dsvDesc.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE2DMSARRAY;
				dsvDesc.Texture2DMSArray.FirstArraySlice = mDesc.BaseArrayLayer;
				dsvDesc.Texture2DMSArray.ArraySize = mDesc.ArrayLayerCount;
			}
			else
			{
				dsvDesc.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE2DARRAY;
				dsvDesc.Texture2DArray.MipSlice = mDesc.BaseMipLevel;
				dsvDesc.Texture2DArray.FirstArraySlice = mDesc.BaseArrayLayer;
				dsvDesc.Texture2DArray.ArraySize = mDesc.ArrayLayerCount;
			}
		default:
			if (mTexture.Desc.SampleCount > 1)
			{
				dsvDesc.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE2DMS;
			}
			else
			{
				dsvDesc.ViewDimension = .D3D12_DSV_DIMENSION_TEXTURE2D;
				dsvDesc.Texture2D.MipSlice = mDesc.BaseMipLevel;
			}
		}

		mDsv = mDevice.DsvHeap.Allocate();
		mDevice.Handle.CreateDepthStencilView(mTexture.Handle, &dsvDesc, mDsv);
		mHasDsv = true;
		return mDsv;
	}

	/// Gets or creates a UAV for this view.
	public D3D12_CPU_DESCRIPTOR_HANDLE GetUav()
	{
		if (mHasUav) return mUav;

		let format = (mDesc.Format == .Undefined) ? mTexture.Desc.Format : mDesc.Format;

		D3D12_UNORDERED_ACCESS_VIEW_DESC uavDesc = default;
		uavDesc.Format = DX12Conversions.ToDxgiFormat(format);

		switch (mDesc.Dimension)
		{
		case .Texture1D:
			uavDesc.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE1D;
			uavDesc.Texture1D.MipSlice = mDesc.BaseMipLevel;
		case .Texture1DArray:
			uavDesc.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE1DARRAY;
			uavDesc.Texture1DArray.MipSlice = mDesc.BaseMipLevel;
			uavDesc.Texture1DArray.FirstArraySlice = mDesc.BaseArrayLayer;
			uavDesc.Texture1DArray.ArraySize = mDesc.ArrayLayerCount;
		case .Texture2D:
			uavDesc.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE2D;
			uavDesc.Texture2D.MipSlice = mDesc.BaseMipLevel;
		case .Texture2DArray, .TextureCube, .TextureCubeArray:
			uavDesc.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE2DARRAY;
			uavDesc.Texture2DArray.MipSlice = mDesc.BaseMipLevel;
			uavDesc.Texture2DArray.FirstArraySlice = mDesc.BaseArrayLayer;
			uavDesc.Texture2DArray.ArraySize = mDesc.ArrayLayerCount;
		case .Texture3D:
			uavDesc.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE3D;
			uavDesc.Texture3D.MipSlice = mDesc.BaseMipLevel;
			uavDesc.Texture3D.FirstWSlice = mDesc.BaseArrayLayer;
			uavDesc.Texture3D.WSize = mDesc.ArrayLayerCount;
		default:
			uavDesc.ViewDimension = .D3D12_UAV_DIMENSION_TEXTURE2D;
			uavDesc.Texture2D.MipSlice = mDesc.BaseMipLevel;
		}

		mUav = mDevice.SrvHeap.Allocate();
		mDevice.Handle.CreateUnorderedAccessView(mTexture.Handle, null, &uavDesc, mUav);
		mHasUav = true;
		return mUav;
	}

	public void Cleanup(DX12Device device)
	{
		if (mHasSrv) { device.SrvHeap.Free(mSrv); mHasSrv = false; }
		if (mHasRtv) { device.RtvHeap.Free(mRtv); mHasRtv = false; }
		if (mHasDsv) { device.DsvHeap.Free(mDsv); mHasDsv = false; }
		if (mHasUav) { device.SrvHeap.Free(mUav); mHasUav = false; }
	}

	// --- Interface ---
	public TextureViewDesc Desc => mDesc;
	public ITexture Texture => mTexture;

	// --- Internal ---
	public DX12Texture DX12Texture => mTexture;
}
