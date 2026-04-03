namespace Sedulous.RHI.Vulkan;

using Bulkan;

using static Sedulous.RHI.TextureFormatExt;

/// Conversion utilities between Sedulous.RHI enums and Vulkan enums.
static class VulkanConversions
{
	public static VkFormat ToVkFormat(TextureFormat format)
	{
		switch (format)
		{
		case .Undefined:          return .VK_FORMAT_UNDEFINED;
		case .R8Unorm:            return .VK_FORMAT_R8_UNORM;
		case .R8Snorm:            return .VK_FORMAT_R8_SNORM;
		case .R8Uint:             return .VK_FORMAT_R8_UINT;
		case .R8Sint:             return .VK_FORMAT_R8_SINT;
		case .R16Uint:            return .VK_FORMAT_R16_UINT;
		case .R16Sint:            return .VK_FORMAT_R16_SINT;
		case .R16Float:           return .VK_FORMAT_R16_SFLOAT;
		case .RG8Unorm:           return .VK_FORMAT_R8G8_UNORM;
		case .RG8Snorm:           return .VK_FORMAT_R8G8_SNORM;
		case .RG8Uint:            return .VK_FORMAT_R8G8_UINT;
		case .RG8Sint:            return .VK_FORMAT_R8G8_SINT;
		case .R32Uint:            return .VK_FORMAT_R32_UINT;
		case .R32Sint:            return .VK_FORMAT_R32_SINT;
		case .R32Float:           return .VK_FORMAT_R32_SFLOAT;
		case .RG16Uint:           return .VK_FORMAT_R16G16_UINT;
		case .RG16Sint:           return .VK_FORMAT_R16G16_SINT;
		case .RG16Float:          return .VK_FORMAT_R16G16_SFLOAT;
		case .RGBA8Unorm:         return .VK_FORMAT_R8G8B8A8_UNORM;
		case .RGBA8UnormSrgb:     return .VK_FORMAT_R8G8B8A8_SRGB;
		case .RGBA8Snorm:         return .VK_FORMAT_R8G8B8A8_SNORM;
		case .RGBA8Uint:          return .VK_FORMAT_R8G8B8A8_UINT;
		case .RGBA8Sint:          return .VK_FORMAT_R8G8B8A8_SINT;
		case .BGRA8Unorm:         return .VK_FORMAT_B8G8R8A8_UNORM;
		case .BGRA8UnormSrgb:     return .VK_FORMAT_B8G8R8A8_SRGB;
		case .RGB10A2Unorm:       return .VK_FORMAT_A2B10G10R10_UNORM_PACK32;
		case .RGB10A2Uint:        return .VK_FORMAT_A2B10G10R10_UINT_PACK32;
		case .RG11B10Float:       return .VK_FORMAT_B10G11R11_UFLOAT_PACK32;
		case .RGB9E5Float:        return .VK_FORMAT_E5B9G9R9_UFLOAT_PACK32;
		case .RG32Uint:           return .VK_FORMAT_R32G32_UINT;
		case .RG32Sint:           return .VK_FORMAT_R32G32_SINT;
		case .RG32Float:          return .VK_FORMAT_R32G32_SFLOAT;
		case .RGBA16Uint:         return .VK_FORMAT_R16G16B16A16_UINT;
		case .RGBA16Sint:         return .VK_FORMAT_R16G16B16A16_SINT;
		case .RGBA16Float:        return .VK_FORMAT_R16G16B16A16_SFLOAT;
		case .RGBA16Unorm:        return .VK_FORMAT_R16G16B16A16_UNORM;
		case .RGBA16Snorm:        return .VK_FORMAT_R16G16B16A16_SNORM;
		case .RGBA32Uint:         return .VK_FORMAT_R32G32B32A32_UINT;
		case .RGBA32Sint:         return .VK_FORMAT_R32G32B32A32_SINT;
		case .RGBA32Float:        return .VK_FORMAT_R32G32B32A32_SFLOAT;
		case .Depth16Unorm:       return .VK_FORMAT_D16_UNORM;
		case .Depth24Plus:        return .VK_FORMAT_X8_D24_UNORM_PACK32;
		case .Depth24PlusStencil8:return .VK_FORMAT_D24_UNORM_S8_UINT;
		case .Depth32Float:       return .VK_FORMAT_D32_SFLOAT;
		case .Depth32FloatStencil8:return .VK_FORMAT_D32_SFLOAT_S8_UINT;
		case .Stencil8:           return .VK_FORMAT_S8_UINT;
		case .BC1RGBAUnorm:       return .VK_FORMAT_BC1_RGBA_UNORM_BLOCK;
		case .BC1RGBAUnormSrgb:   return .VK_FORMAT_BC1_RGBA_SRGB_BLOCK;
		case .BC2RGBAUnorm:       return .VK_FORMAT_BC2_UNORM_BLOCK;
		case .BC2RGBAUnormSrgb:   return .VK_FORMAT_BC2_SRGB_BLOCK;
		case .BC3RGBAUnorm:       return .VK_FORMAT_BC3_UNORM_BLOCK;
		case .BC3RGBAUnormSrgb:   return .VK_FORMAT_BC3_SRGB_BLOCK;
		case .BC4RUnorm:          return .VK_FORMAT_BC4_UNORM_BLOCK;
		case .BC4RSnorm:          return .VK_FORMAT_BC4_SNORM_BLOCK;
		case .BC5RGUnorm:         return .VK_FORMAT_BC5_UNORM_BLOCK;
		case .BC5RGSnorm:         return .VK_FORMAT_BC5_SNORM_BLOCK;
		case .BC6HRGBUfloat:      return .VK_FORMAT_BC6H_UFLOAT_BLOCK;
		case .BC6HRGBFloat:       return .VK_FORMAT_BC6H_SFLOAT_BLOCK;
		case .BC7RGBAUnorm:       return .VK_FORMAT_BC7_UNORM_BLOCK;
		case .BC7RGBAUnormSrgb:   return .VK_FORMAT_BC7_SRGB_BLOCK;
		case .ASTC4x4Unorm:       return .VK_FORMAT_ASTC_4x4_UNORM_BLOCK;
		case .ASTC4x4UnormSrgb:   return .VK_FORMAT_ASTC_4x4_SRGB_BLOCK;
		case .ASTC5x5Unorm:       return .VK_FORMAT_ASTC_5x5_UNORM_BLOCK;
		case .ASTC5x5UnormSrgb:   return .VK_FORMAT_ASTC_5x5_SRGB_BLOCK;
		case .ASTC6x6Unorm:       return .VK_FORMAT_ASTC_6x6_UNORM_BLOCK;
		case .ASTC6x6UnormSrgb:   return .VK_FORMAT_ASTC_6x6_SRGB_BLOCK;
		case .ASTC8x8Unorm:       return .VK_FORMAT_ASTC_8x8_UNORM_BLOCK;
		case .ASTC8x8UnormSrgb:   return .VK_FORMAT_ASTC_8x8_SRGB_BLOCK;
		default:                  return .VK_FORMAT_UNDEFINED;
		}
	}

	public static TextureFormat FromVkFormat(VkFormat format)
	{
		switch (format)
		{
		case .VK_FORMAT_R8G8B8A8_UNORM:  return .RGBA8Unorm;
		case .VK_FORMAT_R8G8B8A8_SRGB:   return .RGBA8UnormSrgb;
		case .VK_FORMAT_B8G8R8A8_UNORM:  return .BGRA8Unorm;
		case .VK_FORMAT_B8G8R8A8_SRGB:   return .BGRA8UnormSrgb;
		case .VK_FORMAT_R16G16B16A16_SFLOAT: return .RGBA16Float;
		case .VK_FORMAT_A2B10G10R10_UNORM_PACK32: return .RGB10A2Unorm;
		default:                         return .Undefined;
		}
	}

	public static VkFormat ToVkVertexFormat(VertexFormat format)
	{
		switch (format)
		{
		case .Uint8x2:     return .VK_FORMAT_R8G8_UINT;
		case .Uint8x4:     return .VK_FORMAT_R8G8B8A8_UINT;
		case .Sint8x2:     return .VK_FORMAT_R8G8_SINT;
		case .Sint8x4:     return .VK_FORMAT_R8G8B8A8_SINT;
		case .Unorm8x2:    return .VK_FORMAT_R8G8_UNORM;
		case .Unorm8x4:    return .VK_FORMAT_R8G8B8A8_UNORM;
		case .Snorm8x2:    return .VK_FORMAT_R8G8_SNORM;
		case .Snorm8x4:    return .VK_FORMAT_R8G8B8A8_SNORM;
		case .Uint16x2:    return .VK_FORMAT_R16G16_UINT;
		case .Uint16x4:    return .VK_FORMAT_R16G16B16A16_UINT;
		case .Sint16x2:    return .VK_FORMAT_R16G16_SINT;
		case .Sint16x4:    return .VK_FORMAT_R16G16B16A16_SINT;
		case .Unorm16x2:   return .VK_FORMAT_R16G16_UNORM;
		case .Unorm16x4:   return .VK_FORMAT_R16G16B16A16_UNORM;
		case .Snorm16x2:   return .VK_FORMAT_R16G16_SNORM;
		case .Snorm16x4:   return .VK_FORMAT_R16G16B16A16_SNORM;
		case .Float16x2:   return .VK_FORMAT_R16G16_SFLOAT;
		case .Float16x4:   return .VK_FORMAT_R16G16B16A16_SFLOAT;
		case .Float32:     return .VK_FORMAT_R32_SFLOAT;
		case .Float32x2:   return .VK_FORMAT_R32G32_SFLOAT;
		case .Float32x3:   return .VK_FORMAT_R32G32B32_SFLOAT;
		case .Float32x4:   return .VK_FORMAT_R32G32B32A32_SFLOAT;
		case .Uint32:      return .VK_FORMAT_R32_UINT;
		case .Uint32x2:    return .VK_FORMAT_R32G32_UINT;
		case .Uint32x3:    return .VK_FORMAT_R32G32B32_UINT;
		case .Uint32x4:    return .VK_FORMAT_R32G32B32A32_UINT;
		case .Sint32:      return .VK_FORMAT_R32_SINT;
		case .Sint32x2:    return .VK_FORMAT_R32G32_SINT;
		case .Sint32x3:    return .VK_FORMAT_R32G32B32_SINT;
		case .Sint32x4:    return .VK_FORMAT_R32G32B32A32_SINT;
		default:           return .VK_FORMAT_UNDEFINED;
		}
	}

	public static VkBufferUsageFlags ToVkBufferUsage(BufferUsage usage)
	{
		VkBufferUsageFlags flags = .None;
		if (usage.HasFlag(.CopySrc))   flags |= .VK_BUFFER_USAGE_TRANSFER_SRC_BIT;
		if (usage.HasFlag(.CopyDst))   flags |= .VK_BUFFER_USAGE_TRANSFER_DST_BIT;
		if (usage.HasFlag(.Vertex))    flags |= .VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
		if (usage.HasFlag(.Index))     flags |= .VK_BUFFER_USAGE_INDEX_BUFFER_BIT;
		if (usage.HasFlag(.Uniform))   flags |= .VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT;
		if (usage.HasFlag(.Storage))   flags |= .VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
		if (usage.HasFlag(.Indirect))  flags |= .VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT;
		if (usage.HasFlag(.AccelStructInput))
			flags |= .VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_BUILD_INPUT_READ_ONLY_BIT_KHR |
				.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT;
		if (usage.HasFlag(.ShaderBindingTable))
			flags |= .VK_BUFFER_USAGE_SHADER_BINDING_TABLE_BIT_KHR |
				.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT;
		if (usage.HasFlag(.AccelStructScratch))
			flags |= .VK_BUFFER_USAGE_STORAGE_BUFFER_BIT |
				.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT;
		return flags;
	}

	public static VkImageUsageFlags ToVkImageUsage(TextureUsage usage)
	{
		VkImageUsageFlags flags = .None;
		if (usage.HasFlag(.CopySrc))        flags |= .VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
		if (usage.HasFlag(.CopyDst))        flags |= .VK_IMAGE_USAGE_TRANSFER_DST_BIT;
		if (usage.HasFlag(.Sampled))        flags |= .VK_IMAGE_USAGE_SAMPLED_BIT;
		if (usage.HasFlag(.Storage))        flags |= .VK_IMAGE_USAGE_STORAGE_BIT;
		if (usage.HasFlag(.RenderTarget))   flags |= .VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
		if (usage.HasFlag(.DepthStencil))   flags |= .VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;
		if (usage.HasFlag(.InputAttachment))flags |= .VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT;
		return flags;
	}

	public static VkImageType ToVkImageType(TextureDimension dim)
	{
		switch (dim)
		{
		case .Texture1D: return .VK_IMAGE_TYPE_1D;
		case .Texture2D: return .VK_IMAGE_TYPE_2D;
		case .Texture3D: return .VK_IMAGE_TYPE_3D;
		}
	}

	public static VkImageViewType ToVkImageViewType(TextureViewDimension dim)
	{
		switch (dim)
		{
		case .Texture1D:         return .VK_IMAGE_VIEW_TYPE_1D;
		case .Texture1DArray:    return .VK_IMAGE_VIEW_TYPE_1D_ARRAY;
		case .Texture2D:         return .VK_IMAGE_VIEW_TYPE_2D;
		case .Texture2DArray:    return .VK_IMAGE_VIEW_TYPE_2D_ARRAY;
		case .TextureCube:       return .VK_IMAGE_VIEW_TYPE_CUBE;
		case .TextureCubeArray:  return .VK_IMAGE_VIEW_TYPE_CUBE_ARRAY;
		case .Texture3D:         return .VK_IMAGE_VIEW_TYPE_3D;
		}
	}

	public static VkFilter ToVkFilter(FilterMode mode)
	{
		switch (mode)
		{
		case .Nearest: return .VK_FILTER_NEAREST;
		case .Linear:  return .VK_FILTER_LINEAR;
		}
	}

	public static VkSamplerMipmapMode ToVkMipmapMode(MipmapFilterMode mode)
	{
		switch (mode)
		{
		case .Nearest: return .VK_SAMPLER_MIPMAP_MODE_NEAREST;
		case .Linear:  return .VK_SAMPLER_MIPMAP_MODE_LINEAR;
		}
	}

	public static VkSamplerAddressMode ToVkAddressMode(AddressMode mode)
	{
		switch (mode)
		{
		case .Repeat:       return .VK_SAMPLER_ADDRESS_MODE_REPEAT;
		case .MirrorRepeat: return .VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT;
		case .ClampToEdge:  return .VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
		case .ClampToBorder:return .VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER;
		}
	}

	public static VkBorderColor ToVkBorderColor(SamplerBorderColor color)
	{
		switch (color)
		{
		case .TransparentBlack: return .VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK;
		case .OpaqueBlack:      return .VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK;
		case .OpaqueWhite:      return .VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE;
		}
	}

	public static VkCompareOp ToVkCompareOp(CompareFunction func)
	{
		switch (func)
		{
		case .Never:        return .VK_COMPARE_OP_NEVER;
		case .Less:         return .VK_COMPARE_OP_LESS;
		case .Equal:        return .VK_COMPARE_OP_EQUAL;
		case .LessEqual:    return .VK_COMPARE_OP_LESS_OR_EQUAL;
		case .Greater:      return .VK_COMPARE_OP_GREATER;
		case .NotEqual:     return .VK_COMPARE_OP_NOT_EQUAL;
		case .GreaterEqual: return .VK_COMPARE_OP_GREATER_OR_EQUAL;
		case .Always:       return .VK_COMPARE_OP_ALWAYS;
		}
	}

	public static VkPrimitiveTopology ToVkTopology(PrimitiveTopology topology)
	{
		switch (topology)
		{
		case .PointList:     return .VK_PRIMITIVE_TOPOLOGY_POINT_LIST;
		case .LineList:      return .VK_PRIMITIVE_TOPOLOGY_LINE_LIST;
		case .LineStrip:     return .VK_PRIMITIVE_TOPOLOGY_LINE_STRIP;
		case .TriangleList:  return .VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
		case .TriangleStrip: return .VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP;
		}
	}

	public static VkFrontFace ToVkFrontFace(FrontFace face)
	{
		switch (face)
		{
		case .CCW: return .VK_FRONT_FACE_COUNTER_CLOCKWISE;
		case .CW:  return .VK_FRONT_FACE_CLOCKWISE;
		}
	}

	public static VkCullModeFlags ToVkCullMode(CullMode mode)
	{
		switch (mode)
		{
		case .None:  return .VK_CULL_MODE_NONE;
		case .Front: return .VK_CULL_MODE_FRONT_BIT;
		case .Back:  return .VK_CULL_MODE_BACK_BIT;
		}
	}

	public static VkPolygonMode ToVkPolygonMode(FillMode mode)
	{
		switch (mode)
		{
		case .Solid:     return .VK_POLYGON_MODE_FILL;
		case .Wireframe: return .VK_POLYGON_MODE_LINE;
		}
	}

	public static VkBlendFactor ToVkBlendFactor(BlendFactor factor)
	{
		switch (factor)
		{
		case .Zero:              return .VK_BLEND_FACTOR_ZERO;
		case .One:               return .VK_BLEND_FACTOR_ONE;
		case .Src:               return .VK_BLEND_FACTOR_SRC_COLOR;
		case .OneMinusSrc:       return .VK_BLEND_FACTOR_ONE_MINUS_SRC_COLOR;
		case .SrcAlpha:          return .VK_BLEND_FACTOR_SRC_ALPHA;
		case .OneMinusSrcAlpha:  return .VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
		case .Dst:               return .VK_BLEND_FACTOR_DST_COLOR;
		case .OneMinusDst:       return .VK_BLEND_FACTOR_ONE_MINUS_DST_COLOR;
		case .DstAlpha:          return .VK_BLEND_FACTOR_DST_ALPHA;
		case .OneMinusDstAlpha:  return .VK_BLEND_FACTOR_ONE_MINUS_DST_ALPHA;
		case .SrcAlphaSaturated: return .VK_BLEND_FACTOR_SRC_ALPHA_SATURATE;
		case .Constant:          return .VK_BLEND_FACTOR_CONSTANT_COLOR;
		case .OneMinusConstant:  return .VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR;
		}
	}

	public static VkBlendOp ToVkBlendOp(BlendOperation op)
	{
		switch (op)
		{
		case .Add:             return .VK_BLEND_OP_ADD;
		case .Subtract:        return .VK_BLEND_OP_SUBTRACT;
		case .ReverseSubtract: return .VK_BLEND_OP_REVERSE_SUBTRACT;
		case .Min:             return .VK_BLEND_OP_MIN;
		case .Max:             return .VK_BLEND_OP_MAX;
		}
	}

	public static VkStencilOp ToVkStencilOp(StencilOperation op)
	{
		switch (op)
		{
		case .Keep:           return .VK_STENCIL_OP_KEEP;
		case .Zero:           return .VK_STENCIL_OP_ZERO;
		case .Replace:        return .VK_STENCIL_OP_REPLACE;
		case .IncrementClamp: return .VK_STENCIL_OP_INCREMENT_AND_CLAMP;
		case .DecrementClamp: return .VK_STENCIL_OP_DECREMENT_AND_CLAMP;
		case .Invert:         return .VK_STENCIL_OP_INVERT;
		case .IncrementWrap:  return .VK_STENCIL_OP_INCREMENT_AND_WRAP;
		case .DecrementWrap:  return .VK_STENCIL_OP_DECREMENT_AND_WRAP;
		}
	}

	public static VkAttachmentLoadOp ToVkLoadOp(LoadOp op)
	{
		switch (op)
		{
		case .Load:     return .VK_ATTACHMENT_LOAD_OP_LOAD;
		case .Clear:    return .VK_ATTACHMENT_LOAD_OP_CLEAR;
		case .DontCare: return .VK_ATTACHMENT_LOAD_OP_DONT_CARE;
		}
	}

	public static VkAttachmentStoreOp ToVkStoreOp(StoreOp op)
	{
		switch (op)
		{
		case .Store:    return .VK_ATTACHMENT_STORE_OP_STORE;
		case .DontCare: return .VK_ATTACHMENT_STORE_OP_DONT_CARE;
		}
	}

	public static VkIndexType ToVkIndexType(IndexFormat format)
	{
		switch (format)
		{
		case .UInt16: return .VK_INDEX_TYPE_UINT16;
		case .UInt32: return .VK_INDEX_TYPE_UINT32;
		}
	}

	public static VkPresentModeKHR ToVkPresentMode(PresentMode mode)
	{
		switch (mode)
		{
		case .Immediate:   return .VK_PRESENT_MODE_IMMEDIATE_KHR;
		case .Mailbox:     return .VK_PRESENT_MODE_MAILBOX_KHR;
		case .Fifo:        return .VK_PRESENT_MODE_FIFO_KHR;
		case .FifoRelaxed: return .VK_PRESENT_MODE_FIFO_RELAXED_KHR;
		}
	}

	public static VkImageAspectFlags GetAspectMask(TextureFormat format)
	{
		if (format.IsDepthStencil())
		{
			VkImageAspectFlags aspect = .VK_IMAGE_ASPECT_NONE;
			if (format.HasDepth()) aspect |= .VK_IMAGE_ASPECT_DEPTH_BIT;
			if (format.HasStencil()) aspect |= .VK_IMAGE_ASPECT_STENCIL_BIT;
			return aspect;
		}
		return .VK_IMAGE_ASPECT_COLOR_BIT;
	}

	public static VkSampleCountFlags ToVkSampleCount(uint32 count)
	{
		switch (count)
		{
		case 1:  return .VK_SAMPLE_COUNT_1_BIT;
		case 2:  return .VK_SAMPLE_COUNT_2_BIT;
		case 4:  return .VK_SAMPLE_COUNT_4_BIT;
		case 8:  return .VK_SAMPLE_COUNT_8_BIT;
		case 16: return .VK_SAMPLE_COUNT_16_BIT;
		case 32: return .VK_SAMPLE_COUNT_32_BIT;
		case 64: return .VK_SAMPLE_COUNT_64_BIT;
		default: return .VK_SAMPLE_COUNT_1_BIT;
		}
	}

	public static VkColorComponentFlags ToVkColorWriteMask(ColorWriteMask mask)
	{
		VkColorComponentFlags flags = .None;
		if (mask.HasFlag(.Red))   flags |= .VK_COLOR_COMPONENT_R_BIT;
		if (mask.HasFlag(.Green)) flags |= .VK_COLOR_COMPONENT_G_BIT;
		if (mask.HasFlag(.Blue))  flags |= .VK_COLOR_COMPONENT_B_BIT;
		if (mask.HasFlag(.Alpha)) flags |= .VK_COLOR_COMPONENT_A_BIT;
		return flags;
	}
}
