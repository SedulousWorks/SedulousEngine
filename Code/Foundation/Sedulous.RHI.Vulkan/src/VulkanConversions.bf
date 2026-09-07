using System;
using Bulkan;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// Turning RHI enumerations into their Vulkan counterparts.
///
/// One place for every mapping, so a format or a blend factor is translated the same way
/// wherever it is needed and a gap is a single missing case rather than a scattered one.
static class VulkanConversions
{
	// Whether the device actually has the packed 24 bit depth formats. Probed once at
	// device creation, because AMD has no X8_D24 and some drivers no D24_S8: the depth
	// mappings below fall back to the 32 bit float forms rather than failing to create.
	private static bool sDepth24S8Supported = true;
	private static bool sDepth24Supported = true;

	/// Called by the device once it has read the physical device's format properties.
	public static void SetDepthFormatSupport(bool depth24S8, bool depth24)
	{
		sDepth24S8Supported = depth24S8;
		sDepth24Supported = depth24;
	}

	public static VkFormat ToVkFormat(TextureFormat f)
	{
		switch (f)
		{
		case .Undefined:
			return .VK_FORMAT_UNDEFINED;
		case .R8Unorm:
			return .VK_FORMAT_R8_UNORM;
		case .R8Snorm:
			return .VK_FORMAT_R8_SNORM;
		case .R8Uint:
			return .VK_FORMAT_R8_UINT;
		case .R8Sint:
			return .VK_FORMAT_R8_SINT;
		case .R16Uint:
			return .VK_FORMAT_R16_UINT;
		case .R16Sint:
			return .VK_FORMAT_R16_SINT;
		case .R16Float:
			return .VK_FORMAT_R16_SFLOAT;
		case .RG8Unorm:
			return .VK_FORMAT_R8G8_UNORM;
		case .RG8Snorm:
			return .VK_FORMAT_R8G8_SNORM;
		case .RG8Uint:
			return .VK_FORMAT_R8G8_UINT;
		case .RG8Sint:
			return .VK_FORMAT_R8G8_SINT;
		case .R32Uint:
			return .VK_FORMAT_R32_UINT;
		case .R32Sint:
			return .VK_FORMAT_R32_SINT;
		case .R32Float:
			return .VK_FORMAT_R32_SFLOAT;
		case .RG16Uint:
			return .VK_FORMAT_R16G16_UINT;
		case .RG16Sint:
			return .VK_FORMAT_R16G16_SINT;
		case .RG16Float:
			return .VK_FORMAT_R16G16_SFLOAT;
		case .RGBA8Unorm:
			return .VK_FORMAT_R8G8B8A8_UNORM;
		case .RGBA8UnormSrgb:
			return .VK_FORMAT_R8G8B8A8_SRGB;
		case .RGBA8Snorm:
			return .VK_FORMAT_R8G8B8A8_SNORM;
		case .RGBA8Uint:
			return .VK_FORMAT_R8G8B8A8_UINT;
		case .RGBA8Sint:
			return .VK_FORMAT_R8G8B8A8_SINT;
		case .BGRA8Unorm:
			return .VK_FORMAT_B8G8R8A8_UNORM;
		case .BGRA8UnormSrgb:
			return .VK_FORMAT_B8G8R8A8_SRGB;
		case .RGB10A2Unorm:
			return .VK_FORMAT_A2B10G10R10_UNORM_PACK32;
		case .RGB10A2Uint:
			return .VK_FORMAT_A2B10G10R10_UINT_PACK32;
		case .RG11B10Float:
			return .VK_FORMAT_B10G11R11_UFLOAT_PACK32;
		case .RGB9E5Float:
			return .VK_FORMAT_E5B9G9R9_UFLOAT_PACK32;
		case .RG32Uint:
			return .VK_FORMAT_R32G32_UINT;
		case .RG32Sint:
			return .VK_FORMAT_R32G32_SINT;
		case .RG32Float:
			return .VK_FORMAT_R32G32_SFLOAT;
		case .RGBA16Uint:
			return .VK_FORMAT_R16G16B16A16_UINT;
		case .RGBA16Sint:
			return .VK_FORMAT_R16G16B16A16_SINT;
		case .RGBA16Float:
			return .VK_FORMAT_R16G16B16A16_SFLOAT;
		case .RGBA16Unorm:
			return .VK_FORMAT_R16G16B16A16_UNORM;
		case .RGBA16Snorm:
			return .VK_FORMAT_R16G16B16A16_SNORM;
		case .RGBA32Uint:
			return .VK_FORMAT_R32G32B32A32_UINT;
		case .RGBA32Sint:
			return .VK_FORMAT_R32G32B32A32_SINT;
		case .RGBA32Float:
			return .VK_FORMAT_R32G32B32A32_SFLOAT;
		case .Depth16Unorm:
			return .VK_FORMAT_D16_UNORM;
		case .Depth24Plus:
			return sDepth24Supported ? .VK_FORMAT_X8_D24_UNORM_PACK32
											: .VK_FORMAT_D32_SFLOAT;
		case .Depth24PlusStencil8:
			return sDepth24S8Supported ? .VK_FORMAT_D24_UNORM_S8_UINT
												: .VK_FORMAT_D32_SFLOAT_S8_UINT;
		case .Depth32Float:
			return .VK_FORMAT_D32_SFLOAT;
		case .Depth32FloatStencil8:
			return .VK_FORMAT_D32_SFLOAT_S8_UINT;
		case .Stencil8:
			return .VK_FORMAT_S8_UINT;
		case .BC1RGBAUnorm:
			return .VK_FORMAT_BC1_RGBA_UNORM_BLOCK;
		case .BC1RGBAUnormSrgb:
			return .VK_FORMAT_BC1_RGBA_SRGB_BLOCK;
		case .BC2RGBAUnorm:
			return .VK_FORMAT_BC2_UNORM_BLOCK;
		case .BC2RGBAUnormSrgb:
			return .VK_FORMAT_BC2_SRGB_BLOCK;
		case .BC3RGBAUnorm:
			return .VK_FORMAT_BC3_UNORM_BLOCK;
		case .BC3RGBAUnormSrgb:
			return .VK_FORMAT_BC3_SRGB_BLOCK;
		case .BC4RUnorm:
			return .VK_FORMAT_BC4_UNORM_BLOCK;
		case .BC4RSnorm:
			return .VK_FORMAT_BC4_SNORM_BLOCK;
		case .BC5RGUnorm:
			return .VK_FORMAT_BC5_UNORM_BLOCK;
		case .BC5RGSnorm:
			return .VK_FORMAT_BC5_SNORM_BLOCK;
		case .BC6HRGBUfloat:
			return .VK_FORMAT_BC6H_UFLOAT_BLOCK;
		case .BC6HRGBFloat:
			return .VK_FORMAT_BC6H_SFLOAT_BLOCK;
		case .BC7RGBAUnorm:
			return .VK_FORMAT_BC7_UNORM_BLOCK;
		case .BC7RGBAUnormSrgb:
			return .VK_FORMAT_BC7_SRGB_BLOCK;
		case .ASTC4x4Unorm:
			return .VK_FORMAT_ASTC_4x4_UNORM_BLOCK;
		case .ASTC4x4UnormSrgb:
			return .VK_FORMAT_ASTC_4x4_SRGB_BLOCK;
		case .ASTC5x5Unorm:
			return .VK_FORMAT_ASTC_5x5_UNORM_BLOCK;
		case .ASTC5x5UnormSrgb:
			return .VK_FORMAT_ASTC_5x5_SRGB_BLOCK;
		case .ASTC6x6Unorm:
			return .VK_FORMAT_ASTC_6x6_UNORM_BLOCK;
		case .ASTC6x6UnormSrgb:
			return .VK_FORMAT_ASTC_6x6_SRGB_BLOCK;
		case .ASTC8x8Unorm:
			return .VK_FORMAT_ASTC_8x8_UNORM_BLOCK;
		case .ASTC8x8UnormSrgb:
			return .VK_FORMAT_ASTC_8x8_SRGB_BLOCK;
		default:
			return .VK_FORMAT_UNDEFINED;
		}
	}

	public static VkFormat ToVkVertexFormat(VertexFormat f)
	{
		switch (f)
		{
		case .Uint8x2:
			return .VK_FORMAT_R8G8_UINT;
		case .Uint8x4:
			return .VK_FORMAT_R8G8B8A8_UINT;
		case .Sint8x2:
			return .VK_FORMAT_R8G8_SINT;
		case .Sint8x4:
			return .VK_FORMAT_R8G8B8A8_SINT;
		case .Unorm8x2:
			return .VK_FORMAT_R8G8_UNORM;
		case .Unorm8x4:
			return .VK_FORMAT_R8G8B8A8_UNORM;
		case .Snorm8x2:
			return .VK_FORMAT_R8G8_SNORM;
		case .Snorm8x4:
			return .VK_FORMAT_R8G8B8A8_SNORM;
		case .Uint16x2:
			return .VK_FORMAT_R16G16_UINT;
		case .Uint16x4:
			return .VK_FORMAT_R16G16B16A16_UINT;
		case .Sint16x2:
			return .VK_FORMAT_R16G16_SINT;
		case .Sint16x4:
			return .VK_FORMAT_R16G16B16A16_SINT;
		case .Unorm16x2:
			return .VK_FORMAT_R16G16_UNORM;
		case .Unorm16x4:
			return .VK_FORMAT_R16G16B16A16_UNORM;
		case .Snorm16x2:
			return .VK_FORMAT_R16G16_SNORM;
		case .Snorm16x4:
			return .VK_FORMAT_R16G16B16A16_SNORM;
		case .Float16x2:
			return .VK_FORMAT_R16G16_SFLOAT;
		case .Float16x4:
			return .VK_FORMAT_R16G16B16A16_SFLOAT;
		case .Float32:
			return .VK_FORMAT_R32_SFLOAT;
		case .Float32x2:
			return .VK_FORMAT_R32G32_SFLOAT;
		case .Float32x3:
			return .VK_FORMAT_R32G32B32_SFLOAT;
		case .Float32x4:
			return .VK_FORMAT_R32G32B32A32_SFLOAT;
		case .Uint32:
			return .VK_FORMAT_R32_UINT;
		case .Uint32x2:
			return .VK_FORMAT_R32G32_UINT;
		case .Uint32x3:
			return .VK_FORMAT_R32G32B32_UINT;
		case .Uint32x4:
			return .VK_FORMAT_R32G32B32A32_UINT;
		case .Sint32:
			return .VK_FORMAT_R32_SINT;
		case .Sint32x2:
			return .VK_FORMAT_R32G32_SINT;
		case .Sint32x3:
			return .VK_FORMAT_R32G32B32_SINT;
		case .Sint32x4:
			return .VK_FORMAT_R32G32B32A32_SINT;
		default:
			return .VK_FORMAT_UNDEFINED;
		}
	}

	public static VkBufferUsageFlags ToVkBufferUsage(BufferUsage u)
	{
		VkBufferUsageFlags f = default;
		if (u.HasFlag(.CopySrc))
			f |= .VK_BUFFER_USAGE_TRANSFER_SRC_BIT;
		if (u.HasFlag(.CopyDst))
			f |= .VK_BUFFER_USAGE_TRANSFER_DST_BIT;
		if (u.HasFlag(.Vertex))
			f |= .VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
		if (u.HasFlag(.Index))
			f |= .VK_BUFFER_USAGE_INDEX_BUFFER_BIT;
		if (u.HasFlag(.Uniform))
			f |= .VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT;
		if (u.HasFlag(.Storage))
			f |= .VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
		if (u.HasFlag(.StorageRead))
			f |= .VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
		if (u.HasFlag(.Indirect))
			f |= .VK_BUFFER_USAGE_INDIRECT_BUFFER_BIT;
		if (u.HasFlag(.AccelStructInput))
			f |= .VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_BUILD_INPUT_READ_ONLY_BIT_KHR |
				.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT;
		if (u.HasFlag(.ShaderBindingTable))
			f |= .VK_BUFFER_USAGE_SHADER_BINDING_TABLE_BIT_KHR |
				.VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT;
		if (u.HasFlag(.AccelStructScratch))
			f |= .VK_BUFFER_USAGE_STORAGE_BUFFER_BIT | .VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT;
		return f;
	}

	public static VkImageUsageFlags ToVkImageUsage(TextureUsage u)
	{
		VkImageUsageFlags f = default;
		if (u.HasFlag(.CopySrc))
			f |= .VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
		if (u.HasFlag(.CopyDst))
			f |= .VK_IMAGE_USAGE_TRANSFER_DST_BIT;
		if (u.HasFlag(.Sampled))
			f |= .VK_IMAGE_USAGE_SAMPLED_BIT;
		if (u.HasFlag(.Storage))
			f |= .VK_IMAGE_USAGE_STORAGE_BIT;
		if (u.HasFlag(.RenderTarget))
			f |= .VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
		if (u.HasFlag(.DepthStencil))
			f |= .VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;
		if (u.HasFlag(.InputAttachment))
			f |= .VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT;
		return f;
	}

	public static VkImageType ToVkImageType(TextureDimension d)
	{
		switch (d)
		{
		case .Texture1D:
			return .VK_IMAGE_TYPE_1D;
		case .Texture2D:
			return .VK_IMAGE_TYPE_2D;
		case .Texture3D:
			return .VK_IMAGE_TYPE_3D;
		}
	}

	public static VkImageViewType ToVkImageViewType(TextureViewDimension d)
	{
		switch (d)
		{
		case .Texture1D:
			return .VK_IMAGE_VIEW_TYPE_1D;
		case .Texture1DArray:
			return .VK_IMAGE_VIEW_TYPE_1D_ARRAY;
		case .Texture2D:
			return .VK_IMAGE_VIEW_TYPE_2D;
		case .Texture2DArray:
			return .VK_IMAGE_VIEW_TYPE_2D_ARRAY;
		case .TextureCube:
			return .VK_IMAGE_VIEW_TYPE_CUBE;
		case .TextureCubeArray:
			return .VK_IMAGE_VIEW_TYPE_CUBE_ARRAY;
		case .Texture3D:
			return .VK_IMAGE_VIEW_TYPE_3D;
		}
	}

	public static VkFilter ToVkFilter(FilterMode m)
	{
		return m == .Nearest ? .VK_FILTER_NEAREST : .VK_FILTER_LINEAR;
	}

	public static VkSamplerMipmapMode ToVkMipmapMode(MipmapFilterMode m)
	{
		return m == .Nearest ? .VK_SAMPLER_MIPMAP_MODE_NEAREST
											: .VK_SAMPLER_MIPMAP_MODE_LINEAR;
	}

	public static VkSamplerAddressMode ToVkAddressMode(AddressMode m)
	{
		switch (m)
		{
		case .Repeat:
			return .VK_SAMPLER_ADDRESS_MODE_REPEAT;
		case .MirrorRepeat:
			return .VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT;
		case .ClampToEdge:
			return .VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
		case .ClampToBorder:
			return .VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER;
		}
	}

	public static VkBorderColor ToVkBorderColor(SamplerBorderColor c)
	{
		switch (c)
		{
		case .TransparentBlack:
			return .VK_BORDER_COLOR_FLOAT_TRANSPARENT_BLACK;
		case .OpaqueBlack:
			return .VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK;
		case .OpaqueWhite:
			return .VK_BORDER_COLOR_FLOAT_OPAQUE_WHITE;
		}
	}

	public static VkCompareOp ToVkCompareOp(CompareFunction f)
	{
		switch (f)
		{
		case .Never:
			return .VK_COMPARE_OP_NEVER;
		case .Less:
			return .VK_COMPARE_OP_LESS;
		case .Equal:
			return .VK_COMPARE_OP_EQUAL;
		case .LessEqual:
			return .VK_COMPARE_OP_LESS_OR_EQUAL;
		case .Greater:
			return .VK_COMPARE_OP_GREATER;
		case .NotEqual:
			return .VK_COMPARE_OP_NOT_EQUAL;
		case .GreaterEqual:
			return .VK_COMPARE_OP_GREATER_OR_EQUAL;
		case .Always:
			return .VK_COMPARE_OP_ALWAYS;
		}
	}

	public static VkPrimitiveTopology ToVkTopology(PrimitiveTopology t)
	{
		switch (t)
		{
		case .PointList:
			return .VK_PRIMITIVE_TOPOLOGY_POINT_LIST;
		case .LineList:
			return .VK_PRIMITIVE_TOPOLOGY_LINE_LIST;
		case .LineStrip:
			return .VK_PRIMITIVE_TOPOLOGY_LINE_STRIP;
		case .TriangleList:
			return .VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
		case .TriangleStrip:
			return .VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP;
		}
	}

	public static VkFrontFace ToVkFrontFace(FrontFace f)
	{
		return f == .CCW ? .VK_FRONT_FACE_COUNTER_CLOCKWISE : .VK_FRONT_FACE_CLOCKWISE;
	}

	public static VkCullModeFlags ToVkCullMode(CullMode m)
	{
		switch (m)
		{
		case .None:
			return .VK_CULL_MODE_NONE;
		case .Front:
			return .VK_CULL_MODE_FRONT_BIT;
		case .Back:
			return .VK_CULL_MODE_BACK_BIT;
		}
	}

	public static VkPolygonMode ToVkPolygonMode(FillMode m)
	{
		return m == .Solid ? .VK_POLYGON_MODE_FILL : .VK_POLYGON_MODE_LINE;
	}

	public static VkBlendFactor ToVkBlendFactor(BlendFactor f)
	{
		switch (f)
		{
		case .Zero:
			return .VK_BLEND_FACTOR_ZERO;
		case .One:
			return .VK_BLEND_FACTOR_ONE;
		case .Src:
			return .VK_BLEND_FACTOR_SRC_COLOR;
		case .OneMinusSrc:
			return .VK_BLEND_FACTOR_ONE_MINUS_SRC_COLOR;
		case .SrcAlpha:
			return .VK_BLEND_FACTOR_SRC_ALPHA;
		case .OneMinusSrcAlpha:
			return .VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
		case .Dst:
			return .VK_BLEND_FACTOR_DST_COLOR;
		case .OneMinusDst:
			return .VK_BLEND_FACTOR_ONE_MINUS_DST_COLOR;
		case .DstAlpha:
			return .VK_BLEND_FACTOR_DST_ALPHA;
		case .OneMinusDstAlpha:
			return .VK_BLEND_FACTOR_ONE_MINUS_DST_ALPHA;
		case .SrcAlphaSaturated:
			return .VK_BLEND_FACTOR_SRC_ALPHA_SATURATE;
		case .Constant:
			return .VK_BLEND_FACTOR_CONSTANT_COLOR;
		case .OneMinusConstant:
			return .VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR;
		}
	}

	public static VkBlendOp ToVkBlendOp(BlendOperation o)
	{
		switch (o)
		{
		case .Add:
			return .VK_BLEND_OP_ADD;
		case .Subtract:
			return .VK_BLEND_OP_SUBTRACT;
		case .ReverseSubtract:
			return .VK_BLEND_OP_REVERSE_SUBTRACT;
		case .Min:
			return .VK_BLEND_OP_MIN;
		case .Max:
			return .VK_BLEND_OP_MAX;
		}
	}

	public static VkStencilOp ToVkStencilOp(StencilOperation o)
	{
		switch (o)
		{
		case .Keep:
			return .VK_STENCIL_OP_KEEP;
		case .Zero:
			return .VK_STENCIL_OP_ZERO;
		case .Replace:
			return .VK_STENCIL_OP_REPLACE;
		case .IncrementClamp:
			return .VK_STENCIL_OP_INCREMENT_AND_CLAMP;
		case .DecrementClamp:
			return .VK_STENCIL_OP_DECREMENT_AND_CLAMP;
		case .Invert:
			return .VK_STENCIL_OP_INVERT;
		case .IncrementWrap:
			return .VK_STENCIL_OP_INCREMENT_AND_WRAP;
		case .DecrementWrap:
			return .VK_STENCIL_OP_DECREMENT_AND_WRAP;
		}
	}

	public static VkAttachmentLoadOp ToVkLoadOp(LoadOp o)
	{
		switch (o)
		{
		case .Load:
			return .VK_ATTACHMENT_LOAD_OP_LOAD;
		case .Clear:
			return .VK_ATTACHMENT_LOAD_OP_CLEAR;
		case .DontCare:
			return .VK_ATTACHMENT_LOAD_OP_DONT_CARE;
		}
	}

	public static VkAttachmentStoreOp ToVkStoreOp(StoreOp o)
	{
		return o == .Store ? .VK_ATTACHMENT_STORE_OP_STORE
								: .VK_ATTACHMENT_STORE_OP_DONT_CARE;
	}

	public static VkIndexType ToVkIndexType(IndexFormat f)
	{
		return f == .UInt16 ? .VK_INDEX_TYPE_UINT16 : .VK_INDEX_TYPE_UINT32;
	}

	public static VkPresentModeKHR ToVkPresentMode(PresentMode m)
	{
		switch (m)
		{
		case .Immediate:
			return .VK_PRESENT_MODE_IMMEDIATE_KHR;
		case .Mailbox:
			return .VK_PRESENT_MODE_MAILBOX_KHR;
		case .Fifo:
			return .VK_PRESENT_MODE_FIFO_KHR;
		case .FifoRelaxed:
			return .VK_PRESENT_MODE_FIFO_RELAXED_KHR;
		}
	}

	public static VkImageAspectFlags GetAspectMask(TextureFormat f)
	{
		if (TextureFormats.IsDepthStencil(f))
		{
		VkImageAspectFlags a = default;
			if (TextureFormats.HasDepth(f))
				a |= .VK_IMAGE_ASPECT_DEPTH_BIT;
			if (TextureFormats.HasStencil(f))
				a |= .VK_IMAGE_ASPECT_STENCIL_BIT;
			return a;
		}
		return .VK_IMAGE_ASPECT_COLOR_BIT;
	}

	public static VkSampleCountFlags ToVkSampleCount(uint32 c)
	{
		switch (c)
		{
		case 1:
			return .VK_SAMPLE_COUNT_1_BIT;
		case 2:
			return .VK_SAMPLE_COUNT_2_BIT;
		case 4:
			return .VK_SAMPLE_COUNT_4_BIT;
		case 8:
			return .VK_SAMPLE_COUNT_8_BIT;
		case 16:
			return .VK_SAMPLE_COUNT_16_BIT;
		case 32:
			return .VK_SAMPLE_COUNT_32_BIT;
		case 64:
			return .VK_SAMPLE_COUNT_64_BIT;
		default:
			return .VK_SAMPLE_COUNT_1_BIT;
		}
	}

	public static VkColorComponentFlags ToVkColorWriteMask(ColorWriteMask m)
	{
		VkColorComponentFlags f = default;
		if (m.HasFlag(.Red))
			f |= .VK_COLOR_COMPONENT_R_BIT;
		if (m.HasFlag(.Green))
			f |= .VK_COLOR_COMPONENT_G_BIT;
		if (m.HasFlag(.Blue))
			f |= .VK_COLOR_COMPONENT_B_BIT;
		if (m.HasFlag(.Alpha))
			f |= .VK_COLOR_COMPONENT_A_BIT;
		return f;
	}

	public static VkShaderStageFlags ToVkShaderStageFlags(ShaderStage s)
	{
		VkShaderStageFlags f = default;
		if (s.HasFlag(.Vertex))
			f |= .VK_SHADER_STAGE_VERTEX_BIT;
		if (s.HasFlag(.Fragment))
			f |= .VK_SHADER_STAGE_FRAGMENT_BIT;
		if (s.HasFlag(.Compute))
			f |= .VK_SHADER_STAGE_COMPUTE_BIT;
		if (s.HasFlag(.Mesh))
			f |= .VK_SHADER_STAGE_MESH_BIT_EXT;
		if (s.HasFlag(.Task))
			f |= .VK_SHADER_STAGE_TASK_BIT_EXT;
		if (s.HasFlag(.RayGen))
			f |= .VK_SHADER_STAGE_RAYGEN_BIT_KHR;
		if (s.HasFlag(.ClosestHit))
			f |= .VK_SHADER_STAGE_CLOSEST_HIT_BIT_KHR;
		if (s.HasFlag(.Miss))
			f |= .VK_SHADER_STAGE_MISS_BIT_KHR;
		if (s.HasFlag(.AnyHit))
			f |= .VK_SHADER_STAGE_ANY_HIT_BIT_KHR;
		if (s.HasFlag(.Intersection))
			f |= .VK_SHADER_STAGE_INTERSECTION_BIT_KHR;
		if (s.HasFlag(.Callable))
			f |= .VK_SHADER_STAGE_CALLABLE_BIT_KHR;
		return f;
	}

}
