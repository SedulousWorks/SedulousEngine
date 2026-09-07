using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A timeline semaphore, which is what the RHI's fence is.
///
/// A TIMELINE rather than a binary fence, so one object orders many submissions and a
/// waiter names the value it cares about instead of needing one fence per frame in flight.
class VulkanFence : IFence
{
	private VkSemaphore mSemaphore;
	private VkDevice mDevice;

	public VkSemaphore Handle => mSemaphore;

	public Result<void> Initialize(VkDevice device, uint64 initialValue)
	{
		mDevice = device;

		VkSemaphoreTypeCreateInfo typeInfo = .();
		typeInfo.semaphoreType = .VK_SEMAPHORE_TYPE_TIMELINE;
		typeInfo.initialValue = initialValue;

		VkSemaphoreCreateInfo createInfo = .();
		createInfo.pNext = &typeInfo;

		if (VulkanNative.vkCreateSemaphore(device, &createInfo, null, &mSemaphore) != .VK_SUCCESS)
			return .Err;
		return .Ok;
	}

	public void Cleanup(VkDevice device)
	{
		if (mSemaphore != .Null)
		{
			VulkanNative.vkDestroySemaphore(device, mSemaphore, null);
			mSemaphore = .Null;
		}
	}

	public uint64 CompletedValue()
	{
		uint64 value = 0;
		VulkanNative.vkGetSemaphoreCounterValue(mDevice, mSemaphore, &value);
		return value;
	}

	/// Returns whether the value was reached. False is a TIMEOUT, not an error, and leaves
	/// the fence perfectly usable.
	public bool Wait(uint64 value, uint64 timeoutNs = uint64.MaxValue)
	{
		var target = value;
		var semaphore = mSemaphore;

		VkSemaphoreWaitInfo waitInfo = .();
		waitInfo.semaphoreCount = 1;
		waitInfo.pSemaphores = &semaphore;
		waitInfo.pValues = &target;

		return VulkanNative.vkWaitSemaphores(mDevice, &waitInfo, timeoutNs) == .VK_SUCCESS;
	}
}
