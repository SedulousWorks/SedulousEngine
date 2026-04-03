namespace Sedulous.ShaderReflection.DXIL;

using Sedulous.RHI;
using Sedulous.ShaderReflection;
using Win32.Graphics.Direct3D;

/// Maps D3D12 reflection types to Sedulous.RHI enums.
static class DXILTypeMapper
{
	/// Maps D3D_SHADER_INPUT_TYPE to BindingType.
	/// uFlags is checked for D3D_SIF_COMPARISON_SAMPLER on sampler types.
	public static BindingType ToBindingType(D3D_SHADER_INPUT_TYPE inputType, uint32 uFlags)
	{
		switch (inputType)
		{
		case .D3D_SIT_CBUFFER:                    return .UniformBuffer;
		case .D3D_SIT_TBUFFER:                    return .SampledTexture;
		case .D3D_SIT_TEXTURE:                    return .SampledTexture;
		case .D3D_SIT_SAMPLER:
			return (uFlags & (uint32)D3D_SHADER_INPUT_FLAGS.D3D_SIF_COMPARISON_SAMPLER) != 0
				? .ComparisonSampler : .Sampler;
		case .D3D_SIT_UAV_RWTYPED:                return .StorageTextureReadWrite;
		case .D3D_SIT_STRUCTURED:                 return .StorageBufferReadOnly;
		case .D3D_SIT_UAV_RWSTRUCTURED:           return .StorageBufferReadWrite;
		case .D3D_SIT_BYTEADDRESS:                return .StorageBufferReadOnly;
		case .D3D_SIT_UAV_RWBYTEADDRESS:          return .StorageBufferReadWrite;
		case .D3D_SIT_UAV_APPEND_STRUCTURED:      return .StorageBufferReadWrite;
		case .D3D_SIT_UAV_CONSUME_STRUCTURED:     return .StorageBufferReadWrite;
		case .D3D_SIT_UAV_RWSTRUCTURED_WITH_COUNTER: return .StorageBufferReadWrite;
		case .D3D_SIT_RTACCELERATIONSTRUCTURE:    return .AccelerationStructure;
		default:                                  return .UniformBuffer;
		}
	}

	/// Maps D3D_REGISTER_COMPONENT_TYPE + component mask to VertexFormat.
	/// Mask is a bitmask: bit0=x, bit1=y, bit2=z, bit3=w.
	public static VertexFormat ToVertexFormat(D3D_REGISTER_COMPONENT_TYPE componentType, uint8 mask)
	{
		// Count set bits to determine vector width
		int count = 0;
		var m = mask;
		while (m != 0) { count += m & 1; m >>= 1; }

		switch (componentType)
		{
		case .D3D_REGISTER_COMPONENT_FLOAT32:
			switch (count)
			{
			case 1: return .Float32;
			case 2: return .Float32x2;
			case 3: return .Float32x3;
			case 4: return .Float32x4;
			default: return .Float32;
			}
		case .D3D_REGISTER_COMPONENT_SINT32:
			switch (count)
			{
			case 1: return .Sint32;
			case 2: return .Sint32x2;
			case 3: return .Sint32x3;
			case 4: return .Sint32x4;
			default: return .Sint32;
			}
		case .D3D_REGISTER_COMPONENT_UINT32:
			switch (count)
			{
			case 1: return .Uint32;
			case 2: return .Uint32x2;
			case 3: return .Uint32x3;
			case 4: return .Uint32x4;
			default: return .Uint32;
			}
		default:
			return .Float32;
		}
	}

	/// Maps D3D_SRV_DIMENSION to TextureViewDimension.
	public static TextureViewDimension ToTextureDimension(D3D_SRV_DIMENSION dim)
	{
		switch (dim)
		{
		case .D3D_SRV_DIMENSION_TEXTURE1D:        return .Texture1D;
		case .D3D_SRV_DIMENSION_TEXTURE1DARRAY:   return .Texture1DArray;
		case .D3D_SRV_DIMENSION_TEXTURE2D:        return .Texture2D;
		case .D3D_SRV_DIMENSION_TEXTURE2DARRAY:   return .Texture2DArray;
		case .D3D_SRV_DIMENSION_TEXTURE2DMS:      return .Texture2D;
		case .D3D_SRV_DIMENSION_TEXTURE2DMSARRAY: return .Texture2DArray;
		case .D3D_SRV_DIMENSION_TEXTURE3D:        return .Texture3D;
		case .D3D_SRV_DIMENSION_TEXTURECUBE:      return .TextureCube;
		case .D3D_SRV_DIMENSION_TEXTURECUBEARRAY: return .TextureCubeArray;
		default:                                  return .Texture2D;
		}
	}

	/// Returns true if the D3D_SRV_DIMENSION indicates a multisampled texture.
	public static bool IsMultisampled(D3D_SRV_DIMENSION dim)
	{
		return dim == .D3D_SRV_DIMENSION_TEXTURE2DMS || dim == .D3D_SRV_DIMENSION_TEXTURE2DMSARRAY;
	}

	/// Maps D3D_PRIMITIVE_TOPOLOGY to MeshOutputTopology (for mesh shaders).
	public static MeshOutputTopology ToMeshTopology(D3D_PRIMITIVE_TOPOLOGY topology)
	{
		switch (topology)
		{
		case .D3D_PRIMITIVE_TOPOLOGY_POINTLIST:    return .Points;
		case .D3D_PRIMITIVE_TOPOLOGY_LINELIST:     return .Lines;
		case .D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST: return .Triangles;
		default:                                   return .Unknown;
		}
	}

	/// Determines the shader stage from the D3D12_SHADER_DESC Version field.
	/// The version encodes the shader type in bits [31:16].
	public static ShaderStage StageFromVersion(uint32 version)
	{
		// D3D12_SHADER_DESC.Version: high 16 bits = shader type per D3D12_SHADER_VERSION_TYPE
		let shaderType = (version >> 16) & 0xFFFF;
		switch (shaderType)
		{
		case 0:  return .Fragment;   // Pixel shader
		case 1:  return .Vertex;
		case 5:  return .Compute;
		case 13: return .Mesh;       // Mesh shader (SM6.5+)
		case 14: return .Task;       // Amplification/Task shader
		default: return .None;
		}
	}
}
