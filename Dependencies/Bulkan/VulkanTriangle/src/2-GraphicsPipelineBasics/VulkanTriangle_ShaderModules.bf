using Bulkan;
using System.IO;
using System.Collections;
using System;
namespace VulkanTriangle;

extension VulkanTriangle
{
	private VkPipelineLayout pipelineLayout;
	private VkPipeline graphicsPipeline;

	void CreateShaderModule(List<uint8> code, ref VkShaderModule shaderModule)
	{
		VkShaderModuleCreateInfo createInfo = VkShaderModuleCreateInfo();
		createInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
		createInfo.codeSize = (uint32)code.Count;
		createInfo.pCode = (uint32*)code.Ptr;

		Helpers.CheckErrors(VulkanNative.vkCreateShaderModule(device, &createInfo, null, &shaderModule));
	}

	private void CreateGraphicsPipeline()
	{
		List<uint8> vertShaderCode = scope .();
		if (File.ReadAll("Shaders/vert.spv", vertShaderCode) case .Err) Console.WriteLine("ERROR: Failed to read vertex shader");

		List<uint8> fragShaderCode = scope .();
		if (File.ReadAll("Shaders/frag.spv", fragShaderCode) case .Err) Console.WriteLine("ERROR: Failed to read fragment shader");

		VkShaderModule vertShaderModule = default;
		this.CreateShaderModule(vertShaderCode, ref vertShaderModule);

		VkShaderModule fragShaderModule = default;
		this.CreateShaderModule(fragShaderCode, ref fragShaderModule);

		VkPipelineShaderStageCreateInfo vertShaderStageInfo = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
				stage = VkShaderStageFlags.VK_SHADER_STAGE_VERTEX_BIT,
				module = vertShaderModule,
				pName = "main"
			};

		VkPipelineShaderStageCreateInfo fragShaderStageInfo = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
				stage = VkShaderStageFlags.VK_SHADER_STAGE_FRAGMENT_BIT,
				module = fragShaderModule,
				pName = "main"
			};

		VkPipelineShaderStageCreateInfo[] shaderStages = scope VkPipelineShaderStageCreateInfo[](vertShaderStageInfo, fragShaderStageInfo);

		// Vertex Input
		VkPipelineVertexInputStateCreateInfo vertexInputInfo = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
				vertexBindingDescriptionCount = 0,
				pVertexBindingDescriptions = null, // Optional
				vertexAttributeDescriptionCount = 0,
				pVertexAttributeDescriptions = null // Optional
			};

		// Input assembly
		VkPipelineInputAssemblyStateCreateInfo inputAssembly = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
				topology = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
				primitiveRestartEnable = false
			};

		// Viewports and scissors
		VkViewport viewport = .()
			{
				x = 0.0f,
				y = 0.0f,
				width = (float)swapChainExtent.width,
				height = (float)swapChainExtent.height,
				minDepth = 0.0f,
				maxDepth = 1.0f
			};

		VkRect2D scissor = .()
			{
				offset = .(0, 0),
				extent = swapChainExtent
			};

		VkPipelineViewportStateCreateInfo viewportState = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
				viewportCount = 1,
				pViewports = &viewport,
				scissorCount = 1,
				pScissors = &scissor
			};

		// Rasterizer
		VkPipelineRasterizationStateCreateInfo rasterizer = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
				depthClampEnable = false,
				rasterizerDiscardEnable = false,
				polygonMode = VkPolygonMode.VK_POLYGON_MODE_FILL,
				lineWidth = 1.0f,
				cullMode = VkCullModeFlags.VK_CULL_MODE_BACK_BIT,
				frontFace = VkFrontFace.VK_FRONT_FACE_CLOCKWISE,
				depthBiasEnable = false,
				depthBiasConstantFactor = 0.0f, // Optional
				depthBiasClamp = 0.0f, // Optional
				depthBiasSlopeFactor = 0.0f // Optional
			};

		VkPipelineMultisampleStateCreateInfo multisampling = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
				sampleShadingEnable = false,
				rasterizationSamples = VkSampleCountFlags.VK_SAMPLE_COUNT_1_BIT,
				minSampleShading = 1.0f, // Optional
				pSampleMask = null, // Optional
				alphaToCoverageEnable = false, // Optional
				alphaToOneEnable = false // Optional
			};

		// Depth and Stencil testing
		//VkPipelineDepthStencilStateCreateInfo

		// Color blending
		VkPipelineColorBlendAttachmentState colorBlendAttachment = .()
			{
				colorWriteMask = VkColorComponentFlags.VK_COLOR_COMPONENT_R_BIT |
					VkColorComponentFlags.VK_COLOR_COMPONENT_G_BIT |
					VkColorComponentFlags.VK_COLOR_COMPONENT_B_BIT |
					VkColorComponentFlags.VK_COLOR_COMPONENT_A_BIT,
				blendEnable = false,
				srcColorBlendFactor = VkBlendFactor.VK_BLEND_FACTOR_ONE, // Optional
				dstColorBlendFactor = VkBlendFactor.VK_BLEND_FACTOR_ZERO, // Optional
				colorBlendOp = VkBlendOp.VK_BLEND_OP_ADD, // Optional
				srcAlphaBlendFactor = VkBlendFactor.VK_BLEND_FACTOR_ONE, // Optional
				dstAlphaBlendFactor = VkBlendFactor.VK_BLEND_FACTOR_ZERO, // Optional
				alphaBlendOp = VkBlendOp.VK_BLEND_OP_ADD // Optional
			};

		VkPipelineColorBlendStateCreateInfo colorBlending = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
				logicOpEnable = false,
				logicOp = VkLogicOp.VK_LOGIC_OP_COPY, // Optional
				attachmentCount = 1,
				pAttachments = &colorBlendAttachment,
				blendConstants = .(0.0f, 0.0f, 0.0f, 0.0f) // Optional
			};

		VkPipelineLayoutCreateInfo pipelineLayoutInfo = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
				setLayoutCount = 0, // Optional
				pSetLayouts = null, // Optional
				pushConstantRangeCount = 0, // Optional
				pPushConstantRanges = null // Optional
			};

		VkResult result = VulkanNative.vkCreatePipelineLayout(device, &pipelineLayoutInfo, null, &pipelineLayout);
		Helpers.CheckErrors(result);

		VkGraphicsPipelineCreateInfo pipelineInfo = .()
			{
				sType = VkStructureType.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
				stageCount = (uint32)shaderStages.Count,
				pStages = shaderStages.Ptr,
				pVertexInputState = &vertexInputInfo,
				pInputAssemblyState = &inputAssembly,
				pViewportState = &viewportState,
				pRasterizationState = &rasterizer,
				pMultisampleState = &multisampling,
				pDepthStencilState = null, // Optional
				pColorBlendState = &colorBlending,
				pDynamicState = null, // Optional
				layout = this.pipelineLayout,
				renderPass = this.renderPass,
				subpass = 0,
				basePipelineHandle = 0, // Optional
				basePipelineIndex = -1 // Optional
			};


		result = VulkanNative.vkCreateGraphicsPipelines(device, .Null, 1, &pipelineInfo, null, &graphicsPipeline);
		Helpers.CheckErrors(result);

		VulkanNative.vkDestroyShaderModule(device, fragShaderModule, null);
		VulkanNative.vkDestroyShaderModule(device, vertShaderModule, null);
	}
}