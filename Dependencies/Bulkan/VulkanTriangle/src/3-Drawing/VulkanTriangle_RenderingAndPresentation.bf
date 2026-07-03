using Bulkan;
namespace VulkanTriangle;

extension VulkanTriangle
{
	private VkSemaphore imageAvailableSemaphore;
	private VkSemaphore renderFinishedSemaphore;

	private void CreateSemaphores()
	{
		VkSemaphoreCreateInfo semaphoreInfo = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO
			};

		Helpers.CheckErrors(VulkanNative.vkCreateSemaphore(this.device, &semaphoreInfo, null, &this.imageAvailableSemaphore));

		Helpers.CheckErrors(VulkanNative.vkCreateSemaphore(this.device, &semaphoreInfo, null, &this.renderFinishedSemaphore));
	}

	private void DrawFrame()
	{
		// Acquiring and image from the swap chain
		uint32 imageIndex = 0;
		Helpers.CheckErrors(VulkanNative.vkAcquireNextImageKHR(this.device, this.swapChain, uint64.MaxValue, this.imageAvailableSemaphore, 0, &imageIndex));

		// Submitting the command buffer
		VkSemaphore* waitSemaphores = scope VkSemaphore[]* (this.imageAvailableSemaphore);
		VkPipelineStageFlags* waitStages = scope VkPipelineStageFlags[]* (VkPipelineStageFlags.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT);
		VkSemaphore* signalSemaphores = scope VkSemaphore[]* (this.renderFinishedSemaphore);
		VkCommandBuffer* commandBuffersPtr = scope VkCommandBuffer[]* (commandBuffers[(int)imageIndex]);

		VkSubmitInfo submitInfo = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_SUBMIT_INFO,
				waitSemaphoreCount = 1,
				pWaitSemaphores = waitSemaphores,
				pWaitDstStageMask = waitStages,
				commandBufferCount = 1,
				pCommandBuffers = commandBuffersPtr,
				signalSemaphoreCount = 1,
				pSignalSemaphores = signalSemaphores
			};

		Helpers.CheckErrors(VulkanNative.vkQueueSubmit(this.graphicsQueue, 1, &submitInfo, 0));

		// Presentation
		VkSwapchainKHR* swapChains = scope VkSwapchainKHR[]* (this.swapChain);
		VkPresentInfoKHR presentInfo = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
				waitSemaphoreCount = 1,
				pWaitSemaphores = signalSemaphores,
				swapchainCount = 1,
				pSwapchains = swapChains,
				pImageIndices = &imageIndex,
				pResults = null // Optional
			};

		Helpers.CheckErrors(VulkanNative.vkQueuePresentKHR(this.presentQueue, &presentInfo));

		Helpers.CheckErrors(VulkanNative.vkQueueWaitIdle(this.presentQueue));
	}
}