namespace Sedulous.RHI.DX12;

using System;
using Win32;
using Win32.Foundation;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi;
using Win32.Graphics.Dxgi.Common;
using Sedulous.RHI;
using Win32.System.Com;

/// DX12 implementation of IAdapter.
class DX12Adapter : IAdapter
{
	private IDXGIAdapter1* mAdapter;
	private IDXGIFactory4* mFactory;
	private DXGI_ADAPTER_DESC1 mDesc;

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

	public AdapterInfo GetInfo()
	{
		let info = new AdapterInfo();

		// Convert wide string name to UTF8
		for (int i = 0; i < 128; i++)
		{
			let c = mDesc.Description[i];
			if (c == 0) break;
			info.Name.Append((char8)c); // Simple ASCII conversion for adapter names
		}

		info.VendorId = mDesc.VendorId;
		info.DeviceId = mDesc.DeviceId;

		// Determine adapter type from dedicated video memory
		if (mDesc.DedicatedVideoMemory > 0)
			info.Type = .DiscreteGpu;
		else
			info.Type = .IntegratedGpu;

		info.SupportedFeatures = BuildFeatures();
		return info;
	}

	public DeviceFeatures BuildFeatures()
	{
		// Create a temporary device to query features
		ID3D12Device* tempDevice = null;
		HRESULT hr = D3D12CreateDevice((IUnknown*)mAdapter, .D3D_FEATURE_LEVEL_12_0, ID3D12Device.IID, (void**)&tempDevice);
		if (!SUCCEEDED(hr) || tempDevice == null)
			return default;

		DeviceFeatures f = default;

		// Check feature support
		D3D12_FEATURE_DATA_D3D12_OPTIONS options = default;
		if (SUCCEEDED(tempDevice.CheckFeatureSupport(.D3D12_FEATURE_D3D12_OPTIONS, &options, sizeof(D3D12_FEATURE_DATA_D3D12_OPTIONS))))
		{
			f.BindlessDescriptors = true; // DX12 always supports descriptor indexing
			f.TimestampQueries = true;
			f.MultiDrawIndirect = true;
			f.DepthClamp = true;
			f.FillModeWireframe = true;
			f.TextureCompressionBC = true;
			f.TextureCompressionASTC = false; // Not supported on DX12
			f.IndependentBlend = true;
			f.MultiViewport = true;
			f.PipelineStatisticsQueries = true;
		}

		// Check mesh shader support
		D3D12_FEATURE_DATA_D3D12_OPTIONS7 options7 = default;
		if (SUCCEEDED(tempDevice.CheckFeatureSupport(.D3D12_FEATURE_D3D12_OPTIONS7, &options7, sizeof(D3D12_FEATURE_DATA_D3D12_OPTIONS7))))
		{
			f.MeshShaders = (options7.MeshShaderTier != .D3D12_MESH_SHADER_TIER_NOT_SUPPORTED);
		}

		// Check ray tracing support
		D3D12_FEATURE_DATA_D3D12_OPTIONS5 options5 = default;
		if (SUCCEEDED(tempDevice.CheckFeatureSupport(.D3D12_FEATURE_D3D12_OPTIONS5, &options5, sizeof(D3D12_FEATURE_DATA_D3D12_OPTIONS5))))
		{
			f.RayTracing = (options5.RaytracingTier != .D3D12_RAYTRACING_TIER_NOT_SUPPORTED);
		}

		// Limits — use conservative defaults for D3D12 feature level 12.0
		f.MaxBindGroups = 32; // Root signature descriptor tables
		f.MaxBindingsPerGroup = 1000000; // DX12 descriptor heaps are huge
		f.MaxPushConstantSize = 128; // 32 root constants * 4 bytes
		f.MaxTextureDimension2D = 16384;
		f.MaxTextureArrayLayers = 2048;
		f.MaxComputeWorkgroupSizeX = 1024;
		f.MaxComputeWorkgroupSizeY = 1024;
		f.MaxComputeWorkgroupSizeZ = 64;
		f.MaxComputeWorkgroupsPerDimension = 65535;
		f.MaxBufferSize = (uint64)mDesc.DedicatedVideoMemory;
		f.MinUniformBufferOffsetAlignment = 256;
		f.MinStorageBufferOffsetAlignment = 16;
		f.TimestampPeriodNs = 1; // DX12 timestamps are already in ticks, period queried at runtime

		tempDevice.Release();
		return f;
	}

	public Result<IDevice> CreateDevice(DeviceDesc desc)
	{
		let device = new DX12Device();
		if (device.Init(this, desc) case .Err)
		{
			delete device;
			return .Err;
		}
		return .Ok(device);
	}

	// --- Internal ---
	public IDXGIAdapter1* Handle => mAdapter;
	public IDXGIFactory4* Factory => mFactory;
	public DXGI_ADAPTER_DESC1 Desc => mDesc;
}
