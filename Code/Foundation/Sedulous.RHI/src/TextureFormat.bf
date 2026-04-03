namespace Sedulous.RHI;

/// Texture pixel format.
enum TextureFormat
{
	Undefined = 0,

	// ===== 8-bit =====
	R8Unorm,
	R8Snorm,
	R8Uint,
	R8Sint,

	// ===== 16-bit =====
	R16Uint,
	R16Sint,
	R16Float,
	RG8Unorm,
	RG8Snorm,
	RG8Uint,
	RG8Sint,

	// ===== 32-bit =====
	R32Uint,
	R32Sint,
	R32Float,
	RG16Uint,
	RG16Sint,
	RG16Float,
	RGBA8Unorm,
	RGBA8UnormSrgb,
	RGBA8Snorm,
	RGBA8Uint,
	RGBA8Sint,
	BGRA8Unorm,
	BGRA8UnormSrgb,
	RGB10A2Unorm,
	RGB10A2Uint,
	RG11B10Float,
	RGB9E5Float,

	// ===== 64-bit =====
	RG32Uint,
	RG32Sint,
	RG32Float,
	RGBA16Uint,
	RGBA16Sint,
	RGBA16Float,
	RGBA16Unorm,
	RGBA16Snorm,

	// ===== 128-bit =====
	RGBA32Uint,
	RGBA32Sint,
	RGBA32Float,

	// ===== Depth/Stencil =====
	Depth16Unorm,
	Depth24Plus,
	Depth24PlusStencil8,
	Depth32Float,
	Depth32FloatStencil8,
	Stencil8,

	// ===== BC Compressed =====
	BC1RGBAUnorm,
	BC1RGBAUnormSrgb,
	BC2RGBAUnorm,
	BC2RGBAUnormSrgb,
	BC3RGBAUnorm,
	BC3RGBAUnormSrgb,
	BC4RUnorm,
	BC4RSnorm,
	BC5RGUnorm,
	BC5RGSnorm,
	BC6HRGBUfloat,
	BC6HRGBFloat,
	BC7RGBAUnorm,
	BC7RGBAUnormSrgb,

	// ===== ASTC Compressed (mobile, future-proofing) =====
	ASTC4x4Unorm,
	ASTC4x4UnormSrgb,
	ASTC5x5Unorm,
	ASTC5x5UnormSrgb,
	ASTC6x6Unorm,
	ASTC6x6UnormSrgb,
	ASTC8x8Unorm,
	ASTC8x8UnormSrgb,
}

/// Extension methods for TextureFormat.
static class TextureFormatExt
{
	/// Extension to check if a TextureFormat is a depth format
	public static bool IsDepthFormat(this TextureFormat fmt)
	{
		switch (fmt)
		{
		case .Depth16Unorm,.Depth24Plus,.Depth24PlusStencil8,.Depth32Float,.Depth32FloatStencil8:
			return true;
		default:
			return false;
		}
	}
	/// Returns true if this is a depth or depth/stencil format.
	public static bool IsDepthStencil(this TextureFormat fmt)
	{
		switch (fmt)
		{
		case .Depth16Unorm,.Depth24Plus,.Depth24PlusStencil8,.Depth32Float,.Depth32FloatStencil8,.Stencil8:
			return true;
		default:
			return false;
		}
	}

	/// Returns true if this format has a depth component.
	public static bool HasDepth(this TextureFormat fmt)
	{
		switch (fmt)
		{
		case .Depth16Unorm,.Depth24Plus,.Depth24PlusStencil8,
			.Depth32Float,.Depth32FloatStencil8:
			return true;
		default:
			return false;
		}
	}

	/// Returns true if this format has a stencil component.
	public static bool HasStencil(this TextureFormat fmt)
	{
		switch (fmt)
		{
		case .Depth24PlusStencil8,.Depth32FloatStencil8,.Stencil8:
			return true;
		default:
			return false;
		}
	}

	/// Returns true if this is a BC or ASTC compressed format.
	public static bool IsCompressed(this TextureFormat fmt)
	{
		switch (fmt)
		{
		case .BC1RGBAUnorm,.BC1RGBAUnormSrgb,
			.BC2RGBAUnorm,.BC2RGBAUnormSrgb,
			.BC3RGBAUnorm,.BC3RGBAUnormSrgb,
			.BC4RUnorm,.BC4RSnorm,
			.BC5RGUnorm,.BC5RGSnorm,
			.BC6HRGBUfloat,.BC6HRGBFloat,
			.BC7RGBAUnorm,.BC7RGBAUnormSrgb,
			.ASTC4x4Unorm,.ASTC4x4UnormSrgb,
			.ASTC5x5Unorm,.ASTC5x5UnormSrgb,
			.ASTC6x6Unorm,.ASTC6x6UnormSrgb,
			.ASTC8x8Unorm,.ASTC8x8UnormSrgb:
			return true;
		default:
			return false;
		}
	}

	/// Returns true if this is an sRGB format.
	public static bool IsSrgb(this TextureFormat fmt)
	{
		switch (fmt)
		{
		case .RGBA8UnormSrgb,.BGRA8UnormSrgb,
			.BC1RGBAUnormSrgb,.BC2RGBAUnormSrgb,.BC3RGBAUnormSrgb,
			.BC7RGBAUnormSrgb,
			.ASTC4x4UnormSrgb,.ASTC5x5UnormSrgb,
			.ASTC6x6UnormSrgb,.ASTC8x8UnormSrgb:
			return true;
		default:
			return false;
		}
	}

	/// Returns the number of bytes per pixel for uncompressed formats.
	/// Returns 0 for compressed and undefined formats.
	public static uint32 BytesPerPixel(this TextureFormat fmt)
	{
		switch (fmt)
		{
		// 1 byte
		case .R8Unorm,.R8Snorm,.R8Uint,.R8Sint,.Stencil8:
			return 1;
		// 2 bytes
		case .R16Uint,.R16Sint,.R16Float,
			.RG8Unorm,.RG8Snorm,.RG8Uint,.RG8Sint,
			.Depth16Unorm:
			return 2;
		// 4 bytes
		case .R32Uint,.R32Sint,.R32Float,
			.RG16Uint,.RG16Sint,.RG16Float,
			.RGBA8Unorm,.RGBA8UnormSrgb,.RGBA8Snorm,.RGBA8Uint,.RGBA8Sint,
			.BGRA8Unorm,.BGRA8UnormSrgb,
			.RGB10A2Unorm,.RGB10A2Uint,
			.RG11B10Float,.RGB9E5Float,
			.Depth24Plus,.Depth24PlusStencil8,.Depth32Float:
			return 4;
		// 5 bytes
		case .Depth32FloatStencil8:
			return 5;
		// 8 bytes
		case .RG32Uint,.RG32Sint,.RG32Float,
			.RGBA16Uint,.RGBA16Sint,.RGBA16Float,.RGBA16Unorm,.RGBA16Snorm:
			return 8;
		// 16 bytes
		case .RGBA32Uint,.RGBA32Sint,.RGBA32Float:
			return 16;
		default:
			return 0;
		}
	}

	/// Returns the BC block size in bytes for compressed formats (all BC = 4x4 blocks).
	/// Returns 0 for non-compressed formats.
	public static uint32 BlockSize(this TextureFormat fmt)
	{
		switch (fmt)
		{
		// 8 bytes per 4x4 block
		case .BC1RGBAUnorm,.BC1RGBAUnormSrgb,
			.BC4RUnorm,.BC4RSnorm:
			return 8;
		// 16 bytes per 4x4 block
		case .BC2RGBAUnorm,.BC2RGBAUnormSrgb,
			.BC3RGBAUnorm,.BC3RGBAUnormSrgb,
			.BC5RGUnorm,.BC5RGSnorm,
			.BC6HRGBUfloat,.BC6HRGBFloat,
			.BC7RGBAUnorm,.BC7RGBAUnormSrgb:
			return 16;
		// ASTC: 16 bytes per block (all ASTC block sizes use 128 bits)
		case .ASTC4x4Unorm,.ASTC4x4UnormSrgb,
			.ASTC5x5Unorm,.ASTC5x5UnormSrgb,
			.ASTC6x6Unorm,.ASTC6x6UnormSrgb,
			.ASTC8x8Unorm,.ASTC8x8UnormSrgb:
			return 16;
		default:
			return 0;
		}
	}
}
