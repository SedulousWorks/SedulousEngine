using System;
using System.Collections;
using Sedulous.RHI;

namespace Sedulous.Texture.Compression.Tests;

/// The engine's own BC6H encoder, measured against the vendored reference decoder.
///
/// The decoder is independent bit packing code, so a mistake in the mode 11 layout shows here
/// rather than cancelling itself out against a decoder written alongside the encoder.
class Bc6hEncoderTests
{
	[Test]
	public static void AFlatBlockRoundTripsWithinHalfPrecision()
	{
		// Sky like: one radiance across the whole block, well above one. The straddle path is
		// what lets the 4 bit weights recover the precision 10 bit endpoints drop, which is why
		// this lands near half precision rather than near a quantisation step.
		const uint32 cWidth = 4;
		const uint32 cHeight = 4;
		let source = scope List<float>();
		source.Count = (int)cWidth * (int)cHeight * 4;
		for (int i < (int)cWidth * (int)cHeight)
		{
			source[i * 4 + 0] = 0.37f;
			source[i * 4 + 1] = 2.5f;
			source[i * 4 + 2] = 11.0f;
			source[i * 4 + 3] = 1.0f;
		}

		let encoded = scope List<uint8>();
		TextureCompression.EncodeBlockCompressedHdr(&source[0], cWidth, cHeight, 255, encoded);
		Test.Assert(encoded.Count == 16);
		Test.Assert(TextureCompression.BlockCompressedSize(.BC6HRGBUfloat, cWidth, cHeight) == 16);

		let decoded = CompressionFixtures.DecodeBc6h(encoded, cWidth, cHeight);
		defer delete decoded;
		let relative = CompressionFixtures.MaxRelativeError(source, decoded, cWidth, cHeight);
		Test.Assert(relative < 0.002f, "a flat block should land within half precision");
	}

	[Test]
	public static void AGradientReconstructsCloselyAndEdgeBlocksClamp()
	{
		// Thirteen by nine: not a multiple of four, so the right and bottom blocks replicate
		// their edge texels. A smooth radiance ramp across a wide range, offset per channel so
		// the segment through colour space is not axis aligned.
		const uint32 cWidth = 13;
		const uint32 cHeight = 9;
		let source = scope List<float>();
		source.Count = (int)cWidth * (int)cHeight * 4;
		for (uint32 y < cHeight)
		{
			for (uint32 x < cWidth)
			{
				let t = (float)(x + y) / (float)(cWidth + cHeight - 2);
				let p = &source[((int)y * (int)cWidth + (int)x) * 4];
				// A realistic sky: no more than about a fifth of a change across any one block.
				p[0] = 0.8f + 1.2f * t;
				p[1] = 1.5f + 1.0f * t * t;
				p[2] = 4.0f - 1.5f * t;
				p[3] = 1.0f;
			}
		}

		let encoded = scope List<uint8>();
		TextureCompression.EncodeBlockCompressedHdr(&source[0], cWidth, cHeight, 255, encoded);
		Test.Assert((uint64)encoded.Count
			== TextureCompression.BlockCompressedSize(.BC6HRGBUfloat, cWidth, cHeight));
		Test.Assert(encoded.Count == 4 * 3 * 16);

		let decoded = CompressionFixtures.DecodeBc6h(encoded, cWidth, cHeight);
		defer delete decoded;
		let relative = CompressionFixtures.MaxRelativeError(source, decoded, cWidth, cHeight);
		Test.Assert(relative < 0.03f, "one region across a 4x4 ramp");

		// And more effort never makes it worse.
		let fast = scope List<uint8>();
		TextureCompression.EncodeBlockCompressedHdr(&source[0], cWidth, cHeight, 0, fast);
		let fastDecoded = CompressionFixtures.DecodeBc6h(fast, cWidth, cHeight);
		defer delete fastDecoded;
		let fastRelative = CompressionFixtures.MaxRelativeError(source, fastDecoded, cWidth,
			cHeight);
		Test.Assert(relative <= fastRelative + 1.0e-6f);
	}

	[Test]
	public static void TheUnsignedFormatClampsNegativesNaNAndBeyondHalfValues()
	{
		const uint32 cWidth = 4;
		const uint32 cHeight = 4;
		let source = scope List<float>();
		source.Count = (int)cWidth * (int)cHeight * 4;
		for (int i < source.Count)
			source[i] = 1.0f;
		source[0] = -5.0f;      // a negative becomes nought
		source[4] = float.NaN;  // a NaN becomes nought, and never poisons the block
		source[8] = 1.0e9f;     // past the largest finite half becomes that half

		let encoded = scope List<uint8>();
		TextureCompression.EncodeBlockCompressedHdr(&source[0], cWidth, cHeight, 128, encoded);
		let decoded = CompressionFixtures.DecodeBc6h(encoded, cWidth, cHeight);
		defer delete decoded;

		Test.Assert(decoded[0] >= 0.0f);
		Test.Assert(decoded[3] >= 0.0f);
		Test.Assert(decoded[3] == decoded[3], "the NaN did not spread");
		Test.Assert(decoded[6] > 60000.0f);
		Test.Assert(decoded[6] <= 65504.0f);

		// And no input, or an empty level, is an empty result rather than a crash.
		let empty = scope List<uint8>();
		TextureCompression.EncodeBlockCompressedHdr(null, 4, 4, 128, empty);
		Test.Assert(empty.IsEmpty);
		TextureCompression.EncodeBlockCompressedHdr(&source[0], 0, 4, 128, empty);
		Test.Assert(empty.IsEmpty);
	}
}
