using System;
using Sedulous.RHI;
using Win32.Graphics.Direct3D;
using Win32.Graphics.Direct3D12;
using Win32.Graphics.Dxgi.Common;

namespace Sedulous.RHI.DX12;

/// Turning RHI enumerations into their DX12 and DXGI counterparts.
///
/// One place for every mapping, so a format or a blend factor is translated the same way
/// wherever it is needed and a gap is a single missing case rather than a scattered one.
/// The Vulkan backend's conversions are the sibling to read this against.
static class DxConversions
{

	public static DXGI_FORMAT ToDxgiFormat(TextureFormat f)
	{
		switch (f)
		{
		case .Undefined:
			return .DXGI_FORMAT_UNKNOWN;
		case .R8Unorm:
			return .DXGI_FORMAT_R8_UNORM;
		case .R8Snorm:
			return .DXGI_FORMAT_R8_SNORM;
		case .R8Uint:
			return .DXGI_FORMAT_R8_UINT;
		case .R8Sint:
			return .DXGI_FORMAT_R8_SINT;
		case .R16Uint:
			return .DXGI_FORMAT_R16_UINT;
		case .R16Sint:
			return .DXGI_FORMAT_R16_SINT;
		case .R16Float:
			return .DXGI_FORMAT_R16_FLOAT;
		case .RG8Unorm:
			return .DXGI_FORMAT_R8G8_UNORM;
		case .RG8Snorm:
			return .DXGI_FORMAT_R8G8_SNORM;
		case .RG8Uint:
			return .DXGI_FORMAT_R8G8_UINT;
		case .RG8Sint:
			return .DXGI_FORMAT_R8G8_SINT;
		case .R32Uint:
			return .DXGI_FORMAT_R32_UINT;
		case .R32Sint:
			return .DXGI_FORMAT_R32_SINT;
		case .R32Float:
			return .DXGI_FORMAT_R32_FLOAT;
		case .RG16Uint:
			return .DXGI_FORMAT_R16G16_UINT;
		case .RG16Sint:
			return .DXGI_FORMAT_R16G16_SINT;
		case .RG16Float:
			return .DXGI_FORMAT_R16G16_FLOAT;
		case .RGBA8Unorm:
			return .DXGI_FORMAT_R8G8B8A8_UNORM;
		case .RGBA8UnormSrgb:
			return .DXGI_FORMAT_R8G8B8A8_UNORM_SRGB;
		case .RGBA8Snorm:
			return .DXGI_FORMAT_R8G8B8A8_SNORM;
		case .RGBA8Uint:
			return .DXGI_FORMAT_R8G8B8A8_UINT;
		case .RGBA8Sint:
			return .DXGI_FORMAT_R8G8B8A8_SINT;
		case .BGRA8Unorm:
			return .DXGI_FORMAT_B8G8R8A8_UNORM;
		case .BGRA8UnormSrgb:
			return .DXGI_FORMAT_B8G8R8A8_UNORM_SRGB;
		case .RGB10A2Unorm:
			return .DXGI_FORMAT_R10G10B10A2_UNORM;
		case .RGB10A2Uint:
			return .DXGI_FORMAT_R10G10B10A2_UINT;
		case .RG11B10Float:
			return .DXGI_FORMAT_R11G11B10_FLOAT;
		case .RGB9E5Float:
			return .DXGI_FORMAT_R9G9B9E5_SHAREDEXP;
		case .RG32Uint:
			return .DXGI_FORMAT_R32G32_UINT;
		case .RG32Sint:
			return .DXGI_FORMAT_R32G32_SINT;
		case .RG32Float:
			return .DXGI_FORMAT_R32G32_FLOAT;
		case .RGBA16Uint:
			return .DXGI_FORMAT_R16G16B16A16_UINT;
		case .RGBA16Sint:
			return .DXGI_FORMAT_R16G16B16A16_SINT;
		case .RGBA16Float:
			return .DXGI_FORMAT_R16G16B16A16_FLOAT;
		case .RGBA16Unorm:
			return .DXGI_FORMAT_R16G16B16A16_UNORM;
		case .RGBA16Snorm:
			return .DXGI_FORMAT_R16G16B16A16_SNORM;
		case .RGBA32Uint:
			return .DXGI_FORMAT_R32G32B32A32_UINT;
		case .RGBA32Sint:
			return .DXGI_FORMAT_R32G32B32A32_SINT;
		case .RGBA32Float:
			return .DXGI_FORMAT_R32G32B32A32_FLOAT;
		case .Depth16Unorm:
			return .DXGI_FORMAT_D16_UNORM;
		case .Depth24Plus:
			return .DXGI_FORMAT_D24_UNORM_S8_UINT;
		case .Depth24PlusStencil8:
			return .DXGI_FORMAT_D24_UNORM_S8_UINT;
		case .Depth32Float:
			return .DXGI_FORMAT_D32_FLOAT;
		case .Depth32FloatStencil8:
			return .DXGI_FORMAT_D32_FLOAT_S8X24_UINT;
		case .Stencil8:
			return .DXGI_FORMAT_R8_UINT;
		case .BC1RGBAUnorm:
			return .DXGI_FORMAT_BC1_UNORM;
		case .BC1RGBAUnormSrgb:
			return .DXGI_FORMAT_BC1_UNORM_SRGB;
		case .BC2RGBAUnorm:
			return .DXGI_FORMAT_BC2_UNORM;
		case .BC2RGBAUnormSrgb:
			return .DXGI_FORMAT_BC2_UNORM_SRGB;
		case .BC3RGBAUnorm:
			return .DXGI_FORMAT_BC3_UNORM;
		case .BC3RGBAUnormSrgb:
			return .DXGI_FORMAT_BC3_UNORM_SRGB;
		case .BC4RUnorm:
			return .DXGI_FORMAT_BC4_UNORM;
		case .BC4RSnorm:
			return .DXGI_FORMAT_BC4_SNORM;
		case .BC5RGUnorm:
			return .DXGI_FORMAT_BC5_UNORM;
		case .BC5RGSnorm:
			return .DXGI_FORMAT_BC5_SNORM;
		case .BC6HRGBUfloat:
			return .DXGI_FORMAT_BC6H_UF16;
		case .BC6HRGBFloat:
			return .DXGI_FORMAT_BC6H_SF16;
		case .BC7RGBAUnorm:
			return .DXGI_FORMAT_BC7_UNORM;
		case .BC7RGBAUnormSrgb:
			return .DXGI_FORMAT_BC7_UNORM_SRGB;
		default:
			return .DXGI_FORMAT_UNKNOWN;
		}
	}

	public static TextureFormat FromDxgiFormat(DXGI_FORMAT f)
	{
		switch (f)
		{
		case .DXGI_FORMAT_R8G8B8A8_UNORM:
			return .RGBA8Unorm;
		case .DXGI_FORMAT_R8G8B8A8_UNORM_SRGB:
			return .RGBA8UnormSrgb;
		case .DXGI_FORMAT_B8G8R8A8_UNORM:
			return .BGRA8Unorm;
		case .DXGI_FORMAT_B8G8R8A8_UNORM_SRGB:
			return .BGRA8UnormSrgb;
		case .DXGI_FORMAT_R16G16B16A16_FLOAT:
			return .RGBA16Float;
		case .DXGI_FORMAT_R10G10B10A2_UNORM:
			return .RGB10A2Unorm;
		case .DXGI_FORMAT_R32G32B32A32_FLOAT:
			return .RGBA32Float;
		default:
			return .Undefined;
		}
	}

	public static DXGI_FORMAT ToDxgiVertexFormat(VertexFormat f)
	{
		switch (f)
		{
		case .Uint8x2:
			return .DXGI_FORMAT_R8G8_UINT;
		case .Uint8x4:
			return .DXGI_FORMAT_R8G8B8A8_UINT;
		case .Sint8x2:
			return .DXGI_FORMAT_R8G8_SINT;
		case .Sint8x4:
			return .DXGI_FORMAT_R8G8B8A8_SINT;
		case .Unorm8x2:
			return .DXGI_FORMAT_R8G8_UNORM;
		case .Unorm8x4:
			return .DXGI_FORMAT_R8G8B8A8_UNORM;
		case .Snorm8x2:
			return .DXGI_FORMAT_R8G8_SNORM;
		case .Snorm8x4:
			return .DXGI_FORMAT_R8G8B8A8_SNORM;
		case .Uint16x2:
			return .DXGI_FORMAT_R16G16_UINT;
		case .Uint16x4:
			return .DXGI_FORMAT_R16G16B16A16_UINT;
		case .Sint16x2:
			return .DXGI_FORMAT_R16G16_SINT;
		case .Sint16x4:
			return .DXGI_FORMAT_R16G16B16A16_SINT;
		case .Unorm16x2:
			return .DXGI_FORMAT_R16G16_UNORM;
		case .Unorm16x4:
			return .DXGI_FORMAT_R16G16B16A16_UNORM;
		case .Snorm16x2:
			return .DXGI_FORMAT_R16G16_SNORM;
		case .Snorm16x4:
			return .DXGI_FORMAT_R16G16B16A16_SNORM;
		case .Float16x2:
			return .DXGI_FORMAT_R16G16_FLOAT;
		case .Float16x4:
			return .DXGI_FORMAT_R16G16B16A16_FLOAT;
		case .Float32:
			return .DXGI_FORMAT_R32_FLOAT;
		case .Float32x2:
			return .DXGI_FORMAT_R32G32_FLOAT;
		case .Float32x3:
			return .DXGI_FORMAT_R32G32B32_FLOAT;
		case .Float32x4:
			return .DXGI_FORMAT_R32G32B32A32_FLOAT;
		case .Uint32:
			return .DXGI_FORMAT_R32_UINT;
		case .Uint32x2:
			return .DXGI_FORMAT_R32G32_UINT;
		case .Uint32x3:
			return .DXGI_FORMAT_R32G32B32_UINT;
		case .Uint32x4:
			return .DXGI_FORMAT_R32G32B32A32_UINT;
		case .Sint32:
			return .DXGI_FORMAT_R32_SINT;
		case .Sint32x2:
			return .DXGI_FORMAT_R32G32_SINT;
		case .Sint32x3:
			return .DXGI_FORMAT_R32G32B32_SINT;
		case .Sint32x4:
			return .DXGI_FORMAT_R32G32B32A32_SINT;
		default:
			return .DXGI_FORMAT_UNKNOWN;
		}
	}

	public static DXGI_FORMAT ToDxgiIndexFormat(IndexFormat f)
	{
		switch (f)
		{
		case .UInt16:
			return .DXGI_FORMAT_R16_UINT;
		case .UInt32:
			return .DXGI_FORMAT_R32_UINT;
		}
	}

	public static D3D12_COMMAND_LIST_TYPE ToCommandListType(QueueType t)
	{
		switch (t)
		{
		case .Graphics:
			return .D3D12_COMMAND_LIST_TYPE_DIRECT;
		case .Compute:
			return .D3D12_COMMAND_LIST_TYPE_COMPUTE;
		case .Transfer:
			return .D3D12_COMMAND_LIST_TYPE_COPY;
		}
	}

	public static D3D12_HEAP_TYPE ToHeapType(MemoryLocation loc)
	{
		switch (loc)
		{
		case .GpuOnly:
			return .D3D12_HEAP_TYPE_DEFAULT;
		case .CpuToGpu:
			return .D3D12_HEAP_TYPE_UPLOAD;
		case .GpuToCpu:
			return .D3D12_HEAP_TYPE_READBACK;
		case .Auto:
			return .D3D12_HEAP_TYPE_DEFAULT;
		}
	}

	public static D3D12_RESOURCE_FLAGS ToTextureResourceFlags(TextureUsage usage)
	{
		D3D12_RESOURCE_FLAGS flags = .D3D12_RESOURCE_FLAG_NONE;
		if (usage.HasFlag(.RenderTarget))
			flags |= .D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET;
		if (usage.HasFlag(.DepthStencil))
			flags |= .D3D12_RESOURCE_FLAG_ALLOW_DEPTH_STENCIL;
		if (usage.HasFlag(.Storage))
			flags |= .D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
		return flags;
	}

	public static D3D12_RESOURCE_FLAGS ToBufferResourceFlags(BufferUsage usage)
	{
		D3D12_RESOURCE_FLAGS flags = .D3D12_RESOURCE_FLAG_NONE;
		if (usage.HasFlag(.Storage))
			flags |= .D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
		if (usage.HasFlag(.AccelStructScratch))
			flags |= .D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
		return flags;
	}

	public static D3D12_RESOURCE_DIMENSION ToResourceDimension(TextureDimension d)
	{
		switch (d)
		{
		case .Texture1D:
			return .D3D12_RESOURCE_DIMENSION_TEXTURE1D;
		case .Texture2D:
			return .D3D12_RESOURCE_DIMENSION_TEXTURE2D;
		case .Texture3D:
			return .D3D12_RESOURCE_DIMENSION_TEXTURE3D;
		}
	}

	public static D3D12_COMPARISON_FUNC ToComparisonFunc(CompareFunction f)
	{
		switch (f)
		{
		case .Never:
			return .D3D12_COMPARISON_FUNC_NEVER;
		case .Less:
			return .D3D12_COMPARISON_FUNC_LESS;
		case .Equal:
			return .D3D12_COMPARISON_FUNC_EQUAL;
		case .LessEqual:
			return .D3D12_COMPARISON_FUNC_LESS_EQUAL;
		case .Greater:
			return .D3D12_COMPARISON_FUNC_GREATER;
		case .NotEqual:
			return .D3D12_COMPARISON_FUNC_NOT_EQUAL;
		case .GreaterEqual:
			return .D3D12_COMPARISON_FUNC_GREATER_EQUAL;
		case .Always:
			return .D3D12_COMPARISON_FUNC_ALWAYS;
		}
	}

	public static D3D12_TEXTURE_ADDRESS_MODE ToAddressMode(AddressMode m)
	{
		switch (m)
		{
		case .Repeat:
			return .D3D12_TEXTURE_ADDRESS_MODE_WRAP;
		case .MirrorRepeat:
			return .D3D12_TEXTURE_ADDRESS_MODE_MIRROR;
		case .ClampToEdge:
			return .D3D12_TEXTURE_ADDRESS_MODE_CLAMP;
		case .ClampToBorder:
			return .D3D12_TEXTURE_ADDRESS_MODE_BORDER;
		}
	}

	public static D3D12_FILTER ToFilter(FilterMode min, FilterMode mag, MipmapFilterMode mip,
								bool comparison)
	{
		bool minL = min == .Linear;
		bool magL = mag == .Linear;
		bool mipL = mip == .Linear;
		if (comparison)
		{
			if (!minL && !magL && !mipL)
				return .D3D12_FILTER_COMPARISON_MIN_MAG_MIP_POINT;
			if (!minL && !magL && mipL)
				return .D3D12_FILTER_COMPARISON_MIN_MAG_POINT_MIP_LINEAR;
			if (!minL && magL && !mipL)
				return .D3D12_FILTER_COMPARISON_MIN_POINT_MAG_LINEAR_MIP_POINT;
			if (!minL && magL && mipL)
				return .D3D12_FILTER_COMPARISON_MIN_POINT_MAG_MIP_LINEAR;
			if (minL && !magL && !mipL)
				return .D3D12_FILTER_COMPARISON_MIN_LINEAR_MAG_MIP_POINT;
			if (minL && !magL && mipL)
				return .D3D12_FILTER_COMPARISON_MIN_LINEAR_MAG_POINT_MIP_LINEAR;
			if (minL && magL && !mipL)
				return .D3D12_FILTER_COMPARISON_MIN_MAG_LINEAR_MIP_POINT;
			return .D3D12_FILTER_COMPARISON_MIN_MAG_MIP_LINEAR;
		}
		if (!minL && !magL && !mipL)
			return .D3D12_FILTER_MIN_MAG_MIP_POINT;
		if (!minL && !magL && mipL)
			return .D3D12_FILTER_MIN_MAG_POINT_MIP_LINEAR;
		if (!minL && magL && !mipL)
			return .D3D12_FILTER_MIN_POINT_MAG_LINEAR_MIP_POINT;
		if (!minL && magL && mipL)
			return .D3D12_FILTER_MIN_POINT_MAG_MIP_LINEAR;
		if (minL && !magL && !mipL)
			return .D3D12_FILTER_MIN_LINEAR_MAG_MIP_POINT;
		if (minL && !magL && mipL)
			return .D3D12_FILTER_MIN_LINEAR_MAG_POINT_MIP_LINEAR;
		if (minL && magL && !mipL)
			return .D3D12_FILTER_MIN_MAG_LINEAR_MIP_POINT;
		return .D3D12_FILTER_MIN_MAG_MIP_LINEAR;
	}

	public static DXGI_FORMAT ToTypelessDepthFormat(TextureFormat f)
	{
		switch (f)
		{
		case .Depth16Unorm:
			return .DXGI_FORMAT_R16_TYPELESS;
		case .Depth24Plus, .Depth24PlusStencil8:
			return .DXGI_FORMAT_R24G8_TYPELESS;
		case .Depth32Float:
			return .DXGI_FORMAT_R32_TYPELESS;
		case .Depth32FloatStencil8:
			return .DXGI_FORMAT_R32G8X24_TYPELESS;
		default:
			return ToDxgiFormat(f);
		}
	}

	public static DXGI_FORMAT ToDepthSrvFormat(TextureFormat f)
	{
		switch (f)
		{
		case .Depth16Unorm:
			return .DXGI_FORMAT_R16_UNORM;
		case .Depth24Plus, .Depth24PlusStencil8:
			return .DXGI_FORMAT_R24_UNORM_X8_TYPELESS;
		case .Depth32Float:
			return .DXGI_FORMAT_R32_FLOAT;
		case .Depth32FloatStencil8:
			return .DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS;
		default:
			return ToDxgiFormat(f);
		}
	}

	public static DXGI_FORMAT ToStencilSrvFormat(TextureFormat f)
	{
		switch (f)
		{
		case .Depth24PlusStencil8:
			return .DXGI_FORMAT_X24_TYPELESS_G8_UINT;
		case .Depth32FloatStencil8:
			return .DXGI_FORMAT_X32_TYPELESS_G8X24_UINT;
		default:
			return ToDxgiFormat(f);
		}
	}

	public static D3D12_PRIMITIVE_TOPOLOGY_TYPE ToPrimitiveTopologyType(PrimitiveTopology t)
	{
		switch (t)
		{
		case .PointList:
			return .D3D12_PRIMITIVE_TOPOLOGY_TYPE_POINT;
		case .LineList, .LineStrip:
			return .D3D12_PRIMITIVE_TOPOLOGY_TYPE_LINE;
		case .TriangleList, .TriangleStrip:
			return .D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;
		}
	}

	public static D3D_PRIMITIVE_TOPOLOGY ToPrimitiveTopology(PrimitiveTopology t)
	{
		switch (t)
		{
		case .PointList:
			return .D3D_PRIMITIVE_TOPOLOGY_POINTLIST;
		case .LineList:
			return .D3D_PRIMITIVE_TOPOLOGY_LINELIST;
		case .LineStrip:
			return .D3D_PRIMITIVE_TOPOLOGY_LINESTRIP;
		case .TriangleList:
			return .D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST;
		case .TriangleStrip:
			return .D3D_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP;
		}
	}

	public static D3D12_CULL_MODE ToCullMode(CullMode m)
	{
		switch (m)
		{
		case .None:
			return .D3D12_CULL_MODE_NONE;
		case .Front:
			return .D3D12_CULL_MODE_FRONT;
		case .Back:
			return .D3D12_CULL_MODE_BACK;
		}
	}

	public static D3D12_FILL_MODE ToFillMode(FillMode m)
	{
		switch (m)
		{
		case .Solid:
			return .D3D12_FILL_MODE_SOLID;
		case .Wireframe:
			return .D3D12_FILL_MODE_WIREFRAME;
		}
	}

	public static D3D12_BLEND ToBlendFactor(BlendFactor f)
	{
		switch (f)
		{
		case .Zero:
			return .D3D12_BLEND_ZERO;
		case .One:
			return .D3D12_BLEND_ONE;
		case .Src:
			return .D3D12_BLEND_SRC_COLOR;
		case .OneMinusSrc:
			return .D3D12_BLEND_INV_SRC_COLOR;
		case .SrcAlpha:
			return .D3D12_BLEND_SRC_ALPHA;
		case .OneMinusSrcAlpha:
			return .D3D12_BLEND_INV_SRC_ALPHA;
		case .Dst:
			return .D3D12_BLEND_DEST_COLOR;
		case .OneMinusDst:
			return .D3D12_BLEND_INV_DEST_COLOR;
		case .DstAlpha:
			return .D3D12_BLEND_DEST_ALPHA;
		case .OneMinusDstAlpha:
			return .D3D12_BLEND_INV_DEST_ALPHA;
		case .SrcAlphaSaturated:
			return .D3D12_BLEND_SRC_ALPHA_SAT;
		case .Constant:
			return .D3D12_BLEND_BLEND_FACTOR;
		case .OneMinusConstant:
			return .D3D12_BLEND_INV_BLEND_FACTOR;
		}
	}

	public static D3D12_BLEND_OP ToBlendOp(BlendOperation op)
	{
		switch (op)
		{
		case .Add:
			return .D3D12_BLEND_OP_ADD;
		case .Subtract:
			return .D3D12_BLEND_OP_SUBTRACT;
		case .ReverseSubtract:
			return .D3D12_BLEND_OP_REV_SUBTRACT;
		case .Min:
			return .D3D12_BLEND_OP_MIN;
		case .Max:
			return .D3D12_BLEND_OP_MAX;
		}
	}

	public static D3D12_STENCIL_OP ToStencilOp(StencilOperation op)
	{
		switch (op)
		{
		case .Keep:
			return .D3D12_STENCIL_OP_KEEP;
		case .Zero:
			return .D3D12_STENCIL_OP_ZERO;
		case .Replace:
			return .D3D12_STENCIL_OP_REPLACE;
		case .IncrementClamp:
			return .D3D12_STENCIL_OP_INCR_SAT;
		case .DecrementClamp:
			return .D3D12_STENCIL_OP_DECR_SAT;
		case .Invert:
			return .D3D12_STENCIL_OP_INVERT;
		case .IncrementWrap:
			return .D3D12_STENCIL_OP_INCR;
		case .DecrementWrap:
			return .D3D12_STENCIL_OP_DECR;
		}
	}

	public static D3D12_DESCRIPTOR_RANGE_TYPE ToDescriptorRangeType(BindingType t)
	{
		switch (t)
		{
		case .UniformBuffer:
			return .D3D12_DESCRIPTOR_RANGE_TYPE_CBV;
		case .StorageBufferReadOnly:
			return .D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
		case .StorageBufferReadWrite:
			return .D3D12_DESCRIPTOR_RANGE_TYPE_UAV;
		case .SampledTexture:
			return .D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
		case .StorageTextureReadOnly:
			return .D3D12_DESCRIPTOR_RANGE_TYPE_UAV;
		case .StorageTextureReadWrite:
			return .D3D12_DESCRIPTOR_RANGE_TYPE_UAV;
		case .Sampler:
			return .D3D12_DESCRIPTOR_RANGE_TYPE_SAMPLER;
		case .ComparisonSampler:
			return .D3D12_DESCRIPTOR_RANGE_TYPE_SAMPLER;
		case .BindlessTextures:
			return .D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
		case .BindlessSamplers:
			return .D3D12_DESCRIPTOR_RANGE_TYPE_SAMPLER;
		case .BindlessStorageBuffers:
			return .D3D12_DESCRIPTOR_RANGE_TYPE_UAV;
		case .BindlessStorageTextures:
			return .D3D12_DESCRIPTOR_RANGE_TYPE_UAV;
		case .AccelerationStructure:
			return .D3D12_DESCRIPTOR_RANGE_TYPE_SRV;
		}
	}

	public static bool IsSamplerBinding(BindingType t)
	{
		return t == .Sampler || t == .ComparisonSampler ||
			t == .BindlessSamplers;
	}

	/// Strips sRGB from a DXGI format (needed for DXGI flip model swap chains).
	public static DXGI_FORMAT StripSrgb(DXGI_FORMAT f)
	{
		switch (f)
		{
		case .DXGI_FORMAT_R8G8B8A8_UNORM_SRGB:
			return .DXGI_FORMAT_R8G8B8A8_UNORM;
		case .DXGI_FORMAT_B8G8R8A8_UNORM_SRGB:
			return .DXGI_FORMAT_B8G8R8A8_UNORM;
		case .DXGI_FORMAT_BC1_UNORM_SRGB:
			return .DXGI_FORMAT_BC1_UNORM;
		case .DXGI_FORMAT_BC2_UNORM_SRGB:
			return .DXGI_FORMAT_BC2_UNORM;
		case .DXGI_FORMAT_BC3_UNORM_SRGB:
			return .DXGI_FORMAT_BC3_UNORM;
		case .DXGI_FORMAT_BC7_UNORM_SRGB:
			return .DXGI_FORMAT_BC7_UNORM;
		default:
			return f;
		}
	}
}
