namespace Sedulous.ShaderReflection.SPIRV;

using Sedulous.RHI;
using SPIRV_Cross;

/// Maps SPIR-V types to Sedulous.RHI enums.
static class SPIRVTypeMapper
{
	/// Maps SPIR-V base type + vector size to VertexFormat.
	public static VertexFormat ToVertexFormat(spvc_basetype baseType, uint32 vecSize)
	{
		switch (baseType)
		{
		case .Fp32:
			switch (vecSize)
			{
			case 1: return .Float32;
			case 2: return .Float32x2;
			case 3: return .Float32x3;
			case 4: return .Float32x4;
			default: return .Float32;
			}
		case .Int32:
			switch (vecSize)
			{
			case 1: return .Sint32;
			case 2: return .Sint32x2;
			case 3: return .Sint32x3;
			case 4: return .Sint32x4;
			default: return .Sint32;
			}
		case .Uint32:
			switch (vecSize)
			{
			case 1: return .Uint32;
			case 2: return .Uint32x2;
			case 3: return .Uint32x3;
			case 4: return .Uint32x4;
			default: return .Uint32;
			}
		case .Fp16:
			switch (vecSize)
			{
			case 2: return .Float16x2;
			case 4: return .Float16x4;
			default: return .Float16x2;
			}
		default:
			return .Float32;
		}
	}

	/// Maps SpvExecutionModel to ShaderStage.
	public static ShaderStage ToShaderStage(SpvExecutionModel model)
	{
		switch (model)
		{
		case .SpvExecutionModelVertex:       return .Vertex;
		case .SpvExecutionModelFragment:     return .Fragment;
		case .SpvExecutionModelGLCompute:    return .Compute;
		case .SpvExecutionModelMeshEXT:      return .Mesh;
		case .SpvExecutionModelMeshNV:       return .Mesh;
		case .SpvExecutionModelTaskEXT:      return .Task;
		case .SpvExecutionModelTaskNV:       return .Task;
		case .SpvExecutionModelRayGenerationKHR:  return .RayGen;
		case .SpvExecutionModelClosestHitKHR:     return .ClosestHit;
		case .SpvExecutionModelMissKHR:           return .Miss;
		case .SpvExecutionModelAnyHitKHR:         return .AnyHit;
		case .SpvExecutionModelIntersectionKHR:   return .Intersection;
		default:                             return .None;
		}
	}

	/// Maps SpvDim + arrayed flag to TextureViewDimension.
	public static TextureViewDimension ToTextureDimension(SpvDim dim, bool arrayed)
	{
		switch (dim)
		{
		case .SpvDim1D:   return arrayed ? .Texture1DArray : .Texture1D;
		case .SpvDim2D:   return arrayed ? .Texture2DArray : .Texture2D;
		case .SpvDim3D:   return .Texture3D;
		case .SpvDimCube: return arrayed ? .TextureCubeArray : .TextureCube;
		default:          return .Texture2D;
		}
	}

	/// Maps spvc_resource_type to BindingType.
	/// For storage buffers, isNonWritable distinguishes read-only vs read-write.
	public static BindingType ToBindingType(spvc_resource_type resourceType, bool isNonWritable = false, bool isDepthImage = false)
	{
		switch (resourceType)
		{
		case .UniformBuffer:    return .UniformBuffer;
		case .StorageBuffer:    return isNonWritable ? .StorageBufferReadOnly : .StorageBufferReadWrite;
		case .SampledImage:     return .SampledTexture;
		case .SeparateImage:    return .SampledTexture;
		case .StorageImage:     return isNonWritable ? .StorageTextureReadOnly : .StorageTextureReadWrite;
		case .SeparateSamplers: return isDepthImage ? .ComparisonSampler : .Sampler;
		case .AccelerationStructure: return .AccelerationStructure;
		default:                return .UniformBuffer;
		}
	}
}
