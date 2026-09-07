using System;
using System.Collections;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A compiled mesh shader pipeline.
///
/// A graphics pipeline like the render one, except there is NO vertex input and no input
/// assembly at all: a mesh shader produces its own primitives rather than reading a vertex
/// buffer, which is the point of it.
class VulkanMeshPipeline : IMeshPipeline
{
	private VkPipeline mPipeline;
	private VulkanPipelineLayout mLayout;

	public IPipelineLayout Layout => mLayout;
	public VkPipeline Handle => mPipeline;

	public Result<void> Initialize(VkDevice device, MeshPipelineDesc desc)
	{
		mLayout = desc.Layout as VulkanPipelineLayout;
		if (mLayout == null)
			return .Err;

		let meshModule = desc.Mesh.Module as VulkanShaderModule;
		if (meshModule == null)
			return .Err;

		let taskEntry = scope String();
		let meshEntry = scope String(desc.Mesh.EntryPoint);
		let fragmentEntry = scope String();
		let stages = scope List<VkPipelineShaderStageCreateInfo>();

		// The task stage is optional: without it the mesh shader is dispatched directly.
		if (desc.Task.HasValue)
		{
			if (let taskModule = desc.Task.Value.Module as VulkanShaderModule)
			{
				taskEntry.Set(desc.Task.Value.EntryPoint);
				VkPipelineShaderStageCreateInfo taskStage = .();
				taskStage.stage = .VK_SHADER_STAGE_TASK_BIT_EXT;
				taskStage.module = taskModule.Handle;
				taskStage.pName = taskEntry.CStr();
				stages.Add(taskStage);
			}
		}

		VkPipelineShaderStageCreateInfo meshStage = .();
		meshStage.stage = .VK_SHADER_STAGE_MESH_BIT_EXT;
		meshStage.module = meshModule.Handle;
		meshStage.pName = meshEntry.CStr();
		stages.Add(meshStage);

		if (desc.Fragment.HasValue)
		{
			if (let fragmentModule = desc.Fragment.Value.Shader.Module as VulkanShaderModule)
			{
				fragmentEntry.Set(desc.Fragment.Value.Shader.EntryPoint);
				VkPipelineShaderStageCreateInfo fragmentStage = .();
				fragmentStage.stage = .VK_SHADER_STAGE_FRAGMENT_BIT;
				fragmentStage.module = fragmentModule.Handle;
				fragmentStage.pName = fragmentEntry.CStr();
				stages.Add(fragmentStage);
			}
		}

		VkPipelineViewportStateCreateInfo viewportState = .();
		viewportState.viewportCount = 1;
		viewportState.scissorCount = 1;

		VkPipelineRasterizationStateCreateInfo rasterization = .();
		rasterization.depthClampEnable = !desc.Primitive.DepthClipEnabled;
		rasterization.polygonMode = VulkanConversions.ToVkPolygonMode(desc.Primitive.FillMode);
		rasterization.cullMode = VulkanConversions.ToVkCullMode(desc.Primitive.CullMode);
		rasterization.frontFace = VulkanConversions.ToVkFrontFace(desc.Primitive.FrontFace);
		rasterization.lineWidth = 1.0f;

		var sampleMask = desc.Multisample.Mask;
		VkPipelineMultisampleStateCreateInfo multisample = .();
		multisample.rasterizationSamples = VulkanConversions.ToVkSampleCount(desc.Multisample.Count);
		multisample.alphaToCoverageEnable = desc.Multisample.AlphaToCoverageEnabled;
		multisample.pSampleMask = &sampleMask;

		let targets = desc.ColorTargets;
		let targetCount = targets.Length;
		let blendAttachments = scope VkPipelineColorBlendAttachmentState[targetCount == 0 ? 1 : targetCount];
		for (int i < targetCount)
		{
			blendAttachments[i] = default;
			blendAttachments[i].colorWriteMask =
				VulkanConversions.ToVkColorWriteMask(targets[i].WriteMask);
			if (targets[i].Blend.HasValue)
			{
				let blend = targets[i].Blend.Value;
				blendAttachments[i].blendEnable = true;
				blendAttachments[i].srcColorBlendFactor = VulkanConversions.ToVkBlendFactor(blend.Color.SrcFactor);
				blendAttachments[i].dstColorBlendFactor = VulkanConversions.ToVkBlendFactor(blend.Color.DstFactor);
				blendAttachments[i].colorBlendOp = VulkanConversions.ToVkBlendOp(blend.Color.Operation);
				blendAttachments[i].srcAlphaBlendFactor = VulkanConversions.ToVkBlendFactor(blend.Alpha.SrcFactor);
				blendAttachments[i].dstAlphaBlendFactor = VulkanConversions.ToVkBlendFactor(blend.Alpha.DstFactor);
				blendAttachments[i].alphaBlendOp = VulkanConversions.ToVkBlendOp(blend.Alpha.Operation);
			}
		}

		VkPipelineColorBlendStateCreateInfo colorBlend = .();
		colorBlend.attachmentCount = (uint32)targetCount;
		colorBlend.pAttachments = &blendAttachments[0];

		VkPipelineDepthStencilStateCreateInfo depthStencil = .();
		if (desc.DepthStencil.HasValue)
		{
			let source = desc.DepthStencil.Value;
			depthStencil.depthTestEnable = source.DepthTestEnabled;
			depthStencil.depthWriteEnable = source.DepthWriteEnabled;
			depthStencil.depthCompareOp = VulkanConversions.ToVkCompareOp(source.DepthCompare);
			depthStencil.stencilTestEnable = source.StencilEnabled;
		}

		let dynamicStates = scope VkDynamicState[4](
			.VK_DYNAMIC_STATE_VIEWPORT, .VK_DYNAMIC_STATE_SCISSOR,
			.VK_DYNAMIC_STATE_BLEND_CONSTANTS, .VK_DYNAMIC_STATE_STENCIL_REFERENCE);
		VkPipelineDynamicStateCreateInfo dynamicState = .();
		dynamicState.dynamicStateCount = 4;
		dynamicState.pDynamicStates = &dynamicStates[0];

		let colorFormats = scope VkFormat[targetCount == 0 ? 1 : targetCount];
		for (int i < targetCount)
			colorFormats[i] = VulkanConversions.ToVkFormat(targets[i].Format);

		VkPipelineRenderingCreateInfo renderingInfo = .();
		renderingInfo.colorAttachmentCount = (uint32)targetCount;
		renderingInfo.pColorAttachmentFormats = &colorFormats[0];
		if (desc.DepthStencil.HasValue)
		{
			let format = desc.DepthStencil.Value.Format;
			let vkFormat = VulkanConversions.ToVkFormat(format);
			if (TextureFormats.HasDepth(format))
				renderingInfo.depthAttachmentFormat = vkFormat;
			if (TextureFormats.HasStencil(format))
				renderingInfo.stencilAttachmentFormat = vkFormat;
		}

		VkGraphicsPipelineCreateInfo createInfo = .();
		createInfo.pNext = &renderingInfo;
		createInfo.stageCount = (uint32)stages.Count;
		createInfo.pStages = stages.Ptr;
		// Both NULL, which is what makes this a mesh pipeline: there is no vertex stream to
		// describe and nothing to assemble.
		createInfo.pVertexInputState = null;
		createInfo.pInputAssemblyState = null;
		createInfo.pViewportState = &viewportState;
		createInfo.pRasterizationState = &rasterization;
		createInfo.pMultisampleState = &multisample;
		createInfo.pDepthStencilState = desc.DepthStencil.HasValue ? &depthStencil : null;
		createInfo.pColorBlendState = &colorBlend;
		createInfo.pDynamicState = &dynamicState;
		createInfo.layout = mLayout.Handle;

		VkPipelineCache cache = .Null;
		if (let pipelineCache = desc.Cache as VulkanPipelineCache)
			cache = pipelineCache.Handle;

		if (VulkanNative.vkCreateGraphicsPipelines(device, cache, 1, &createInfo, null, &mPipeline)
			!= .VK_SUCCESS)
			return .Err;
		return .Ok;
	}

	public void Cleanup(VkDevice device)
	{
		if (mPipeline != .Null)
		{
			VulkanNative.vkDestroyPipeline(device, mPipeline, null);
			mPipeline = .Null;
		}
	}
}
