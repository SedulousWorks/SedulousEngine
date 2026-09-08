using System;
using Sedulous.Image;
using Sedulous.RHI;
using Sedulous.Texture;

namespace Sedulous.Texture.Tests;

/// The upload descriptor: what each factory sets, and what a mip level costs.
class TextureDataTests
{
	[Test]
	public static void TheFactoriesDescribeTheirShapes()
	{
		uint8[16] pixels = .();
		let bytes = Span<uint8>(&pixels[0], 16);

		let flat = TextureData.Create2D(bytes, 2, 2, .RGBA8Unorm);
		Test.Assert(flat.Width == 2);
		Test.Assert(flat.Height == 2);
		Test.Assert(flat.DepthOrArrayLayers == 1);
		Test.Assert(flat.MipLevels == 1);
		Test.Assert(flat.Dimension == .Texture2D);
		Test.Assert(flat.Format == .RGBA8Unorm);
		Test.Assert(flat.Size == 16);

		let mipped = TextureData.Create2DWithMips(bytes, 4, 4, 3, .RGBA8Unorm);
		Test.Assert(mipped.MipLevels == 3);
		Test.Assert(mipped.DepthOrArrayLayers == 1);

		// A cube is six SQUARE faces, stored as six layers: the shape the GPU has.
		let cube = TextureData.CreateCube(bytes, 8, .RGBA8Unorm);
		Test.Assert(cube.DepthOrArrayLayers == 6);
		Test.Assert(cube.Width == 8);
		Test.Assert(cube.Height == 8);
		Test.Assert(cube.Dimension == .Texture2D, "storage is a 2D array; the cube is a view");

		let array = TextureData.Create2DArray(bytes, 4, 4, 5, .RGBA8Unorm);
		Test.Assert(array.DepthOrArrayLayers == 5);
		Test.Assert(array.MipLevels == 1);
	}

	/// The descriptor owns nothing: it points at the caller's bytes.
	[Test]
	public static void TheDescriptorPointsAtTheCallersBytes()
	{
		uint8[4] pixels = .(1, 2, 3, 4);
		let data = TextureData.Create2D(.(&pixels[0], 4), 1, 1, .RGBA8Unorm);
		Test.Assert(data.Pixels.Ptr == &pixels[0]);
		Test.Assert(data.Pixels[3] == 4);

		pixels[3] = 9;
		Test.Assert(data.Pixels[3] == 9, "a view, not a copy");
	}

	/// Auto by default. Zero is not "no rows", it is "work it out from the format", which
	/// is what almost every caller wants and what a wrong guess here would silently break.
	[Test]
	public static void TheRowStridesDefaultToAuto()
	{
		let data = TextureData.Create2D(.(), 4, 4, .RGBA8Unorm);
		Test.Assert(data.BytesPerRow == 0);
		Test.Assert(data.RowsPerImage == 0);
	}

	[Test]
	public static void BytesPerPixelComesFromTheOneTable()
	{
		Test.Assert(TextureData.GetBytesPerPixel(.R8Unorm) == 1);
		Test.Assert(TextureData.GetBytesPerPixel(.RG8Unorm) == 2);
		Test.Assert(TextureData.GetBytesPerPixel(.RGBA8Unorm) == 4);
		Test.Assert(TextureData.GetBytesPerPixel(.RGBA8UnormSrgb) == 4);
		Test.Assert(TextureData.GetBytesPerPixel(.RGBA16Float) == 8);
		Test.Assert(TextureData.GetBytesPerPixel(.RGBA32Float) == 16);
		Test.Assert(TextureData.GetBytesPerPixel(.Depth16Unorm) == 2);

		// The two a second table with a default of four used to get wrong.
		Test.Assert(TextureData.GetBytesPerPixel(.RGBA16Unorm) == 8);
		Test.Assert(TextureData.GetBytesPerPixel(.Stencil8) == 1);

		// A block compressed format has no per texel size at all.
		Test.Assert(TextureData.GetBytesPerPixel(.BC7RGBAUnorm) == 0);
	}

	[Test]
	public static void AMipLevelHalvesAndFloorsAtOne()
	{
		let data = TextureData.Create2D(.(), 8, 8, .RGBA8Unorm);
		Test.Assert(data.CalculateMipSize(0) == 8 * 8 * 4);
		Test.Assert(data.CalculateMipSize(1) == 4 * 4 * 4);
		Test.Assert(data.CalculateMipSize(3) == 1 * 1 * 4, "the last level is one texel");
		Test.Assert(data.CalculateMipSize(9) == 1 * 1 * 4, "and it stays there");
	}

	/// A non square texture floors each dimension on its own, so the short side stops at
	/// one while the long side keeps halving.
	[Test]
	public static void ANonSquareMipFloorsEachDimensionSeparately()
	{
		let data = TextureData.Create2D(.(), 8, 2, .RGBA8Unorm);
		Test.Assert(data.CalculateMipSize(0) == 8 * 2 * 4);
		Test.Assert(data.CalculateMipSize(1) == 4 * 1 * 4);
		Test.Assert(data.CalculateMipSize(2) == 2 * 1 * 4);
		Test.Assert(data.CalculateMipSize(3) == 1 * 1 * 4);
	}

	/// Every layer costs a level, which is what makes a cube six times a face.
	[Test]
	public static void EveryLayerCostsAWholeLevel()
	{
		let cube = TextureData.CreateCube(.(), 8, .RGBA8Unorm);
		Test.Assert(cube.CalculateMipSize(0) == 8 * 8 * 4 * 6);

		let array = TextureData.Create2DArray(.(), 4, 4, 3, .RGBA8Unorm);
		Test.Assert(array.CalculateMipSize(0) == 4 * 4 * 4 * 3);
		Test.Assert(array.CalculateMipSize(1) == 2 * 2 * 4 * 3);
	}

	/// A compressed level is sized by BLOCK, and a block is indivisible: a 4x4 BC7 level
	/// and a 1x1 one both cost one whole block.
	[Test]
	public static void ACompressedLevelIsSizedByBlock()
	{
		let bc7 = TextureData.Create2D(.(), 8, 8, .BC7RGBAUnorm);
		Test.Assert(bc7.CalculateMipSize(0) == 4 * 16, "two by two blocks of sixteen bytes");
		Test.Assert(bc7.CalculateMipSize(1) == 16);
		Test.Assert(bc7.CalculateMipSize(3) == 16, "a one texel level still pays for a block");

		// BC1 packs the same footprint into half the bytes.
		let bc1 = TextureData.Create2D(.(), 8, 8, .BC1RGBAUnorm);
		Test.Assert(bc1.CalculateMipSize(0) == 4 * 8);
	}
}
