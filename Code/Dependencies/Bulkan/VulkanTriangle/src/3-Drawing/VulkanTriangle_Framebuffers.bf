using Bulkan;
namespace VulkanTriangle;

extension VulkanTriangle
{
	private VkFramebuffer[] swapChainFramebuffers;

	private void CreateFramebuffers()
	{
		this.swapChainFramebuffers = new VkFramebuffer[this.swapChainImageViews.Count];

		for (int i = 0; i < this.swapChainImageViews.Count; i++)
		{
			VkFramebufferCreateInfo framebufferInfo = .();
			framebufferInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
			framebufferInfo.renderPass = renderPass;
			framebufferInfo.attachmentCount = 1;
			framebufferInfo.pAttachments = &swapChainImageViews[i];
			framebufferInfo.width = swapChainExtent.width;
			framebufferInfo.height = swapChainExtent.height;
			framebufferInfo.layers = 1;

			Helpers.CheckErrors(VulkanNative.vkCreateFramebuffer(device, &framebufferInfo, null, &this.swapChainFramebuffers[i]));
		}
	}
}