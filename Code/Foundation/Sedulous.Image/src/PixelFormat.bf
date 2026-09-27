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

	/// IEEE 754 binary16 to float, exact: sign, the five exponent bits and the ten mantissa
	/// bits re-based (subnormals normalised, infinities and NaNs kept). The decoder behind every
	/// 16 bit float pixel read on the CPU: a render target read back for a thumbnail or a
	/// viewport capture.
	public static float HalfToFloat(uint16 h)
	{
		let sign = (uint32)(h >> 15) & 1;
		let exponent = (uint32)(h >> 10) & 0x1F;
		let mantissa = (uint32)h & 0x3FF;
		uint32 bits;
		if (exponent == 0)
		{
			if (mantissa == 0)
			{
				bits = sign << 31; // signed zero
			}
			else
			{
				// A subnormal half: normalise into a float exponent.
				uint32 e = 127 - 15 + 1;
				var m = mantissa;
				while ((m & 0x400) == 0)
				{
					m <<= 1;
					e--;
				}
				bits = (sign << 31) | (e << 23) | ((m & 0x3FF) << 13);
			}
		}
		else if (exponent == 0x1F)
		{
			bits = (sign << 31) | 0x7F800000 | (mantissa << 13); // inf / nan
		}
		else
		{
			bits = (sign << 31) | ((exponent - 15 + 127) << 23) | (mantissa << 13);
		}
		return *(float*)&bits;
	}

	/// A 16 bit float channel as an 8 bit one: clamped to [0, 1] and quantised. No encoding: a
	/// display referred 16F target (a tonemapped viewport) already holds encoded values.
	public static uint8 HalfToUnorm8(uint16 h)
	{
		let value = HalfToFloat(h);
		let clamped = (value < 0.0f) ? 0.0f : ((value > 1.0f) ? 1.0f : value);
		return (uint8)(clamped * 255.0f + 0.5f);
	}
}
