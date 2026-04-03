using Bulkan;
namespace VulkanTriangle;

extension VulkanTriangle
{
	private VkCommandPool commandPool;
	private VkCommandBuffer[] commandBuffers;

	private void CreateCommandPool()
	{
		QueueFamilyIndices queueFamilyIndices = this.FindQueueFamilies(this.physicalDevice);

		VkCommandPoolCreateInfo poolInfo = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
				queueFamilyIndex = queueFamilyIndices.graphicsFamily.Value,
				flags = 0 // Optional,
			};

		Helpers.CheckErrors(VulkanNative.vkCreateCommandPool(device, &poolInfo, null, &this.commandPool));
	}

	private void CreateCommandBuffers()
	{
		this.commandBuffers = new VkCommandBuffer[this.swapChainFramebuffers.Count];

		VkCommandBufferAllocateInfo allocInfo = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
				commandPool = commandPool,
				level = VkCommandBufferLevel.VK_COMMAND_BUFFER_LEVEL_PRIMARY,
				commandBufferCount = (uint32)commandBuffers.Count
			};

		Helpers.CheckErrors(VulkanNative.vkAllocateCommandBuffers(this.device, &allocInfo, this.commandBuffers.Ptr));

		// Begin
		for (int i = 0; i < this.commandBuffers.Count; i++)
		{
			VkCommandBufferBeginInfo beginInfo = .()
				{
					sType = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
					flags = 0, // Optional
					pInheritanceInfo = null // Optional
				};

			Helpers.CheckErrors(VulkanNative.vkBeginCommandBuffer(this.commandBuffers[i], &beginInfo));

			// Pass
			VkClearValue clearColor = .()
				{
					color = .(0.0f, 0.0f, 0.0f, 1.0f)
				};

			VkRenderPassBeginInfo renderPassInfo = .()
				{
					sType = VkStructureType.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
					renderPass = this.renderPass,
					framebuffer = this.swapChainFramebuffers[i],
					renderArea = VkRect2D(0, 0, this.swapChainExtent.width, this.swapChainExtent.height),
					clearValueCount = 1,
					pClearValues = &clearColor
				};

			VulkanNative.vkCmdBeginRenderPass(this.commandBuffers[i], &renderPassInfo, VkSubpassContents.VK_SUBPASS_CONTENTS_INLINE);

			// Draw
			VulkanNative.vkCmdBindPipeline(this.commandBuffers[i], VkPipelineBindPoint.VK_PIPELINE_BIND_POINT_GRAPHICS, this.graphicsPipeline);

			VulkanNative.vkCmdDraw(this.commandBuffers[i], 3, 1, 0, 0);

			VulkanNative.vkCmdEndRenderPass(this.commandBuffers[i]);

			Helpers.CheckErrors(VulkanNative.vkEndCommandBuffer(this.commandBuffers[i]));
		}
	}
}