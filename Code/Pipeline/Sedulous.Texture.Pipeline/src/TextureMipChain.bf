using System;
using System.Collections;

namespace Sedulous.Texture.Pipeline;

/// Building a mip chain at cook time.
///
/// The averaging happens in LINEAR space for an sRGB image's colour channels, and it has to: a
/// half black, half white checker averages to linear one half, which is about 188 in sRGB and
/// not 128. Averaging the stored bytes directly darkens every level.
static class TextureMipChain
{
	private static float SrgbToLinear(uint8 value)
	{
		let c = (float)value / 255.0f;
		return (c <= 0.04045f) ? (c / 12.92f) : Math.Pow((c + 0.055f) / 1.055f, 2.4f);
	}

	private static uint8 LinearToSrgb(float value)
	{
		let c = Math.Clamp(value, 0.0f, 1.0f);
		let encoded = (c <= 0.0031308f) ? (c * 12.92f)
			: (1.055f * Math.Pow(c, 1.0f / 2.4f) - 0.055f);
		return (uint8)(encoded * 255.0f + 0.5f);
	}

	/// Appends every level below the first to `pixels`, which already holds level nought as
	/// tightly packed RGBA8, by a two by two box clamped at an odd edge. Alpha, and everything
	/// in a linear image, averages directly.
	///
	/// Returns the TOTAL level count, the first one included.
	public static uint32 Append(List<uint8> pixels, uint32 width, uint32 height, bool srgb)
	{
		uint32 levels = 1;
		var sourceOffset = 0;
		var sourceWidth = width;
		var sourceHeight = height;

		while ((sourceWidth > 1) || (sourceHeight > 1))
		{
			let destinationWidth = (sourceWidth > 1) ? sourceWidth / 2 : 1;
			let destinationHeight = (sourceHeight > 1) ? sourceHeight / 2 : 1;
			let destinationOffset = pixels.Count;
			pixels.Count = destinationOffset + (int)destinationWidth * (int)destinationHeight * 4;

			let source = pixels.Ptr + sourceOffset;
			let destination = pixels.Ptr + destinationOffset;

			for (uint32 y < destinationHeight)
			{
				let y0 = y * 2;
				let y1 = ((y0 + 1) < sourceHeight) ? (y0 + 1) : y0; // clamped at an odd edge
				for (uint32 x < destinationWidth)
				{
					let x0 = x * 2;
					let x1 = ((x0 + 1) < sourceWidth) ? (x0 + 1) : x0;

					let p00 = source + ((int)y0 * (int)sourceWidth + (int)x0) * 4;
					let p01 = source + ((int)y0 * (int)sourceWidth + (int)x1) * 4;
					let p10 = source + ((int)y1 * (int)sourceWidth + (int)x0) * 4;
					let p11 = source + ((int)y1 * (int)sourceWidth + (int)x1) * 4;
					let outTexel = destination + ((int)y * (int)destinationWidth + (int)x) * 4;

					for (int c < 4)
					{
						if (srgb && (c < 3))
						{
							let average = (SrgbToLinear(p00[c]) + SrgbToLinear(p01[c])
								+ SrgbToLinear(p10[c]) + SrgbToLinear(p11[c])) * 0.25f;
							outTexel[c] = LinearToSrgb(average);
						}
						else
						{
							outTexel[c] = (uint8)(((uint32)p00[c] + p01[c] + p10[c] + p11[c] + 2) / 4);
						}
					}
				}
			}

			sourceOffset = destinationOffset;
			sourceWidth = destinationWidth;
			sourceHeight = destinationHeight;
			levels++;
		}
		return levels;
	}
}
