namespace Sedulous.RHI;

/// Pixel formats for textures and render targets.
///
/// Naming follows the WebGPU and Vulkan convention: component layout, then bit depth, then
/// type. ORDER IS LOAD BEARING: the depth and compressed predicates below are range checks
/// over these members, so moving one silently changes what counts as a depth format.
enum TextureFormat : uint32
{
	Undefined = 0,

	// 8 bit per channel.
	R8Unorm,
	R8Snorm,
	R8Uint,
	R8Sint,

	// 16 bit per channel.
	R16Uint,
	R16Sint,
	R16Float,
	RG8Unorm,
	RG8Snorm,
	RG8Uint,
	RG8Sint,

	// 32 bit per channel.
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

	// 64 bit per channel.
	RG32Uint,
	RG32Sint,
	RG32Float,
	RGBA16Uint,
	RGBA16Sint,
	RGBA16Float,
	RGBA16Unorm,
	RGBA16Snorm,

	// 128 bit per channel.
	RGBA32Uint,
	RGBA32Sint,
	RGBA32Float,

	// Depth and stencil. The depth predicates bracket this run.
	Depth16Unorm,
	Depth24Plus,
	Depth24PlusStencil8,
	Depth32Float,
	Depth32FloatStencil8,
	Stencil8,

	// BC compressed. IsCompressed brackets from here to the last ASTC member.
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

	// ASTC compressed.
	ASTC4x4Unorm,
	ASTC4x4UnormSrgb,
	ASTC5x5Unorm,
	ASTC5x5UnormSrgb,
	ASTC6x6Unorm,
	ASTC6x6UnormSrgb,
	ASTC8x8Unorm,
	ASTC8x8UnormSrgb
}

/// What a format is made of, and how much room it takes.
static class TextureFormats
{
	/// The depth formats, Stencil8 excluded: it carries no depth.
	public static bool IsDepthFormat(TextureFormat f)
		=> (f >= .Depth16Unorm) && (f <= .Depth32FloatStencil8);

	/// Any depth OR stencil format, which is the run above plus Stencil8.
	public static bool IsDepthStencil(TextureFormat f)
		=> (f >= .Depth16Unorm) && (f <= .Stencil8);

	public static bool HasDepth(TextureFormat f)
	{
		switch (f)
		{
		case .Depth16Unorm, .Depth24Plus, .Depth24PlusStencil8, .Depth32Float,
			.Depth32FloatStencil8:
			return true;
		default:
			return false;
		}
	}

	public static bool HasStencil(TextureFormat f)
	{
		switch (f)
		{
		case .Depth24PlusStencil8, .Depth32FloatStencil8, .Stencil8:
			return true;
		default:
			return false;
		}
	}

	/// BC or ASTC.
	public static bool IsCompressed(TextureFormat f)
		=> (f >= .BC1RGBAUnorm) && (f <= .ASTC8x8UnormSrgb);

	/// The sRGB variants, which decode to linear when sampled and encode back when written.
	public static bool IsSrgb(TextureFormat f)
	{
		switch (f)
		{
		case .RGBA8UnormSrgb, .BGRA8UnormSrgb,
			.BC1RGBAUnormSrgb, .BC2RGBAUnormSrgb, .BC3RGBAUnormSrgb, .BC7RGBAUnormSrgb,
			.ASTC4x4UnormSrgb, .ASTC5x5UnormSrgb, .ASTC6x6UnormSrgb, .ASTC8x8UnormSrgb:
			return true;
		default:
			return false;
		}
	}

	/// Bytes per pixel for an uncompressed format; zero for a compressed one, where a pixel
	/// has no independent size and BlockBytes is the question to ask.
	///
	/// NOTE: this also returns zero for a number of perfectly ordinary uncompressed formats
	/// that the table below simply does not list, R8Uint and RGBA8Snorm among them. That is
	/// Raptor's behaviour and is ported as is rather than quietly corrected; the tests pin
	/// it so a later fix is a deliberate change with a failing test behind it.
	public static uint32 BytesPerPixel(TextureFormat f)
	{
		switch (f)
		{
		case .R8Unorm, .Stencil8:
			return 1;
		case .R16Uint, .R16Sint, .R16Float, .RG8Unorm, .Depth16Unorm:
			return 2;
		case .RGBA8Unorm, .RGBA8UnormSrgb, .BGRA8Unorm, .BGRA8UnormSrgb, .RG16Float,
			.R32Float, .R32Uint, .R32Sint, .RGB10A2Unorm, .RG11B10Float,
			.Depth24Plus, .Depth24PlusStencil8, .Depth32Float:
			return 4;
		case .Depth32FloatStencil8,
			.RG32Float, .RG32Uint, .RGBA16Float, .RGBA16Uint, .RGBA16Sint:
			return 8;
		case .RGBA32Float, .RGBA32Uint, .RGBA32Sint:
			return 16;
		default:
			return 0; // compressed, or a format the table does not list
		}
	}

	/// The block footprint in texels; one for an uncompressed format. BC is always four by
	/// four; ASTC varies with the format.
	public static uint32 BlockWidth(TextureFormat f)
	{
		switch (f)
		{
		case .ASTC5x5Unorm, .ASTC5x5UnormSrgb:
			return 5;
		case .ASTC6x6Unorm, .ASTC6x6UnormSrgb:
			return 6;
		case .ASTC8x8Unorm, .ASTC8x8UnormSrgb:
			return 8;
		default:
			return IsCompressed(f) ? 4 : 1; // every BC block, and ASTC 4x4
		}
	}

	/// Every supported block is square, so this is BlockWidth. It exists as its own name so
	/// call sites read correctly and a non square block later has one place to change.
	public static uint32 BlockHeight(TextureFormat f) => BlockWidth(f);

	/// Bytes one compressed block occupies; zero for uncompressed. BC1 and BC4 are eight,
	/// every other BC block and every ASTC block is sixteen.
	public static uint32 BlockBytes(TextureFormat f)
	{
		switch (f)
		{
		case .BC1RGBAUnorm, .BC1RGBAUnormSrgb, .BC4RUnorm, .BC4RSnorm:
			return 8;
		default:
			return IsCompressed(f) ? 16 : 0;
		}
	}

	/// Bytes between consecutive block ROWS of a compressed level, which is the bytesPerRow
	/// an upload wants; zero for uncompressed. The width is rounded up to whole blocks.
	public static uint32 CompressedRowPitch(TextureFormat f, uint32 width)
	{
		if (!IsCompressed(f))
			return 0;
		let blockWidth = BlockWidth(f);
		return ((width + blockWidth - 1) / blockWidth) * BlockBytes(f);
	}

	/// Total bytes a compressed two dimensional level occupies; zero for uncompressed.
	public static uint64 CompressedLevelBytes(TextureFormat f, uint32 width, uint32 height)
	{
		if (!IsCompressed(f))
			return 0;
		let blockHeight = BlockHeight(f);
		return (uint64)CompressedRowPitch(f, width) * (uint64)((height + blockHeight - 1) / blockHeight);
	}
}
