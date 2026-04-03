namespace Sedulous.RHI.Null;

using System;
using System.Collections;

/// No-op RHI backend. All operations succeed immediately without GPU interaction.
/// Useful for headless testing, CI pipelines, and benchmarking CPU-side logic.
class NullBackend : IBackend
{
	private bool mInitialized;
	private NullAdapter mAdapter ~ delete _;

	public bool IsInitialized => mInitialized;

	public static Result<NullBackend> Create()
	{
		let backend = new NullBackend();
		backend.mInitialized = true;
		backend.mAdapter = new NullAdapter();
		return .Ok(backend);
	}

	public void EnumerateAdapters(List<IAdapter> adapters)
	{
		adapters.Add(mAdapter);
	}

	public Result<ISurface> CreateSurface(void* windowHandle, void* displayHandle = null)
	{
		return .Ok(new NullSurface());
	}

	public void Destroy()
	{
		mInitialized = false;
	}
}

class NullAdapter : IAdapter
{
	public AdapterInfo GetInfo()
	{
		let info = new AdapterInfo();
		info.Name.Set("Null Adapter");
		info.VendorId = 0;
		info.DeviceId = 0;
		info.Type = .Cpu;
		info.SupportedFeatures = DefaultFeatures();
		return info;
	}

	public Result<IDevice> CreateDevice(DeviceDesc desc)
	{
		return .Ok(new NullDevice());
	}

	public static DeviceFeatures DefaultFeatures()
	{
		DeviceFeatures f = default;
		f.BindlessDescriptors = true;
		f.TimestampQueries = true;
		f.PipelineStatisticsQueries = true;
		f.MultiDrawIndirect = true;
		f.DepthClamp = true;
		f.FillModeWireframe = true;
		f.TextureCompressionBC = true;
		f.IndependentBlend = true;
		f.MultiViewport = true;
		f.MeshShaders = true;
		f.RayTracing = true;
		f.MaxBindGroups = 8;
		f.MaxBindingsPerGroup = 1000;
		f.MaxPushConstantSize = 256;
		f.MaxTextureDimension2D = 16384;
		f.MaxTextureArrayLayers = 2048;
		f.MaxComputeWorkgroupSizeX = 1024;
		f.MaxComputeWorkgroupSizeY = 1024;
		f.MaxComputeWorkgroupSizeZ = 64;
		f.MaxComputeWorkgroupsPerDimension = 65535;
		f.MaxBufferSize = 256 * 1024 * 1024;
		f.MinUniformBufferOffsetAlignment = 256;
		f.MinStorageBufferOffsetAlignment = 16;
		f.TimestampPeriodNs = 1;
		f.MaxMeshOutputVertices = 256;
		f.MaxMeshOutputPrimitives = 256;
		f.MaxMeshWorkgroupSize = 128;
		f.MaxTaskWorkgroupSize = 128;
		return f;
	}
}

class NullSurface : ISurface
{
}
