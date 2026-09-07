using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A Vulkan buffer and the memory behind it.
class VulkanBuffer : IBuffer
{
	private BufferDesc mDesc;
	private VkBuffer mBuffer;
	private VkDeviceMemory mMemory;
	private void* mMapped;

	public BufferDesc Desc => mDesc;
	public VkBuffer Handle => mBuffer;
	public VkDeviceMemory Memory => mMemory;

	public Result<void> Initialize(VkDevice device, VulkanAdapter adapter, BufferDesc desc)
	{
		mDesc = desc;

		VkBufferCreateInfo createInfo = .();
		createInfo.size = desc.Size;
		createInfo.usage = VulkanConversions.ToVkBufferUsage(desc.Usage);
		createInfo.sharingMode = .VK_SHARING_MODE_EXCLUSIVE;

		if (VulkanNative.vkCreateBuffer(device, &createInfo, null, &mBuffer) != .VK_SUCCESS)
			return .Err;

		VkMemoryRequirements requirements = default;
		VulkanNative.vkGetBufferMemoryRequirements(device, mBuffer, &requirements);

		var memoryType = adapter.FindMemoryType(requirements.memoryTypeBits,
			VulkanAdapter.GetMemoryFlags(desc.Memory));

		// Auto asked for device local and the device has none of the right kind, so fall
		// back to host visible: Auto means "you choose", and refusing would be the one
		// answer it does not allow.
		if ((memoryType < 0) && (desc.Memory == .Auto))
		{
			memoryType = adapter.FindMemoryType(requirements.memoryTypeBits,
				.VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | .VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
		}

		if (memoryType < 0)
		{
			VulkanNative.vkDestroyBuffer(device, mBuffer, null);
			mBuffer = .Null;
			return .Err;
		}

		// A buffer a shader or a build reaches by ADDRESS has to say so at allocation time,
		// not only at creation, or taking its address later fails.
		let needsDeviceAddress = desc.Usage.HasFlag(.AccelStructInput)
			|| desc.Usage.HasFlag(.ShaderBindingTable)
			|| desc.Usage.HasFlag(.AccelStructScratch);

		VkMemoryAllocateFlagsInfo allocateFlags = .();
		if (needsDeviceAddress)
			allocateFlags.flags = .VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT;

		VkMemoryAllocateInfo allocateInfo = .();
		if (needsDeviceAddress)
			allocateInfo.pNext = &allocateFlags;
		allocateInfo.allocationSize = requirements.size;
		allocateInfo.memoryTypeIndex = (uint32)memoryType;

		if (VulkanNative.vkAllocateMemory(device, &allocateInfo, null, &mMemory) != .VK_SUCCESS)
		{
			VulkanNative.vkDestroyBuffer(device, mBuffer, null);
			mBuffer = .Null;
			return .Err;
		}

		VulkanNative.vkBindBufferMemory(device, mBuffer, mMemory, 0);

		// Host visible memory is mapped ONCE and stays mapped for the buffer's life.
		// Mapping is not free, and a per frame uniform buffer would otherwise pay for it
		// every frame.
		if ((desc.Memory == .CpuToGpu) || (desc.Memory == .GpuToCpu))
			VulkanNative.vkMapMemory(device, mMemory, 0, desc.Size, 0, &mMapped);

		return .Ok;
	}

	public void Cleanup(VkDevice device)
	{
		if (mMapped != null)
		{
			VulkanNative.vkUnmapMemory(device, mMemory);
			mMapped = null;
		}
		if (mMemory != .Null)
		{
			VulkanNative.vkFreeMemory(device, mMemory, null);
			mMemory = .Null;
		}
		if (mBuffer != .Null)
		{
			VulkanNative.vkDestroyBuffer(device, mBuffer, null);
			mBuffer = .Null;
		}
	}

	/// Null for a device local buffer, which is not mappable at all.
	public void* Map() => mMapped;

	/// Nothing to do: the mapping is persistent, so this exists to satisfy the pairing a
	/// caller writes rather than to undo anything.
	public void Unmap() {}
}
