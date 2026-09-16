using System;
using wgpu_Beef;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// One WebGPU adapter: what it is, what it can do, and the device made from it.
///
/// BORROWS its backend, which outlives every adapter on it.
class WebGpuAdapter : IAdapter
{
	private WebGpuBackend mBackend;
	private WGPUAdapter mHandle;

	public WGPUAdapter Handle => mHandle;
	public WebGpuBackend Backend => mBackend;

	/// TAKES the handle. Releasing it is this object's job.
	public this(WebGpuBackend backend, WGPUAdapter handle)
	{
		mBackend = backend;
		mHandle = handle;
	}

	public ~this()
	{
		if (mHandle != null)
		{
			wgpuAdapterRelease(mHandle);
			mHandle = null;
		}
	}

	public void GetInfo(AdapterInfo outInfo)
	{
		WGPUAdapterInfo info = .();
		wgpuAdapterGetInfo(mHandle, &info);

		// The strings belong to wgpu until FreeMembers, so the name is COPIED out
		// before that runs rather than referenced.
		outInfo.Name.Set(StringView((char8*)info.device.data, (int)info.device.length));
		outInfo.VendorId = info.vendorID;
		outInfo.DeviceId = info.deviceID;

		switch (info.adapterType)
		{
		case .WGPUAdapterType_DiscreteGPU: outInfo.Type = .DiscreteGpu;
		case .WGPUAdapterType_IntegratedGPU: outInfo.Type = .IntegratedGpu;
		case .WGPUAdapterType_CPU: outInfo.Type = .Cpu;
		default: outInfo.Type = .Unknown;
		}

		wgpuAdapterInfoFreeMembers(info);

		WGPULimits limits = .();
		if (wgpuAdapterGetLimits(mHandle, &limits) == .WGPUStatus_Success)
		{
			outInfo.SupportedFeatures.MaxBindGroups = limits.maxBindGroups;
			// WebGPU has no single "bindings per group" limit; the sampled texture
			// count is the one that actually binds first in practice.
			outInfo.SupportedFeatures.MaxBindingsPerGroup = limits.maxSampledTexturesPerShaderStage;
			outInfo.SupportedFeatures.MaxTextureDimension2D = limits.maxTextureDimension2D;
			outInfo.SupportedFeatures.MaxTextureArrayLayers = limits.maxTextureArrayLayers;
			outInfo.SupportedFeatures.MaxComputeWorkgroupSizeX = limits.maxComputeWorkgroupSizeX;
			outInfo.SupportedFeatures.MaxComputeWorkgroupSizeY = limits.maxComputeWorkgroupSizeY;
			outInfo.SupportedFeatures.MaxComputeWorkgroupSizeZ = limits.maxComputeWorkgroupSizeZ;
			outInfo.SupportedFeatures.MaxComputeWorkgroupsPerDimension =
				limits.maxComputeWorkgroupsPerDimension;
			outInfo.SupportedFeatures.MinUniformBufferOffsetAlignment =
				limits.minUniformBufferOffsetAlignment;
			outInfo.SupportedFeatures.MinStorageBufferOffsetAlignment =
				limits.minStorageBufferOffsetAlignment;
			outInfo.SupportedFeatures.MaxBufferSize = limits.maxBufferSize;
		}

		WGPUSupportedFeatures features = .();
		wgpuAdapterGetFeatures(mHandle, &features);
		for (uint i = 0; i < features.featureCount; i++)
		{
			switch (features.features[i])
			{
			case .WGPUFeatureName_TimestampQuery:
				outInfo.SupportedFeatures.TimestampQueries = true;
			case .WGPUFeatureName_TextureCompressionBC:
				outInfo.SupportedFeatures.TextureCompressionBC = true;
			case .WGPUFeatureName_TextureCompressionASTC:
				outInfo.SupportedFeatures.TextureCompressionASTC = true;
			case .WGPUFeatureName_DepthClipControl:
				outInfo.SupportedFeatures.DepthClamp = true;
			default:
			}
		}
		wgpuSupportedFeaturesFreeMembers(features);

		// Not probed, because WebGPU guarantees them. Per attachment blend state is in
		// the spec, and occlusion works through the pass begin declaration rather than
		// through a feature. Push constants are decided at device creation, which is
		// where MaxPushConstantSize gets stamped.
		outInfo.SupportedFeatures.IndependentBlend = true;
		outInfo.SupportedFeatures.OcclusionQueries = true;
	}

	public Result<IDevice> CreateDevice(DeviceDesc desc)
	{
		// The device lands with the next file.
		return .Err;
	}
}
