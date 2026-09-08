using System;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.Texture;

namespace Sedulous.Texture.Tests;

/// Choosing the GPU format that reads an image's bytes correctly.
class TextureFormatUtilsTests
{
	/// Colour imagery takes the sRGB format, so the hardware decodes to linear on sample
	/// rather than leaving every shader to do it.
	[Test]
	public static void SrgbColourImageryTakesTheSrgbFormat()
	{
		Test.Assert(TextureFormatUtils.Convert(.RGBA8, .Srgb) == .RGBA8UnormSrgb);
		Test.Assert(TextureFormatUtils.Convert(.RGB8, .Srgb) == .RGBA8UnormSrgb);
		Test.Assert(TextureFormatUtils.Convert(.BGRA8, .Srgb) == .BGRA8UnormSrgb);
		Test.Assert(TextureFormatUtils.Convert(.BGR8, .Srgb) == .BGRA8UnormSrgb);
	}

	/// The same bytes read as data stay linear. This is the case that matters: a normal
	/// map decoded as sRGB has its vectors bent, not merely its look shifted.
	[Test]
	public static void LinearDataStaysUnorm()
	{
		Test.Assert(TextureFormatUtils.Convert(.RGBA8, .Linear) == .RGBA8Unorm);
		Test.Assert(TextureFormatUtils.Convert(.BGRA8, .Linear) == .BGRA8Unorm);
		Test.Assert(TextureFormatUtils.Convert(.R8, .Linear) == .R8Unorm);
		Test.Assert(TextureFormatUtils.Convert(.RG8, .Linear) == .RG8Unorm);
	}

	/// No GPU stores three channels, so they widen to four.
	[Test]
	public static void ThreeChannelsWidenToFour()
	{
		Test.Assert(TextureFormatUtils.Convert(.RGB8, .Linear) == .RGBA8Unorm);
		Test.Assert(TextureFormatUtils.Convert(.RGB16F, .Linear) == .RGBA16Float);
		Test.Assert(TextureFormatUtils.Convert(.RGB32F, .Linear) == .RGBA32Float);
	}

	/// Only the eight bit colour formats have an sRGB variant, so asking for sRGB on
	/// anything else is ignored rather than approximated.
	[Test]
	public static void AFloatFormatHasNoSrgbVariantToTake()
	{
		Test.Assert(TextureFormatUtils.Convert(.RGB16F, .Srgb) == .RGBA16Float);
		Test.Assert(TextureFormatUtils.Convert(.RGBA32F, .Srgb) == .RGBA32Float);
		Test.Assert(TextureFormatUtils.Convert(.R8, .Srgb) == .R8Unorm,
			"single channel has no sRGB form either");
	}

	[Test]
	public static void TheFloatFormatsPassThrough()
	{
		Test.Assert(TextureFormatUtils.Convert(.R16F, .Linear) == .R16Float);
		Test.Assert(TextureFormatUtils.Convert(.RG16F, .Linear) == .RG16Float);
		Test.Assert(TextureFormatUtils.Convert(.RGBA16F, .Linear) == .RGBA16Float);
		Test.Assert(TextureFormatUtils.Convert(.R32F, .Linear) == .R32Float);
		Test.Assert(TextureFormatUtils.Convert(.RG32F, .Linear) == .RG32Float);
		Test.Assert(TextureFormatUtils.Convert(.RGBA32F, .Linear) == .RGBA32Float);
	}

	/// R16 is the heightmap format and this RHI has no single channel sixteen bit unorm to
	/// carry it, so it falls to the default. Pinned because that mapping is WRONG for the
	/// bytes: it is only harmless while heightmaps stay CPU side, and this is the test that
	/// fails when somebody tries to upload one.
	[Test]
	public static void R16HasNoGpuFormatAndTakesTheDefault()
	{
		Test.Assert(TextureFormatUtils.Convert(.R16, .Linear) == .RGBA8Unorm);
		Test.Assert(TextureFormatUtils.Convert(.R16, .Srgb) == .RGBA8Unorm);
	}
}
