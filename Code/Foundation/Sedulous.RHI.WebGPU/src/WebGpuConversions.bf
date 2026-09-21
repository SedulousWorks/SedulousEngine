using System;
using wgpu_Beef;
using Sedulous.RHI;

namespace Sedulous.RHI.WebGPU;

/// The RHI vocabulary in WebGPU's spelling.
///
/// Every mapping is total: an enum the backend does not know maps to the WebGPU
/// Undefined rather than to something plausible, so an unsupported format fails at
/// creation instead of drawing wrong.
static class WebGpuConversions
{
	/// The engine wide register space shift table, shared with Vulkan: CBV at 0, SRV
	/// at +100, UAV at +200, sampler at +300.
	///
	/// Compact on purpose. WebGPU validates binding indices against
	/// maxBindingsPerBindGroup, which is 1000 in a browser, so the Vulkan style wide
	/// spacing does not fit. DXC bakes these into the SPIR-V, so a layout has to
	/// declare the same numbers. The cook time WGSL path emits compact bindings and
	/// bypasses shifting entirely.
	public const uint32 cSrvBindingShift = 100;
	public const uint32 cUavBindingShift = 200;
	public const uint32 cSamplerBindingShift = 300;

	/// A label, borrowed. WebGPU reads the bytes during the call and does not keep
	/// them, so a scoped string is enough at every call site.
	public static WGPUStringView ToWgpuStringView(StringView label)
	{
		return .() { data = label.Ptr, length = (uint)label.Length };
	}

	/// Buffer usage, with the Map emulation's transport folded in.
	///
	/// A CPU to GPU buffer shadows its uploads through WriteBuffer, so it needs
	/// CopyDst. A GPU to CPU one maps for real, and WebGPU validates MapRead as
	/// combinable with NOTHING but CopyDst, so that case REPLACES the usage rather
	/// than adding to it.
	public static WGPUBufferUsage ToWgpuBufferUsage(BufferUsage usage, MemoryLocation memory)
	{
		WGPUBufferUsage flags = WGPUBufferUsage_None;

		if (usage.HasFlag(.CopySrc))
			flags |= WGPUBufferUsage_CopySrc;
		if (usage.HasFlag(.CopyDst))
			flags |= WGPUBufferUsage_CopyDst;
		if (usage.HasFlag(.Vertex))
			flags |= WGPUBufferUsage_Vertex;
		if (usage.HasFlag(.Index))
			flags |= WGPUBufferUsage_Index;
		if (usage.HasFlag(.Uniform))
			flags |= WGPUBufferUsage_Uniform;
		if (usage.HasFlag(.Storage) || usage.HasFlag(.StorageRead))
			flags |= WGPUBufferUsage_Storage;
		if (usage.HasFlag(.Indirect))
			flags |= WGPUBufferUsage_Indirect;

		if (memory == .CpuToGpu)
			flags |= WGPUBufferUsage_CopyDst;
		else if (memory == .GpuToCpu)
			flags = WGPUBufferUsage_MapRead | WGPUBufferUsage_CopyDst;

		return flags;
	}

	/// Texture usage. An input attachment is read as a sampled texture here, WebGPU
	/// having no subpass input of its own.
	public static WGPUTextureUsage ToWgpuTextureUsage(TextureUsage usage)
	{
		WGPUTextureUsage flags = WGPUTextureUsage_None;

		if (usage.HasFlag(.CopySrc))
			flags |= WGPUTextureUsage_CopySrc;
		if (usage.HasFlag(.CopyDst))
			flags |= WGPUTextureUsage_CopyDst;
		if (usage.HasFlag(.Sampled))
			flags |= WGPUTextureUsage_TextureBinding;
		if (usage.HasFlag(.Storage))
			flags |= WGPUTextureUsage_StorageBinding;
		if (usage.HasFlag(.RenderTarget) || usage.HasFlag(.DepthStencil))
			flags |= WGPUTextureUsage_RenderAttachment;
		if (usage.HasFlag(.InputAttachment))
			flags |= WGPUTextureUsage_TextureBinding;

		return flags;
	}

	/// The stages WebGPU actually has. The mesh and ray tracing stages have no
	/// counterpart and drop out.
	public static WGPUShaderStage ToWgpuShaderStage(ShaderStage stages)
	{
		WGPUShaderStage flags = WGPUShaderStage_None;

		if (stages.HasFlag(.Vertex))
			flags |= WGPUShaderStage_Vertex;
		if (stages.HasFlag(.Fragment))
			flags |= WGPUShaderStage_Fragment;
		if (stages.HasFlag(.Compute))
			flags |= WGPUShaderStage_Compute;

		return flags;
	}

	public static WGPUColorWriteMask ToWgpuColorWriteMask(ColorWriteMask mask)
	{
		WGPUColorWriteMask flags = WGPUColorWriteMask_None;

		if (mask.HasFlag(.Red))
			flags |= WGPUColorWriteMask_Red;
		if (mask.HasFlag(.Green))
			flags |= WGPUColorWriteMask_Green;
		if (mask.HasFlag(.Blue))
			flags |= WGPUColorWriteMask_Blue;
		if (mask.HasFlag(.Alpha))
			flags |= WGPUColorWriteMask_Alpha;

		return flags;
	}

	public static WGPUTextureFormat ToWgpuTextureFormat(TextureFormat format)
	{
		switch (format)
		{
		case .Undefined: return .WGPUTextureFormat_Undefined;
		case .R8Unorm: return .WGPUTextureFormat_R8Unorm;
		case .R8Snorm: return .WGPUTextureFormat_R8Snorm;
		case .R8Uint: return .WGPUTextureFormat_R8Uint;
		case .R8Sint: return .WGPUTextureFormat_R8Sint;
		case .R16Uint: return .WGPUTextureFormat_R16Uint;
		case .R16Sint: return .WGPUTextureFormat_R16Sint;
		case .R16Float: return .WGPUTextureFormat_R16Float;
		case .RG8Unorm: return .WGPUTextureFormat_RG8Unorm;
		case .RG8Snorm: return .WGPUTextureFormat_RG8Snorm;
		case .RG8Uint: return .WGPUTextureFormat_RG8Uint;
		case .RG8Sint: return .WGPUTextureFormat_RG8Sint;
		case .R32Uint: return .WGPUTextureFormat_R32Uint;
		case .R32Sint: return .WGPUTextureFormat_R32Sint;
		case .R32Float: return .WGPUTextureFormat_R32Float;
		case .RG16Uint: return .WGPUTextureFormat_RG16Uint;
		case .RG16Sint: return .WGPUTextureFormat_RG16Sint;
		case .RG16Float: return .WGPUTextureFormat_RG16Float;
		case .RGBA8Unorm: return .WGPUTextureFormat_RGBA8Unorm;
		case .RGBA8UnormSrgb: return .WGPUTextureFormat_RGBA8UnormSrgb;
		case .RGBA8Snorm: return .WGPUTextureFormat_RGBA8Snorm;
		case .RGBA8Uint: return .WGPUTextureFormat_RGBA8Uint;
		case .RGBA8Sint: return .WGPUTextureFormat_RGBA8Sint;
		case .BGRA8Unorm: return .WGPUTextureFormat_BGRA8Unorm;
		case .BGRA8UnormSrgb: return .WGPUTextureFormat_BGRA8UnormSrgb;
		case .RGB10A2Unorm: return .WGPUTextureFormat_RGB10A2Unorm;
		case .RGB10A2Uint: return .WGPUTextureFormat_RGB10A2Uint;
		case .RG11B10Float: return .WGPUTextureFormat_RG11B10Ufloat;
		case .RGB9E5Float: return .WGPUTextureFormat_RGB9E5Ufloat;
		case .RG32Uint: return .WGPUTextureFormat_RG32Uint;
		case .RG32Sint: return .WGPUTextureFormat_RG32Sint;
		case .RG32Float: return .WGPUTextureFormat_RG32Float;
		case .RGBA16Uint: return .WGPUTextureFormat_RGBA16Uint;
		case .RGBA16Sint: return .WGPUTextureFormat_RGBA16Sint;
		case .RGBA16Float: return .WGPUTextureFormat_RGBA16Float;
		case .RGBA16Unorm: return .WGPUTextureFormat_Undefined;
		case .RGBA16Snorm: return .WGPUTextureFormat_Undefined;
		case .RGBA32Uint: return .WGPUTextureFormat_RGBA32Uint;
		case .RGBA32Sint: return .WGPUTextureFormat_RGBA32Sint;
		case .RGBA32Float: return .WGPUTextureFormat_RGBA32Float;
		case .Depth16Unorm: return .WGPUTextureFormat_Depth16Unorm;
		case .Depth24Plus: return .WGPUTextureFormat_Depth24Plus;
		case .Depth24PlusStencil8: return .WGPUTextureFormat_Depth24PlusStencil8;
		case .Depth32Float: return .WGPUTextureFormat_Depth32Float;
		case .Depth32FloatStencil8: return .WGPUTextureFormat_Depth32FloatStencil8;
		case .Stencil8: return .WGPUTextureFormat_Stencil8;
		case .BC1RGBAUnorm: return .WGPUTextureFormat_BC1RGBAUnorm;
		case .BC1RGBAUnormSrgb: return .WGPUTextureFormat_BC1RGBAUnormSrgb;
		case .BC2RGBAUnorm: return .WGPUTextureFormat_BC2RGBAUnorm;
		case .BC2RGBAUnormSrgb: return .WGPUTextureFormat_BC2RGBAUnormSrgb;
		case .BC3RGBAUnorm: return .WGPUTextureFormat_BC3RGBAUnorm;
		case .BC3RGBAUnormSrgb: return .WGPUTextureFormat_BC3RGBAUnormSrgb;
		case .BC4RUnorm: return .WGPUTextureFormat_BC4RUnorm;
		case .BC4RSnorm: return .WGPUTextureFormat_BC4RSnorm;
		case .BC5RGUnorm: return .WGPUTextureFormat_BC5RGUnorm;
		case .BC5RGSnorm: return .WGPUTextureFormat_BC5RGSnorm;
		case .BC6HRGBUfloat: return .WGPUTextureFormat_BC6HRGBUfloat;
		case .BC6HRGBFloat: return .WGPUTextureFormat_BC6HRGBFloat;
		case .BC7RGBAUnorm: return .WGPUTextureFormat_BC7RGBAUnorm;
		case .BC7RGBAUnormSrgb: return .WGPUTextureFormat_BC7RGBAUnormSrgb;
		case .ASTC4x4Unorm: return .WGPUTextureFormat_ASTC4x4Unorm;
		case .ASTC4x4UnormSrgb: return .WGPUTextureFormat_ASTC4x4UnormSrgb;
		case .ASTC5x5Unorm: return .WGPUTextureFormat_ASTC5x5Unorm;
		case .ASTC5x5UnormSrgb: return .WGPUTextureFormat_ASTC5x5UnormSrgb;
		case .ASTC6x6Unorm: return .WGPUTextureFormat_ASTC6x6Unorm;
		case .ASTC6x6UnormSrgb: return .WGPUTextureFormat_ASTC6x6UnormSrgb;
		case .ASTC8x8Unorm: return .WGPUTextureFormat_ASTC8x8Unorm;
		case .ASTC8x8UnormSrgb: return .WGPUTextureFormat_ASTC8x8UnormSrgb;
		default: return .WGPUTextureFormat_Undefined;
		}
	}

	public static WGPUTextureDimension ToWgpuTextureDimension(TextureDimension dimension)
	{
		switch (dimension)
		{
		case .Texture1D: return .WGPUTextureDimension_1D;
		case .Texture2D: return .WGPUTextureDimension_2D;
		case .Texture3D: return .WGPUTextureDimension_3D;
		default: return .WGPUTextureDimension_2D;
		}
	}

	public static WGPUTextureViewDimension ToWgpuTextureViewDimension(TextureViewDimension dimension)
	{
		switch (dimension)
		{
		case .Texture1D: return .WGPUTextureViewDimension_1D;
		case .Texture1DArray: return .WGPUTextureViewDimension_Undefined;
		case .Texture2D: return .WGPUTextureViewDimension_2D;
		case .Texture2DArray: return .WGPUTextureViewDimension_2DArray;
		case .TextureCube: return .WGPUTextureViewDimension_Cube;
		case .TextureCubeArray: return .WGPUTextureViewDimension_CubeArray;
		case .Texture3D: return .WGPUTextureViewDimension_3D;
		default: return .WGPUTextureViewDimension_2D;
		}
	}

	public static WGPUTextureAspect ToWgpuTextureAspect(TextureAspect aspect)
	{
		switch (aspect)
		{
		case .All: return .WGPUTextureAspect_All;
		case .DepthOnly: return .WGPUTextureAspect_DepthOnly;
		case .StencilOnly: return .WGPUTextureAspect_StencilOnly;
		default: return .WGPUTextureAspect_All;
		}
	}

	public static WGPUAddressMode ToWgpuAddressMode(AddressMode mode)
	{
		switch (mode)
		{
		case .Repeat: return .WGPUAddressMode_Repeat;
		case .MirrorRepeat: return .WGPUAddressMode_MirrorRepeat;
		case .ClampToEdge: return .WGPUAddressMode_ClampToEdge;
		default: return .WGPUAddressMode_Repeat;
		}
	}

	public static WGPUCompareFunction ToWgpuCompareFunction(CompareFunction compare)
	{
		switch (compare)
		{
		case .Never: return .WGPUCompareFunction_Never;
		case .Less: return .WGPUCompareFunction_Less;
		case .Equal: return .WGPUCompareFunction_Equal;
		case .LessEqual: return .WGPUCompareFunction_LessEqual;
		case .Greater: return .WGPUCompareFunction_Greater;
		case .NotEqual: return .WGPUCompareFunction_NotEqual;
		case .GreaterEqual: return .WGPUCompareFunction_GreaterEqual;
		case .Always: return .WGPUCompareFunction_Always;
		default: return .WGPUCompareFunction_Always;
		}
	}

	public static WGPUPrimitiveTopology ToWgpuPrimitiveTopology(PrimitiveTopology topology)
	{
		switch (topology)
		{
		case .PointList: return .WGPUPrimitiveTopology_PointList;
		case .LineList: return .WGPUPrimitiveTopology_LineList;
		case .LineStrip: return .WGPUPrimitiveTopology_LineStrip;
		case .TriangleList: return .WGPUPrimitiveTopology_TriangleList;
		case .TriangleStrip: return .WGPUPrimitiveTopology_TriangleStrip;
		default: return .WGPUPrimitiveTopology_TriangleList;
		}
	}

	public static WGPUCullMode ToWgpuCullMode(CullMode mode)
	{
		switch (mode)
		{
		case .None: return .WGPUCullMode_None;
		case .Front: return .WGPUCullMode_Front;
		case .Back: return .WGPUCullMode_Back;
		default: return .WGPUCullMode_None;
		}
	}

	public static WGPUStencilOperation ToWgpuStencilOperation(StencilOperation op)
	{
		switch (op)
		{
		case .Keep: return .WGPUStencilOperation_Keep;
		case .Zero: return .WGPUStencilOperation_Zero;
		case .Replace: return .WGPUStencilOperation_Replace;
		case .IncrementClamp: return .WGPUStencilOperation_IncrementClamp;
		case .DecrementClamp: return .WGPUStencilOperation_DecrementClamp;
		case .Invert: return .WGPUStencilOperation_Invert;
		case .IncrementWrap: return .WGPUStencilOperation_IncrementWrap;
		case .DecrementWrap: return .WGPUStencilOperation_DecrementWrap;
		default: return .WGPUStencilOperation_Keep;
		}
	}

	public static WGPUBlendFactor ToWgpuBlendFactor(BlendFactor factor)
	{
		switch (factor)
		{
		case .Zero: return .WGPUBlendFactor_Zero;
		case .One: return .WGPUBlendFactor_One;
		case .Src: return .WGPUBlendFactor_Src;
		case .OneMinusSrc: return .WGPUBlendFactor_OneMinusSrc;
		case .SrcAlpha: return .WGPUBlendFactor_SrcAlpha;
		case .OneMinusSrcAlpha: return .WGPUBlendFactor_OneMinusSrcAlpha;
		case .Dst: return .WGPUBlendFactor_Dst;
		case .OneMinusDst: return .WGPUBlendFactor_OneMinusDst;
		case .DstAlpha: return .WGPUBlendFactor_DstAlpha;
		case .OneMinusDstAlpha: return .WGPUBlendFactor_OneMinusDstAlpha;
		case .SrcAlphaSaturated: return .WGPUBlendFactor_SrcAlphaSaturated;
		case .Constant: return .WGPUBlendFactor_Constant;
		case .OneMinusConstant: return .WGPUBlendFactor_OneMinusConstant;
		default: return .WGPUBlendFactor_One;
		}
	}

	public static WGPUBlendOperation ToWgpuBlendOperation(BlendOperation op)
	{
		switch (op)
		{
		case .Add: return .WGPUBlendOperation_Add;
		case .Subtract: return .WGPUBlendOperation_Subtract;
		case .ReverseSubtract: return .WGPUBlendOperation_ReverseSubtract;
		case .Min: return .WGPUBlendOperation_Min;
		case .Max: return .WGPUBlendOperation_Max;
		default: return .WGPUBlendOperation_Add;
		}
	}

	public static WGPUVertexFormat ToWgpuVertexFormat(VertexFormat format)
	{
		switch (format)
		{
		case .Uint8x2: return .WGPUVertexFormat_Uint8x2;
		case .Uint8x4: return .WGPUVertexFormat_Uint8x4;
		case .Sint8x2: return .WGPUVertexFormat_Sint8x2;
		case .Sint8x4: return .WGPUVertexFormat_Sint8x4;
		case .Unorm8x2: return .WGPUVertexFormat_Unorm8x2;
		case .Unorm8x4: return .WGPUVertexFormat_Unorm8x4;
		case .Snorm8x2: return .WGPUVertexFormat_Snorm8x2;
		case .Snorm8x4: return .WGPUVertexFormat_Snorm8x4;
		case .Uint16x2: return .WGPUVertexFormat_Uint16x2;
		case .Uint16x4: return .WGPUVertexFormat_Uint16x4;
		case .Sint16x2: return .WGPUVertexFormat_Sint16x2;
		case .Sint16x4: return .WGPUVertexFormat_Sint16x4;
		case .Unorm16x2: return .WGPUVertexFormat_Unorm16x2;
		case .Unorm16x4: return .WGPUVertexFormat_Unorm16x4;
		case .Snorm16x2: return .WGPUVertexFormat_Snorm16x2;
		case .Snorm16x4: return .WGPUVertexFormat_Snorm16x4;
		case .Float16x2: return .WGPUVertexFormat_Float16x2;
		case .Float16x4: return .WGPUVertexFormat_Float16x4;
		case .Float32: return .WGPUVertexFormat_Float32;
		case .Float32x2: return .WGPUVertexFormat_Float32x2;
		case .Float32x3: return .WGPUVertexFormat_Float32x3;
		case .Float32x4: return .WGPUVertexFormat_Float32x4;
		case .Uint32: return .WGPUVertexFormat_Uint32;
		case .Uint32x2: return .WGPUVertexFormat_Uint32x2;
		case .Uint32x3: return .WGPUVertexFormat_Uint32x3;
		case .Uint32x4: return .WGPUVertexFormat_Uint32x4;
		case .Sint32: return .WGPUVertexFormat_Sint32;
		case .Sint32x2: return .WGPUVertexFormat_Sint32x2;
		case .Sint32x3: return .WGPUVertexFormat_Sint32x3;
		case .Sint32x4: return .WGPUVertexFormat_Sint32x4;
		default: return .WGPUVertexFormat_Float32;
		}
	}

	public static WGPUTextureSampleType ToWgpuTextureSampleType(TextureSampleType type)
	{
		switch (type)
		{
		case .Float: return .WGPUTextureSampleType_Float;
		case .UnfilterableFloat: return .WGPUTextureSampleType_UnfilterableFloat;
		case .Depth: return .WGPUTextureSampleType_Depth;
		case .Uint: return .WGPUTextureSampleType_Uint;
		case .Sint: return .WGPUTextureSampleType_Sint;
		default: return .WGPUTextureSampleType_Float;
		}
	}

	public static WGPULoadOp ToWgpuLoadOp(LoadOp op)
	{
		switch (op)
		{
		case .Load: return .WGPULoadOp_Load;
		case .Clear: return .WGPULoadOp_Clear;
		case .DontCare: return .WGPULoadOp_Clear;
		default: return .WGPULoadOp_Clear;
		}
	}

	public static WGPUPresentMode ToWgpuPresentMode(PresentMode mode)
	{
		switch (mode)
		{
		case .Immediate: return .WGPUPresentMode_Immediate;
		case .Mailbox: return .WGPUPresentMode_Mailbox;
		case .Fifo: return .WGPUPresentMode_Fifo;
		case .FifoRelaxed: return .WGPUPresentMode_FifoRelaxed;
		default: return .WGPUPresentMode_Fifo;
		}
	}

	// The two-way ones. Each names the ONE value that is not the default, so a new enum
	// member lands on the default rather than silently on the named one.

	public static WGPUFilterMode ToWgpuFilterMode(FilterMode filter)
	{
		return (filter == .Nearest) ? .WGPUFilterMode_Nearest : .WGPUFilterMode_Linear;
	}

	public static WGPUMipmapFilterMode ToWgpuMipmapFilterMode(MipmapFilterMode filter)
	{
		return (filter == .Nearest) ? .WGPUMipmapFilterMode_Nearest : .WGPUMipmapFilterMode_Linear;
	}

	public static WGPUFrontFace ToWgpuFrontFace(FrontFace face)
	{
		return (face == .CCW) ? .WGPUFrontFace_CCW : .WGPUFrontFace_CW;
	}

	public static WGPUVertexStepMode ToWgpuVertexStepMode(VertexStepMode mode)
	{
		return (mode == .Instance) ? .WGPUVertexStepMode_Instance : .WGPUVertexStepMode_Vertex;
	}

	public static WGPUStoreOp ToWgpuStoreOp(StoreOp op)
	{
		return (op == .Store) ? .WGPUStoreOp_Store : .WGPUStoreOp_Discard;
	}

	/// Where a binding actually lands, once the register space shift is applied.
	///
	/// HLSL's register classes are what the shift encodes: a constant buffer stays put,
	/// an SRV moves up by a hundred, a UAV by two, a sampler by three. A StructuredBuffer
	/// is an SRV in HLSL terms, which is why a read only storage buffer shifts with the
	/// sampled textures rather than with the writable ones.
	///
	/// DXC bakes these into the SPIR-V, so a layout has to declare the same numbers.
	public static uint32 ShiftedBinding(BindingType type, uint32 binding)
	{
		switch (type)
		{
		case .UniformBuffer:
			return binding;
		case .SampledTexture, .StorageBufferReadOnly:
			return binding + cSrvBindingShift;
		case .StorageTextureReadOnly, .StorageTextureReadWrite, .StorageBufferReadWrite:
			return binding + cUavBindingShift;
		case .Sampler, .ComparisonSampler:
			return binding + cSamplerBindingShift;
		default:
			// Bindless and acceleration structure bindings never reach a WebGPU layout.
			return binding;
		}
	}

	/// Whether the internal blit pass can RENDER to this format, which decides whether a
	/// mip chain can be generated into it.
	///
	/// WebGPU has no image blit, so mips are generated by drawing, and that needs a 2D
	/// colour target. This is the ALLOWLIST of WebGPU's renderable colour formats, spelled
	/// that way on purpose: as an exclusion list it forgot ASTC and the 8 bit snorm formats,
	/// so a mip chained texture in one of those had RenderAttachment widened onto it and
	/// failed at creation. A format this does not name is not blit capable.
	public static bool IsBlitCapableFormat(TextureFormat format)
	{
		switch (format)
		{
		case .R8Unorm, .R8Uint, .R8Sint,
			.R16Uint, .R16Sint, .R16Float,
			.RG8Unorm, .RG8Uint, .RG8Sint,
			.R32Uint, .R32Sint, .R32Float,
			.RG16Uint, .RG16Sint, .RG16Float,
			.RGBA8Unorm, .RGBA8UnormSrgb, .RGBA8Uint, .RGBA8Sint,
			.BGRA8Unorm, .BGRA8UnormSrgb,
			.RGB10A2Unorm, .RGB10A2Uint,
			.RG32Uint, .RG32Sint, .RG32Float,
			.RGBA16Uint, .RGBA16Sint, .RGBA16Float,
			.RGBA32Uint, .RGBA32Sint, .RGBA32Float:
			return true;
		default:
			// Depth and stencil, every BC and ASTC block format, the 8 bit snorm trio,
			// RGBA16Unorm and Snorm, RGB9E5 and RG11B10, which are feature gated, and
			// Undefined.
			return false;
		}
	}
}
