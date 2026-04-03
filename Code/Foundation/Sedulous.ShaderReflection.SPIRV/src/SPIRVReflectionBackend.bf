namespace Sedulous.ShaderReflection.SPIRV;

using System;
using System.Diagnostics;
using Sedulous.RHI;
using SPIRV_Cross;

/// SPIR-V reflection backend using SPIRV-Cross.
class SPIRVReflectionBackend : IReflectionBackend
{
	public ShaderFormat Format => .SPIRV;

	public Result<ReflectedShader> Reflect(Span<uint8> bytecode, StringView entryPoint = default)
	{
		// SPIR-V is uint32-aligned
		if (bytecode.Length == 0 || bytecode.Length % 4 != 0)
			return .Err;

		spvc_context context = .Null;
		if (SPIRV.spvc_context_create(&context) != .SPVC_SUCCESS)
			return .Err;

		defer SPIRV.spvc_context_destroy(context);

		// Parse SPIR-V bytecode
		spvc_parsed_ir parsedIr = .Null;
		let wordCount = (uint)(bytecode.Length / 4);
		if (SPIRV.spvc_context_parse_spirv(context, (SpvId*)bytecode.Ptr, wordCount, &parsedIr) != .SPVC_SUCCESS)
		{
			Debug.WriteLine("SPIRV reflection: failed to parse SPIR-V");
			return .Err;
		}

		// Create compiler (SPVC_BACKEND_NONE = reflection only)
		spvc_compiler compiler = .Null;
		if (SPIRV.spvc_context_create_compiler(context, .None, parsedIr, .Copy, &compiler) != .SPVC_SUCCESS)
		{
			Debug.WriteLine("SPIRV reflection: failed to create compiler");
			return .Err;
		}

		// Determine shader stage
		let execModel = SPIRV.spvc_compiler_get_execution_model(compiler);
		let stage = SPIRVTypeMapper.ToShaderStage(execModel);

		let result = new ReflectedShader();
		result.Stage = stage;

		// Set entry point
		if (!entryPoint.IsEmpty)
			result.EntryPoint.Set(entryPoint);
		else
			result.EntryPoint.Set("main");

		// Get shader resources
		spvc_resources resources = .Null;
		if (SPIRV.spvc_compiler_create_shader_resources(compiler, &resources) != .SPVC_SUCCESS)
		{
			delete result;
			return .Err;
		}

		// Extract resource bindings
		ReflectResourceType(compiler, resources, .UniformBuffer, stage, result);
		ReflectResourceType(compiler, resources, .StorageBuffer, stage, result);
		ReflectResourceType(compiler, resources, .SampledImage, stage, result);
		ReflectResourceType(compiler, resources, .SeparateImage, stage, result);
		ReflectResourceType(compiler, resources, .StorageImage, stage, result);
		ReflectResourceType(compiler, resources, .SeparateSamplers, stage, result);
		ReflectResourceType(compiler, resources, .AccelerationStructure, stage, result);

		// Extract vertex inputs (vertex shaders only)
		if (stage == .Vertex)
			ReflectVertexInputs(compiler, resources, result);

		// Extract push constants
		ReflectPushConstants(compiler, resources, stage, result);

		// Extract thread group size (compute, mesh, task shaders)
		if (stage == .Compute || stage == .Mesh || stage == .Task)
			ReflectThreadGroupSize(compiler, result);

		// Extract mesh shader output properties
		if (stage == .Mesh)
			ReflectMeshOutput(compiler, result);

		// Extract specialization constants
		ReflectSpecConstants(compiler, result);

		return .Ok(result);
	}

	private void ReflectResourceType(spvc_compiler compiler, spvc_resources resources,
		spvc_resource_type resourceType, ShaderStage stage, ReflectedShader result)
	{
		spvc_reflected_resource* resourceList = null;
		uint resourceCount = 0;
		if (SPIRV.spvc_resources_get_resource_list_for_type(resources, resourceType, &resourceList, &resourceCount) != .SPVC_SUCCESS)
			return;

		for (uint i = 0; i < resourceCount; i++)
		{
			let resource = resourceList[i];

			let set = SPIRV.spvc_compiler_get_decoration(compiler, .(resource.id), .SpvDecorationDescriptorSet);
			let binding = SPIRV.spvc_compiler_get_decoration(compiler, .(resource.id), .SpvDecorationBinding);

			// Check for NonWritable decoration (storage buffers)
			bool isNonWritable = false;
			if (resourceType == .StorageBuffer)
			{
				SpvDecoration* decorations = null;
				uint numDecorations = 0;
				if (SPIRV.spvc_compiler_get_buffer_block_decorations(compiler, resource.id, &decorations, &numDecorations) == .SPVC_SUCCESS)
				{
					for (uint d = 0; d < numDecorations; d++)
					{
						if (decorations[d] == .SpvDecorationNonWritable)
						{
							isNonWritable = true;
							break;
						}
					}
				}
			}

			// Check for NonWritable on storage images
			if (resourceType == .StorageImage)
				isNonWritable = SPIRV.spvc_compiler_has_decoration(compiler, .(resource.id), .SpvDecorationNonWritable);

			// Check if sampler is for a depth image (comparison sampler)
			bool isDepthImage = false;
			if (resourceType == .SeparateSamplers)
				isDepthImage = SPIRV.spvc_compiler_variable_is_depth_or_compare(compiler, resource.id);

			// Determine array count
			let typeHandle = SPIRV.spvc_compiler_get_type_handle(compiler, resource.type_id);
			uint32 count = 1;
			let numDims = SPIRV.spvc_type_get_num_array_dimensions(typeHandle);
			if (numDims > 0)
			{
				if (SPIRV.spvc_type_array_dimension_is_literal(typeHandle, 0))
					count = SPIRV.spvc_type_get_array_dimension(typeHandle, 0).Value;
				else
					count = 0; // Runtime-sized (bindless)
			}

			let bindingType = SPIRVTypeMapper.ToBindingType(resourceType, isNonWritable, isDepthImage);

			// Extract texture dimension and multisampled flag for image types
			var texDimension = TextureViewDimension.Texture2D;
			bool texMultisampled = false;
			if (resourceType == .SampledImage || resourceType == .SeparateImage || resourceType == .StorageImage)
			{
				let imgDim = SPIRV.spvc_type_get_image_dimension(typeHandle);
				let imgArrayed = SPIRV.spvc_type_get_image_arrayed(typeHandle);
				texDimension = SPIRVTypeMapper.ToTextureDimension(imgDim, imgArrayed);
				texMultisampled = SPIRV.spvc_type_get_image_multisampled(typeHandle);
			}

			// Convert bindless arrays to bindless binding types
			var finalType = bindingType;
			if (count == 0)
			{
				switch (bindingType)
				{
				case .SampledTexture:           finalType = .BindlessTextures;
				case .Sampler:                  finalType = .BindlessSamplers;
				case .StorageBufferReadOnly,
					 .StorageBufferReadWrite:   finalType = .BindlessStorageBuffers;
				case .StorageTextureReadOnly,
					 .StorageTextureReadWrite:  finalType = .BindlessStorageTextures;
				default:
				}
			}

			let name = resource.name != null ? result.InternString(StringView(resource.name)) : StringView();

			result.Bindings.Add(.()
			{
				Set = set,
				Binding = binding,
				Type = finalType,
				Stages = stage,
				Count = count,
				Name = name,
				TextureDimension = texDimension,
				TextureMultisampled = texMultisampled
			});
		}
	}

	private void ReflectVertexInputs(spvc_compiler compiler, spvc_resources resources, ReflectedShader result)
	{
		spvc_reflected_resource* inputList = null;
		uint inputCount = 0;
		if (SPIRV.spvc_resources_get_resource_list_for_type(resources, .StageInput, &inputList, &inputCount) != .SPVC_SUCCESS)
			return;

		for (uint i = 0; i < inputCount; i++)
		{
			let input = inputList[i];

			// Skip built-in inputs
			if (SPIRV.spvc_compiler_has_decoration(compiler, .(input.id), .SpvDecorationBuiltIn))
				continue;

			let location = SPIRV.spvc_compiler_get_decoration(compiler, .(input.id), .SpvDecorationLocation);

			let typeHandle = SPIRV.spvc_compiler_get_type_handle(compiler, input.type_id);
			let baseType = SPIRV.spvc_type_get_basetype(typeHandle);
			let vecSize = SPIRV.spvc_type_get_vector_size(typeHandle);

			let format = SPIRVTypeMapper.ToVertexFormat(baseType, vecSize);
			let name = input.name != null ? result.InternString(StringView(input.name)) : StringView();

			result.VertexInputs.Add(.()
			{
				Location = location,
				Format = format,
				Name = name
			});
		}
	}

	private void ReflectPushConstants(spvc_compiler compiler, spvc_resources resources,
		ShaderStage stage, ReflectedShader result)
	{
		spvc_reflected_resource* pcList = null;
		uint pcCount = 0;
		if (SPIRV.spvc_resources_get_resource_list_for_type(resources, .PushConstant, &pcList, &pcCount) != .SPVC_SUCCESS)
			return;

		for (uint i = 0; i < pcCount; i++)
		{
			let pc = pcList[i];
			let typeHandle = SPIRV.spvc_compiler_get_type_handle(compiler, pc.base_type_id);

			uint size = 0;
			if (SPIRV.spvc_compiler_get_declared_struct_size(compiler, typeHandle, &size) != .SPVC_SUCCESS)
				continue;

			result.PushConstants.Add(.()
			{
				Offset = 0,
				Size = (uint32)size,
				Stages = stage
			});
		}
	}

	private void ReflectThreadGroupSize(spvc_compiler compiler, ReflectedShader result)
	{
		result.ThreadGroupSize[0] = SPIRV.spvc_compiler_get_execution_mode_argument(compiler, .SpvExecutionModeLocalSize);
		result.ThreadGroupSize[1] = SPIRV.spvc_compiler_get_execution_mode_argument_by_index(compiler, .SpvExecutionModeLocalSize, 1);
		result.ThreadGroupSize[2] = SPIRV.spvc_compiler_get_execution_mode_argument_by_index(compiler, .SpvExecutionModeLocalSize, 2);
	}

	private void ReflectSpecConstants(spvc_compiler compiler, ReflectedShader result)
	{
		spvc_specialization_constant* constants = null;
		uint numConstants = 0;
		// The C API expects spvc_specialization_constant**; cast through void* for the Beef binding
		if (SPIRV.spvc_compiler_get_specialization_constants(compiler, (spvc_specialization_constant*)(void*)&constants, &numConstants) != .SPVC_SUCCESS)
			return;

		for (uint i = 0; i < numConstants; i++)
		{
			let sc = constants[i];

			// Get name
			let namePtr = SPIRV.spvc_compiler_get_name(compiler, .(sc.id));
			let name = namePtr != null ? result.InternString(StringView(namePtr)) : StringView();

			// Get constant handle to read type and default value
			let constHandle = SPIRV.spvc_compiler_get_constant_handle(compiler, sc.id);
			let typeId = SPIRV.spvc_constant_get_type(constHandle);
			let typeHandle = SPIRV.spvc_compiler_get_type_handle(compiler, typeId);
			let baseType = SPIRV.spvc_type_get_basetype(typeHandle);

			var scType = SpecConstantType.Unknown;
			uint32 defaultVal = 0;

			switch (baseType)
			{
			case .Boolean:
				scType = .Bool;
				defaultVal = SPIRV.spvc_constant_get_scalar_u32(constHandle, 0, 0);
			case .Int32:
				scType = .Int32;
				defaultVal = (uint32)SPIRV.spvc_constant_get_scalar_i32(constHandle, 0, 0);
			case .Uint32:
				scType = .Uint32;
				defaultVal = SPIRV.spvc_constant_get_scalar_u32(constHandle, 0, 0);
			case .Fp32:
				scType = .Float32;
				var f = SPIRV.spvc_constant_get_scalar_fp32(constHandle, 0, 0);
				defaultVal = *(uint32*)&f;
			default:
			}

			result.SpecConstants.Add(.()
			{
				ConstantId = sc.constant_id,
				Type = scType,
				DefaultValue = defaultVal,
				Name = name
			});
		}
	}

	private void ReflectMeshOutput(spvc_compiler compiler, ReflectedShader result)
	{
		result.MeshOutput.MaxVertices = SPIRV.spvc_compiler_get_execution_mode_argument(compiler, .SpvExecutionModeOutputVertices);
		result.MeshOutput.MaxPrimitives = SPIRV.spvc_compiler_get_execution_mode_argument(compiler, .SpvExecutionModeOutputPrimitivesEXT);

		// Determine output topology from execution modes
		SpvExecutionMode* modes = null;
		uint numModes = 0;
		// The C API expects SpvExecutionMode** but the Beef binding has SpvExecutionMode*; cast through void*
		if (SPIRV.spvc_compiler_get_execution_modes(compiler, (SpvExecutionMode*)(void*)&modes, &numModes) == .SPVC_SUCCESS)
		{
			for (uint i = 0; i < numModes; i++)
			{
				switch (modes[i])
				{
				case .SpvExecutionModeOutputTrianglesEXT: result.MeshOutput.Topology = .Triangles;
				case .SpvExecutionModeOutputLinesEXT:     result.MeshOutput.Topology = .Lines;
				case .SpvExecutionModeOutputPoints:       result.MeshOutput.Topology = .Points;
				default:
				}
			}
		}
	}
}
