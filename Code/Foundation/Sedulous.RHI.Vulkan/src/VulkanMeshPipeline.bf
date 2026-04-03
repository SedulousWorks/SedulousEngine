namespace Sedulous.RHI.Vulkan;

using System;
using System.Collections;
using Bulkan;
using Sedulous.RHI;

using static Sedulous.RHI.TextureFormatExt;

/// Vulkan implementation of IMeshPipeline.
class VulkanMeshPipeline : IMeshPipeline
{
	private VkPipeline mPipeline;
	private VulkanPipelineLayout mLayout;

	public IPipelineLayout Layout => mLayout;

	public this() { }

	public Result<void> Init(VulkanDevice device, MeshPipelineDesc desc)
	{
		mLayout = desc.Layout as VulkanPipelineLayout;
		if (mLayout == null) return .Err;

		// --- Shader stages ---
		List<VkPipelineShaderStageCreateInfo> stages = scope .();

		// Capture entry points
		let meshEntryPoint = scope String(desc.Mesh.EntryPoint);
		let taskEntryPoint = scope String();
		let fsEntryPoint = scope String();
		if (desc.Task != null)
			taskEntryPoint.Set(desc.Task.Value.EntryPoint);
		if (desc.Fragment != null)
			fsEntryPoint.Set(desc.Fragment.Value.EntryPoint);

		// Task stage (optional)
		if (desc.Task != null)
		{
			let task = desc.Task.Value;
			if (let vkModule = task.Module as VulkanShaderModule)
			{
				VkPipelineShaderStageCreateInfo stage = .();
				stage.stage = .VK_SHADER_STAGE_TASK_BIT_EXT;
				stage.module = vkModule.Handle;
				stage.pName = taskEntryPoint.CStr();
				stages.Add(stage);
			}
		}

		// Mesh stage (required)
		if (let vkModule = desc.Mesh.Module as VulkanShaderModule)
		{
			VkPipelineShaderStageCreateInfo stage = .();
			stage.stage = .VK_SHADER_STAGE_MESH_BIT_EXT;
			stage.module = vkModule.Handle;
			stage.pName = meshEntryPoint.CStr();
			stages.Add(stage);
		}
		else return .Err;

		// Fragment stage (optional)
		if (desc.Fragment != null)
		{
			let frag = desc.Fragment.Value;
			if (let vkModule = frag.Module as VulkanShaderModule)
			{
				VkPipelineShaderStageCreateInfo stage = .();
				stage.stage = .VK_SHADER_STAGE_FRAGMENT_BIT;
				stage.module = vkModule.Handle;
				stage.pName = fsEntryPoint.CStr();
				stages.Add(stage);
			}
		}

		// --- Viewport/Scissor (dynamic) ---
		VkPipelineViewportStateCreateInfo viewportState = .();
		viewportState.viewportCount = 1;
		viewportState.scissorCount = 1;

		// --- Rasterization ---
		VkPipelineRasterizationStateCreateInfo rasterization = .();
		rasterization.depthClampEnable = desc.Primitive.DepthClipEnabled ? VkBool32.False : VkBool32.True;
		rasterization.rasterizerDiscardEnable = VkBool32.False;
		rasterization.polygonMode = VulkanConversions.ToVkPolygonMode(desc.Primitive.FillMode);
		rasterization.cullMode = VulkanConversions.ToVkCullMode(desc.Primitive.CullMode);
		rasterization.frontFace = VulkanConversions.ToVkFrontFace(desc.Primitive.FrontFace);
		rasterization.lineWidth = 1.0f;

		if (desc.DepthStencil != null)
		{
			let ds = desc.DepthStencil.Value;
			rasterization.depthBiasEnable = (ds.DepthBias != 0 || ds.DepthBiasSlopeScale != 0) ? VkBool32.True : VkBool32.False;
			rasterization.depthBiasConstantFactor = (float)ds.DepthBias;
			rasterization.depthBiasSlopeFactor = ds.DepthBiasSlopeScale;
			rasterization.depthBiasClamp = ds.DepthBiasClamp;
		}

		// --- Multisample ---
		VkPipelineMultisampleStateCreateInfo multisample = .();
		multisample.rasterizationSamples = VulkanConversions.ToVkSampleCount(desc.Multisample.Count);
		multisample.alphaToCoverageEnable = desc.Multisample.AlphaToCoverageEnabled ? VkBool32.True : VkBool32.False;
		var sampleMask = desc.Multisample.Mask;
		multisample.pSampleMask = &sampleMask;

		// --- Color blend ---
		let vkMeshColorTargets = desc.ColorTargets;
		VkPipelineColorBlendAttachmentState[] blendAttachments = scope VkPipelineColorBlendAttachmentState[vkMeshColorTargets.Length];
		for (int i = 0; i < vkMeshColorTargets.Length; i++)
		{
			let target = vkMeshColorTargets[i];
			blendAttachments[i] = .();
			blendAttachments[i].colorWriteMask = VulkanConversions.ToVkColorWriteMask(target.WriteMask);

			if (target.Blend != null)
			{
				let blend = target.Blend.Value;
				blendAttachments[i].blendEnable = VkBool32.True;
				blendAttachments[i].srcColorBlendFactor = VulkanConversions.ToVkBlendFactor(blend.Color.SrcFactor);
				blendAttachments[i].dstColorBlendFactor = VulkanConversions.ToVkBlendFactor(blend.Color.DstFactor);
				blendAttachments[i].colorBlendOp = VulkanConversions.ToVkBlendOp(blend.Color.Operation);
				blendAttachments[i].srcAlphaBlendFactor = VulkanConversions.ToVkBlendFactor(blend.Alpha.SrcFactor);
				blendAttachments[i].dstAlphaBlendFactor = VulkanConversions.ToVkBlendFactor(blend.Alpha.DstFactor);
				blendAttachments[i].alphaBlendOp = VulkanConversions.ToVkBlendOp(blend.Alpha.Operation);
			}
		}

		VkPipelineColorBlendStateCreateInfo colorBlend = .();
		colorBlend.attachmentCount = (uint32)vkMeshColorTargets.Length;
		colorBlend.pAttachments = blendAttachments.CArray();

		// --- Depth/stencil ---
		VkPipelineDepthStencilStateCreateInfo depthStencil = .();
		if (desc.DepthStencil != null)
		{
			let ds = desc.DepthStencil.Value;
			depthStencil.depthTestEnable = ds.DepthTestEnabled ? VkBool32.True : VkBool32.False;
			depthStencil.depthWriteEnable = ds.DepthWriteEnabled ? VkBool32.True : VkBool32.False;
			depthStencil.depthCompareOp = VulkanConversions.ToVkCompareOp(ds.DepthCompare);
			depthStencil.stencilTestEnable = ds.StencilEnabled ? VkBool32.True : VkBool32.False;

			depthStencil.front.failOp = VulkanConversions.ToVkStencilOp(ds.StencilFront.FailOp);
			depthStencil.front.passOp = VulkanConversions.ToVkStencilOp(ds.StencilFront.PassOp);
			depthStencil.front.depthFailOp = VulkanConversions.ToVkStencilOp(ds.StencilFront.DepthFailOp);
			depthStencil.front.compareOp = VulkanConversions.ToVkCompareOp(ds.StencilFront.Compare);
			depthStencil.front.compareMask = ds.StencilReadMask;
			depthStencil.front.writeMask = ds.StencilWriteMask;

			depthStencil.back.failOp = VulkanConversions.ToVkStencilOp(ds.StencilBack.FailOp);
			depthStencil.back.passOp = VulkanConversions.ToVkStencilOp(ds.StencilBack.PassOp);
			depthStencil.back.depthFailOp = VulkanConversions.ToVkStencilOp(ds.StencilBack.DepthFailOp);
			depthStencil.back.compareOp = VulkanConversions.ToVkCompareOp(ds.StencilBack.Compare);
			depthStencil.back.compareMask = ds.StencilReadMask;
			depthStencil.back.writeMask = ds.StencilWriteMask;
		}

		// --- Dynamic state ---
		VkDynamicState[4] dynamicStates = .(
			.VK_DYNAMIC_STATE_VIEWPORT,
			.VK_DYNAMIC_STATE_SCISSOR,
			.VK_DYNAMIC_STATE_BLEND_CONSTANTS,
			.VK_DYNAMIC_STATE_STENCIL_REFERENCE
		);
		VkPipelineDynamicStateCreateInfo dynamicState = .();
		dynamicState.dynamicStateCount = (uint32)dynamicStates.Count;
		dynamicState.pDynamicStates = &dynamicStates;

		// --- Dynamic rendering (Vulkan 1.3) ---
		VkFormat[] colorFormats = scope VkFormat[vkMeshColorTargets.Length];
		for (int i = 0; i < vkMeshColorTargets.Length; i++)
			colorFormats[i] = VulkanConversions.ToVkFormat(vkMeshColorTargets[i].Format);

		VkPipelineRenderingCreateInfo renderingInfo = .();
		renderingInfo.colorAttachmentCount = (uint32)vkMeshColorTargets.Length;
		renderingInfo.pColorAttachmentFormats = colorFormats.CArray();
		if (desc.DepthStencil != null)
		{
			let dsFormat = VulkanConversions.ToVkFormat(desc.DepthStencil.Value.Format);
			if (desc.DepthStencil.Value.Format.HasDepth())
				renderingInfo.depthAttachmentFormat = dsFormat;
			if (desc.DepthStencil.Value.Format.HasStencil())
				renderingInfo.stencilAttachmentFormat = dsFormat;
		}

		// --- Create pipeline ---
		// Mesh shader pipelines use the same VkGraphicsPipelineCreateInfo but
		// without vertex input or input assembly state (no traditional vertex processing).
		VkGraphicsPipelineCreateInfo pipelineInfo = .();
		pipelineInfo.pNext = &renderingInfo;
		pipelineInfo.stageCount = (uint32)stages.Count;
		pipelineInfo.pStages = stages.Ptr;
		pipelineInfo.pVertexInputState = null;
		pipelineInfo.pInputAssemblyState = null;
		pipelineInfo.pViewportState = &viewportState;
		pipelineInfo.pRasterizationState = &rasterization;
		pipelineInfo.pMultisampleState = &multisample;
		pipelineInfo.pDepthStencilState = (desc.DepthStencil != null) ? &depthStencil : null;
		pipelineInfo.pColorBlendState = &colorBlend;
		pipelineInfo.pDynamicState = &dynamicState;
		pipelineInfo.layout = mLayout.Handle;

		VkPipelineCache cache = .Null;
		if (let vkCache = desc.Cache as VulkanPipelineCache)
			cache = vkCache.Handle;

		let result = VulkanNative.vkCreateGraphicsPipelines(device.Handle, cache, 1, &pipelineInfo, null, &mPipeline);
		if (result != .VK_SUCCESS)
			return .Err;

		return .Ok;
	}

	public void Cleanup(VulkanDevice device)
	{
		if (mPipeline.Handle != 0)
		{
			VulkanNative.vkDestroyPipeline(device.Handle, mPipeline, null);
			mPipeline = .Null;
		}
	}

	public VkPipeline Handle => mPipeline;
}
