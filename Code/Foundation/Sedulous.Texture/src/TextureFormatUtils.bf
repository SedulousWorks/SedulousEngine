using Sedulous.Image;
using Sedulous.RHI;

namespace Sedulous.Texture;

/// The bridge between how an image stores its pixels and how the GPU reads them.
static class TextureFormatUtils
{
	/// A CPU pixel format plus the colour space its data is in, to the GPU format that
	/// reads it correctly.
	///
	/// The colour space is a PARAMETER rather than read off the image, because it is an
	/// authoring decision and not something a loader can know: the same eight bit RGBA
	/// bytes are a photograph in one asset and a normal map in the next, and picking the
	/// sRGB format for the second corrupts the vectors rather than merely shifting the
	/// look.
	public static TextureFormat Convert(PixelFormat format, ImageColorSpace colorSpace)
	{
		// Only the eight bit colour formats have an sRGB variant, so only they can take
		// the hardware decode. Everything else falls through to its linear mapping.
		if (colorSpace == .Srgb)
		{
			switch (format)
			{
			case .RGB8, .RGBA8: return .RGBA8UnormSrgb;
			case .BGR8, .BGRA8: return .BGRA8UnormSrgb;
			default:
			}
		}

		switch (format)
		{
		case .R8: return .R8Unorm;
		case .RG8: return .RG8Unorm;
		// Three channels map to four: no GPU stores a three channel texture, so the
		// upload widens and the unused channel costs a quarter of the memory.
		case .RGB8, .RGBA8: return .RGBA8Unorm;
		case .BGR8, .BGRA8: return .BGRA8Unorm;
		case .R16F: return .R16Float;
		case .RG16F: return .RG16Float;
		case .RGB16F, .RGBA16F: return .RGBA16Float;
		case .R32F: return .R32Float;
		case .RG32F: return .RG32Float;
		case .RGB32F, .RGBA32F: return .RGBA32Float;

		// R16 is the HEIGHTMAP format, and this RHI has no single channel sixteen bit
		// unorm to carry it. It stays CPU side, where a heightfield reads the samples
		// directly, so nothing asks for a GPU format for it. Falling through to the
		// default here would silently upload it as RGBA8: named, so that is a decision
		// rather than an omission.
		default: return .RGBA8Unorm;
		}
	}
}
