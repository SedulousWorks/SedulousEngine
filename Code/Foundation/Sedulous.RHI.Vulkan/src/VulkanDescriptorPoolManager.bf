namespace Sedulous.RHI.Vulkan;

using System;
using System.Collections;
using Bulkan;

/// Manages VkDescriptorPool allocation with auto-grow.
class VulkanDescriptorPoolManager
{
	private VkDevice mDevice;
	private List<VkDescriptorPool> mPools = new .() ~ delete _;
	private uint32 mMaxSetsPerPool;
	private bool mAccelerationStructureEnabled;

	public this(VkDevice device, uint32 maxSetsPerPool = 256, bool accelerationStructureEnabled = false)
	{
		mDevice = device;
		mMaxSetsPerPool = maxSetsPerPool;
		mAccelerationStructureEnabled = accelerationStructureEnabled;
	}

	public Result<VkDescriptorSet> Allocate(VkDescriptorSetLayout layout, out VkDescriptorPool outPool, bool updateAfterBind = false, uint32 variableDescriptorCount = 0)
	{
		outPool = .Null;
		var layout;
		var varCount = variableDescriptorCount;

		// Variable descriptor count pNext (for bindless)
		VkDescriptorSetVariableDescriptorCountAllocateInfo varCountInfo = .();
		if (variableDescriptorCount > 0)
		{
			varCountInfo.descriptorSetCount = 1;
			varCountInfo.pDescriptorCounts = &varCount;
		}

		// Try existing pools
		for (let pool in mPools)
		{
			VkDescriptorSet set = default;
			VkDescriptorSetAllocateInfo allocInfo = .();
			allocInfo.descriptorPool = pool;
			allocInfo.descriptorSetCount = 1;
			allocInfo.pSetLayouts = &layout;
			if (variableDescriptorCount > 0)
				allocInfo.pNext = &varCountInfo;

			let result = VulkanNative.vkAllocateDescriptorSets(mDevice, &allocInfo, &set);
			if (result == .VK_SUCCESS)
			{
				outPool = pool;
				return .Ok(set);
			}
		}

		// All pools exhausted — create a new one
		if (CreatePool(updateAfterBind) case .Err)
		{
			System.Diagnostics.Debug.WriteLine("VulkanDescriptorPoolManager: failed to create new descriptor pool");
			return .Err;
		}

		let pool = mPools.Back;
		VkDescriptorSet set = default;
		VkDescriptorSetAllocateInfo allocInfo = .();
		allocInfo.descriptorPool = pool;
		allocInfo.descriptorSetCount = 1;
		allocInfo.pSetLayouts = &layout;
		if (variableDescriptorCount > 0)
			allocInfo.pNext = &varCountInfo;

		let result = VulkanNative.vkAllocateDescriptorSets(mDevice, &allocInfo, &set);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanDescriptorPoolManager: vkAllocateDescriptorSets failed ({result})");
			return .Err;
		}

		outPool = pool;
		return .Ok(set);
	}

	/// Frees a descriptor set back to its pool.
	public void Free(VkDescriptorPool pool, VkDescriptorSet descriptorSet)
	{
		var descriptorSet;
		VulkanNative.vkFreeDescriptorSets(mDevice, pool, 1, &descriptorSet);
	}

	public void ResetAll()
	{
		for (let pool in mPools)
			VulkanNative.vkResetDescriptorPool(mDevice, pool, /*VkFlags.None*/0);
	}

	public void Destroy()
	{
		for (let pool in mPools)
			VulkanNative.vkDestroyDescriptorPool(mDevice, pool, null);
		mPools.Clear();
	}

	private Result<void> CreatePool(bool updateAfterBind)
	{
		// Bindless pools need much larger descriptor counts for unbounded arrays
		uint32 bindlessMultiplier = updateAfterBind ? 64 : 1;

		VkDescriptorPoolSize[12] poolSizes = .(
			.() { type = .VK_DESCRIPTOR_TYPE_SAMPLER, descriptorCount = mMaxSetsPerPool * bindlessMultiplier },
			.() { type = .VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE, descriptorCount = mMaxSetsPerPool * 4 * bindlessMultiplier },
			.() { type = .VK_DESCRIPTOR_TYPE_STORAGE_IMAGE, descriptorCount = mMaxSetsPerPool * bindlessMultiplier },
			.() { type = .VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, descriptorCount = mMaxSetsPerPool * 2 },
			.() { type = .VK_DESCRIPTOR_TYPE_STORAGE_BUFFER, descriptorCount = mMaxSetsPerPool * 2 * bindlessMultiplier },
			.() { type = .VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER_DYNAMIC, descriptorCount = mMaxSetsPerPool },
			.() { type = .VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC, descriptorCount = mMaxSetsPerPool },
			.() { type = .VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, descriptorCount = mMaxSetsPerPool * 4 * bindlessMultiplier },
			.() { type = .VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT, descriptorCount = mMaxSetsPerPool },
			.() { type = .VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER, descriptorCount = mMaxSetsPerPool },
			.() { type = .VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER, descriptorCount = mMaxSetsPerPool },
			.() { type = .VK_DESCRIPTOR_TYPE_ACCELERATION_STRUCTURE_KHR, descriptorCount = mMaxSetsPerPool }
		);

		// Only include acceleration structure descriptor type if the extension is enabled
		uint32 poolSizeCount = mAccelerationStructureEnabled ? (uint32)poolSizes.Count : (uint32)poolSizes.Count - 1;

		VkDescriptorPoolCreateInfo poolInfo = .();
		poolInfo.flags = .VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT;
		if (updateAfterBind)
			poolInfo.flags |= .VK_DESCRIPTOR_POOL_CREATE_UPDATE_AFTER_BIND_BIT;
		poolInfo.maxSets = mMaxSetsPerPool;
		poolInfo.poolSizeCount = poolSizeCount;
		poolInfo.pPoolSizes = &poolSizes;

		VkDescriptorPool pool = default;
		let result = VulkanNative.vkCreateDescriptorPool(mDevice, &poolInfo, null, &pool);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanDescriptorPoolManager: vkCreateDescriptorPool failed ({result})");
			return .Err;
		}

		mPools.Add(pool);
		return .Ok;
	}
}
