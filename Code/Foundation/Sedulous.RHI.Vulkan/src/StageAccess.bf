using Bulkan;

namespace Sedulous.RHI.Vulkan;

/// The pipeline stages and access kinds one resource state implies.
///
/// A barrier is expressed in Vulkan as a stage and an access mask on each side, not as a
/// state, so a state has to be translated into both before it can be submitted.
struct StageAccess
{
	public VkPipelineStageFlags2 StageMask = 0;
	public VkAccessFlags2 AccessMask = 0;

	public this() {}
}
