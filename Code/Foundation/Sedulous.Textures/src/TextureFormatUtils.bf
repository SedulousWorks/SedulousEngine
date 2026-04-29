namespace Sedulous.Textures;

using Sedulous.RHI;
using Sedulous.Images;

/// Converts between Image pixel formats and RHI texture formats.
public static class TextureFormatUtils
{
	/// Converts an Image.PixelFormat to the corresponding RHI TextureFormat,
	/// honoring the source pixel data's color space.
	///
	/// When colorSpace is Srgb and the format has an sRGB variant (8-bit RGB/RGBA/
	/// BGR/BGRA), the sRGB GPU format is returned so hardware decodes sRGB->linear
	/// on sample. Float and single/two-channel formats have no sRGB variant and
	/// pass through unchanged.
	///
	/// Note: RGB/3-channel formats map to RGBA since GPUs don't support 3-channel.
	public static TextureFormat Convert(PixelFormat format, ImageColorSpace colorSpace)
	{
		if (colorSpace == .Srgb)
		{
			switch (format)
			{
			case .RGB8, .RGBA8: return .RGBA8UnormSrgb;
			case .BGR8, .BGRA8: return .BGRA8UnormSrgb;
			default: break;
			}
		}

		switch (format)
		{
		case .R8:       return .R8Unorm;
		case .RG8:      return .RG8Unorm;
		case .RGB8:     return .RGBA8Unorm;
		case .RGBA8:    return .RGBA8Unorm;
		case .BGR8:     return .BGRA8Unorm;
		case .BGRA8:    return .BGRA8Unorm;
		case .R16F:     return .R16Float;
		case .RG16F:    return .RG16Float;
		case .RGB16F:   return .RGBA16Float;
		case .RGBA16F:  return .RGBA16Float;
		case .R32F:     return .R32Float;
		case .RG32F:    return .RG32Float;
		case .RGB32F:   return .RGBA32Float;
		case .RGBA32F:  return .RGBA32Float;
		default:        return .RGBA8Unorm;
		}
	}
}
