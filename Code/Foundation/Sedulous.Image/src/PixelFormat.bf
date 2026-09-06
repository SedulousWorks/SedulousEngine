namespace Sedulous.Image;

/// The layout of one pixel in CPU side image data.
///
/// Values are appended, never reordered: the enum is stored in cooked textures, so moving
/// one silently reinterprets every image already written.
enum PixelFormat : uint32
{
	case R8;
	case RG8;
	case RGB8;
	case RGBA8;
	case R16F;
	case RG16F;
	case RGB16F;
	case RGBA16F;
	case R32F;
	case RG32F;
	case RGB32F;
	case RGBA32F;
	case BGR8;
	case BGRA8;
	/// Unsigned 16 bit single channel, for heightmaps. Appended last to keep the values
	/// above stable.
	case R16;
}

static class PixelFormats
{
	public static uint32 BytesPerPixel(PixelFormat format)
	{
		switch (format)
		{
		case .R8: return 1;
		case .RG8: return 2;
		case .RGB8, .BGR8: return 3;
		case .RGBA8, .BGRA8: return 4;
		case .R16, .R16F: return 2;
		case .RG16F: return 4;
		case .RGB16F: return 6;
		case .RGBA16F: return 8;
		case .R32F: return 4;
		case .RG32F: return 8;
		case .RGB32F: return 12;
		case .RGBA32F: return 16;
		}
	}

	public static uint32 ChannelCount(PixelFormat format)
	{
		switch (format)
		{
		case .R8, .R16, .R16F, .R32F: return 1;
		case .RG8, .RG16F, .RG32F: return 2;
		case .RGB8, .BGR8, .RGB16F, .RGB32F: return 3;
		case .RGBA8, .BGRA8, .RGBA16F, .RGBA32F: return 4;
		}
	}

	public static bool HasAlpha(PixelFormat format)
	{
		switch (format)
		{
		case .RGBA8, .BGRA8, .RGBA16F, .RGBA32F: return true;
		default: return false;
		}
	}
}
