using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.Texture.Compression.Tests;

/// The low dynamic range encoders end to end: out through the module and back through an
/// independent decoder, measured as peak signal to noise ratio.
class CompressionEncodeTests
{
	[Test]
	public static void Bc1RoundTripsAtTheExactSize()
	{
		const uint32 cWidth = 128;
		const uint32 cHeight = 128;
		let image = CompressionFixtures.MakeImage(cWidth, cHeight, false);
		defer delete image;

		let encoded = scope List<uint8>();
		TextureCompression.EncodeBlockCompressed(&image[0], cWidth, cHeight, .BC1RGBAUnorm, 200,
			encoded);
		Test.Assert((uint64)encoded.Count
			== TextureCompression.BlockCompressedSize(.BC1RGBAUnorm, cWidth, cHeight));

		let decoded = CompressionFixtures.DecodeBc(encoded, cWidth, cHeight, .BC1RGBAUnorm);
		defer delete decoded;
		let psnr = CompressionFixtures.Psnr(image, decoded, (int)cWidth * (int)cHeight, 3);
		// BC1 on a smooth ramp reconstructs well above this floor, and a broken encoder scores
		// far below it.
		Test.Assert(psnr > 30.0, "BC1 did not reconstruct the ramp");
	}

	[Test]
	public static void Bc7RoundTripsAcrossAllFourChannels()
	{
		const uint32 cWidth = 128;
		const uint32 cHeight = 128;
		let image = CompressionFixtures.MakeImage(cWidth, cHeight, true);
		defer delete image;

		let encoded = scope List<uint8>();
		TextureCompression.EncodeBlockCompressed(&image[0], cWidth, cHeight, .BC7RGBAUnorm, 255,
			encoded);
		Test.Assert((uint64)encoded.Count
			== TextureCompression.BlockCompressedSize(.BC7RGBAUnorm, cWidth, cHeight));

		let decoded = CompressionFixtures.DecodeBc(encoded, cWidth, cHeight, .BC7RGBAUnorm);
		defer delete decoded;
		let psnr = CompressionFixtures.Psnr(image, decoded, (int)cWidth * (int)cHeight, 4);
		// BC7 is near lossless on a smooth gradient, and the high floor is what guards the full
		// four channel path rather than just the colour one.
		Test.Assert(psnr > 40.0, "BC7 did not reconstruct the gradient");
	}

	[Test]
	public static void Astc4x4RoundTripsAtEightBitsPerTexel()
	{
		const uint32 cWidth = 128;
		const uint32 cHeight = 128;
		let image = CompressionFixtures.MakeImage(cWidth, cHeight, true);
		defer delete image;

		let encoded = scope List<uint8>();
		TextureCompression.EncodeBlockCompressed(&image[0], cWidth, cHeight, .ASTC4x4Unorm, 200,
			encoded);
		Test.Assert((uint64)encoded.Count
			== TextureCompression.BlockCompressedSize(.ASTC4x4Unorm, cWidth, cHeight));
		// Sixteen bytes a 4x4 block is eight bits a texel, the same footprint as BC7.
		Test.Assert(encoded.Count == (int)(cWidth / 4) * (int)(cHeight / 4) * 16);

		let decoded = CompressionFixtures.DecodeAstc(encoded, cWidth, cHeight, false);
		defer delete decoded;
		Test.Assert(decoded.Count == (int)cWidth * (int)cHeight * 4);
		let psnr = CompressionFixtures.Psnr(image, decoded, (int)cWidth * (int)cHeight, 4);
		Test.Assert(psnr > 40.0, "ASTC did not reconstruct the gradient");
	}

	[Test]
	public static void AnUnsupportedFormatOrNoInputEncodesNothing()
	{
		const uint32 cWidth = 8;
		const uint32 cHeight = 8;
		let image = CompressionFixtures.MakeImage(cWidth, cHeight, false);
		defer delete image;

		let encoded = scope List<uint8>();
		TextureCompression.EncodeBlockCompressed(&image[0], cWidth, cHeight, .RGBA8Unorm, 128,
			encoded);
		Test.Assert(encoded.IsEmpty, "an uncompressed format is not this path's job");

		TextureCompression.EncodeBlockCompressed(null, cWidth, cHeight, .BC1RGBAUnorm, 128,
			encoded);
		Test.Assert(encoded.IsEmpty, "no input is an empty result rather than a crash");

		// BC6H does not go through the block dispatch: it has its own entry point, and asking
		// for it here appends nothing rather than writing sixteen bytes of rubbish.
		TextureCompression.EncodeBlockCompressed(&image[0], cWidth, cHeight, .BC6HRGBUfloat, 128,
			encoded);
		Test.Assert(encoded.IsEmpty);
	}
}
