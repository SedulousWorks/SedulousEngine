using System;
using System.Collections;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// A compiled graphics pipeline.
///
/// Built for DYNAMIC RENDERING rather than a render pass object: the attachment formats
/// are declared here and a pass is begun against matching views, with no framebuffer or
/// VkRenderPass in between.
class VulkanRenderPipeline : IRenderPipeline
{
	private VkPipeline mPipeline;
	private VulkanPipelineLayout mLayout;

	public IPipelineLayout Layout => mLayout;
	public VkPipeline Handle => mPipeline;

	public Result<void> Initialize(VkDevice device, RenderPipelineDesc desc)
	{
		mLayout = desc.Layout as VulkanPipelineLayout;
		if (mLayout == null)
			return .Err;

		let vertexModule = desc.Vertex.Shader.Module as VulkanShaderModule;
		if (vertexModule == null)
			return .Err;

		// The entry point names must OUTLIVE the create call, since the structures only
		// hold pointers into them.
		let vertexEntry = scope String(desc.Vertex.Shader.EntryPoint);
		let fragmentEntry = scope String();

		let stages = scope List<VkPipelineShaderStageCreateInfo>();

		VkPipelineShaderStageCreateInfo vertexStage = .();
		vertexStage.stage = .VK_SHADER_STAGE_VERTEX_BIT;
		vertexStage.module = vertexModule.Handle;
		vertexStage.pName = vertexEntry.CStr();
		stages.Add(vertexStage);

		if (desc.Fragment.HasValue)
		{
			let fragment = desc.Fragment.Value;
			if (let fragmentModule = fragment.Shader.Module as VulkanShaderModule)
			{
				fragmentEntry.Set(fragment.Shader.EntryPoint);
				VkPipelineShaderStageCreateInfo fragmentStage = .();
				fragmentStage.stage = .VK_SHADER_STAGE_FRAGMENT_BIT;
				fragmentStage.module = fragmentModule.Handle;
				fragmentStage.pName = fragmentEntry.CStr();
				stages.Add(fragmentStage);
			}
		}

		// ---- vertex input ----
		//
		// The buffer's INDEX is its binding number, so the order of the layouts here is the
		// order a caller binds vertex buffers in.
		let bindings = scope List<VkVertexInputBindingDescription>();
		let attributes = scope List<VkVertexInputAttributeDescription>();

		for (int i < desc.Vertex.Buffers.Length)
		{
			let buffer = desc.Vertex.Buffers[i];

			VkVertexInputBindingDescription binding = default;
			binding.binding = (uint32)i;
			binding.stride = buffer.Stride;
			binding.inputRate = (buffer.StepMode == .Instance)
				? .VK_VERTEX_INPUT_RATE_INSTANCE : .VK_VERTEX_INPUT_RATE_VERTEX;
			bindings.Add(binding);

			for (int j < buffer.Attributes.Length)
			{
				let source = buffer.Attributes[j];
				VkVertexInputAttributeDescription attribute = default;
				attribute.location = source.ShaderLocation;
				attribute.binding = (uint32)i;
				attribute.format = VulkanConversions.ToVkVertexFormat(source.Format);
				attribute.offset = source.Offset;
				attributes.Add(attribute);
			}
		}

		VkPipelineVertexInputStateCreateInfo vertexInput = .();
		vertexInput.vertexBindingDescriptionCount = (uint32)bindings.Count;
		vertexInput.pVertexBindingDescriptions = bindings.Ptr;
		vertexInput.vertexAttributeDescriptionCount = (uint32)attributes.Count;
		vertexInput.pVertexAttributeDescriptions = attributes.Ptr;

		VkPipelineInputAssemblyStateCreateInfo inputAssembly = .();
		inputAssembly.topology = VulkanConversions.ToVkTopology(desc.Primitive.Topology);

		// Counts only: the viewport and scissor are dynamic, so their values come from the
		// pass rather than being baked in.
		VkPipelineViewportStateCreateInfo viewportState = .();
		viewportState.viewportCount = 1;
		viewportState.scissorCount = 1;

		VkPipelineRasterizationStateCreateInfo rasterization = .();
		// The two are INVERSES: clipping enabled means clamping disabled.
		rasterization.depthClampEnable = !desc.Primitive.DepthClipEnabled;
		rasterization.polygonMode = VulkanConversions.ToVkPolygonMode(desc.Primitive.FillMode);
		rasterization.cullMode = VulkanConversions.ToVkCullMode(desc.Primitive.CullMode);
		rasterization.frontFace = VulkanConversions.ToVkFrontFace(desc.Primitive.FrontFace);
		rasterization.lineWidth = 1.0f;

		if (desc.DepthStencil.HasValue)
		{
			let depth = desc.DepthStencil.Value;
			// Enabled by either bias being non zero, so a caller sets the numbers and not a
			// flag that could disagree with them.
			rasterization.depthBiasEnable = (depth.DepthBias != 0)
				|| (depth.DepthBiasSlopeScale != 0);
			rasterization.depthBiasConstantFactor = (float)depth.DepthBias;
			rasterization.depthBiasSlopeFactor = depth.DepthBiasSlopeScale;
			rasterization.depthBiasClamp = depth.DepthBiasClamp;
		}

		var sampleMask = desc.Multisample.Mask;
		VkPipelineMultisampleStateCreateInfo multisample = .();
		multisample.rasterizationSamples = VulkanConversions.ToVkSampleCount(desc.Multisample.Count);
		multisample.alphaToCoverageEnable = desc.Multisample.AlphaToCoverageEnabled;
		multisample.pSampleMask = &sampleMask;

		// ---- colour blending ----
		let targets = desc.Fragment.HasValue ? desc.Fragment.Value.Targets
			: Span<ColorTargetState>();
		let targetCount = targets.Length;
		let blendAttachments = scope VkPipelineColorBlendAttachmentState[targetCount == 0 ? 1 : targetCount];

		for (int i < targetCount)
		{
			blendAttachments[i] = default;
			blendAttachments[i].colorWriteMask =
				VulkanConversions.ToVkColorWriteMask(targets[i].WriteMask);

			// No blend state means the hardware skips the read entirely, which is not the
			// same as a blend that happens to pass through.
			if (targets[i].Blend.HasValue)
			{
				let blend = targets[i].Blend.Value;
				blendAttachments[i].blendEnable = true;
				blendAttachments[i].srcColorBlendFactor =
					VulkanConversions.ToVkBlendFactor(blend.Color.SrcFactor);
				blendAttachments[i].dstColorBlendFactor =
					VulkanConversions.ToVkBlendFactor(blend.Color.DstFactor);
				blendAttachments[i].colorBlendOp =
					VulkanConversions.ToVkBlendOp(blend.Color.Operation);
				blendAttachments[i].srcAlphaBlendFactor =
					VulkanConversions.ToVkBlendFactor(blend.Alpha.SrcFactor);
				blendAttachments[i].dstAlphaBlendFactor =
					VulkanConversions.ToVkBlendFactor(blend.Alpha.DstFactor);
				blendAttachments[i].alphaBlendOp =
					VulkanConversions.ToVkBlendOp(blend.Alpha.Operation);
			}
		}

		VkPipelineColorBlendStateCreateInfo colorBlend = .();
		colorBlend.attachmentCount = (uint32)targetCount;
		colorBlend.pAttachments = &blendAttachments[0];

		// ---- depth and stencil ----
		VkPipelineDepthStencilStateCreateInfo depthStencil = .();
		if (desc.DepthStencil.HasValue)
		{
			let source = desc.DepthStencil.Value;
			depthStencil.depthTestEnable = source.DepthTestEnabled;
			depthStencil.depthWriteEnable = source.DepthWriteEnabled;
			depthStencil.depthCompareOp = VulkanConversions.ToVkCompareOp(source.DepthCompare);
			depthStencil.stencilTestEnable = source.StencilEnabled;

			// The read and write masks are shared by both faces: the RHI keeps one pair
			// rather than one per face, which is what almost every use wants.
			depthStencil.front = .()
				{
					failOp = VulkanConversions.ToVkStencilOp(source.StencilFront.FailOp),
					passOp = VulkanConversions.ToVkStencilOp(source.StencilFront.PassOp),
					depthFailOp = VulkanConversions.ToVkStencilOp(source.StencilFront.DepthFailOp),
					compareOp = VulkanConversions.ToVkCompareOp(source.StencilFront.Compare),
					compareMask = source.StencilReadMask,
					writeMask = source.StencilWriteMask
				};
			depthStencil.back = .()
				{
					failOp = VulkanConversions.ToVkStencilOp(source.StencilBack.FailOp),
					passOp = VulkanConversions.ToVkStencilOp(source.StencilBack.PassOp),
					depthFailOp = VulkanConversions.ToVkStencilOp(source.StencilBack.DepthFailOp),
					compareOp = VulkanConversions.ToVkCompareOp(source.StencilBack.Compare),
					compareMask = source.StencilReadMask,
					writeMask = source.StencilWriteMask
				};
		}

		// The four states the RHI lets a pass change. Baking these would mean recompiling a
		// pipeline for every viewport.
		let dynamicStates = scope VkDynamicState[4](
			.VK_DYNAMIC_STATE_VIEWPORT, .VK_DYNAMIC_STATE_SCISSOR,
			.VK_DYNAMIC_STATE_BLEND_CONSTANTS, .VK_DYNAMIC_STATE_STENCIL_REFERENCE);

		VkPipelineDynamicStateCreateInfo dynamicState = .();
		dynamicState.dynamicStateCount = 4;
		dynamicState.pDynamicStates = &dynamicStates[0];

		// ---- dynamic rendering ----
		//
		// The attachment FORMATS are declared on the pipeline instead of a render pass
		// object, and a pass is begun directly against views that match.
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
			// Set per ASPECT: a depth only format leaves the stencil slot undefined, and
			// naming it there would not match the attachment.
			if (TextureFormats.HasDepth(format))
				renderingInfo.depthAttachmentFormat = vkFormat;
			if (TextureFormats.HasStencil(format))
				renderingInfo.stencilAttachmentFormat = vkFormat;
		}

		VkGraphicsPipelineCreateInfo createInfo = .();
		createInfo.pNext = &renderingInfo;
		createInfo.stageCount = (uint32)stages.Count;
		createInfo.pStages = stages.Ptr;
		createInfo.pVertexInputState = &vertexInput;
		createInfo.pInputAssemblyState = &inputAssembly;
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
