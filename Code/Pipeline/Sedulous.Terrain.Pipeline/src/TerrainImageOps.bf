using System;

namespace Sedulous.Terrain.Pipeline;

/// The pixel work the palette cook needs: a resize onto the common slice size, and the halving
/// that builds each slice's mip chain.
static class TerrainImageOps
{
	/// Bilinearly resizes an RGBA8 image onto the destination extent.
	public static void ResizeRgba8Bilinear(Span<uint8> source, uint32 sourceWidth,
		uint32 sourceHeight, Span<uint8> destination, uint32 destinationWidth,
		uint32 destinationHeight)
	{
		if (source.IsEmpty || (sourceWidth == 0) || (sourceHeight == 0)
			|| (destinationWidth == 0) || (destinationHeight == 0))
		{
			return;
		}

		for (uint32 y < destinationHeight)
		{
			let v = (destinationHeight > 1)
				? (float)y / (float)(destinationHeight - 1) * (float)(sourceHeight - 1) : 0.0f;
			let y0 = (uint32)v;
			let y1 = Math.Min(y0 + 1, sourceHeight - 1);
			let fy = v - (float)y0;

			for (uint32 x < destinationWidth)
			{
				let u = (destinationWidth > 1)
					? (float)x / (float)(destinationWidth - 1) * (float)(sourceWidth - 1) : 0.0f;
				let x0 = (uint32)u;
				let x1 = Math.Min(x0 + 1, sourceWidth - 1);
				let fx = u - (float)x0;

				for (int c < 4)
				{
					let p00 = (float)source[((int)y0 * (int)sourceWidth + (int)x0) * 4 + c];
					let p01 = (float)source[((int)y0 * (int)sourceWidth + (int)x1) * 4 + c];
					let p10 = (float)source[((int)y1 * (int)sourceWidth + (int)x0) * 4 + c];
					let p11 = (float)source[((int)y1 * (int)sourceWidth + (int)x1) * 4 + c];
					let top = p00 + (p01 - p00) * fx;
					let bottom = p10 + (p11 - p10) * fx;
					destination[((int)y * (int)destinationWidth + (int)x) * 4 + c]
						= (uint8)(top + (bottom - top) * fy + 0.5f);
				}
			}
		}
	}

	/// Halves a LINEAR level by a plain box filter, which is what a normal map, an occlusion
	/// and roughness map, a height map and a coverage mask all want.
	public static uint32 BoxHalveRgba8(Span<uint8> source, uint32 dimension, Span<uint8> destination)
	{
		let half = (dimension > 1) ? dimension / 2 : 1;
		for (uint32 y < half)
		{
			let sy0 = Math.Min(y * 2, dimension - 1);
			let sy1 = Math.Min(y * 2 + 1, dimension - 1);
			for (uint32 x < half)
			{
				let sx0 = Math.Min(x * 2, dimension - 1);
				let sx1 = Math.Min(x * 2 + 1, dimension - 1);
				for (int c < 4)
				{
					let sum = (uint32)source[((int)sy0 * (int)dimension + (int)sx0) * 4 + c]
						+ source[((int)sy0 * (int)dimension + (int)sx1) * 4 + c]
						+ source[((int)sy1 * (int)dimension + (int)sx0) * 4 + c]
						+ source[((int)sy1 * (int)dimension + (int)sx1) * 4 + c];
					destination[((int)y * (int)half + (int)x) * 4 + c] = (uint8)((sum + 2) / 4);
				}
			}
		}
		return half;
	}

	/// Halves an sRGB ENCODED level, averaging the colour channels in LINEAR space.
	///
	/// Averaging the stored bytes directly darkens every level: a half black, half white
	/// checker has to average to about 188, not 128. Alpha is linear already and averages as
	/// it stands. Only the albedo array needs this; the rest are linear data.
	public static uint32 BoxHalveRgba8SrgbAware(Span<uint8> source, uint32 dimension,
		Span<uint8> destination)
	{
		let half = (dimension > 1) ? dimension / 2 : 1;
		for (uint32 y < half)
		{
			let sy0 = Math.Min(y * 2, dimension - 1);
			let sy1 = Math.Min(y * 2 + 1, dimension - 1);
			for (uint32 x < half)
			{
				let sx0 = Math.Min(x * 2, dimension - 1);
				let sx1 = Math.Min(x * 2 + 1, dimension - 1);
				let at = uint32[4](
					((uint32)sy0 * dimension + sx0) * 4,
					((uint32)sy0 * dimension + sx1) * 4,
					((uint32)sy1 * dimension + sx0) * 4,
					((uint32)sy1 * dimension + sx1) * 4);

				for (int c < 3)
				{
					let average = (SrgbToLinear(source[(int)at[0] + c])
						+ SrgbToLinear(source[(int)at[1] + c])
						+ SrgbToLinear(source[(int)at[2] + c])
						+ SrgbToLinear(source[(int)at[3] + c])) * 0.25f;
					destination[((int)y * (int)half + (int)x) * 4 + c] = LinearToSrgb(average);
				}

				let alpha = (uint32)source[(int)at[0] + 3] + source[(int)at[1] + 3] + source[(int)at[2] + 3]
					+ source[(int)at[3] + 3];
				destination[((int)y * (int)half + (int)x) * 4 + 3] = (uint8)((alpha + 2) / 4);
			}
		}
		return half;
	}

	private static float SrgbToLinear(uint8 value)
	{
		let c = (float)value / 255.0f;
		return (c <= 0.04045f) ? (c / 12.92f) : Math.Pow((c + 0.055f) / 1.055f, 2.4f);
	}

	private static uint8 LinearToSrgb(float value)
	{
		let encoded = (value <= 0.0031308f) ? (value * 12.92f)
			: (1.055f * Math.Pow(value, 1.0f / 2.4f) - 0.055f);
		return (uint8)Math.Clamp(encoded * 255.0f + 0.5f, 0.0f, 255.0f);
	}
}
