using Bulkan;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// Turning a resource state into the stage, access and image layout a Vulkan barrier needs.
static class VulkanBarrierHelper
{
	/// Cuts a stage mask down to what `queue`'s family can actually execute.
	///
	/// GetStageAccess names ALL_GRAPHICS | COMPUTE_SHADER for shader access because it does
	/// not know the queue. A barrier recorded on a compute only or transfer only family
	/// with a graphics stage in it is INVALID
	/// (VUID-vkCmdPipelineBarrier2-srcStageMask-03849 and its siblings). A graphics family
	/// executes everything, so it is left alone. A mask the cut would empty, a render
	/// target state on a compute queue, becomes ALL_COMMANDS: valid on every family and
	/// merely stronger than needed.
	public static VkPipelineStageFlags2 MaskStagesForQueue(VkPipelineStageFlags2 stages,
		QueueType queue)
	{
		if ((queue == .Graphics) || (stages == 0))
			return stages;

		const VkPipelineStageFlags2 cAnyFamily = .VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT
			| .VK_PIPELINE_STAGE_2_BOTTOM_OF_PIPE_BIT
			| .VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT
			| .VK_PIPELINE_STAGE_2_HOST_BIT
			| .VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT
			| .VK_PIPELINE_STAGE_2_COPY_BIT
			| .VK_PIPELINE_STAGE_2_CLEAR_BIT;
		const VkPipelineStageFlags2 cCompute = cAnyFamily
			| .VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT
			| .VK_PIPELINE_STAGE_2_DRAW_INDIRECT_BIT
			| .VK_PIPELINE_STAGE_2_ACCELERATION_STRUCTURE_BUILD_BIT_KHR
			| .VK_PIPELINE_STAGE_2_RAY_TRACING_SHADER_BIT_KHR
			| .VK_PIPELINE_STAGE_2_BLIT_BIT
			| .VK_PIPELINE_STAGE_2_RESOLVE_BIT;

		let allowed = (queue == .Compute) ? cCompute : cAnyFamily;
		let masked = stages & allowed;
		return (masked != 0) ? masked : .VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT;
	}

	/// Cuts an access mask down the same way, to what the retained stages can support.
	///
	/// Cutting the stages alone is NOT enough: VERTEX_ATTRIBUTE_READ left in an access mask
	/// whose stages were reduced to ALL_COMMANDS on a compute family is still rejected,
	/// because ALL_COMMANDS expands per family and the compute expansion has no stage that
	/// supports it (VUID-VkBufferMemoryBarrier2-srcAccessMask-03902 and its siblings). An
	/// empty result is legal and means an execution dependency with no memory dependency.
	public static VkAccessFlags2 MaskAccessForQueue(VkAccessFlags2 access, QueueType queue)
	{
		if ((queue == .Graphics) || (access == 0))
			return access;

		const VkAccessFlags2 cAnyFamily = .VK_ACCESS_2_TRANSFER_READ_BIT
			| .VK_ACCESS_2_TRANSFER_WRITE_BIT
			| .VK_ACCESS_2_HOST_READ_BIT
			| .VK_ACCESS_2_HOST_WRITE_BIT
			| .VK_ACCESS_2_MEMORY_READ_BIT
			| .VK_ACCESS_2_MEMORY_WRITE_BIT;
		const VkAccessFlags2 cCompute = cAnyFamily
			| .VK_ACCESS_2_INDIRECT_COMMAND_READ_BIT
			| .VK_ACCESS_2_UNIFORM_READ_BIT
			| .VK_ACCESS_2_SHADER_READ_BIT
			| .VK_ACCESS_2_SHADER_WRITE_BIT
			| .VK_ACCESS_2_SHADER_SAMPLED_READ_BIT
			| .VK_ACCESS_2_SHADER_STORAGE_READ_BIT
			| .VK_ACCESS_2_SHADER_STORAGE_WRITE_BIT
			| .VK_ACCESS_2_ACCELERATION_STRUCTURE_READ_BIT_KHR
			| .VK_ACCESS_2_ACCELERATION_STRUCTURE_WRITE_BIT_KHR;

		return access & ((queue == .Compute) ? cCompute : cAnyFamily);
	}

	/// Both halves of a StageAccess cut to one queue family, which is how a caller should
	/// reach for this: masking one without the other produces a mask pair the layers reject.
	public static StageAccess MaskForQueue(StageAccess stageAccess, QueueType queue)
	{
		var result = StageAccess();
		result.StageMask = MaskStagesForQueue(stageAccess.StageMask, queue);
		result.AccessMask = MaskAccessForQueue(stageAccess.AccessMask, queue);
		return result;
	}

	/// The stages and accesses a state covers.
	///
	/// A state is a FLAG SET, so several reads combine and the masks accumulate: that is
	/// what makes one barrier into a combined read state cheaper than several separate ones.
	public static StageAccess GetStageAccess(ResourceState state)
	{
		var result = StageAccess();

		if (state.HasFlag(.VertexBuffer))
		{
			result.StageMask |= .VK_PIPELINE_STAGE_2_VERTEX_INPUT_BIT;
			result.AccessMask |= .VK_ACCESS_2_VERTEX_ATTRIBUTE_READ_BIT;
		}
		if (state.HasFlag(.IndexBuffer))
		{
			result.StageMask |= .VK_PIPELINE_STAGE_2_INDEX_INPUT_BIT;
			result.AccessMask |= .VK_ACCESS_2_INDEX_READ_BIT;
		}
		if (state.HasFlag(.UniformBuffer))
		{
			result.StageMask |= .VK_PIPELINE_STAGE_2_ALL_GRAPHICS_BIT
				| .VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT;
			result.AccessMask |= .VK_ACCESS_2_UNIFORM_READ_BIT;
		}
		if (state.HasFlag(.ShaderRead))
		{
			result.StageMask |= .VK_PIPELINE_STAGE_2_ALL_GRAPHICS_BIT
				| .VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT;
			result.AccessMask |= .VK_ACCESS_2_SHADER_READ_BIT;
		}
		if (state.HasFlag(.ShaderWrite))
		{
			result.StageMask |= .VK_PIPELINE_STAGE_2_ALL_GRAPHICS_BIT
				| .VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT;
			result.AccessMask |= .VK_ACCESS_2_SHADER_WRITE_BIT;
		}
		if (state.HasFlag(.RenderTarget))
		{
			result.StageMask |= .VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT;
			result.AccessMask |= .VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT
				| .VK_ACCESS_2_COLOR_ATTACHMENT_READ_BIT;
		}
		if (state.HasFlag(.DepthStencilWrite))
		{
			// Both fragment test stages: depth is touched before and after the fragment
			// shader, and naming only one leaves the other unordered.
			result.StageMask |= .VK_PIPELINE_STAGE_2_EARLY_FRAGMENT_TESTS_BIT
				| .VK_PIPELINE_STAGE_2_LATE_FRAGMENT_TESTS_BIT;
			result.AccessMask |= .VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT
				| .VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_READ_BIT;
		}
		if (state.HasFlag(.DepthStencilRead))
		{
			result.StageMask |= .VK_PIPELINE_STAGE_2_EARLY_FRAGMENT_TESTS_BIT
				| .VK_PIPELINE_STAGE_2_LATE_FRAGMENT_TESTS_BIT;
			result.AccessMask |= .VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_READ_BIT;
		}
		if (state.HasFlag(.IndirectArgument))
		{
			result.StageMask |= .VK_PIPELINE_STAGE_2_DRAW_INDIRECT_BIT;
			result.AccessMask |= .VK_ACCESS_2_INDIRECT_COMMAND_READ_BIT;
		}
		if (state.HasFlag(.CopySrc))
		{
			result.StageMask |= .VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT;
			result.AccessMask |= .VK_ACCESS_2_TRANSFER_READ_BIT;
		}
		if (state.HasFlag(.CopyDst))
		{
			result.StageMask |= .VK_PIPELINE_STAGE_2_ALL_TRANSFER_BIT;
			result.AccessMask |= .VK_ACCESS_2_TRANSFER_WRITE_BIT;
		}
		if (state.HasFlag(.Present))
		{
			// Bottom of pipe and NO access: the presentation engine's read is not one the
			// application's access masks can describe.
			result.StageMask |= .VK_PIPELINE_STAGE_2_BOTTOM_OF_PIPE_BIT;
		}
		// The synchronization2 spellings, not the legacy ones. They are numerically
		// identical, but Beef types Flags2 separately and will not take the legacy names.
		if (state.HasFlag(.AccelStructRead))
		{
			result.StageMask |= .VK_PIPELINE_STAGE_2_ACCELERATION_STRUCTURE_BUILD_BIT_KHR
				| .VK_PIPELINE_STAGE_2_RAY_TRACING_SHADER_BIT_KHR;
			result.AccessMask |= .VK_ACCESS_2_ACCELERATION_STRUCTURE_READ_BIT_KHR;
		}
		if (state.HasFlag(.AccelStructWrite))
		{
			result.StageMask |= .VK_PIPELINE_STAGE_2_ACCELERATION_STRUCTURE_BUILD_BIT_KHR;
			result.AccessMask |= .VK_ACCESS_2_ACCELERATION_STRUCTURE_WRITE_BIT_KHR;
		}
		if (state.HasFlag(.General))
		{
			result.StageMask |= .VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT;
			result.AccessMask |= .VK_ACCESS_2_MEMORY_READ_BIT | .VK_ACCESS_2_MEMORY_WRITE_BIT;
		}

		// A state that named no stage still needs one, and top of pipe is the safe end to
		// use: an empty stage mask is invalid and the layers reject it.
		if (result.StageMask == 0)
			result.StageMask = .VK_PIPELINE_STAGE_2_TOP_OF_PIPE_BIT;

		return result;
	}

	/// The image layout a texture should be in for a state.
	///
	/// Ordered by PRIORITY rather than combined, because an image has exactly one layout:
	/// where a state names several uses, the most restrictive wins.
	public static VkImageLayout GetImageLayout(ResourceState state,
		TextureFormat format = .Undefined)
	{
		if (state.HasFlag(.Present))
			return .VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
		if (state.HasFlag(.RenderTarget))
			return .VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
		if (state.HasFlag(.DepthStencilWrite))
			return .VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
		if (state.HasFlag(.DepthStencilRead))
			return .VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL;

		if (state.HasFlag(.ShaderRead))
		{
			// A sampled depth or stencil texture takes the DEPTH_STENCIL read only layout,
			// not the shader read only one, which is for colour alone.
			if (TextureFormats.IsDepthFormat(format))
				return .VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL;
			return .VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
		}

		if (state.HasFlag(.ShaderWrite))
			return .VK_IMAGE_LAYOUT_GENERAL;
		if (state.HasFlag(.CopySrc))
			return .VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
		if (state.HasFlag(.CopyDst))
			return .VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
		if (state.HasFlag(.General))
			return .VK_IMAGE_LAYOUT_GENERAL;

		return .VK_IMAGE_LAYOUT_UNDEFINED;
	}
}
