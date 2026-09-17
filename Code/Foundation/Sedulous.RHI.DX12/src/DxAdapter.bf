using System;
using System.Collections;
using System.Text;
using Sedulous.Core;
using Sedulous.RHI;
using Win32;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi;
using Win32.System.Com;

namespace Sedulous.RHI.DX12;

/// One physical adapter: what it is, what it supports, and how a device is made on it.
///
/// OWNERSHIP, which is two things at once here. The DXGI adapter is a COM object this holds
/// a reference to and releases in the destructor. The FACTORY is not: the backend owns that
/// and outlives every adapter it enumerated, so this only names it.
///
/// Devices created through this will be OWNED here, the way the Vulkan adapter owns its own,
/// so a caller never has to decide who deletes one. CreateDevice cannot make one yet, so
/// there is nothing to hold; the list lands with DxDevice.
class DxAdapter : IAdapter
{
	private IDXGIAdapter1* mAdapter = null; // owned, released in the destructor
	private IDXGIFactory4* mFactory = null; // NOT owned, the backend's
	private DXGI_ADAPTER_DESC1 mDesc = .();

	public this(IDXGIAdapter1* adapter, IDXGIFactory4* factory)
	{
		mAdapter = adapter;
		mFactory = factory;
		mAdapter.GetDesc1(&mDesc);
	}

	public ~this()
	{
		if (mAdapter != null)
		{
			mAdapter.Release();
			mAdapter = null;
		}
	}

	public IDXGIAdapter1* Handle => mAdapter;
	public IDXGIFactory4* Factory => mFactory;
	public DXGI_ADAPTER_DESC1 AdapterDesc => mDesc;

	public void GetInfo(AdapterInfo outInfo)
	{
		// The DXGI description is a UTF-16 WCHAR array, so it transcodes rather than copies.
		outInfo.Name.Clear();
		UTF16.Decode(&mDesc.Description[0], outInfo.Name);

		outInfo.VendorId = mDesc.VendorId;
		outInfo.DeviceId = mDesc.DeviceId;
		outInfo.Type = (mDesc.DedicatedVideoMemory > 0) ? .DiscreteGpu : .IntegratedGpu;
		outInfo.SupportedFeatures = BuildFeatures();
	}

	/// What this adapter supports, answered by creating a THROWAWAY device.
	///
	/// D3D12 has no way to ask an adapter about features without a device on it, so one is
	/// made and released here. Released on every path, including the early ones: this runs
	/// during enumeration, so a leak would be one device object per adapter per listing.
	public DeviceFeatures BuildFeatures()
	{
		DeviceFeatures f = .();

		ID3D12Device* tempDevice = null;
		let hr = D3D12CreateDevice((IUnknown*)mAdapter, .D3D_FEATURE_LEVEL_12_0,
			ID3D12Device.IID, (void**)&tempDevice);
		if (FAILED(hr) || (tempDevice == null))
			return f;
		defer tempDevice.Release();

		D3D12_FEATURE_DATA_D3D12_OPTIONS options = .();
		if (SUCCEEDED(tempDevice.CheckFeatureSupport(.D3D12_FEATURE_D3D12_OPTIONS, &options,
			(uint32)sizeof(D3D12_FEATURE_DATA_D3D12_OPTIONS))))
		{
			f.BindlessDescriptors = true; // DX12 always supports descriptor indexing
			f.TimestampQueries = true;
			f.OcclusionQueries = true; // BeginQuery works anywhere in a pass
			f.BorderSampling = true;
			f.MultiDrawIndirect = true;
			f.DepthClamp = true;
			f.FillModeWireframe = true;
			f.TextureCompressionBC = true;
			f.TextureCompressionASTC = false;
			f.IndependentBlend = true;
			f.MultiViewport = true;
			f.PipelineStatisticsQueries = true;
		}

		D3D12_FEATURE_DATA_D3D12_OPTIONS7 options7 = .();
		if (SUCCEEDED(tempDevice.CheckFeatureSupport(.D3D12_FEATURE_D3D12_OPTIONS7, &options7,
			(uint32)sizeof(D3D12_FEATURE_DATA_D3D12_OPTIONS7))))
		{
			f.MeshShaders = options7.MeshShaderTier != .D3D12_MESH_SHADER_TIER_NOT_SUPPORTED;
		}

		D3D12_FEATURE_DATA_D3D12_OPTIONS5 options5 = .();
		if (SUCCEEDED(tempDevice.CheckFeatureSupport(.D3D12_FEATURE_D3D12_OPTIONS5, &options5,
			(uint32)sizeof(D3D12_FEATURE_DATA_D3D12_OPTIONS5))))
		{
			f.RayTracing = options5.RaytracingTier != .D3D12_RAYTRACING_TIER_NOT_SUPPORTED;
		}

		// Conservative limits for D3D12 feature level 12.0.
		f.MaxBindGroups = 32;
		f.MaxBindingsPerGroup = 1000000;
		f.MaxPushConstantSize = 128;
		f.MaxTextureDimension2D = 16384;
		f.MaxTextureArrayLayers = 2048;
		f.MaxComputeWorkgroupSizeX = 1024;
		f.MaxComputeWorkgroupSizeY = 1024;
		f.MaxComputeWorkgroupSizeZ = 64;
		f.MaxComputeWorkgroupsPerDimension = 65535;
		f.MaxBufferSize = (uint64)mDesc.DedicatedVideoMemory;
		f.MinUniformBufferOffsetAlignment = 256;
		f.MinStorageBufferOffsetAlignment = 16;
		f.TimestampPeriodNs = 1; // DX12 timestamps are ticks; the period is queried at run time
		return f;
	}

	public Result<IDevice> CreateDevice(DeviceDesc desc)
	{
		// Lands with DxDevice, which is what this has to construct.
		return .Err;
	}
}
