namespace Sedulous.Image.DDS;

/// The DXGI formats a DDS may carry that the engine reads.
///
/// A legacy FourCC header maps onto the same values, DXT1 becoming BC1, DXT5 BC3, ATI2 BC5
/// and so on, so the rest of the reader never has to know which header form it came from.
enum DdsFormat : uint8
{
	case Unknown;
	case R8;
	case RG8;
	case RGBA8;
	case RGBA8Srgb;
	case BGRA8;
	case BGRA8Srgb;
	case RGBA16F;
	case RGBA32F;
	case BC1;
	case BC1Srgb;
	case BC2;
	case BC2Srgb;
	case BC3;
	case BC3Srgb;
	case BC4;
	case BC4Snorm;
	case BC5;
	case BC5Snorm;
	/// Unsigned half float radiance.
	case BC6HUf;
	case BC6HSf;
	case BC7;
	case BC7Srgb;
}

static class DdsFormats
{
	public static bool IsBlockCompressed(DdsFormat format)
		=> (format >= .BC1) && (format <= .BC7Srgb);

	/// Bytes per four by four block, nought when the format is not compressed.
	public static uint32 BlockBytes(DdsFormat format)
	{
		switch (format)
		{
		case .BC1, .BC1Srgb, .BC4, .BC4Snorm:
			return 8;
		default:
			return IsBlockCompressed(format) ? 16 : 0;
		}
	}

	/// Bytes per texel, nought when the format IS compressed.
	public static uint32 BytesPerPixel(DdsFormat format)
	{
		switch (format)
		{
		case .R8: return 1;
		case .RG8: return 2;
		case .RGBA8, .RGBA8Srgb, .BGRA8, .BGRA8Srgb: return 4;
		case .RGBA16F: return 8;
		case .RGBA32F: return 16;
		default: return 0;
		}
	}

	public static bool IsSrgb(DdsFormat format)
	{
		switch (format)
		{
		case .RGBA8Srgb, .BGRA8Srgb, .BC1Srgb, .BC2Srgb, .BC3Srgb, .BC7Srgb:
			return true;
		default:
			return false;
		}
	}

	/// True for the float formats, BC6H and the half and float texel ones: they decode to
	/// RGBA32F and everything else to RGBA8.
	public static bool IsHdr(DdsFormat format)
		=> (format == .RGBA16F) || (format == .RGBA32F) || (format == .BC6HUf)
			|| (format == .BC6HSf);

	/// The sRGB or non sRGB twin of a format where one exists, which is the same bytes under
	/// another GPU view; a format without a twin comes back unchanged.
	public static DdsFormat WithSrgb(DdsFormat format, bool srgb)
	{
		switch (format)
		{
		case .RGBA8, .RGBA8Srgb: return srgb ? .RGBA8Srgb : .RGBA8;
		case .BGRA8, .BGRA8Srgb: return srgb ? .BGRA8Srgb : .BGRA8;
		case .BC1, .BC1Srgb: return srgb ? .BC1Srgb : .BC1;
		case .BC2, .BC2Srgb: return srgb ? .BC2Srgb : .BC2;
		case .BC3, .BC3Srgb: return srgb ? .BC3Srgb : .BC3;
		case .BC7, .BC7Srgb: return srgb ? .BC7Srgb : .BC7;
		default: return format;
		}
	}

	/// The bytes one level of a given size occupies, block ceiled for a compressed format.
	public static int LevelBytes(DdsFormat format, uint32 width, uint32 height)
	{
		if (IsBlockCompressed(format))
		{
			let blocksX = ((int)width + 3) / 4;
			let blocksY = ((int)height + 3) / 4;
			return blocksX * blocksY * (int)BlockBytes(format);
		}
		return (int)width * (int)height * (int)BytesPerPixel(format);
	}
}
