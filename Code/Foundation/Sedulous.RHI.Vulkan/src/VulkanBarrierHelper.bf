namespace Sedulous.RHI.Vulkan;

using Bulkan;
using Sedulous.RHI;

/// Converts ResourceState to Vulkan synchronization2 stage/access/layout.
static class VulkanBarrierHelper
{
	public struct StageAccess
	{
		public uint64 StageMask;
		public uint64 AccessMask;
	}

	public static StageAccess GetStageAccess(ResourceState state)
	{
		StageAccess sa = default;

		if (state.HasFlag(.VertexBuffer))
		{
			sa.StageMask |= (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_VERTEX_INPUT_BIT;
			sa.AccessMask |= (uint64)VkAccessFlags2.VK_ACCESS_2_VERTEX_ATTRIBUTE_READ_BIT;
		}
		if (state.HasFlag(.IndexBuffer))
		{
			sa.StageMask |= (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_INDEX_INPUT_BIT;
			sa.AccessMask |= (uint64)VkAccessFlags2.VK_ACCESS_2_INDEX_READ_BIT;
		}
		if (state.HasFlag(.UniformBuffer))
		{
			sa.StageMask |= (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_GRAPHICS_BIT |
				(uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT;
			sa.AccessMask |= (uint64)VkAccessFlags2.VK_ACCESS_2_UNIFORM_READ_BIT;
		}
		if (state.HasFlag(.ShaderRead))
		{
			sa.StageMask |= (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_GRAPHICS_BIT |
				(uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT;
			sa.AccessMask |= (uint64)VkAccessFlags2.VK_ACCESS_2_SHADER_READ_BIT;
		}
		if (state.HasFlag(.ShaderWrite))
		{
			sa.StageMask |= (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_GRAPHICS_BIT |
				(uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT;
			sa.AccessMask |= (uint64)VkAccessFlags2.VK_ACCESS_2_SHADER_WRITE_BIT;
		}
		if (state.HasFlag(.RenderTarget))
		{
			sa.StageMask |= (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT;
			sa.AccessMask |= (uint64)VkAccessFlags2.VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT |
				(uint64)VkAccessFlags2.VK_ACCESS_2_COLOR_ATTACHMENT_READ_BIT;
		}
		if (state.HasFlag(.DepthStencilWrite))
		{
			sa.StageMask |= (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_EARLY_FRAGMENT_TESTS_BIT |
				(uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_LATE_FRAGMENT_TESTS_BIT;
			sa.AccessMask |= (uint64)VkAccessFlags2.VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT |
				(uint64)VkAccessFlags2.VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_READ_BIT;
		}
		if (state.HasFlag(.DepthStencilRead))
		{
			sa.StageMask |= (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_EARLY_FRAGMENT_TESTS_BIT |
				(uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_LATE_FRAGMENT_TESTS_BIT;
			sa.AccessMask |= (uint64)VkAccessFlags2.VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_READ_BIT;
		}
		if (state.HasFlag(.IndirectArgument))
		{
			sa.StageMask |= (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_DRAW_INDIRECT_BIT;
			sa.AccessMask |= (uint64)VkAccessFlags2.VK_ACCESS_2_INDIRECT_COMMAND_READ_BIT;
		}
		if (state.HasFlag(.CopySrc))
		{
			// Note: VK_PIPELINE_STAGE_2_TRANSFER_BIT is incorrectly defined as 0 in Bulkan bindings.
			// Use ALL_TRANSFER_BIT which has the correct value (0x1000).
			sa.StageMask |= (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT;
			sa.AccessMask |= (uint64)VkAccessFlags2.VK_ACCESS_2_TRANSFER_READ_BIT;
		}
		if (state.HasFlag(.CopyDst))
		{
			sa.StageMask |= (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT;
			sa.AccessMask |= (uint64)VkAccessFlags2.VK_ACCESS_2_TRANSFER_WRITE_BIT;
		}
		if (state.HasFlag(.Present))
		{
			sa.StageMask |= (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_BOTTOM_OF_PIPE_BIT;
			sa.AccessMask |= 0;
		}
		if (state.HasFlag(.AccelStructRead))
		{
			// VK_PIPELINE_STAGE_2_ACCELERATION_STRUCTURE_BUILD_BIT_KHR | VK_PIPELINE_STAGE_2_RAY_TRACING_SHADER_BIT_KHR
			sa.StageMask |= (uint64)VkPipelineStageFlags.VK_PIPELINE_STAGE_ACCELERATION_STRUCTURE_BUILD_BIT_KHR |
				(uint64)VkPipelineStageFlags.VK_PIPELINE_STAGE_RAY_TRACING_SHADER_BIT_KHR;
			// VK_ACCESS_2_ACCELERATION_STRUCTURE_READ_BIT_KHR
			sa.AccessMask |= (uint64)VkAccessFlags.VK_ACCESS_ACCELERATION_STRUCTURE_READ_BIT_KHR;
		}
		if (state.HasFlag(.AccelStructWrite))
		{
			sa.StageMask |= (uint64)VkPipelineStageFlags.VK_PIPELINE_STAGE_ACCELERATION_STRUCTURE_BUILD_BIT_KHR;
			sa.AccessMask |= (uint64)VkAccessFlags.VK_ACCESS_ACCELERATION_STRUCTURE_WRITE_BIT_KHR;
		}
		if (state.HasFlag(.General))
		{
			sa.StageMask |= (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT;
			sa.AccessMask |= (uint64)VkAccessFlags2.VK_ACCESS_2_MEMORY_READ_BIT |
				(uint64)VkAccessFlags2.VK_ACCESS_2_MEMORY_WRITE_BIT;
		}

		if (sa.StageMask == 0)
			sa.StageMask = (uint64)VkPipelineStageFlags2.VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT;

		return sa;
	}

	/// Gets the image layout for a new (destination) state.
	public static VkImageLayout GetImageLayout(ResourceState state)
	{
		// Determine layout from the most specific state
		if (state.HasFlag(.Present))          return .VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
		if (state.HasFlag(.RenderTarget))      return .VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
		if (state.HasFlag(.DepthStencilWrite)) return .VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
		if (state.HasFlag(.DepthStencilRead))  return .VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL;
		if (state.HasFlag(.ShaderRead))         return .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		if (state.HasFlag(.ShaderWrite))        return .VK_IMAGE_LAYOUT_GENERAL;
		if (state.HasFlag(.CopySrc))            return .VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
		if (state.HasFlag(.CopyDst))            return .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
		if (state.HasFlag(.General))            return .VK_IMAGE_LAYOUT_GENERAL;
		return .VK_IMAGE_LAYOUT_UNDEFINED;
	}
}
