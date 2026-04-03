namespace Sedulous.RHI.Vulkan;

using System;
using System.Collections;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IRayTracingExt.
class VulkanRayTracingExt : IRayTracingExt
{
	private VulkanDevice mDevice;
	private VulkanAdapter mAdapter;
	private VkPhysicalDeviceRayTracingPipelinePropertiesKHR mRtProperties;

	public uint32 ShaderGroupHandleSize => mRtProperties.shaderGroupHandleSize;
	public uint32 ShaderGroupHandleAlignment => mRtProperties.shaderGroupHandleAlignment;
	public uint32 ShaderGroupBaseAlignment => mRtProperties.shaderGroupBaseAlignment;

	public this(VulkanDevice device, VulkanAdapter adapter)
	{
		mDevice = device;
		mAdapter = adapter;

		// Query RT pipeline properties
		mRtProperties = .();
		VkPhysicalDeviceProperties2 props2 = .();
		props2.pNext = &mRtProperties;
		VulkanNative.vkGetPhysicalDeviceProperties2(adapter.PhysicalDevice, &props2);
	}

	public Result<IAccelStruct> CreateAccelStruct(AccelStructDesc desc)
	{
		// To create an acceleration structure, we need to know its size.
		// We query the build sizes with a dummy geometry info.
		// The caller is expected to call BuildBottomLevel/BuildTopLevel later with actual geometry.
		// For now, allocate a reasonably large AS and let the build command populate it.
		// A more complete implementation would expose GetAccelStructBuildSizes().

		// Use a default size — the user must ensure the AS is large enough.
		// In practice, users should call a size query first. For now, use 256KB as default.
		uint64 defaultSize = 256 * 1024;

		let accelStruct = new VulkanAccelStruct();
		if (accelStruct.Init(mDevice, mAdapter, desc, defaultSize) case .Err)
		{
			delete accelStruct;
			return .Err;
		}
		return .Ok(accelStruct);
	}

	public void DestroyAccelStruct(ref IAccelStruct accelStruct)
	{
		if (let vk = accelStruct as VulkanAccelStruct)
		{
			vk.Cleanup(mDevice);
			delete vk;
		}
		accelStruct = null;
	}

	public Result<IRayTracingPipeline> CreateRayTracingPipeline(RayTracingPipelineDesc desc)
	{
		let pipeline = new VulkanRayTracingPipeline();
		if (pipeline.Init(mDevice, desc) case .Err)
		{
			delete pipeline;
			return .Err;
		}
		return .Ok(pipeline);
	}

	public void DestroyRayTracingPipeline(ref IRayTracingPipeline pipeline)
	{
		if (let vk = pipeline as VulkanRayTracingPipeline)
		{
			vk.Cleanup(mDevice);
			delete vk;
		}
		pipeline = null;
	}

	public Result<void> GetShaderGroupHandles(IRayTracingPipeline pipeline,
		uint32 firstGroup, uint32 groupCount, Span<uint8> outData)
	{
		let vkPipeline = pipeline as VulkanRayTracingPipeline;
		if (vkPipeline == null) return .Err;

		let result = VulkanNative.vkGetRayTracingShaderGroupHandlesKHR(
			mDevice.Handle, vkPipeline.Handle,
			firstGroup, groupCount,
			(uint)outData.Length, outData.Ptr);

		return (result == .VK_SUCCESS) ? .Ok : .Err;
	}
}
