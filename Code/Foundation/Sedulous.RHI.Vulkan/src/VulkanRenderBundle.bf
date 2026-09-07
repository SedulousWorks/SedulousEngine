using Bulkan;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A recorded secondary command buffer, replayable into a compatible pass.
///
/// The handle belongs to the POOL, which recycles it on reset. This only names it, so a
/// bundle outlives its encoder but not the pool's next reset.
class VulkanRenderBundle : IRenderBundle
{
	private VkCommandBuffer mCommandBuffer;

	public this(VkCommandBuffer commandBuffer) => mCommandBuffer = commandBuffer;

	public VkCommandBuffer Handle => mCommandBuffer;
}
