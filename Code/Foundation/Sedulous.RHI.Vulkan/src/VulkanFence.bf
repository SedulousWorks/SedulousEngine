namespace Sedulous.RHI.Vulkan;

using System;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IFence (timeline semaphore).
class VulkanFence : IFence
{
	private VkSemaphore mSemaphore;
	private VkDevice mDevice;

	public this() { }

	public Result<void> Init(VulkanDevice device, uint64 initialValue)
	{
		mDevice = device.Handle;

		VkSemaphoreTypeCreateInfo typeInfo = .();
		typeInfo.semaphoreType = .VK_SEMAPHORE_TYPE_TIMELINE;
		typeInfo.initialValue = initialValue;

		VkSemaphoreCreateInfo createInfo = .();
		createInfo.pNext = &typeInfo;

		let result = VulkanNative.vkCreateSemaphore(device.Handle, &createInfo, null, &mSemaphore);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanFence: vkCreateSemaphore failed ({result})");
			return .Err;
		}

		return .Ok;
	}

	public uint64 CompletedValue
	{
		get
		{
			uint64 value = 0;
			VulkanNative.vkGetSemaphoreCounterValue(mDevice, mSemaphore, &value);
			return value;
		}
	}

	public bool Wait(uint64 value, uint64 timeoutNs = uint64.MaxValue)
	{
		var value;
		VkSemaphoreWaitInfo waitInfo = .();
		waitInfo.semaphoreCount = 1;
		waitInfo.pSemaphores = &mSemaphore;
		waitInfo.pValues = &value;

		let result = VulkanNative.vkWaitSemaphores(mDevice, &waitInfo, timeoutNs);
		return result == .VK_SUCCESS;
	}

	public void Cleanup(VulkanDevice device)
	{
		if (mSemaphore.Handle != 0)
		{
			VulkanNative.vkDestroySemaphore(device.Handle, mSemaphore, null);
			mSemaphore = .Null;
		}
	}

	// --- Internal ---
	public VkSemaphore Handle => mSemaphore;
}
