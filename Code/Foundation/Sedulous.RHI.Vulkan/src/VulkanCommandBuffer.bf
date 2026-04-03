namespace Sedulous.RHI.Vulkan;

using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of ICommandBuffer.
class VulkanCommandBuffer : ICommandBuffer
{
	private VkCommandBuffer mCmdBuf;

	public this(VkCommandBuffer cmdBuf)
	{
		mCmdBuf = cmdBuf;
	}

	public VkCommandBuffer Handle => mCmdBuf;
}
