namespace Sedulous.RHI.Vulkan;

using System;
using Bulkan;
using Sedulous.RHI;

/// Vulkan implementation of IPipelineLayout.
class VulkanPipelineLayout : IPipelineLayout
{
	private VkPipelineLayout mLayout;

	public this() { }

	public Result<void> Init(VulkanDevice device, PipelineLayoutDesc desc)
	{
		// Collect descriptor set layouts
		VkDescriptorSetLayout[] setLayouts = scope VkDescriptorSetLayout[desc.BindGroupLayouts.Length];
		for (int i = 0; i < desc.BindGroupLayouts.Length; i++)
		{
			let vkLayout = desc.BindGroupLayouts[i] as VulkanBindGroupLayout;
			if (vkLayout == null)
			{
				System.Diagnostics.Debug.WriteLine("VulkanPipelineLayout: bind group layout is not a VulkanBindGroupLayout");
				return .Err;
			}
			setLayouts[i] = vkLayout.Handle;
		}

		// Push constant ranges
		VkPushConstantRange[] pushRanges = scope VkPushConstantRange[desc.PushConstantRanges.Length];
		for (int i = 0; i < desc.PushConstantRanges.Length; i++)
		{
			pushRanges[i] = .();
			pushRanges[i].stageFlags = VulkanBindGroupLayout.ToVkShaderStageFlags(desc.PushConstantRanges[i].Stages);
			pushRanges[i].offset = desc.PushConstantRanges[i].Offset;
			pushRanges[i].size = desc.PushConstantRanges[i].Size;
		}

		VkPipelineLayoutCreateInfo layoutInfo = .();
		layoutInfo.setLayoutCount = (uint32)desc.BindGroupLayouts.Length;
		layoutInfo.pSetLayouts = setLayouts.CArray();
		layoutInfo.pushConstantRangeCount = (uint32)desc.PushConstantRanges.Length;
		layoutInfo.pPushConstantRanges = pushRanges.CArray();

		let result = VulkanNative.vkCreatePipelineLayout(device.Handle, &layoutInfo, null, &mLayout);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanPipelineLayout: vkCreatePipelineLayout failed ({result})");
			return .Err;
		}

		return .Ok;
	}

	public void Cleanup(VulkanDevice device)
	{
		if (mLayout.Handle != 0)
		{
			VulkanNative.vkDestroyPipelineLayout(device.Handle, mLayout, null);
			mLayout = .Null;
		}
	}

	public VkPipelineLayout Handle => mLayout;
}
