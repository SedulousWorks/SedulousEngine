using System;
using System.Collections;
using Sedulous.Image;
using Sedulous.Texture.Pipeline;
using Sedulous.Texture.Resource;

namespace Sedulous.Texture.Pipeline.Tests;

/// The mip chain the cook builds.
///
/// The gap this pins was the missing middle of the plumbing: the flag, the record field and the
/// per level upload all existed, and nothing ever BUILT a chain, so every texture rendered at
/// its finest level and shimmered.
class TextureMipTests
{
	/// Cooks one embedded image through the fixture and hands back the level count and payload.
	private static void CookChain(TexturePipelineFixture fixture, uint32 width, uint32 height,
		ImageColorSpace colorSpace, delegate uint8(uint32 x, uint32 y, int c) pixelAt,
		out uint32 outMipLevels, List<uint8> outPayload)
	{
		let pixels = scope List<uint8>();
		pixels.Count = (int)width * (int)height * 4;
		for (uint32 y < height)
		{
			for (uint32 x < width)
			{
				for (int c < 4)
					pixels[((int)y * (int)width + (int)x) * 4 + c] = pixelAt(x, y, c);
			}
		}

		let asset = scope TextureAsset();
		asset.EmbeddedWidth = width;
		asset.EmbeddedHeight = height;
		asset.ColorSpace = colorSpace;
		asset.GenerateMipmaps = true;

		let output = fixture.CreateOutput("out");
		Test.Assert(fixture.CookEmbedded(asset, pixels, output) case .Ok);

		let record = scope TextureResource();
		Test.Assert(fixture.ReadCooked(output, record, outPayload) case .Ok);
		outMipLevels = record.MipLevels;
	}

	[Test]
	public static void AnSrgbChainAveragesInLinearSpace()
	{
		let fixture = scope TexturePipelineFixture("mips_srgb");

		// A four by four checker, black and white alternating.
		let payload = scope List<uint8>();
		CookChain(fixture, 4, 4, .Srgb, scope (x, y, c) =>
			(c == 3) ? (uint8)255 : ((((x + y) & 1) != 0) ? (uint8)255 : (uint8)0),
			let mipLevels, payload);

		Test.Assert(mipLevels == 3);
		Test.Assert(payload.Count == (16 + 4 + 1) * 4);

		// The first level's first texel: a two by two checker averages to linear one half,
		// which is about 188 in sRGB. The naive byte average would be 127, and that is what
		// makes every mip of every texture too dark.
		let mip1 = payload[16 * 4];
		Test.Assert((mip1 >= 186) && (mip1 <= 190), "the colour channels filtered in linear space");
		Test.Assert(payload[16 * 4 + 3] == 255, "alpha averages directly");
	}

	[Test]
	public static void ALinearChainAveragesTheBytesDirectly()
	{
		let fixture = scope TexturePipelineFixture("mips_linear");

		// The SAME checker as a linear data map: nothing about it is perceptual, so the
		// straight byte average is the right answer.
		let payload = scope List<uint8>();
		CookChain(fixture, 4, 4, .Linear, scope (x, y, c) =>
			(c == 3) ? (uint8)255 : ((((x + y) & 1) != 0) ? (uint8)255 : (uint8)0),
			let mipLevels, payload);

		Test.Assert(mipLevels == 3);
		let mip1 = payload[16 * 4];
		Test.Assert((mip1 >= 127) && (mip1 <= 128));
	}

	[Test]
	public static void OddDimensionsClampDownTheChain()
	{
		let fixture = scope TexturePipelineFixture("mips_npot");

		// Five by three goes to two by one, then one by one.
		let payload = scope List<uint8>();
		CookChain(fixture, 5, 3, .Linear, scope (x, y, c) => (uint8)200,
			let mipLevels, payload);

		Test.Assert(mipLevels == 3);
		Test.Assert(payload.Count == (15 + 2 + 1) * 4);
	}
}
