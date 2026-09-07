using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A Vulkan pipeline cache.
///
/// The blob is opaque and DRIVER SPECIFIC: it is written out after a run and fed back to
/// the next one, and a driver that does not recognise it ignores it and compiles again
/// rather than failing.
class VulkanPipelineCache : IPipelineCache
{
	private VkPipelineCache mCache;
	private VkDevice mDevice;

	public VkPipelineCache Handle => mCache;

	public Result<void> Initialize(VkDevice device, PipelineCacheDesc desc)
	{
		mDevice = device;

		VkPipelineCacheCreateInfo createInfo = .();
		if (!desc.InitialData.IsEmpty)
		{
			createInfo.initialDataSize = (uint)desc.InitialData.Length;
			createInfo.pInitialData = desc.InitialData.Ptr;
		}

		if (VulkanNative.vkCreatePipelineCache(device, &createInfo, null, &mCache) != .VK_SUCCESS)
			return .Err;
		return .Ok;
	}

	public void Cleanup(VkDevice device)
	{
		if (mCache != .Null)
		{
			VulkanNative.vkDestroyPipelineCache(device, mCache, null);
			mCache = .Null;
		}
	}

	/// How many bytes GetData will write, asked first so a caller can size its buffer.
	public uint32 GetDataSize()
	{
		uint size = 0;
		VulkanNative.vkGetPipelineCacheData(mDevice, mCache, &size, null);
		return (uint32)size;
	}

	/// Writes the cache out. Fails when the buffer is smaller than GetDataSize reported.
	public Result<void> GetData(Span<uint8> outData)
	{
		uint size = (uint)outData.Length;
		if (size == 0)
			return .Ok;

		if (VulkanNative.vkGetPipelineCacheData(mDevice, mCache, &size, outData.Ptr) != .VK_SUCCESS)
			return .Err;
		return .Ok;
	}
}
