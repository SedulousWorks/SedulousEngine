using Bulkan;
namespace VulkanTriangle;

extension VulkanTriangle
{
	private VkRenderPass renderPass;

	private void CreateRenderPass()
	{
		// Attachment description
		VkAttachmentDescription colorAttachment = .()
			{
				format = this.swapChainImageFormat,
				samples = VkSampleCountFlags.VK_SAMPLE_COUNT_1_BIT,
				loadOp = VkAttachmentLoadOp.VK_ATTACHMENT_LOAD_OP_CLEAR,
				storeOp = VkAttachmentStoreOp.VK_ATTACHMENT_STORE_OP_STORE,
				stencilLoadOp = VkAttachmentLoadOp.VK_ATTACHMENT_LOAD_OP_DONT_CARE,
				stencilStoreOp = VkAttachmentStoreOp.VK_ATTACHMENT_STORE_OP_DONT_CARE,
				initialLayout = VkImageLayout.VK_IMAGE_LAYOUT_UNDEFINED,
				finalLayout = VkImageLayout.VK_IMAGE_LAYOUT_PRESENT_SRC_KHR
			};

		// Subpasses and attachment references
		VkAttachmentReference colorAttachmentRef = .()
			{
				attachment = 0,
				layout = VkImageLayout.VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
			};

		VkSubpassDescription subpass = .()
			{
				pipelineBindPoint = VkPipelineBindPoint.VK_PIPELINE_BIND_POINT_GRAPHICS,
				colorAttachmentCount = 1,
				pColorAttachments = &colorAttachmentRef
			};

		// Render  pass
		VkSubpassDependency dependency = .()
			{
				srcSubpass = VulkanNative.VK_SUBPASS_EXTERNAL,
				dstSubpass = 0,
				srcStageMask = VkPipelineStageFlags.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
				srcAccessMask = 0,
				dstStageMask = VkPipelineStageFlags.VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
				dstAccessMask = VkAccessFlags.VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT
			};

		VkRenderPassCreateInfo renderPassInfo = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
				attachmentCount = 1,
				pAttachments = &colorAttachment,
				subpassCount = 1,
				pSubpasses = &subpass,
				dependencyCount = 1,
				pDependencies = &dependency
			};

		Helpers.CheckErrors(VulkanNative.vkCreateRenderPass(this.device, &renderPassInfo, null, &this.renderPass));
	}
}