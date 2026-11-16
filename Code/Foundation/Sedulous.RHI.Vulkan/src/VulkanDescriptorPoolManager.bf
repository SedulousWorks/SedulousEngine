using System;
using System.Collections;
using Bulkan;
using Sedulous.Core;

namespace Sedulous.RHI.Vulkan;

/// Hands out descriptor sets, growing by whole pools.
///
/// A Vulkan pool has a FIXED capacity decided at creation, and allocating past it fails
/// rather than growing. So allocation tries every pool it already has and makes another
/// only when they are all full, which is what lets a caller allocate freely without
/// knowing how many sets it will end up needing.
class VulkanDescriptorPoolManager
{
	private VkDevice mDevice;
	/// Plain pools, then update-after-bind ones: each kind of set comes from pools of its own kind.
	private List<VkDescriptorPool>[2] mPools = .(new .(), new .()) ~ { delete _[0]; delete _[1]; };
	private uint32 mMaxSetsPerPool;
	private bool mAccelStructEnabled;
	private VkDescriptorSet mLastAllocatedSet;

	public this(VkDevice device, uint32 maxSetsPerPool = 256, bool accelStructEnabled = false)
	{
		mDevice = device;
		mMaxSetsPerPool = maxSetsPerPool;
		mAccelStructEnabled = accelStructEnabled;
	}

	/// The set the last successful Allocate produced. Read straight after allocating.
	public VkDescriptorSet LastAllocatedSet => mLastAllocatedSet;
	/// How many pools of one kind exist.
	public int PoolCount(bool updateAfterBind) => mPools[updateAfterBind ? 1 : 0].Count;

	public Result<VkDescriptorPool> Allocate(VkDescriptorSetLayout layout,
		bool updateAfterBind = false, uint32 variableCount = 0)
	{
		var count = variableCount;
		VkDescriptorSetVariableDescriptorCountAllocateInfo variableInfo = .();
		if (variableCount > 0)
		{
			variableInfo.descriptorSetCount = 1;
			variableInfo.pDescriptorCounts = &count;
		}

		// Every existing pool of the same kind first: an update-after-bind layout must come from an
		// update-after-bind pool, and a plain set has no place in one (their sizes are 64x). A
		// failure here is "this pool is full", not an error: it is the ordinary way to discover
		// the capacity has run out.
		let pools = mPools[updateAfterBind ? 1 : 0];
		for (let pool in pools)
		{
			if (TryAllocateFrom(pool, layout, variableCount, &variableInfo) case .Ok(let set))
			{
				mLastAllocatedSet = set;
				return .Ok(pool);
			}
		}

		if (CreatePool(updateAfterBind) case .Err)
			return .Err;

		let fresh = pools.Back;
		if (TryAllocateFrom(fresh, layout, variableCount, &variableInfo) case .Ok(let set))
		{
			mLastAllocatedSet = set;
			return .Ok(fresh);
		}
		return .Err;
	}

	private Result<VkDescriptorSet> TryAllocateFrom(VkDescriptorPool pool,
		VkDescriptorSetLayout layout, uint32 variableCount,
		VkDescriptorSetVariableDescriptorCountAllocateInfo* variableInfo)
	{
		var setLayout = layout;
		VkDescriptorSet set = .Null;

		VkDescriptorSetAllocateInfo allocateInfo = .();
		allocateInfo.descriptorPool = pool;
		allocateInfo.descriptorSetCount = 1;
		allocateInfo.pSetLayouts = &setLayout;
		if (variableCount > 0)
			allocateInfo.pNext = variableInfo;

		if (VulkanNative.vkAllocateDescriptorSets(mDevice, &allocateInfo, &set) != .VK_SUCCESS)
			return .Err;
		return .Ok(set);
	}

	public void Free(VkDescriptorPool pool, VkDescriptorSet set)
	{
		var target = set;
		VulkanNative.vkFreeDescriptorSets(mDevice, pool, 1, &target);
	}

	public void Destroy()
	{
		for (let pools in mPools)
		{
			for (let pool in pools)
				VulkanNative.vkDestroyDescriptorPool(mDevice, pool, null);
			pools.Clear();
		}
	}

	/// A pool sized by a rough profile of what a frame binds, rather than by counting.
	///
	/// The multiples are guesses at the shape of real usage: several sampled images per
	/// set, a couple of uniform buffers, one of most other things. A bindless pool
	/// multiplies the image and buffer kinds heavily, because one bindless set holds
	/// thousands of descriptors rather than a handful.
	private Result<void> CreatePool(bool updateAfterBind)
	{
		let multiplier = (uint32)(updateAfterBind ? 64 : 1);

		let sizes = scope VkDescriptorPoolSize[12];
		sizes[0] = .() { type = .VK_DESCRIPTOR_TYPE_SAMPLER, descriptorCount = mMaxSetsPerPool * multiplier };
		sizes[1] = .() { type = .VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, descriptorCount = mMaxSetsPerPool * 4 * multiplier };
		sizes[2] = .() { type = .VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, descriptorCount = mMaxSetsPerPool * multiplier };
		sizes[3] = .() { type = .VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, descriptorCount = mMaxSetsPerPool * 2 };
		sizes[4] = .() { type = .VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, descriptorCount = mMaxSetsPerPool * 2 * multiplier };
		sizes[5] = .() { type = .VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, descriptorCount = mMaxSetsPerPool };
		sizes[6] = .() { type = .VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC, descriptorCount = mMaxSetsPerPool };
		sizes[7] = .() { type = .VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, descriptorCount = mMaxSetsPerPool * 4 * multiplier };
		sizes[8] = .() { type = .VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT, descriptorCount = mMaxSetsPerPool };
		sizes[9] = .() { type = .VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER, descriptorCount = mMaxSetsPerPool };
		sizes[10] = .() { type = .VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER, descriptorCount = mMaxSetsPerPool };
		sizes[11] = .() { type = .VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR, descriptorCount = mMaxSetsPerPool };

		// The acceleration structure entry is dropped unless ray tracing is on: naming a
		// descriptor type the device has no extension for fails pool creation.
		let sizeCount = mAccelStructEnabled ? 12 : 11;

		VkDescriptorPoolCreateInfo createInfo = .();
		// Sets are freed individually rather than only by resetting the pool, because a
		// bind group is destroyed on its own schedule.
		createInfo.flags = .VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT;
		if (updateAfterBind)
			createInfo.flags |= .VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT;
		createInfo.maxSets = mMaxSetsPerPool;
		createInfo.poolSizeCount = (uint32)sizeCount;
		createInfo.pPoolSizes = &sizes[0];

		VkDescriptorPool pool = .Null;
		if (VulkanNative.vkCreateDescriptorPool(mDevice, &createInfo, null, &pool) != .VK_SUCCESS)
			return .Err;

		mPools[updateAfterBind ? 1 : 0].Add(pool);
		return .Ok;
	}
}
