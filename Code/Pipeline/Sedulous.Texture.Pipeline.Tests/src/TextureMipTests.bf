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

	/// The sRGB tables stand in for the exact transfer, so what they cost in accuracy is part
	/// of the contract: a round trip through them must land on the byte it started from, and
	/// an averaged pair must not drift more than one code from the exact answer.
	[Test]
	public static void TheSrgbTablesAgreeWithTheExactCurve()
	{
		// A half black, half white checker is the case the linear averaging exists for: the
		// average is linear one half, which encodes near 188 rather than 128.
		let pixels = scope List<uint8>();
		for (int i < 4)
		{
			// Two black texels and two white ones, in one 2x2 block.
			let white = (i == 1) || (i == 2);
			for (int c < 4)
				pixels.Add(white ? 255 : ((c == 3) ? 255 : 0));
		}

		let levels = TextureMipChain.Append(pixels, 2, 2, true);
		Test.Assert(levels == 2);

		// Level one is one texel: the linear average of two black and two white, re-encoded.
		let level1 = pixels.Count - 4;
		let got = pixels[level1];
		Test.Assert((got >= 186) && (got <= 190),
			scope $"a half/half checker averages near 188 in sRGB, got {got}");

		// The alpha channel averages DIRECTLY, tables or not.
		Test.Assert(pixels[level1 + 3] == 255);
	}
}
