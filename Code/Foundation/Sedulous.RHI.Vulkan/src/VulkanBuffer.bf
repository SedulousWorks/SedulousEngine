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
	/// The bytes the driver allocated for it (IDevice.Counters).
	private uint64 mAllocationSize;
	private void* mMapped;
	/// The device the mapping belongs to, for Map's invalidate and Unmap's flush.
	private VkDevice mDevice;
	/// Mapped memory that is not coherent, so it needs Map's invalidate and Unmap's flush.
	private bool mNonCoherent;

	public BufferDesc Desc => mDesc;
	public uint64 AllocationSize => mAllocationSize;
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

		let memoryFlags = VulkanAdapter.GetMemoryFlags(desc.Memory);
		int32 memoryType = -1;
		// A readback reads best from cached memory; coherent as well where the device has it,
		// so no cache maintenance is needed (Map invalidates otherwise).
		if (desc.Memory == .GpuToCpu)
		{
			memoryType = adapter.FindMemoryType(requirements.memoryTypeBits,
				memoryFlags | .VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
		}
		if (memoryType < 0)
			memoryType = adapter.FindMemoryType(requirements.memoryTypeBits, memoryFlags);

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
		mAllocationSize = requirements.size;
		mDevice = device;
		mNonCoherent = !adapter.GetMemoryTypeFlags(memoryType).HasFlag(.VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);

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
	///
	/// The mapping is persistent. On memory that is not coherent (a readback's cached memory
	/// on some GPUs, Mali's among them) the CPU's cache can hold stale lines over what the GPU
	/// wrote, so Map invalidates them: a read after the GPU's work (its fence waited) sees it.
	public void* Map()
	{
		if (mNonCoherent && (mMapped != null))
		{
			VkMappedMemoryRange range = .();
			range.memory = mMemory;
			range.offset = 0;
			range.size = VulkanNative.VK_WHOLE_SIZE;
			VulkanNative.vkInvalidateMappedMemoryRanges(mDevice, 1, &range);
		}
		return mMapped;
	}

	/// The mapping is persistent, so this does not unmap; on memory that is not coherent it
	/// flushes what the CPU wrote.
	public void Unmap()
	{
		if (mNonCoherent && (mMapped != null))
		{
			VkMappedMemoryRange range = .();
			range.memory = mMemory;
			range.offset = 0;
			range.size = VulkanNative.VK_WHOLE_SIZE;
			VulkanNative.vkFlushMappedMemoryRanges(mDevice, 1, &range);
		}
	}
}
