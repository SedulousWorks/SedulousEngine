using System;
using System.Collections;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.Texture.Compression;
using Sedulous.Texture.Pipeline;
using Sedulous.Texture.Resource;
using static Sedulous.RHI.TextureFormats;

namespace Sedulous.Texture.Pipeline.Tests;

/// The cook's block compression: which format the policy picks, and that the payload is EXACTLY
/// the block bytes for it.
///
/// 128 by 128 throughout, which clears the small texture escape hatch.
class TextureCompressionCookTests
{
	private const uint32 cSize = 128;

	private static void Cook(TexturePipelineFixture fixture, SourceUsage usage,
		CompressionChoice choice, ImageColorSpace colorSpace, bool alpha, bool gray,
		out TextureFormat outFormat, out uint32 outMipLevels, out int outPayloadBytes)
	{
		let pixels = scope List<uint8>();
		TexturePipelineFixture.FillRamp(pixels, cSize, cSize, alpha, gray);

		let asset = scope TextureAsset();
		asset.EmbeddedWidth = cSize;
		asset.EmbeddedHeight = cSize;
		asset.ColorSpace = colorSpace;
		asset.GenerateMipmaps = true;
		asset.Usage = usage;
		asset.Compression = choice;

		let output = fixture.CreateOutput(scope $"out_{fixture.Database.RootGroup.Instances.Count}");
		Test.Assert(fixture.CookEmbedded(asset, pixels, output) case .Ok);

		let record = scope TextureResource();
		let payload = scope List<uint8>();
		Test.Assert(fixture.ReadCooked(output, record, payload) case .Ok);
		outFormat = record.Format;
		outMipLevels = record.MipLevels;
		outPayloadBytes = payload.Count;
	}

	/// The sum of per level block bytes for a full chain, which is the exact cooked size.
	private static int ExpectedCompressed(TextureFormat format, uint32 levels)
	{
		uint64 total = 0;
		var width = cSize;
		var height = cSize;
		for (uint32 i < levels)
		{
			total += CompressedLevelBytes(format, width, height);
			width = (width > 1) ? width / 2 : 1;
			height = (height > 1) ? height / 2 : 1;
		}
		return (int)total;
	}

	[Test]
	public static void ColourPicksTheSmallFormatWhenOpaqueAndTheLargeOneWhenNot()
	{
		let fixture = scope TexturePipelineFixture("bc_colour");

		Cook(fixture, .Color, .Default, .Srgb, false, false, let opaqueFormat, let opaqueMips,
			let opaqueBytes);
		Test.Assert(opaqueFormat == .BC1RGBAUnormSrgb);
		Test.Assert(opaqueBytes == ExpectedCompressed(.BC1RGBAUnormSrgb, opaqueMips));

		// The uncompressed chain, for the size comparison.
		Cook(fixture, .Color, .None, .Srgb, false, false, let rawFormat, let rawMips,
			let rawBytes);
		Test.Assert(rawFormat == .RGBA8UnormSrgb);
		// Four bits a texel against thirty two: about eight times smaller. The check guards a
		// real, large drop rather than the exact ratio.
		Test.Assert(opaqueBytes * 6 < rawBytes);

		// Alpha forces the large format, and so does an authored Quality on an opaque image.
		Cook(fixture, .Color, .Default, .Srgb, true, false, let alphaFormat, let alphaMips,
			let alphaBytes);
		Test.Assert(alphaFormat == .BC7RGBAUnormSrgb);
		Test.Assert(alphaBytes == ExpectedCompressed(.BC7RGBAUnormSrgb, alphaMips));

		Cook(fixture, .Color, .Quality, .Linear, false, false, let qualityFormat, ?, ?);
		Test.Assert(qualityFormat == .BC7RGBAUnorm);
	}

	[Test]
	public static void ANormalMapNeverGoesToTheTwoChannelFormat()
	{
		let fixture = scope TexturePipelineFixture("bc_normal");

		// BC7 linear rather than BC5: the shaders decode rgb times two minus one, and BC5 has
		// no blue, so the tangent's z decodes to minus one and the surface shades white.
		Cook(fixture, .Normal, .Default, .Linear, false, false, let format, let mips, let bytes);
		Test.Assert(format == .BC7RGBAUnorm);
		Test.Assert(bytes == ExpectedCompressed(.BC7RGBAUnorm, mips));
	}

	[Test]
	public static void TheMaskGuardSplitsPackedFromSingleChannel()
	{
		let fixture = scope TexturePipelineFixture("bc_mask");

		// This fixture's gradient has DISTINCT channels, which is the shape of a packed mask:
		// the sniff routes it to the four channel format, since the single channel one would
		// silently drop everything but red.
		Cook(fixture, .Mask, .Default, .Linear, false, false, let packedFormat, ?, ?);
		Test.Assert(packedFormat == .BC7RGBAUnorm);

		// A TRUE single channel mask, grey throughout, keeps the small one.
		Cook(fixture, .Mask, .Default, .Linear, false, true, let grayFormat, let grayMips,
			let grayBytes);
		Test.Assert(grayFormat == .BC4RUnorm);
		Test.Assert(grayBytes == ExpectedCompressed(.BC4RUnorm, grayMips));
	}
}
