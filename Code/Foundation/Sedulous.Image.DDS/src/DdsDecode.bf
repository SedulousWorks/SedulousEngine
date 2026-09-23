using System;
using Sedulous.Core;
using bcdec_Beef;

namespace Sedulous.Image.DDS;

/// Decoding one DDS level to an Image: the block formats through bcdec, the uncompressed
/// texels by swizzle.
///
/// The SIGNED block formats, BC4S and BC5S, go through bcdec's float entry points, which the
/// vendored archive carries because it is built with BCDEC_BC4BC5_PRECISE: the byte entry
/// points fold a signed block's minus one through one into nought through 255 on bcdec's own
/// terms rather than this module's, and a normal map read through the wrong one is subtly
/// wrong rather than obviously so.
static class DdsDecode
{
	private static float HalfToFloat(uint16 h)
	{
		let sign = ((uint32)h & 0x8000) << 16;
		var exponent = ((uint32)h >> 10) & 0x1F;
		var mantissa = (uint32)h & 0x3FF;
		uint32 bits;
		if (exponent == 0)
		{
			if (mantissa == 0)
			{
				bits = sign; // a signed zero
			}
			else
			{
				// Subnormal, so normalise it.
				exponent = 127 - 15 + 1;
				while ((mantissa & 0x400) == 0)
				{
					mantissa <<= 1;
					exponent--;
				}
				mantissa &= 0x3FF;
				bits = sign | (exponent << 23) | (mantissa << 13);
			}
		}
		else if (exponent == 0x1F)
		{
			bits = sign | 0x7F800000 | (mantissa << 13); // infinity or not a number
		}
		else
		{
			bits = sign | ((exponent + 127 - 15) << 23) | (mantissa << 13);
		}
		return *(float*)&bits;
	}

	private static uint8 UnitToByte(float value)
	{
		let v = Math.Clamp(value, 0.0f, 1.0f);
		return (uint8)(v * 255.0f + 0.5f);
	}

	/// Minus one through one onto nought through 255.
	private static uint8 SignedToByte(float value) => UnitToByte(value * 0.5f + 0.5f);

	/// A two channel tangent space normal's Z, so a decoded image is a WHOLE normal map.
	private static uint8 ReconstructZ(uint8 r, uint8 g)
	{
		let x = (float)r / 255.0f * 2.0f - 1.0f;
		let y = (float)g / 255.0f * 2.0f - 1.0f;
		let zz = 1.0f - x * x - y * y;
		let z = (zz > 0.0f) ? Math.Sqrt(zz) : 0.0f;
		return SignedToByte(z);
	}

	private static ImageColorSpace ColorSpaceFor(DdsImage dds)
	{
		if (DdsFormats.IsSrgb(dds.Format))
			return .Srgb;
		if (dds.ColorSpaceKnown)
			return .Linear;

		// A legacy header names no colour space: a COLOUR format is sRGB by the authoring
		// norm, and a data format linear.
		switch (dds.Format)
		{
		case .RGBA8, .BGRA8, .BC1, .BC2, .BC3, .BC7:
			return .Srgb;
		default:
			return .Linear;
		}
	}

	/// Decodes every four by four block, filling a sixteen texel RGBA tile, and copies the in
	/// bounds texels of each tile into the destination.
	private static void DecodeBlocks(uint8* source, uint32 blockBytes, uint32 width,
		uint32 height, uint8* destination, delegate void(uint8* block, uint8* tile) decodeBlock)
	{
		let blocksX = (width + 3) / 4;
		let blocksY = (height + 3) / 4;
		uint8[4 * 4 * 4] tile = .();
		for (uint32 by < blocksY)
		{
			for (uint32 bx < blocksX)
			{
				decodeBlock(source + ((int)by * (int)blocksX + (int)bx) * (int)blockBytes, &tile[0]);
				for (uint32 y < 4)
				{
					let py = by * 4 + y;
					if (py >= height)
						break;
					for (uint32 x < 4)
					{
						let px = bx * 4 + x;
						if (px >= width)
							break;
						Internal.MemCpy(destination + ((int)py * (int)width + (int)px) * 4,
							&tile[((int)y * 4 + (int)x) * 4], 4);
					}
				}
			}
		}
	}

	/// Decodes one level of one layer to an Image.
	///
	/// RGBA8 for the low dynamic range formats, with a single channel replicated to RGB and a
	/// two channel one given a reconstructed Z so it reads as a whole normal map, and RGBA32F
	/// for the float ones. The colour space follows the format.
	public static Result<void, ErrorCode> DecodeLevel(DdsImage dds, uint32 layer, uint32 level,
		Image outImage)
	{
		if ((layer >= dds.ArrayLayers) || (level >= dds.MipLevels))
			return .Err(.OutOfRange);

		let source = dds.Level(layer, level);
		let width = dds.LevelWidth(level);
		let height = dds.LevelHeight(level);
		if (source.IsEmpty)
			return .Err(.InvalidArgument);

		let texels = (int)width * (int)height;

		if (DdsFormats.IsHdr(dds.Format))
		{
			outImage.ReplaceData(width, height, .RGBA32F, .());
			let destination = (float*)outImage.PixelData.Ptr;
			switch (dds.Format)
			{
			case .RGBA32F:
				Internal.MemCpy(destination, source.Ptr, texels * 16);
			case .RGBA16F:
				let halves = (uint16*)source.Ptr;
				for (int i < texels * 4)
					destination[i] = HalfToFloat(halves[i]);
			case .BC6HUf, .BC6HSf:
				let isSigned = (dds.Format == .BC6HSf) ? (int32)1 : 0;
				let blocksX = (width + 3) / 4;
				let blocksY = (height + 3) / 4;
				float[4 * 4 * 3] tile = .();
				for (uint32 by < blocksY)
				{
					for (uint32 bx < blocksX)
					{
						bcdec_bc6h_float(source.Ptr + ((int)by * (int)blocksX + (int)bx) * 16,
							&tile[0], 4 * 3, isSigned);
						for (uint32 y < 4)
						{
							if ((by * 4 + y) >= height)
								break;
							for (uint32 x < 4)
							{
								if ((bx * 4 + x) >= width)
									break;
								let p = destination
									+ ((int)(by * 4 + y) * (int)width + (int)(bx * 4 + x)) * 4;
								p[0] = tile[((int)y * 4 + (int)x) * 3 + 0];
								p[1] = tile[((int)y * 4 + (int)x) * 3 + 1];
								p[2] = tile[((int)y * 4 + (int)x) * 3 + 2];
								p[3] = 1.0f;
							}
						}
					}
				}
			default:
				return .Err(.NotSupported);
			}
			outImage.SetColorSpace(.Linear);
			return .Ok;
		}

		outImage.ReplaceData(width, height, .RGBA8, .());
		let destination = outImage.PixelData.Ptr;
		switch (dds.Format)
		{
		case .RGBA8, .RGBA8Srgb:
			Internal.MemCpy(destination, source.Ptr, texels * 4);
		case .BGRA8, .BGRA8Srgb:
			for (int i < texels)
			{
				destination[i * 4 + 0] = source[i * 4 + 2];
				destination[i * 4 + 1] = source[i * 4 + 1];
				destination[i * 4 + 2] = source[i * 4 + 0];
				destination[i * 4 + 3] = source[i * 4 + 3];
			}
		case .R8:
			for (int i < texels)
			{
				destination[i * 4 + 0] = source[i];
				destination[i * 4 + 1] = source[i];
				destination[i * 4 + 2] = source[i];
				destination[i * 4 + 3] = 255;
			}
		case .RG8:
			for (int i < texels)
			{
				destination[i * 4 + 0] = source[i * 2 + 0];
				destination[i * 4 + 1] = source[i * 2 + 1];
				destination[i * 4 + 2] = ReconstructZ(source[i * 2 + 0], source[i * 2 + 1]);
				destination[i * 4 + 3] = 255;
			}
		case .BC1, .BC1Srgb:
			DecodeBlocks(source.Ptr, 8, width, height, destination,
				scope (block, tile) => { bcdec_bc1(block, tile, 4 * 4); });
		case .BC2, .BC2Srgb:
			DecodeBlocks(source.Ptr, 16, width, height, destination,
				scope (block, tile) => { bcdec_bc2(block, tile, 4 * 4); });
		case .BC3, .BC3Srgb:
			DecodeBlocks(source.Ptr, 16, width, height, destination,
				scope (block, tile) => { bcdec_bc3(block, tile, 4 * 4); });
		case .BC7, .BC7Srgb:
			DecodeBlocks(source.Ptr, 16, width, height, destination,
				scope (block, tile) => { bcdec_bc7(block, tile, 4 * 4); });
		case .BC4, .BC4Snorm:
			let isSigned = dds.Format == .BC4Snorm;
			DecodeBlocks(source.Ptr, 8, width, height, destination,
				scope [&] (block, tile) =>
				{
					uint8[16] values = .();
					if (isSigned)
					{
						float[16] signedValues = .();
						bcdec_bc4_float(block, &signedValues[0], 4, 1);
						for (int i < 16)
							values[i] = SignedToByte(signedValues[i]);
					}
					else
					{
						bcdec_bc4(block, &values[0], 4, 0);
					}
					for (int i < 16)
					{
						tile[i * 4 + 0] = values[i];
						tile[i * 4 + 1] = values[i];
						tile[i * 4 + 2] = values[i];
						tile[i * 4 + 3] = 255;
					}
				});
		case .BC5, .BC5Snorm:
			let isSigned = dds.Format == .BC5Snorm;
			DecodeBlocks(source.Ptr, 16, width, height, destination,
				scope [&] (block, tile) =>
				{
					uint8[32] pairs = .();
					if (isSigned)
					{
						float[32] signedPairs = .();
						bcdec_bc5_float(block, &signedPairs[0], 4 * 2, 1);
						for (int i < 32)
							pairs[i] = SignedToByte(signedPairs[i]);
					}
					else
					{
						bcdec_bc5(block, &pairs[0], 4 * 2, 0);
					}
					for (int i < 16)
					{
						tile[i * 4 + 0] = pairs[i * 2 + 0];
						tile[i * 4 + 1] = pairs[i * 2 + 1];
						tile[i * 4 + 2] = ReconstructZ(pairs[i * 2 + 0], pairs[i * 2 + 1]);
						tile[i * 4 + 3] = 255;
					}
				});
		default:
			return .Err(.NotSupported);
		}

		outImage.SetColorSpace(ColorSpaceFor(dds));
		return .Ok;
	}
}
