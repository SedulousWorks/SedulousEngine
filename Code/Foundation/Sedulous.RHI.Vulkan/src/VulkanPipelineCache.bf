namespace Sedulous.RHI.Vulkan;

using System;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IPipelineCache.
class VulkanPipelineCache : IPipelineCache
{
	private VkPipelineCache mCache;
	private VkDevice mDevice;

	public this() { }

	public Result<void> Init(VulkanDevice device, PipelineCacheDesc desc)
	{
		mDevice = device.Handle;

		VkPipelineCacheCreateInfo createInfo = .();
		if (desc.InitialData.Length > 0)
		{
			createInfo.initialDataSize = (uint)desc.InitialData.Length;
			createInfo.pInitialData = desc.InitialData.Ptr;
		}

		let result = VulkanNative.vkCreatePipelineCache(device.Handle, &createInfo, null, &mCache);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanPipelineCache: vkCreatePipelineCache failed ({result})");
			return .Err;
		}

		return .Ok;
	}

	public uint GetDataSize()
	{
		uint size = 0;
		VulkanNative.vkGetPipelineCacheData(mDevice, mCache, &size, null);
		return size;
	}

	public Result<int> GetData(Span<uint8> outData)
	{
		var size = (uint)outData.Length;
		let result = VulkanNative.vkGetPipelineCacheData(mDevice, mCache, &size, outData.Ptr);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanPipelineCache: vkGetPipelineCacheData failed ({result})");
			return .Err;
		}
		return .Ok((int)size);
	}

	public void Cleanup(VulkanDevice device)
	{
		if (mCache.Handle != 0)
		{
			VulkanNative.vkDestroyPipelineCache(device.Handle, mCache, null);
			mCache = .Null;
		}
	}

	public VkPipelineCache Handle => mCache;
}
