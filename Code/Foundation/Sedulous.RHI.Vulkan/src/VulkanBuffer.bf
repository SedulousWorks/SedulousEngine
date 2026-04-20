namespace Sedulous.RHI.Vulkan;

using System;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IBuffer.
class VulkanBuffer : IBuffer
{
	private VkBuffer mBuffer;
	private VkDeviceMemory mMemory;
	private BufferDesc mDesc;
	private void* mMappedPtr;

	public BufferDesc Desc => mDesc;
	public uint64 Size => mDesc.Size;
	public BufferUsage Usage => mDesc.Usage;

	public this() { }

	public Result<void> Init(VulkanDevice device, VulkanAdapter adapter, BufferDesc desc)
	{
		mDesc = desc;

		// Create buffer
		VkBufferCreateInfo bufferInfo = .();
		bufferInfo.size = desc.Size;
		bufferInfo.usage = VulkanConversions.ToVkBufferUsage(desc.Usage);
		bufferInfo.sharingMode = .VK_SHARING_MODE_EXCLUSIVE;

		let result = VulkanNative.vkCreateBuffer(device.Handle, &bufferInfo, null, &mBuffer);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanBuffer: vkCreateBuffer failed ({result})");
			return .Err;
		}

		// Get memory requirements
		VkMemoryRequirements memReqs = default;
		VulkanNative.vkGetBufferMemoryRequirements(device.Handle, mBuffer, &memReqs);

		// Find memory type
		let memFlags = VulkanAdapter.GetMemoryFlags(desc.Memory);
		int32 memTypeIndex = adapter.FindMemoryType((uint32)memReqs.memoryTypeBits, memFlags);

		// If Auto and device-local fails, try host-visible
		if (memTypeIndex < 0 && desc.Memory == .Auto)
			memTypeIndex = adapter.FindMemoryType((uint32)memReqs.memoryTypeBits,
				.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | .VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);

		if (memTypeIndex < 0)
		{
			System.Diagnostics.Debug.WriteLine("VulkanBuffer: no suitable memory type found");
			VulkanNative.vkDestroyBuffer(device.Handle, mBuffer, null);
			mBuffer = .Null;
			return .Err;
		}

		// Allocate memory
		VkMemoryAllocateFlagsInfo allocFlags = .();
		bool needsDeviceAddress = desc.Usage.HasFlag(.AccelStructInput) || desc.Usage.HasFlag(.ShaderBindingTable) || desc.Usage.HasFlag(.AccelStructScratch);
		if (needsDeviceAddress)
			allocFlags.flags = .VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT;

		VkMemoryAllocateInfo allocInfo = .();
		if (needsDeviceAddress)
			allocInfo.pNext = &allocFlags;
		allocInfo.allocationSize = memReqs.size;
		allocInfo.memoryTypeIndex = (uint32)memTypeIndex;

		let allocResult = VulkanNative.vkAllocateMemory(device.Handle, &allocInfo, null, &mMemory);
		if (allocResult != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanBuffer: vkAllocateMemory failed ({allocResult})");
			VulkanNative.vkDestroyBuffer(device.Handle, mBuffer, null);
			mBuffer = .Null;
			return .Err;
		}

		// Bind memory
		VulkanNative.vkBindBufferMemory(device.Handle, mBuffer, mMemory, 0);

		// Persistently map host-visible buffers
		if (desc.Memory == .CpuToGpu || desc.Memory == .GpuToCpu)
		{
			VulkanNative.vkMapMemory(device.Handle, mMemory, 0, desc.Size, .None, &mMappedPtr);
		}

		return .Ok;
	}

	public void* Map()
	{
		return mMappedPtr;
	}

	public void Unmap()
	{
		// Persistently mapped - nothing to do
	}

	public void Cleanup(VulkanDevice device)
	{
		if (mMappedPtr != null)
		{
			VulkanNative.vkUnmapMemory(device.Handle, mMemory);
			mMappedPtr = null;
		}
		if (mMemory.Handle != 0)
		{
			VulkanNative.vkFreeMemory(device.Handle, mMemory, null);
			mMemory = .Null;
		}
		if (mBuffer.Handle != 0)
		{
			VulkanNative.vkDestroyBuffer(device.Handle, mBuffer, null);
			mBuffer = .Null;
		}
	}

	// --- Internal ---
	public VkBuffer Handle => mBuffer;
	public VkDeviceMemory Memory => mMemory;
}
