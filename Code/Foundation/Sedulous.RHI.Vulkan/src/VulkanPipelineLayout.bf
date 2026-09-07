using System;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A pipeline layout: the set layouts a pipeline binds, and its push constant ranges.
class VulkanPipelineLayout : IPipelineLayout
{
	private VkPipelineLayout mLayout;

	public VkPipelineLayout Handle => mLayout;

	public Result<void> Initialize(VkDevice device, PipelineLayoutDesc desc)
	{
		let layoutCount = desc.BindGroupLayouts.Length;
		let setLayouts = scope VkDescriptorSetLayout[layoutCount == 0 ? 1 : layoutCount];

		for (int i < layoutCount)
		{
			let layout = desc.BindGroupLayouts[i] as VulkanBindGroupLayout;
			// A null or foreign layout would leave a null handle in the array, which the
			// driver dereferences: refused here instead.
			if (layout == null)
				return .Err;
			setLayouts[i] = layout.Handle;
		}

		let rangeCount = desc.PushConstantRanges.Length;
		let pushRanges = scope VkPushConstantRange[rangeCount == 0 ? 1 : rangeCount];
		for (int i < rangeCount)
		{
			let range = desc.PushConstantRanges[i];
			pushRanges[i] = default;
			pushRanges[i].stageFlags = VulkanConversions.ToVkShaderStageFlags(range.Stages);
			pushRanges[i].offset = range.Offset;
			pushRanges[i].size = range.Size;
		}

		VkPipelineLayoutCreateInfo createInfo = .();
		createInfo.setLayoutCount = (uint32)layoutCount;
		createInfo.pSetLayouts = (layoutCount > 0) ? &setLayouts[0] : null;
		createInfo.pushConstantRangeCount = (uint32)rangeCount;
		createInfo.pPushConstantRanges = (rangeCount > 0) ? &pushRanges[0] : null;

		if (VulkanNative.vkCreatePipelineLayout(device, &createInfo, null, &mLayout) != .VK_SUCCESS)
			return .Err;
		return .Ok;
	}

	public void Cleanup(VkDevice device)
	{
		if (mLayout != .Null)
		{
			VulkanNative.vkDestroyPipelineLayout(device, mLayout, null);
			mLayout = .Null;
		}
	}
}
