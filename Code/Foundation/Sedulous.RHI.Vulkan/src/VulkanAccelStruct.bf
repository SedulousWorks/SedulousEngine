namespace Sedulous.RHI.Vulkan;

using System;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IAccelStruct.
class VulkanAccelStruct : IAccelStruct
{
	private VkAccelerationStructureKHR mAccelStruct;
	private VkBuffer mBuffer;
	private VkDeviceMemory mMemory;
	private AccelStructType mType;
	private uint64 mDeviceAddress;

	public AccelStructType Type => mType;
	public uint64 DeviceAddress => mDeviceAddress;

	public this() { }

	public Result<void> Init(VulkanDevice device, VulkanAdapter adapter, AccelStructDesc desc, uint64 size)
	{
		mType = desc.Type;

		// Create backing buffer for the acceleration structure
		VkBufferCreateInfo bufferInfo = .();
		bufferInfo.size = size;
		bufferInfo.usage = .VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_STORAGE_BIT_KHR |
			.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT;
		bufferInfo.sharingMode = .VK_SHARING_MODE_EXCLUSIVE;

		let bufResult = VulkanNative.vkCreateBuffer(device.Handle, &bufferInfo, null, &mBuffer);
		if (bufResult != .VK_SUCCESS)
			return .Err;

		// Allocate memory
		VkMemoryRequirements memReqs = default;
		VulkanNative.vkGetBufferMemoryRequirements(device.Handle, mBuffer, &memReqs);

		let memFlags = VkMemoryPropertyFlags.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;
		int32 memTypeIndex = adapter.FindMemoryType((uint32)memReqs.memoryTypeBits, memFlags);
		if (memTypeIndex < 0)
		{
			VulkanNative.vkDestroyBuffer(device.Handle, mBuffer, null);
			return .Err;
		}

		VkMemoryAllocateFlagsInfo allocFlags = .();
		allocFlags.flags = .VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT;

		VkMemoryAllocateInfo allocInfo = .();
		allocInfo.pNext = &allocFlags;
		allocInfo.allocationSize = memReqs.size;
		allocInfo.memoryTypeIndex = (uint32)memTypeIndex;

		let allocResult = VulkanNative.vkAllocateMemory(device.Handle, &allocInfo, null, &mMemory);
		if (allocResult != .VK_SUCCESS)
		{
			VulkanNative.vkDestroyBuffer(device.Handle, mBuffer, null);
			return .Err;
		}

		VulkanNative.vkBindBufferMemory(device.Handle, mBuffer, mMemory, 0);

		// Create acceleration structure
		VkAccelerationStructureCreateInfoKHR createInfo = .();
		createInfo.buffer = mBuffer;
		createInfo.size = size;
		createInfo.type = (desc.Type == .TopLevel)
			? .VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_KHR
			: .VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_KHR;

		let asResult = VulkanNative.vkCreateAccelerationStructureKHR(device.Handle, &createInfo, null, &mAccelStruct);
		if (asResult != .VK_SUCCESS)
		{
			VulkanNative.vkFreeMemory(device.Handle, mMemory, null);
			VulkanNative.vkDestroyBuffer(device.Handle, mBuffer, null);
			return .Err;
		}

		// Get device address
		VkAccelerationStructureDeviceAddressInfoKHR addressInfo = .();
		addressInfo.accelerationStructure = mAccelStruct;
		mDeviceAddress = VulkanNative.vkGetAccelerationStructureDeviceAddressKHR(device.Handle, &addressInfo);

		return .Ok;
	}

	public void Cleanup(VulkanDevice device)
	{
		if (mAccelStruct.Handle != 0)
		{
			VulkanNative.vkDestroyAccelerationStructureKHR(device.Handle, mAccelStruct, null);
			mAccelStruct = .Null;
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

	public VkAccelerationStructureKHR Handle => mAccelStruct;
}
