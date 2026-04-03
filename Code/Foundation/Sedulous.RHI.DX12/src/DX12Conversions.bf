namespace Sedulous.RHI.DX12;

using Sedulous.RHI;
using Win32.Graphics.Dxgi.Common;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Direct3D;

/// Conversion utilities between RHI enums and DX12/DXGI enums.
static class DX12Conversions
{
	public static DXGI_FORMAT ToDxgiFormat(TextureFormat format)
	{
		switch (format)
		{
		case .Undefined:           return .DXGI_FORMAT_UNKNOWN;
		case .R8Unorm:             return .DXGI_FORMAT_R8_UNORM;
		case .R8Snorm:             return .DXGI_FORMAT_R8_SNORM;
		case .R8Uint:              return .DXGI_FORMAT_R8_UINT;
		case .R8Sint:              return .DXGI_FORMAT_R8_SINT;
		case .R16Uint:             return .DXGI_FORMAT_R16_UINT;
		case .R16Sint:             return .DXGI_FORMAT_R16_SINT;
		case .R16Float:            return .DXGI_FORMAT_R16_FLOAT;
		case .RG8Unorm:            return .DXGI_FORMAT_R8G8_UNORM;
		case .RG8Snorm:            return .DXGI_FORMAT_R8G8_SNORM;
		case .RG8Uint:             return .DXGI_FORMAT_R8G8_UINT;
		case .RG8Sint:             return .DXGI_FORMAT_R8G8_SINT;
		case .R32Uint:             return .DXGI_FORMAT_R32_UINT;
		case .R32Sint:             return .DXGI_FORMAT_R32_SINT;
		case .R32Float:            return .DXGI_FORMAT_R32_FLOAT;
		case .RG16Uint:            return .DXGI_FORMAT_R16G16_UINT;
		case .RG16Sint:            return .DXGI_FORMAT_R16G16_SINT;
		case .RG16Float:           return .DXGI_FORMAT_R16G16_FLOAT;
		case .RGBA8Unorm:          return .DXGI_FORMAT_R8G8B8A8_UNORM;
		case .RGBA8UnormSrgb:      return .DXGI_FORMAT_R8G8B8A8_UNORM_SRGB;
		case .RGBA8Snorm:          return .DXGI_FORMAT_R8G8B8A8_SNORM;
		case .RGBA8Uint:           return .DXGI_FORMAT_R8G8B8A8_UINT;
		case .RGBA8Sint:           return .DXGI_FORMAT_R8G8B8A8_SINT;
		case .BGRA8Unorm:          return .DXGI_FORMAT_B8G8R8A8_UNORM;
		case .BGRA8UnormSrgb:      return .DXGI_FORMAT_B8G8R8A8_UNORM_SRGB;
		case .RGB10A2Unorm:        return .DXGI_FORMAT_R10G10B10A2_UNORM;
		case .RGB10A2Uint:         return .DXGI_FORMAT_R10G10B10A2_UINT;
		case .RG11B10Float:        return .DXGI_FORMAT_R11G11B10_FLOAT;
		case .RGB9E5Float:         return .DXGI_FORMAT_R9G9B9E5_SHAREDEXP;
		case .RG32Uint:            return .DXGI_FORMAT_R32G32_UINT;
		case .RG32Sint:            return .DXGI_FORMAT_R32G32_SINT;
		case .RG32Float:           return .DXGI_FORMAT_R32G32_FLOAT;
		case .RGBA16Uint:          return .DXGI_FORMAT_R16G16B16A16_UINT;
		case .RGBA16Sint:          return .DXGI_FORMAT_R16G16B16A16_SINT;
		case .RGBA16Float:         return .DXGI_FORMAT_R16G16B16A16_FLOAT;
		case .RGBA16Unorm:         return .DXGI_FORMAT_R16G16B16A16_UNORM;
		case .RGBA16Snorm:         return .DXGI_FORMAT_R16G16B16A16_SNORM;
		case .RGBA32Uint:          return .DXGI_FORMAT_R32G32B32A32_UINT;
		case .RGBA32Sint:          return .DXGI_FORMAT_R32G32B32A32_SINT;
		case .RGBA32Float:         return .DXGI_FORMAT_R32G32B32A32_FLOAT;
		case .Depth16Unorm:        return .DXGI_FORMAT_D16_UNORM;
		case .Depth24Plus:         return .DXGI_FORMAT_D24_UNORM_S8_UINT;
		case .Depth24PlusStencil8: return .DXGI_FORMAT_D24_UNORM_S8_UINT;
		case .Depth32Float:        return .DXGI_FORMAT_D32_FLOAT;
		case .Depth32FloatStencil8:return .DXGI_FORMAT_D32_FLOAT_S8X24_UINT;
		case .Stencil8:            return .DXGI_FORMAT_R8_UINT; // No native stencil-only in DXGI
		case .BC1RGBAUnorm:        return .DXGI_FORMAT_BC1_UNORM;
		case .BC1RGBAUnormSrgb:    return .DXGI_FORMAT_BC1_UNORM_SRGB;
		case .BC2RGBAUnorm:        return .DXGI_FORMAT_BC2_UNORM;
		case .BC2RGBAUnormSrgb:    return .DXGI_FORMAT_BC2_UNORM_SRGB;
		case .BC3RGBAUnorm:        return .DXGI_FORMAT_BC3_UNORM;
		case .BC3RGBAUnormSrgb:    return .DXGI_FORMAT_BC3_UNORM_SRGB;
		case .BC4RUnorm:           return .DXGI_FORMAT_BC4_UNORM;
		case .BC4RSnorm:           return .DXGI_FORMAT_BC4_SNORM;
		case .BC5RGUnorm:          return .DXGI_FORMAT_BC5_UNORM;
		case .BC5RGSnorm:          return .DXGI_FORMAT_BC5_SNORM;
		case .BC6HRGBUfloat:       return .DXGI_FORMAT_BC6H_UF16;
		case .BC6HRGBFloat:        return .DXGI_FORMAT_BC6H_SF16;
		case .BC7RGBAUnorm:        return .DXGI_FORMAT_BC7_UNORM;
		case .BC7RGBAUnormSrgb:    return .DXGI_FORMAT_BC7_UNORM_SRGB;
		case .ASTC4x4Unorm,
			 .ASTC4x4UnormSrgb,
			 .ASTC5x5Unorm,
			 .ASTC5x5UnormSrgb,
			 .ASTC6x6Unorm,
			 .ASTC6x6UnormSrgb,
			 .ASTC8x8Unorm,
			 .ASTC8x8UnormSrgb:    return .DXGI_FORMAT_UNKNOWN; // ASTC not supported on DX12
		default:                   return .DXGI_FORMAT_UNKNOWN;
		}
	}

	public static TextureFormat FromDxgiFormat(DXGI_FORMAT format)
	{
		switch (format)
		{
		case .DXGI_FORMAT_R8G8B8A8_UNORM:      return .RGBA8Unorm;
		case .DXGI_FORMAT_R8G8B8A8_UNORM_SRGB: return .RGBA8UnormSrgb;
		case .DXGI_FORMAT_B8G8R8A8_UNORM:      return .BGRA8Unorm;
		case .DXGI_FORMAT_B8G8R8A8_UNORM_SRGB: return .BGRA8UnormSrgb;
		case .DXGI_FORMAT_R16G16B16A16_FLOAT:   return .RGBA16Float;
		case .DXGI_FORMAT_R10G10B10A2_UNORM:    return .RGB10A2Unorm;
		case .DXGI_FORMAT_R32G32B32A32_FLOAT:   return .RGBA32Float;
		default:                                return .Undefined;
		}
	}

	public static DXGI_FORMAT ToDxgiVertexFormat(VertexFormat format)
	{
		switch (format)
		{
		case .Uint8x2:     return .DXGI_FORMAT_R8G8_UINT;
		case .Uint8x4:     return .DXGI_FORMAT_R8G8B8A8_UINT;
		case .Sint8x2:     return .DXGI_FORMAT_R8G8_SINT;
		case .Sint8x4:     return .DXGI_FORMAT_R8G8B8A8_SINT;
		case .Unorm8x2:    return .DXGI_FORMAT_R8G8_UNORM;
		case .Unorm8x4:    return .DXGI_FORMAT_R8G8B8A8_UNORM;
		case .Snorm8x2:    return .DXGI_FORMAT_R8G8_SNORM;
		case .Snorm8x4:    return .DXGI_FORMAT_R8G8B8A8_SNORM;
		case .Uint16x2:    return .DXGI_FORMAT_R16G16_UINT;
		case .Uint16x4:    return .DXGI_FORMAT_R16G16B16A16_UINT;
		case .Sint16x2:    return .DXGI_FORMAT_R16G16_SINT;
		case .Sint16x4:    return .DXGI_FORMAT_R16G16B16A16_SINT;
		case .Unorm16x2:   return .DXGI_FORMAT_R16G16_UNORM;
		case .Unorm16x4:   return .DXGI_FORMAT_R16G16B16A16_UNORM;
		case .Snorm16x2:   return .DXGI_FORMAT_R16G16_SNORM;
		case .Snorm16x4:   return .DXGI_FORMAT_R16G16B16A16_SNORM;
		case .Float16x2:   return .DXGI_FORMAT_R16G16_FLOAT;
		case .Float16x4:   return .DXGI_FORMAT_R16G16B16A16_FLOAT;
		case .Float32:     return .DXGI_FORMAT_R32_FLOAT;
		case .Float32x2:   return .DXGI_FORMAT_R32G32_FLOAT;
		case .Float32x3:   return .DXGI_FORMAT_R32G32B32_FLOAT;
		case .Float32x4:   return .DXGI_FORMAT_R32G32B32A32_FLOAT;
		case .Uint32:      return .DXGI_FORMAT_R32_UINT;
		case .Uint32x2:    return .DXGI_FORMAT_R32G32_UINT;
		case .Uint32x3:    return .DXGI_FORMAT_R32G32B32_UINT;
		case .Uint32x4:    return .DXGI_FORMAT_R32G32B32A32_UINT;
		case .Sint32:      return .DXGI_FORMAT_R32_SINT;
		case .Sint32x2:    return .DXGI_FORMAT_R32G32_SINT;
		case .Sint32x3:    return .DXGI_FORMAT_R32G32B32_SINT;
		case .Sint32x4:    return .DXGI_FORMAT_R32G32B32A32_SINT;
		default:           return .DXGI_FORMAT_UNKNOWN;
		}
	}

	public static DXGI_FORMAT ToDxgiIndexFormat(IndexFormat format)
	{
		switch (format)
		{
		case .UInt16: return .DXGI_FORMAT_R16_UINT;
		case .UInt32: return .DXGI_FORMAT_R32_UINT;
		}
	}

	public static D3D12_COMMAND_LIST_TYPE ToCommandListType(QueueType type)
	{
		switch (type)
		{
		case .Graphics: return .D3D12_COMMAND_LIST_TYPE_DIRECT;
		case .Compute:  return .D3D12_COMMAND_LIST_TYPE_COMPUTE;
		case .Transfer: return .D3D12_COMMAND_LIST_TYPE_COPY;
		}
	}

	public static D3D12_HEAP_TYPE ToHeapType(MemoryLocation location)
	{
		switch (location)
		{
		case .GpuOnly: return .D3D12_HEAP_TYPE_DEFAULT;
		case .CpuToGpu: return .D3D12_HEAP_TYPE_UPLOAD;
		case .GpuToCpu: return .D3D12_HEAP_TYPE_READBACK;
		case .Auto: return .D3D12_HEAP_TYPE_DEFAULT;
		}
	}

	public static D3D12_RESOURCE_FLAGS ToResourceFlags(TextureUsage usage)
	{
		D3D12_RESOURCE_FLAGS flags = .D3D12_RESOURCE_FLAG_NONE;
		if (usage.HasFlag(.RenderTarget))  flags |= .D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET;
		if (usage.HasFlag(.DepthStencil))  flags |= .D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL;
		if (usage.HasFlag(.Storage))       flags |= .D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
		return flags;
	}

	public static D3D12_RESOURCE_FLAGS ToBufferFlags(BufferUsage usage)
	{
		D3D12_RESOURCE_FLAGS flags = .D3D12_RESOURCE_FLAG_NONE;
		if (usage.HasFlag(.Storage)) flags |= .D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
		if (usage.HasFlag(.AccelStructScratch)) flags |= .D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
		return flags;
	}

	public static D3D12_RESOURCE_DIMENSION ToResourceDimension(TextureDimension dim)
	{
		switch (dim)
		{
		case .Texture1D: return .D3D12_RESOURCE_DIMENSION_TEXTURE1D;
		case .Texture2D: return .D3D12_RESOURCE_DIMENSION_TEXTURE2D;
		case .Texture3D: return .D3D12_RESOURCE_DIMENSION_TEXTURE3D;
		}
	}

	public static D3D12_COMPARISON_FUNC ToComparisonFunc(CompareFunction func)
	{
		switch (func)
		{
		case .Never:        return .D3D12_COMPARISON_FUNC_NEVER;
		case .Less:         return .D3D12_COMPARISON_FUNC_LESS;
		case .Equal:        return .D3D12_COMPARISON_FUNC_EQUAL;
		case .LessEqual:    return .D3D12_COMPARISON_FUNC_LESS_EQUAL;
		case .Greater:      return .D3D12_COMPARISON_FUNC_GREATER;
		case .NotEqual:     return .D3D12_COMPARISON_FUNC_NOT_EQUAL;
		case .GreaterEqual: return .D3D12_COMPARISON_FUNC_GREATER_EQUAL;
		case .Always:       return .D3D12_COMPARISON_FUNC_ALWAYS;
		}
	}

	public static D3D12_TEXTURE_ADDRESS_MODE ToAddressMode(AddressMode mode)
	{
		switch (mode)
		{
		case .Repeat:        return .D3D12_TEXTURE_ADDRESS_MODE_WRAP;
		case .MirrorRepeat:  return .D3D12_TEXTURE_ADDRESS_MODE_MIRROR;
		case .ClampToEdge:   return .D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
		case .ClampToBorder: return .D3D12_TEXTURE_ADDRESS_MODE_BORDER;
		}
	}

	public static D3D12_FILTER ToFilter(FilterMode min, FilterMode mag, MipmapFilterMode mip, bool comparison)
	{
		// Build filter from components: D3D12 filter is encoded as bit flags
		bool minLinear = min == .Linear;
		bool magLinear = mag == .Linear;
		bool mipLinear = mip == .Linear;

		if (comparison)
		{
			if (!minLinear && !magLinear && !mipLinear) return .D3D12_FILTER_COMPARISON_MIN_MAG_MIP_POINT;
			if (!minLinear && !magLinear && mipLinear)  return .D3D12_FILTER_COMPARISON_MIN_MAG_POINT_MIP_LINEAR;
			if (!minLinear && magLinear && !mipLinear)  return .D3D12_FILTER_COMPARISON_MIN_POINT_MAG_LINEAR_MIP_POINT;
			if (!minLinear && magLinear && mipLinear)   return .D3D12_FILTER_COMPARISON_MIN_POINT_MAG_MIP_LINEAR;
			if (minLinear && !magLinear && !mipLinear)  return .D3D12_FILTER_COMPARISON_MIN_LINEAR_MAG_MIP_POINT;
			if (minLinear && !magLinear && mipLinear)   return .D3D12_FILTER_COMPARISON_MIN_LINEAR_MAG_POINT_MIP_LINEAR;
			if (minLinear && magLinear && !mipLinear)   return .D3D12_FILTER_COMPARISON_MIN_MAG_LINEAR_MIP_POINT;
			return .D3D12_FILTER_COMPARISON_MIN_MAG_MIP_LINEAR;
		}
		else
		{
			if (!minLinear && !magLinear && !mipLinear) return .D3D12_FILTER_MIN_MAG_MIP_POINT;
			if (!minLinear && !magLinear && mipLinear)  return .D3D12_FILTER_MIN_MAG_POINT_MIP_LINEAR;
			if (!minLinear && magLinear && !mipLinear)  return .D3D12_FILTER_MIN_POINT_MAG_LINEAR_MIP_POINT;
			if (!minLinear && magLinear && mipLinear)   return .D3D12_FILTER_MIN_POINT_MAG_MIP_LINEAR;
			if (minLinear && !magLinear && !mipLinear)  return .D3D12_FILTER_MIN_LINEAR_MAG_MIP_POINT;
			if (minLinear && !magLinear && mipLinear)   return .D3D12_FILTER_MIN_LINEAR_MAG_POINT_MIP_LINEAR;
			if (minLinear && magLinear && !mipLinear)   return .D3D12_FILTER_MIN_MAG_LINEAR_MIP_POINT;
			return .D3D12_FILTER_MIN_MAG_MIP_LINEAR;
		}
	}

	/// Returns the DXGI format suitable for SRV when the texture has a depth format.
	/// Depth formats need typeless for resource creation and typed for views.
	public static DXGI_FORMAT ToTypelessDepthFormat(TextureFormat format)
	{
		switch (format)
		{
		case .Depth16Unorm:         return .DXGI_FORMAT_R16_TYPELESS;
		case .Depth24Plus,
			 .Depth24PlusStencil8:  return .DXGI_FORMAT_R24G8_TYPELESS;
		case .Depth32Float:         return .DXGI_FORMAT_R32_TYPELESS;
		case .Depth32FloatStencil8: return .DXGI_FORMAT_R32G8X24_TYPELESS;
		default:                    return ToDxgiFormat(format);
		}
	}

	public static D3D12_PRIMITIVE_TOPOLOGY_TYPE ToPrimitiveTopologyType(PrimitiveTopology topology)
	{
		switch (topology)
		{
		case .PointList:     return .D3D12_PRIMITIVE_TOPOLOGY_TYPE_POINT;
		case .LineList,
			 .LineStrip:     return .D3D12_PRIMITIVE_TOPOLOGY_TYPE_LINE;
		case .TriangleList,
			 .TriangleStrip: return .D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
		}
	}

	public static D3D12_CULL_MODE ToCullMode(CullMode mode)
	{
		switch (mode)
		{
		case .None:  return .D3D12_CULL_MODE_NONE;
		case .Front: return .D3D12_CULL_MODE_FRONT;
		case .Back:  return .D3D12_CULL_MODE_BACK;
		}
	}

	public static D3D12_FILL_MODE ToFillMode(FillMode mode)
	{
		switch (mode)
		{
		case .Solid:     return .D3D12_FILL_MODE_SOLID;
		case .Wireframe: return .D3D12_FILL_MODE_WIREFRAME;
		}
	}

	public static D3D12_BLEND ToBlendFactor(BlendFactor factor)
	{
		switch (factor)
		{
		case .Zero:              return .D3D12_BLEND_ZERO;
		case .One:               return .D3D12_BLEND_ONE;
		case .Src:               return .D3D12_BLEND_SRC_COLOR;
		case .OneMinusSrc:       return .D3D12_BLEND_INV_SRC_COLOR;
		case .SrcAlpha:          return .D3D12_BLEND_SRC_ALPHA;
		case .OneMinusSrcAlpha:  return .D3D12_BLEND_INV_SRC_ALPHA;
		case .Dst:               return .D3D12_BLEND_DEST_COLOR;
		case .OneMinusDst:       return .D3D12_BLEND_INV_DEST_COLOR;
		case .DstAlpha:          return .D3D12_BLEND_DEST_ALPHA;
		case .OneMinusDstAlpha:  return .D3D12_BLEND_INV_DEST_ALPHA;
		case .SrcAlphaSaturated: return .D3D12_BLEND_SRC_ALPHA_SAT;
		case .Constant:          return .D3D12_BLEND_BLEND_FACTOR;
		case .OneMinusConstant:  return .D3D12_BLEND_INV_BLEND_FACTOR;
		}
	}

	public static D3D12_BLEND_OP ToBlendOp(BlendOperation op)
	{
		switch (op)
		{
		case .Add:             return .D3D12_BLEND_OP_ADD;
		case .Subtract:        return .D3D12_BLEND_OP_SUBTRACT;
		case .ReverseSubtract: return .D3D12_BLEND_OP_REV_SUBTRACT;
		case .Min:             return .D3D12_BLEND_OP_MIN;
		case .Max:             return .D3D12_BLEND_OP_MAX;
		}
	}

	public static D3D12_STENCIL_OP ToStencilOp(StencilOperation op)
	{
		switch (op)
		{
		case .Keep:           return .D3D12_STENCIL_OP_KEEP;
		case .Zero:           return .D3D12_STENCIL_OP_ZERO;
		case .Replace:        return .D3D12_STENCIL_OP_REPLACE;
		case .IncrementClamp: return .D3D12_STENCIL_OP_INCR_SAT;
		case .DecrementClamp: return .D3D12_STENCIL_OP_DECR_SAT;
		case .Invert:         return .D3D12_STENCIL_OP_INVERT;
		case .IncrementWrap:  return .D3D12_STENCIL_OP_INCR;
		case .DecrementWrap:  return .D3D12_STENCIL_OP_DECR;
		}
	}

	/// Maps BindingType to DX12 descriptor range type.
	public static D3D12_DESCRIPTOR_RANGE_TYPE ToDescriptorRangeType(BindingType type)
	{
		switch (type)
		{
		case .UniformBuffer:             return .D3D12_DESCRIPTOR_RANGE_TYPE_CBV;
		case .StorageBufferReadOnly:     return .D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
		case .StorageBufferReadWrite:    return .D3D12_DESCRIPTOR_RANGE_TYPE_UAV;
		case .SampledTexture:            return .D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
		case .StorageTextureReadOnly:    return .D3D12_DESCRIPTOR_RANGE_TYPE_UAV;
		case .StorageTextureReadWrite:   return .D3D12_DESCRIPTOR_RANGE_TYPE_UAV;
		case .Sampler:                   return .D3D12_DESCRIPTOR_RANGE_TYPE_SAMPLER;
		case .ComparisonSampler:         return .D3D12_DESCRIPTOR_RANGE_TYPE_SAMPLER;
		case .BindlessTextures:          return .D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
		case .BindlessSamplers:          return .D3D12_DESCRIPTOR_RANGE_TYPE_SAMPLER;
		case .BindlessStorageBuffers:    return .D3D12_DESCRIPTOR_RANGE_TYPE_UAV;
		case .BindlessStorageTextures:   return .D3D12_DESCRIPTOR_RANGE_TYPE_UAV;
		case .AccelerationStructure:     return .D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
		}
	}

	/// Returns true if the binding type uses the sampler descriptor heap.
	public static bool IsSamplerBinding(BindingType type)
	{
		switch (type)
		{
		case .Sampler, .ComparisonSampler, .BindlessSamplers: return true;
		default: return false;
		}
	}

	/// Returns the SRV-compatible format for sampling the depth plane.
	public static DXGI_FORMAT ToDepthSrvFormat(TextureFormat format)
	{
		switch (format)
		{
		case .Depth16Unorm:         return .DXGI_FORMAT_R16_UNORM;
		case .Depth24Plus,
			 .Depth24PlusStencil8:  return .DXGI_FORMAT_R24_UNORM_X8_TYPELESS;
		case .Depth32Float:         return .DXGI_FORMAT_R32_FLOAT;
		case .Depth32FloatStencil8: return .DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS;
		default:                    return ToDxgiFormat(format);
		}
	}

	/// Returns the SRV-compatible format for sampling the stencil plane.
	public static DXGI_FORMAT ToStencilSrvFormat(TextureFormat format)
	{
		switch (format)
		{
		case .Depth24PlusStencil8:  return .DXGI_FORMAT_X24_TYPELESS_G8_UINT;
		case .Depth32FloatStencil8: return .DXGI_FORMAT_X32_TYPELESS_G8X24_UINT;
		default:                    return ToDxgiFormat(format);
		}
	}
}
