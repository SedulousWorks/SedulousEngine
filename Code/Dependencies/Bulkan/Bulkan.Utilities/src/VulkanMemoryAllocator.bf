using System;
using System.Interop;

using Bulkan;
using static Bulkan.VulkanNative;

// Ported from https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator - commit f6d6e278a6989f854dcc03adf3360c873ca4bad1
//
// Copyright (c) 2017-2022 Advanced Micro Devices, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

namespace Bulkan.Utilities;

enum VmaAllocatorCreateFlags : c_uint
{
	NONE = 0,
	VMA_ALLOCATOR_CREATE_EXTERNALLY_SYNCHRONIZED_BIT = 0x00000001,
	VMA_ALLOCATOR_CREATE_KHR_DEDICATED_ALLOCATION_BIT = 0x00000002,
	VMA_ALLOCATOR_CREATE_KHR_BIND_MEMORY2_BIT = 0x00000004,
	VMA_ALLOCATOR_CREATE_EXT_MEMORY_BUDGET_BIT = 0x00000008,
	VMA_ALLOCATOR_CREATE_AMD_DEVICE_COHERENT_MEMORY_BIT = 0x00000010,
	VMA_ALLOCATOR_CREATE_BUFFER_DEVICE_ADDRESS_BIT = 0x00000020,
	VMA_ALLOCATOR_CREATE_EXT_MEMORY_PRIORITY_BIT = 0x00000040
}

enum VmaMemoryUsage : c_uint
{
	VMA_MEMORY_USAGE_UNKNOWN = 0,
	VMA_MEMORY_USAGE_GPU_ONLY = 1,
	VMA_MEMORY_USAGE_CPU_ONLY = 2,
	VMA_MEMORY_USAGE_CPU_TO_GPU = 3,
	VMA_MEMORY_USAGE_GPU_TO_CPU = 4,
	VMA_MEMORY_USAGE_CPU_COPY = 5,
	VMA_MEMORY_USAGE_GPU_LAZILY_ALLOCATED = 6,
	VMA_MEMORY_USAGE_AUTO = 7,
	VMA_MEMORY_USAGE_AUTO_PREFER_DEVICE = 8,
	VMA_MEMORY_USAGE_AUTO_PREFER_HOST = 9
}

[AllowDuplicates]
enum VmaAllocationCreateFlags : c_uint
{
	NONE = 0,
	VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT = 0x00000001,
	VMA_ALLOCATION_CREATE_NEVER_ALLOCATE_BIT = 0x00000002,
	VMA_ALLOCATION_CREATE_MAPPED_BIT = 0x00000004,
	VMA_ALLOCATION_CREATE_USER_DATA_COPY_STRING_BIT = 0x00000020,
	VMA_ALLOCATION_CREATE_UPPER_ADDRESS_BIT = 0x00000040,
	VMA_ALLOCATION_CREATE_DONT_BIND_BIT = 0x00000080,
	VMA_ALLOCATION_CREATE_WITHIN_BUDGET_BIT = 0x00000100,
	VMA_ALLOCATION_CREATE_CAN_ALIAS_BIT = 0x00000200,
	VMA_ALLOCATION_CREATE_HOST_ACCESS_SEQUENTIAL_WRITE_BIT = 0x00000400,
	VMA_ALLOCATION_CREATE_HOST_ACCESS_RANDOM_BIT = 0x00000800,
	VMA_ALLOCATION_CREATE_HOST_ACCESS_ALLOW_TRANSFER_INSTEAD_BIT = 0x00001000,
	VMA_ALLOCATION_CREATE_STRATEGY_MIN_MEMORY_BIT = 0x00010000,
	VMA_ALLOCATION_CREATE_STRATEGY_MIN_TIME_BIT = 0x00020000,
	VMA_ALLOCATION_CREATE_STRATEGY_MIN_OFFSET_BIT  = 0x00040000,
	VMA_ALLOCATION_CREATE_STRATEGY_BEST_FIT_BIT = VMA_ALLOCATION_CREATE_STRATEGY_MIN_MEMORY_BIT,
	VMA_ALLOCATION_CREATE_STRATEGY_FIRST_FIT_BIT = VMA_ALLOCATION_CREATE_STRATEGY_MIN_TIME_BIT,
	VMA_ALLOCATION_CREATE_STRATEGY_MASK = VMA_ALLOCATION_CREATE_STRATEGY_MIN_MEMORY_BIT | VMA_ALLOCATION_CREATE_STRATEGY_MIN_TIME_BIT | VMA_ALLOCATION_CREATE_STRATEGY_MIN_OFFSET_BIT
}

[AllowDuplicates]
enum VmaPoolCreateFlags : c_uint
{
	NONE = 0,
	VMA_POOL_CREATE_IGNORE_BUFFER_IMAGE_GRANULARITY_BIT = 0x00000002,
	VMA_POOL_CREATE_LINEAR_ALGORITHM_BIT = 0x00000004,
	VMA_POOL_CREATE_ALGORITHM_MASK = VMA_POOL_CREATE_LINEAR_ALGORITHM_BIT
}

enum VmaDefragmentationFlags : c_uint
{
	NONE = 0,
	VMA_DEFRAGMENTATION_FLAG_ALGORITHM_FAST_BIT = 0x1,
	VMA_DEFRAGMENTATION_FLAG_ALGORITHM_BALANCED_BIT = 0x2,
	VMA_DEFRAGMENTATION_FLAG_ALGORITHM_FULL_BIT = 0x4,
	VMA_DEFRAGMENTATION_FLAG_ALGORITHM_EXTENSIVE_BIT = 0x8,
	VMA_DEFRAGMENTATION_FLAG_ALGORITHM_MASK = VMA_DEFRAGMENTATION_FLAG_ALGORITHM_FAST_BIT | VMA_DEFRAGMENTATION_FLAG_ALGORITHM_BALANCED_BIT | VMA_DEFRAGMENTATION_FLAG_ALGORITHM_FULL_BIT | VMA_DEFRAGMENTATION_FLAG_ALGORITHM_EXTENSIVE_BIT
}

enum VmaDefragmentationMoveOperation : c_uint
{
	VMA_DEFRAGMENTATION_MOVE_OPERATION_COPY = 0,
	VMA_DEFRAGMENTATION_MOVE_OPERATION_IGNORE = 1,
	VMA_DEFRAGMENTATION_MOVE_OPERATION_DESTROY = 2
}

[AllowDuplicates]
enum VmaVirtualBlockCreateFlags : c_uint
{
	NONE = 0,
	VMA_VIRTUAL_BLOCK_CREATE_LINEAR_ALGORITHM_BIT = 0x00000001,
	VMA_VIRTUAL_BLOCK_CREATE_ALGORITHM_MASK = VMA_VIRTUAL_BLOCK_CREATE_LINEAR_ALGORITHM_BIT
}

enum VmaVirtualAllocationCreateFlags : c_uint
{
	NONE = 0,
	VMA_VIRTUAL_ALLOCATION_CREATE_UPPER_ADDRESS_BIT = (.)VmaAllocationCreateFlags.VMA_ALLOCATION_CREATE_UPPER_ADDRESS_BIT,
	VMA_VIRTUAL_ALLOCATION_CREATE_STRATEGY_MIN_MEMORY_BIT = (.)VmaAllocationCreateFlags.VMA_ALLOCATION_CREATE_STRATEGY_MIN_MEMORY_BIT,
	VMA_VIRTUAL_ALLOCATION_CREATE_STRATEGY_MIN_TIME_BIT = (.)VmaAllocationCreateFlags.VMA_ALLOCATION_CREATE_STRATEGY_MIN_TIME_BIT,
	VMA_VIRTUAL_ALLOCATION_CREATE_STRATEGY_MIN_OFFSET_BIT = (.)VmaAllocationCreateFlags.VMA_ALLOCATION_CREATE_STRATEGY_MIN_OFFSET_BIT,
	VMA_VIRTUAL_ALLOCATION_CREATE_STRATEGY_MASK = (.)VmaAllocationCreateFlags.VMA_ALLOCATION_CREATE_STRATEGY_MASK
}

[CRepr]
struct VmaAllocator : uint
{
}

[CRepr]
struct VmaPool : uint
{
}

[CRepr]
struct VmaAllocation : uint
{
}

[CRepr]
struct VmaDefragmentationContext : uint
{
}

[CRepr]
struct VmaVirtualAllocation : uint
{
}

[CRepr]
struct VmaVirtualBlock : uint
{
}

typealias PFN_vmaAllocateDeviceMemoryFunction = function void*(
	VmaAllocator allocator,
	uint32 memoryType,
	VkDeviceMemory memory,
	VkDeviceSize size,
	void* pUserData);

typealias PFN_vmaFreeDeviceMemoryFunction = function void*(
	VmaAllocator allocator,
	uint32 memoryType,
	VkDeviceMemory memory,
	VkDeviceSize size,
	void* pUserData);

[CRepr]
struct VmaDeviceMemoryCallbacks
{
	public PFN_vmaAllocateDeviceMemoryFunction pfnAllocate;
	public PFN_vmaFreeDeviceMemoryFunction pfnFree;
	public void* pUserData;
}

[CRepr]
struct VmaVulkanFunctions
{
	public void* vkGetInstanceProcAddr;
	public void* vkGetDeviceProcAddr;
	public void* vkGetPhysicalDeviceProperties;
	public void* vkGetPhysicalDeviceMemoryProperties;
	public void* vkAllocateMemory;
	public void* vkFreeMemory;
	public void* vkMapMemory;
	public void* vkUnmapMemory;
	public void* vkFlushMappedMemoryRanges;
	public void* vkInvalidateMappedMemoryRanges;
	public void* vkBindBufferMemory;
	public void* vkBindImageMemory;
	public void* vkGetBufferMemoryRequirements;
	public void* vkGetImageMemoryRequirements;
	public void* vkCreateBuffer;
	public void* vkDestroyBuffer;
	public void* vkCreateImage;
	public void* vkDestroyImage;
	public void* vkCmdCopyBuffer;
	public void* vkGetBufferMemoryRequirements2KHR;
	public void* vkGetImageMemoryRequirements2KHR;
	public void* vkBindBufferMemory2KHR;
	public void* vkBindImageMemory2KHR;
	public void* vkGetPhysicalDeviceMemoryProperties2KHR;
	public void* vkGetDeviceBufferMemoryRequirements;
	public void* vkGetDeviceImageMemoryRequirements;
}

[CRepr]
struct VmaAllocatorCreateInfo
{
	public VmaAllocatorCreateFlags flags;
	public VkPhysicalDevice physicalDevice;
	public VkDevice device;
	public VkDeviceSize preferredLargeHeapBlockSize;
	public VkAllocationCallbacks* pAllocationCallbacks;
	public VmaDeviceMemoryCallbacks* pDeviceMemoryCallbacks;
	public VkDeviceSize* pHeapSizeLimit;
	public VmaVulkanFunctions* pVulkanFunctions;
	public VkInstance instance;
	public uint32 vulkanApiVersion;
	public VkExternalMemoryHandleTypeFlags* pTypeExternalMemoryHandleTypes;
}

[CRepr]
struct VmaAllocatorInfo
{
	public VkInstance instance;
	public VkPhysicalDevice physicalDevice;
	public VkDevice device;
}

[CRepr]
struct VmaStatistics
{
	public uint32 blockCount;
	public uint32 allocationCount;
	public VkDeviceSize blockBytes;
	public VkDeviceSize allocationBytes;
}

[CRepr]
struct VmaDetailedStatistics
{
	public VmaStatistics statistics;
	public uint32 unusedRangeCount;
	public VkDeviceSize allocationSizeMin;
	public VkDeviceSize allocationSizeMax;
	public VkDeviceSize unusedRangeSizeMin;
	public VkDeviceSize unusedRangeSizeMax;
}

[CRepr]
struct VmaTotalStatistics
{
	public VmaDetailedStatistics[VK_MAX_MEMORY_TYPES] memoryType;
	public VmaDetailedStatistics[VK_MAX_MEMORY_TYPES] memoryHeap;
	public VmaDetailedStatistics total;
}

[CRepr]
struct VmaBudget
{
	public VmaStatistics statistics;
	public VkDeviceSize usage;
	public VkDeviceSize budget;
}

[CRepr]
struct VmaAllocationCreateInfo
{
	public VmaAllocationCreateFlags flags;
	public VmaMemoryUsage usage;
	public VkMemoryPropertyFlags requiredFlags;
	public VkMemoryPropertyFlags preferredFlags;
	public uint32 memoryTypeBits;
	public VmaPool* pool;
	public void* pUserData;
	public float priority;
}

[CRepr]
struct VmaPoolCreateInfo
{
	public uint32 memoryTypeIndex;
	public VmaPoolCreateFlags flags;
	public VkDeviceSize blockSize;
	public c_size minBlockCount;
	public c_size maxBlockCount;
	public float priority;
	public VkDeviceSize minAllocationAlignment;
	public void* pMemoryAllocateNext;
}

[CRepr]
struct VmaAllocationInfo
{
	public uint32 memoryType;
	public VkDeviceMemory deviceMemory;
	public VkDeviceSize offset;
	public VkDeviceSize size;
	public void* pMappedData;
	public void* pUserData;
	public c_char* pName;
}

[CRepr]
struct VmaDefragmentationInfo
{
	public VmaDefragmentationFlags flags;
	public VmaPool* pool;
	public VkDeviceSize maxBytesPerPass;
	public uint32 maxAllocationPerPass;
}

[CRepr]
struct VmaDefragmentationMove
{
	public VmaDefragmentationMoveOperation operation;
	public VmaAllocation srcAllocation;
	public VmaAllocation dstTmpAllocation;
}

[CRepr]
struct VmaDefragmentationPassMoveInfo
{
	public uint32 moveCount;
	public VmaDefragmentationMove* pMoves;
}

[CRepr]
struct VmaDefragmentationStats
{
	public VkDeviceSize bytesMoved;
	public VkDeviceSize bytesFreed;
	public uint32 allocationMoved;
	public uint32 deviceMemoryBlocksFreed;
}

[CRepr]
struct VmaVirtualBlockCreateInfo
{
	public VkDeviceSize size;
	public VmaVirtualBlockCreateFlags flags;
	public VkAllocationCallbacks* pAllocationCallbacks;
}

[CRepr]
struct VmaVirtualAllocationCreateInfo
{
	public VkDeviceSize size;
	public VkDeviceSize alignment;
	public VmaVirtualAllocationCreateFlags flags;
	public void* pUserData;
}

[CRepr]
struct VmaVirtualAllocationInfo
{
	public VkDeviceSize offset;
	public VkDeviceSize size;
	public void* pUserData;
}

static class VulkanMemoryAllocator
{
	[LinkName("vmaCreateAllocator")]
	private static extern VkResult _vmaCreateAllocator(VmaAllocatorCreateInfo* pCreateInfo, VmaAllocator* pAllocator);
	public static VkResult vmaCreateAllocator(VmaAllocatorCreateInfo* pCreateInfo, VmaAllocator* pAllocator)
	{
		if (pCreateInfo.pVulkanFunctions == null)
		{
			VmaVulkanFunctions vulkanFunctions = .()
				{
					vkGetInstanceProcAddr = [Friend]vkGetInstanceProcAddr_ptr,
					vkGetDeviceProcAddr = [Friend]vkGetDeviceProcAddr_ptr,
					vkGetPhysicalDeviceProperties = [Friend]vkGetPhysicalDeviceProperties_ptr,
					vkGetPhysicalDeviceMemoryProperties = [Friend]vkGetPhysicalDeviceMemoryProperties_ptr,
					vkAllocateMemory = [Friend]vkAllocateMemory_ptr,
					vkFreeMemory = [Friend]vkFreeMemory_ptr,
					vkMapMemory = [Friend]vkMapMemory_ptr,
					vkUnmapMemory = [Friend]vkUnmapMemory_ptr,
					vkFlushMappedMemoryRanges = [Friend]vkFlushMappedMemoryRanges_ptr,
					vkInvalidateMappedMemoryRanges = [Friend]vkInvalidateMappedMemoryRanges_ptr,
					vkBindBufferMemory = [Friend]vkBindBufferMemory_ptr,
					vkBindImageMemory = [Friend]vkBindImageMemory_ptr,
					vkGetBufferMemoryRequirements = [Friend]vkGetBufferMemoryRequirements_ptr,
					vkGetImageMemoryRequirements = [Friend]vkGetImageMemoryRequirements_ptr,
					vkCreateBuffer = [Friend]vkCreateBuffer_ptr,
					vkDestroyBuffer = [Friend]vkDestroyBuffer_ptr,
					vkCreateImage = [Friend]vkCreateImage_ptr,
					vkDestroyImage = [Friend]vkDestroyImage_ptr,
					vkCmdCopyBuffer = [Friend]vkCmdCopyBuffer_ptr,
					vkGetBufferMemoryRequirements2KHR = [Friend]vkGetBufferMemoryRequirements2_ptr,
					vkGetImageMemoryRequirements2KHR = [Friend]vkGetImageMemoryRequirements2_ptr,
					vkBindBufferMemory2KHR = [Friend]vkBindBufferMemory2_ptr,
					vkBindImageMemory2KHR = [Friend]vkBindImageMemory2_ptr,
					vkGetPhysicalDeviceMemoryProperties2KHR = [Friend]vkGetPhysicalDeviceMemoryProperties2_ptr,
					vkGetDeviceBufferMemoryRequirements = [Friend]vkGetDeviceBufferMemoryRequirements_ptr,
					vkGetDeviceImageMemoryRequirements = [Friend]vkGetDeviceImageMemoryRequirements_ptr
				};

			pCreateInfo.pVulkanFunctions = &vulkanFunctions;
		}

		return _vmaCreateAllocator(pCreateInfo, pAllocator);
	}

	[CLink]
	public static extern void vmaDestroyAllocator(VmaAllocator allocator);

	[CLink]
	public static extern void vmaGetAllocatorInfo(VmaAllocator allocator, VmaAllocatorInfo* pAllocatorInfo);

	[CLink]
	public static extern void vmaGetPhysicalDeviceProperties(VmaAllocator allocator, VkPhysicalDeviceProperties** ppPhysicalDeviceProperties);

	[CLink]
	public static extern void vmaGetMemoryProperties(VmaAllocator allocator, VkPhysicalDeviceMemoryProperties** ppPhysicalDeviceMemoryProperties);

	[CLink]
	public static extern void vmaGetMemoryTypeProperties(VmaAllocator allocator, uint32 memoryTypeIndex, VkMemoryPropertyFlags* pFlags);

	[CLink]
	public static extern void vmaSetCurrentFrameIndex(VmaAllocator allocator, uint32 frameIndex);

	[CLink]
	public static extern void vmaCalculateStatistics(VmaAllocator allocator, VmaTotalStatistics* pStats);

	[CLink]
	public static extern void vmaGetHeapBudgets(VmaAllocator allocator, VmaBudget* pBudgets);

	[CLink]
	public static extern VkResult vmaFindMemoryTypeIndex(VmaAllocator allocator, uint32 memoryTypeBits, VmaAllocationCreateInfo* pAllocationCreateInfo, uint32* pMemoryTypeIndex);

	[CLink]
	public static extern VkResult vmaFindMemoryTypeIndexForBufferInfo(VmaAllocator allocator, VkBufferCreateInfo* pBufferCreateInfo, VmaAllocationCreateInfo* pAllocationCreateInfo, uint32* pMemoryTypeIndex);

	[CLink]
	public static extern VkResult vmaFindMemoryTypeIndexForImageInfo(VmaAllocator allocator, VkImageCreateInfo* pImageCreateInfo, VmaAllocationCreateInfo* pAllocationCreateInfo, uint32* pMemoryTypeIndex);

	[CLink]
	public static extern VkResult vmaCreatePool(VmaAllocator allocator, VmaPoolCreateInfo* pCreateInfo, VmaPool* pPool);

	[CLink]
	public static extern void vmaDestroyPool(VmaAllocator allocator, VmaPool pool);

	[CLink]
	public static extern void vmaGetPoolStatistics(VmaAllocator allocator, VmaPool pool, VmaStatistics* pPoolStats);

	[CLink]
	public static extern void vmaCalculatePoolStatistics(VmaAllocator allocator, VmaPool pool, VmaDetailedStatistics* pPoolStats);

	[CLink]
	public static extern VkResult vmaCheckPoolCorruption(VmaAllocator allocator, VmaPool pool);

	[CLink]
	public static extern void vmaGetPoolName(VmaAllocator allocator, VmaPool pool, c_char** ppName);

	[CLink]
	public static extern void vmaSetPoolName(VmaAllocator allocator, VmaPool pool, c_char* pName);

	[CLink]
	public static extern VkResult vmaAllocateMemory(VmaAllocator allocator, VkMemoryRequirements* pVkMemoryRequirements, VmaAllocationCreateInfo* pCreateInfo, VmaAllocation* pAllocation, VmaAllocationInfo* pAllocationInfo);

	[CLink]
	public static extern VkResult vmaAllocateMemoryPages(VmaAllocator allocator, VkMemoryRequirements* pVkMemoryRequirements, VmaAllocationCreateInfo* pCreateInfo, c_size allocationCount, VmaAllocation* pAllocations, VmaAllocationInfo* pAllocationInfo);

	[CLink]
	public static extern VkResult vmaAllocateMemoryForBuffer(VmaAllocator allocator, VkBuffer buffer, VmaAllocationCreateInfo* pCreateInfo, VmaAllocation* pAllocation, VmaAllocationInfo* pAllocationInfo);

	[CLink]
	public static extern VkResult vmaAllocateMemoryForImage(VmaAllocator allocator, VkImage image, VmaAllocationCreateInfo* pCreateInfo, VmaAllocation* pAllocation, VmaAllocationInfo* pAllocationInfo);

	[CLink]
	public static extern void vmaFreeMemory(VmaAllocator allocator, VmaAllocation allocation);

	[CLink]
	public static extern void vmaFreeMemoryPages(VmaAllocator allocator, c_size allocationCount, VmaAllocation* pAllocations);

	[CLink]
	public static extern void vmaGetAllocationInfo(VmaAllocator allocator, VmaAllocation allocation, VmaAllocationInfo* pAllocationInfo);

	[CLink]
	public static extern void vmaSetAllocationUserData(VmaAllocator allocator, VmaAllocation allocation, void* pUserData);

	[CLink]
	public static extern void vmaSetAllocationName(VmaAllocator allocator, VmaAllocation allocation, c_char* pName);

	[CLink]
	public static extern void vmaGetAllocationMemoryProperties(VmaAllocator allocator, VmaAllocation allocation, VkMemoryPropertyFlags* pFlags);

	[CLink]
	public static extern VkResult vmaMapMemory(VmaAllocator allocator, VmaAllocation allocation, void** ppData);

	[CLink]
	public static extern void vmaUnmapMemory(VmaAllocator allocator, VmaAllocation allocation);

	[CLink]
	public static extern VkResult vmaFlushAllocation(VmaAllocator allocator, VmaAllocation allocation, VkDeviceSize offset, VkDeviceSize size);

	[CLink]
	public static extern VkResult vmaInvalidateAllocation(VmaAllocator allocator, VmaAllocation allocation, VkDeviceSize offset, VkDeviceSize size);

	[CLink]
	public static extern VkResult vmaFlushAllocations(VmaAllocator allocator, uint32 allocationCount, VmaAllocation* allocations, VkDeviceSize* offsets, VkDeviceSize* sizes);

	[CLink]
	public static extern VkResult vmaInvalidateAllocations(VmaAllocator allocator, uint32 allocationCount, VmaAllocation* allocations, VkDeviceSize* offsets, VkDeviceSize* sizes);

	[CLink]
	public static extern VkResult vmaCheckCorruption(VmaAllocator allocator, uint32 memoryTypeBits);

	[CLink]
	public static extern VkResult vmaBeginDefragmentation(VmaAllocator allocator, VmaDefragmentationInfo* pInfo, VmaDefragmentationContext* pContext);

	[CLink]
	public static extern VkResult vmaEndDefragmentation(VmaAllocator allocator, VmaDefragmentationContext context, VmaDefragmentationStats* pStats);

	[CLink]
	public static extern VkResult vmaBeginDefragmentationPass(VmaAllocator allocator, VmaDefragmentationContext context, VmaDefragmentationPassMoveInfo* pPassInfo);

	[CLink]
	public static extern VkResult vmaEndDefragmentationPass(VmaAllocator allocator, VmaDefragmentationContext context, VmaDefragmentationPassMoveInfo* pPassInfo);

	[CLink]
	public static extern VkResult vmaBindBufferMemory(VmaAllocator allocator, VmaAllocation allocation, VkBuffer buffer);

	[CLink]
	public static extern VkResult vmaBindBufferMemory2(VmaAllocator allocator, VmaAllocation allocation, VkDeviceSize allocationLocalOffset, VkBuffer buffer, void* pNext);

	[CLink]
	public static extern VkResult vmaBindImageMemory(VmaAllocator allocator, VmaAllocation allocation, VkImage image);

	[CLink]
	public static extern VkResult vmaBindImageMemory2(VmaAllocator allocator, VmaAllocation allocation, VkDeviceSize allocationLocalOffset, VkImage image, void* pNext);

	[CLink]
	public static extern VkResult vmaCreateBuffer(VmaAllocator allocator, VkBufferCreateInfo* pBufferCreateInfo, VmaAllocationCreateInfo* pAllocationCreateInfo, VkBuffer* pBuffer, VmaAllocation* pAllocation, VmaAllocationInfo* pAllocationInfo);

	[CLink]
	public static extern VkResult vmaCreateBufferWithAlignment(VmaAllocator allocator, VkBufferCreateInfo* pBufferCreateInfo, VmaAllocationCreateInfo* pAllocationCreateInfo, VkDeviceSize minAlignment, VkBuffer* pBuffer, VmaAllocation* pAllocation, VmaAllocationInfo* pAllocationInfo);

	[CLink]
	public static extern VkResult vmaCreateAliasingBuffer(VmaAllocator allocator, VmaAllocation allocation, VkBufferCreateInfo* pBufferCreateInfo, VkBuffer* pBuffer);

	[CLink]
	public static extern void vmaDestroyBuffer(VmaAllocator allocator, VkBuffer buffer, VmaAllocation allocation);

	[CLink]
	public static extern VkResult vmaCreateImage(VmaAllocator allocator, VkImageCreateInfo* pImageCreateInfo, VmaAllocationCreateInfo* pAllocationCreateInfo, VkImage* pImage, VmaAllocation* pAllocation, VmaAllocationInfo* pAllocationInfo);

	[CLink]
	public static extern VkResult vmaCreateAliasingImage(VmaAllocator allocator, VmaAllocation allocation, VkImageCreateInfo* pImageCreateInfo, VkImage* pImage);

	[CLink]
	public static extern void vmaDestroyImage(VmaAllocator allocator, VkImage image, VmaAllocation allocation);

	[CLink]
	public static extern VkResult vmaCreateVirtualBlock(VmaVirtualBlockCreateInfo* pCreateInfo, VmaVirtualBlock* pVirtualBlock);

	[CLink]
	public static extern void vmaDestroyVirtualBlock(VmaVirtualBlock virtualBlock);

	[CLink]
	public static extern VkBool32 vmaIsVirtualBlockEmpty(VmaVirtualBlock virtualBlock);

	[CLink]
	public static extern void vmaGetVirtualAllocationInfo(VmaVirtualBlock virtualBlock, VmaVirtualAllocation allocation, VmaVirtualAllocationInfo* pVirtualAllocInfo);

	[CLink]
	public static extern VkResult vmaVirtualAllocate(VmaVirtualBlock virtualBlock, VmaVirtualAllocationCreateInfo* pCreateInfo, VmaVirtualAllocation* pAllocation, VkDeviceSize* pOffset);

	[CLink]
	public static extern void vmaVirtualFree(VmaVirtualBlock virtualBlock, VmaVirtualAllocation allocation);

	[CLink]
	public static extern void vmaClearVirtualBlock(VmaVirtualBlock virtualBlock);

	[CLink]
	public static extern void vmaSetVirtualAllocationUserData(VmaVirtualBlock virtualBlock, VmaVirtualAllocation allocation, void* pUserData);

	[CLink]
	public static extern void vmaGetVirtualBlockStatistics(VmaVirtualBlock virtualBlock, VmaStatistics* pStats);

	[CLink]
	public static extern void vmaCalculateVirtualBlockStatistics(VmaVirtualBlock virtualBlock, VmaDetailedStatistics* pStats);

	[CLink]
	public static extern void vmaBuildVirtualBlockStatsString(VmaVirtualBlock virtualBlock, c_char** ppStatsString, VkBool32 detailedMap);

	[CLink]
	public static extern void vmaFreeVirtualBlockStatsString(VmaVirtualBlock virtualBlock, c_char* pStatsString);

	[CLink]
	public static extern void vmaBuildStatsString(VmaAllocator allocator, c_char** ppStatsString, VkBool32 detailedMap);

	[CLink]
	public static extern void vmaFreeStatsString(VmaAllocator allocator, c_char* pStatsString);
}