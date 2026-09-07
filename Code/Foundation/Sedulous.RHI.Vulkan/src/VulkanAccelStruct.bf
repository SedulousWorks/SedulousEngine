using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A ray tracing acceleration structure, and the buffer it lives in.
///
/// The structure is not an allocation of its own: it is built INTO a buffer the caller
/// sizes and owns, so this holds both and frees them together.
class VulkanAccelStruct : IAccelStruct
{
	private VkAccelerationStructureKHR mAccelStruct;
	private VkBuffer mBuffer;
	private VkDeviceMemory mMemory;
	private AccelStructType mType = .BottomLevel;
	private uint64 mDeviceAddress = 0;

	public AccelStructType Type => mType;

	/// The address a shader or a top level build refers to it by. Ray tracing structures
	/// reference each other by address rather than by handle.
	public uint64 DeviceAddress => mDeviceAddress;

	public VkAccelerationStructureKHR Handle => mAccelStruct;

	public Result<void> Initialize(VkDevice device, VulkanAdapter adapter, AccelStructDesc desc,
		uint64 size)
	{
		mType = desc.Type;

		VkBufferCreateInfo bufferInfo = .();
		bufferInfo.size = size;
		bufferInfo.usage = .VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_STORAGE_BIT_KHR
			| .VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT;

		if (VulkanNative.vkCreateBuffer(device, &bufferInfo, null, &mBuffer) != .VK_SUCCESS)
			return .Err;

		VkMemoryRequirements requirements = default;
		VulkanNative.vkGetBufferMemoryRequirements(device, mBuffer, &requirements);

		let memoryType = adapter.FindMemoryType(requirements.memoryTypeBits,
			.VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
		if (memoryType < 0)
		{
			VulkanNative.vkDestroyBuffer(device, mBuffer, null);
			mBuffer = .Null;
			return .Err;
		}

		// The buffer is reached by address during a build, so the allocation has to permit
		// that as well as the buffer's own usage flag.
		VkMemoryAllocateFlagsInfo allocateFlags = .();
		allocateFlags.flags = .VK_MEMORY_ALLOCATE_DEVICE_ADDRESS_BIT;

		VkMemoryAllocateInfo allocateInfo = .();
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

		VkAccelerationStructureCreateInfoKHR createInfo = .();
		createInfo.buffer = mBuffer;
		createInfo.size = size;
		createInfo.type = (desc.Type == .TopLevel)
			? .VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_KHR
			: .VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_KHR;

		if (VulkanNative.vkCreateAccelerationStructureKHR(device, &createInfo, null, &mAccelStruct)
			!= .VK_SUCCESS)
			return .Err;

		VkAccelerationStructureDeviceAddressInfoKHR addressInfo = .();
		addressInfo.accelerationStructure = mAccelStruct;
		mDeviceAddress = VulkanNative.vkGetAccelerationStructureDeviceAddressKHR(device,
			&addressInfo);

		return .Ok;
	}

	public void Cleanup(VkDevice device)
	{
		if (mAccelStruct != .Null)
		{
			VulkanNative.vkDestroyAccelerationStructureKHR(device, mAccelStruct, null);
			mAccelStruct = .Null;
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
}
