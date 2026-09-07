using Bulkan;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A finished recording, ready to submit.
///
/// The HANDLE belongs to the pool that allocated it; this only names it, and the pool
/// recycles it on reset.
class VulkanCommandBuffer : ICommandBuffer
{
	private VkCommandBuffer mCommandBuffer;

	public this(VkCommandBuffer commandBuffer) => mCommandBuffer = commandBuffer;

	public VkCommandBuffer Handle => mCommandBuffer;
}
