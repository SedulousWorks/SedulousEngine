using System;
using Sedulous.RHI;

namespace Sedulous.RHI.Tests;

/// The format tables. Pure data, but the depth and compressed predicates are RANGE CHECKS
/// over the enum's declaration order, so these also pin that order.
class TextureFormatTests
{
	[Test]
	public static void DepthPredicatesBracketTheDepthRun()
	{
		for (let f in TextureFormat[](.Depth16Unorm, .Depth24Plus, .Depth24PlusStencil8,
			.Depth32Float, .Depth32FloatStencil8))
		{
			Test.Assert(TextureFormats.IsDepthFormat(f), scope $"{f} is a depth format");
			Test.Assert(TextureFormats.IsDepthStencil(f));
			Test.Assert(TextureFormats.HasDepth(f));
		}

		// Stencil8 is depth STENCIL but carries no depth, which is exactly why the two
		// predicates have different upper bounds.
		Test.Assert(!TextureFormats.IsDepthFormat(.Stencil8));
		Test.Assert(TextureFormats.IsDepthStencil(.Stencil8));
		Test.Assert(!TextureFormats.HasDepth(.Stencil8));
		Test.Assert(TextureFormats.HasStencil(.Stencil8));

		// A colour format is neither, and neither is a compressed one: the ranges must not
		// have drifted into their neighbours.
		for (let f in TextureFormat[](.RGBA8Unorm, .R32Float, .BC1RGBAUnorm, .ASTC8x8UnormSrgb,
			.Undefined))
		{
			Test.Assert(!TextureFormats.IsDepthStencil(f), scope $"{f} is not depth stencil");
			Test.Assert(!TextureFormats.HasDepth(f));
			Test.Assert(!TextureFormats.HasStencil(f));
		}
	}

	[Test]
	public static void OnlyTheStencilCarryingFormatsHaveStencil()
	{
		Test.Assert(TextureFormats.HasStencil(.Depth24PlusStencil8));
		Test.Assert(TextureFormats.HasStencil(.Depth32FloatStencil8));
		Test.Assert(!TextureFormats.HasStencil(.Depth16Unorm));
		Test.Assert(!TextureFormats.HasStencil(.Depth32Float));
	}

	[Test]
	public static void CompressionBracketsTheBlockFormats()
	{
		Test.Assert(TextureFormats.IsCompressed(.BC1RGBAUnorm), "the first compressed member");
		Test.Assert(TextureFormats.IsCompressed(.ASTC8x8UnormSrgb), "and the last");
		Test.Assert(TextureFormats.IsCompressed(.BC7RGBAUnormSrgb));

		// The members either side of the run.
		Test.Assert(!TextureFormats.IsCompressed(.Stencil8), "just before the run");
		Test.Assert(!TextureFormats.IsCompressed(.RGBA32Float));
		Test.Assert(!TextureFormats.IsCompressed(.Undefined));
	}

	[Test]
	public static void SrgbIsOnlyTheSrgbVariants()
	{
		Test.Assert(TextureFormats.IsSrgb(.RGBA8UnormSrgb));
		Test.Assert(TextureFormats.IsSrgb(.BGRA8UnormSrgb));
		Test.Assert(TextureFormats.IsSrgb(.BC7RGBAUnormSrgb));
		Test.Assert(TextureFormats.IsSrgb(.ASTC4x4UnormSrgb));

		Test.Assert(!TextureFormats.IsSrgb(.RGBA8Unorm), "the linear twin is not sRGB");
		Test.Assert(!TextureFormats.IsSrgb(.BGRA8Unorm));
		Test.Assert(!TextureFormats.IsSrgb(.BC7RGBAUnorm));
		Test.Assert(!TextureFormats.IsSrgb(.RGBA16Float));
	}

	[Test]
	public static void BytesPerPixelCoversTheListedFormats()
	{
		Test.Assert(TextureFormats.BytesPerPixel(.R8Unorm) == 1);
		Test.Assert(TextureFormats.BytesPerPixel(.Stencil8) == 1);
		Test.Assert(TextureFormats.BytesPerPixel(.R16Float) == 2);
		Test.Assert(TextureFormats.BytesPerPixel(.Depth16Unorm) == 2);
		Test.Assert(TextureFormats.BytesPerPixel(.RGBA8Unorm) == 4);
		Test.Assert(TextureFormats.BytesPerPixel(.BGRA8UnormSrgb) == 4);
		Test.Assert(TextureFormats.BytesPerPixel(.Depth32Float) == 4);
		Test.Assert(TextureFormats.BytesPerPixel(.Depth32FloatStencil8) == 8);
		Test.Assert(TextureFormats.BytesPerPixel(.RGBA16Float) == 8);
		Test.Assert(TextureFormats.BytesPerPixel(.RGBA32Float) == 16);

		// Compressed formats have no per pixel size: BlockBytes is the question to ask.
		Test.Assert(TextureFormats.BytesPerPixel(.BC1RGBAUnorm) == 0);
		Test.Assert(TextureFormats.BytesPerPixel(.ASTC4x4Unorm) == 0);
	}

	/// EVERY uncompressed format has a texel size, and every compressed one has a block
	/// size. Neither is never the answer.
	///
	/// Walked over the whole enum rather than spot checked, so a format added later that
	/// nobody sizes fails HERE instead of silently making an upload zero bytes long. The
	/// table used to omit sixteen ordinary uncompressed formats, which is exactly the shape
	/// of defect this catches.
	[Test]
	public static void EveryFormatIsSizedOneWayOrTheOther()
	{
		for (var raw = 1; raw <= (int)TextureFormat.ASTC8x8UnormSrgb; raw++)
		{
			let format = (TextureFormat)raw;
			let bytesPerPixel = TextureFormats.BytesPerPixel(format);
			let blockBytes = TextureFormats.BlockBytes(format);

			if (TextureFormats.IsCompressed(format))
			{
				Test.Assert(blockBytes > 0, scope $"{format} is compressed but has no block size");
				Test.Assert(bytesPerPixel == 0,
					scope $"{format} is compressed, so it has no per texel size");
			}
			else
			{
				Test.Assert(bytesPerPixel > 0,
					scope $"{format} is uncompressed but reports zero bytes per texel");
				Test.Assert(blockBytes == 0,
					scope $"{format} is uncompressed, so it has no block size");
			}
		}
	}

	/// The formats the table used to miss, checked by value.
	///
	/// Spot checks on top of the sweep above: the sweep proves each is non zero, and these
	/// prove each is the RIGHT size.
	[Test]
	public static void TheFormerlyMissingFormatsAreSizedCorrectly()
	{
		Test.Assert(TextureFormats.BytesPerPixel(.R8Snorm) == 1);
		Test.Assert(TextureFormats.BytesPerPixel(.R8Uint) == 1);
		Test.Assert(TextureFormats.BytesPerPixel(.R8Sint) == 1);
		Test.Assert(TextureFormats.BytesPerPixel(.RG8Snorm) == 2);
		Test.Assert(TextureFormats.BytesPerPixel(.RG8Uint) == 2);
		Test.Assert(TextureFormats.BytesPerPixel(.RG8Sint) == 2);
		Test.Assert(TextureFormats.BytesPerPixel(.RG16Uint) == 4);
		Test.Assert(TextureFormats.BytesPerPixel(.RG16Sint) == 4);
		Test.Assert(TextureFormats.BytesPerPixel(.RGBA8Snorm) == 4);
		Test.Assert(TextureFormats.BytesPerPixel(.RGBA8Uint) == 4);
		Test.Assert(TextureFormats.BytesPerPixel(.RGBA8Sint) == 4);
		Test.Assert(TextureFormats.BytesPerPixel(.RGB10A2Uint) == 4);
		Test.Assert(TextureFormats.BytesPerPixel(.RGB9E5Float) == 4);
		Test.Assert(TextureFormats.BytesPerPixel(.RG32Sint) == 8);
		Test.Assert(TextureFormats.BytesPerPixel(.RGBA16Unorm) == 8);
		Test.Assert(TextureFormats.BytesPerPixel(.RGBA16Snorm) == 8);
	}

	[Test]
	public static void BlockFootprintsMatchTheFormatFamily()
	{
		// Uncompressed is a one by one block of no bytes.
		Test.Assert(TextureFormats.BlockWidth(.RGBA8Unorm) == 1);
		Test.Assert(TextureFormats.BlockHeight(.RGBA8Unorm) == 1);
		Test.Assert(TextureFormats.BlockBytes(.RGBA8Unorm) == 0);

		// Every BC block is four by four.
		for (let f in TextureFormat[](.BC1RGBAUnorm, .BC3RGBAUnorm, .BC5RGSnorm, .BC7RGBAUnorm))
		{
			Test.Assert(TextureFormats.BlockWidth(f) == 4, scope $"{f} is a 4x4 block");
			Test.Assert(TextureFormats.BlockHeight(f) == 4);
		}

		// BC1 and BC4 are eight byte blocks; every other BC and all ASTC are sixteen.
		Test.Assert(TextureFormats.BlockBytes(.BC1RGBAUnorm) == 8);
		Test.Assert(TextureFormats.BlockBytes(.BC1RGBAUnormSrgb) == 8);
		Test.Assert(TextureFormats.BlockBytes(.BC4RUnorm) == 8);
		Test.Assert(TextureFormats.BlockBytes(.BC4RSnorm) == 8);
		Test.Assert(TextureFormats.BlockBytes(.BC3RGBAUnorm) == 16);
		Test.Assert(TextureFormats.BlockBytes(.BC7RGBAUnorm) == 16);
		Test.Assert(TextureFormats.BlockBytes(.ASTC4x4Unorm) == 16);

		// ASTC block sizes follow the name.
		Test.Assert(TextureFormats.BlockWidth(.ASTC4x4Unorm) == 4);
		Test.Assert(TextureFormats.BlockWidth(.ASTC5x5UnormSrgb) == 5);
		Test.Assert(TextureFormats.BlockWidth(.ASTC6x6Unorm) == 6);
		Test.Assert(TextureFormats.BlockWidth(.ASTC8x8UnormSrgb) == 8);

		// Every supported block is square.
		for (let f in TextureFormat[](.ASTC5x5Unorm, .ASTC6x6Unorm, .ASTC8x8Unorm))
			Test.Assert(TextureFormats.BlockHeight(f) == TextureFormats.BlockWidth(f));
	}

	/// The row pitch rounds the width UP to whole blocks, which is what makes a level whose
	/// width is not a multiple of the block size upload correctly.
	[Test]
	public static void CompressedPitchRoundsUpToWholeBlocks()
	{
		// BC1: 4x4 blocks of 8 bytes. 16 wide is 4 blocks.
		Test.Assert(TextureFormats.CompressedRowPitch(.BC1RGBAUnorm, 16) == 4 * 8);
		// 17 wide still needs 5 blocks, not 4 and a bit.
		Test.Assert(TextureFormats.CompressedRowPitch(.BC1RGBAUnorm, 17) == 5 * 8);
		// And a width smaller than one block is still one block.
		Test.Assert(TextureFormats.CompressedRowPitch(.BC1RGBAUnorm, 1) == 1 * 8);

		// BC7: same footprint, 16 byte blocks.
		Test.Assert(TextureFormats.CompressedRowPitch(.BC7RGBAUnorm, 16) == 4 * 16);

		// ASTC 8x8: 16 wide is 2 blocks.
		Test.Assert(TextureFormats.CompressedRowPitch(.ASTC8x8Unorm, 16) == 2 * 16);

		// Uncompressed has no block pitch at all.
		Test.Assert(TextureFormats.CompressedRowPitch(.RGBA8Unorm, 16) == 0);
	}

	[Test]
	public static void CompressedLevelBytesRoundsBothAxes()
	{
		// BC1, 16x16: 4 by 4 blocks of 8 bytes.
		Test.Assert(TextureFormats.CompressedLevelBytes(.BC1RGBAUnorm, 16, 16) == 4 * 4 * 8);

		// 17x17 rounds both axes up to 5 by 5.
		Test.Assert(TextureFormats.CompressedLevelBytes(.BC1RGBAUnorm, 17, 17) == 5 * 5 * 8);

		// A 1x1 mip tail is still one whole block.
		Test.Assert(TextureFormats.CompressedLevelBytes(.BC1RGBAUnorm, 1, 1) == 8);

		Test.Assert(TextureFormats.CompressedLevelBytes(.RGBA8Unorm, 16, 16) == 0);
	}
}
