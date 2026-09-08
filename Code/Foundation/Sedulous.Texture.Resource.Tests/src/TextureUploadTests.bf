using System;
using System.Collections;
using Sedulous.RHI;
using Sedulous.Texture;
using Sedulous.Texture.Resource;

namespace Sedulous.Texture.Resource.Tests;

/// Working out what a cooked payload holds and where each piece goes.
///
/// This is the arithmetic that decides how far into a buffer to read, so it gets its own
/// tests rather than being reachable only through a device.
class TextureUploadTests
{
	private static TextureResource Record(uint32 width, uint32 height, uint32 mips = 1,
		TextureFormat format = .RGBA8Unorm, TextureShape shape = .Texture2D)
	{
		let record = new TextureResource();
		record.Width = width;
		record.Height = height;
		record.MipLevels = mips;
		record.Format = format;
		record.Shape = shape;
		return record;
	}

	private static void Enumerate(TextureResource record, int payloadBytes,
		List<TextureUploadWrite> outWrites)
	{
		TextureUpload.EnumerateWrites(record, payloadBytes, outWrites);
	}

	[Test]
	public static void ASingleLevelIsOneWrite()
	{
		let record = Record(4, 2);
		defer delete record;
		let writes = scope List<TextureUploadWrite>();
		Enumerate(record, 4 * 2 * 4, writes);

		Test.Assert(writes.Count == 1);
		Test.Assert(writes[0].Offset == 0);
		Test.Assert(writes[0].ByteCount == 32);
		Test.Assert(writes[0].MipLevel == 0);
		Test.Assert(writes[0].ArrayLayer == 0);
		Test.Assert(writes[0].Extent.Width == 4);
		Test.Assert(writes[0].Extent.Height == 2);
		Test.Assert(writes[0].Extent.Depth == 1);
		Test.Assert(writes[0].Layout.BytesPerRow == 16);
		Test.Assert(writes[0].Layout.RowsPerImage == 2);
	}

	/// The chain is concatenated largest first, and each level starts where the previous
	/// one ended.
	[Test]
	public static void AChainWalksTheConcatenatedLevels()
	{
		let record = Record(8, 8, 4);
		defer delete record;
		let writes = scope List<TextureUploadWrite>();
		Enumerate(record, (256 + 64 + 16 + 4), writes);

		Test.Assert(writes.Count == 4);
		Test.Assert((writes[0].Offset == 0) && (writes[0].ByteCount == 256));
		Test.Assert((writes[1].Offset == 256) && (writes[1].ByteCount == 64));
		Test.Assert((writes[2].Offset == 320) && (writes[2].ByteCount == 16));
		Test.Assert((writes[3].Offset == 336) && (writes[3].ByteCount == 4));

		for (uint32 level = 0; level < 4; level++)
			Test.Assert(writes[level].MipLevel == level);

		Test.Assert(writes[3].Extent.Width == 1);
		Test.Assert(writes[3].Extent.Height == 1);
	}

	/// A payload holding only level zero uploads only that. Uploading what exists beats
	/// refusing, which gives a black texture with no clue why.
	[Test]
	public static void ATruncatedPayloadUploadsTheLevelsItHas()
	{
		let record = Record(8, 8, 4);
		defer delete record;

		let onlyLevelZero = scope List<TextureUploadWrite>();
		Enumerate(record, 256, onlyLevelZero);
		Test.Assert(onlyLevelZero.Count == 1);

		// A payload that stops PART WAY through a level stops before it, never inside it.
		let partial = scope List<TextureUploadWrite>();
		Enumerate(record, 256 + 30, partial);
		Test.Assert(partial.Count == 1, "half of level one is not level one");

		let twoLevels = scope List<TextureUploadWrite>();
		Enumerate(record, 256 + 64, twoLevels);
		Test.Assert(twoLevels.Count == 2);
	}

	/// Never read past the end. That is the whole reason the byte count is consulted.
	[Test]
	public static void EveryWriteStaysInsideThePayload()
	{
		let record = Record(16, 16, 5);
		defer delete record;
		let payloadBytes = 1000;
		let writes = scope List<TextureUploadWrite>();
		Enumerate(record, payloadBytes, writes);

		for (let write in writes)
			Test.Assert((write.Offset + write.ByteCount) <= payloadBytes);
	}

	[Test]
	public static void AnEmptyOrDegeneratePayloadYieldsNothing()
	{
		let record = Record(4, 4);
		defer delete record;

		let empty = scope List<TextureUploadWrite>();
		Enumerate(record, 0, empty);
		Test.Assert(empty.IsEmpty);

		let tooSmall = scope List<TextureUploadWrite>();
		Enumerate(record, 4, tooSmall);
		Test.Assert(tooSmall.IsEmpty, "not even level zero fits");

		let zeroSized = Record(0, 4);
		defer delete zeroSized;
		let none = scope List<TextureUploadWrite>();
		Enumerate(zeroSized, 1024, none);
		Test.Assert(none.IsEmpty);
	}

	/// A non square texture floors each dimension separately, so the short side stops at
	/// one while the long side keeps halving.
	[Test]
	public static void ANonSquareChainFloorsEachDimension()
	{
		let record = Record(8, 2, 4);
		defer delete record;
		let writes = scope List<TextureUploadWrite>();
		Enumerate(record, 1024, writes);

		Test.Assert(writes.Count == 4);
		Test.Assert((writes[0].Extent.Width == 8) && (writes[0].Extent.Height == 2));
		Test.Assert((writes[1].Extent.Width == 4) && (writes[1].Extent.Height == 1));
		Test.Assert((writes[2].Extent.Width == 2) && (writes[2].Extent.Height == 1));
		Test.Assert((writes[3].Extent.Width == 1) && (writes[3].Extent.Height == 1));
	}

	/// A cube is six faces at mip zero, one layer write each, in the order the cook packed
	/// them.
	[Test]
	public static void ACubeIsSixLayerWrites()
	{
		let record = Record(4, 4, 1, .RGBA8Unorm, .Cubemap);
		defer delete record;
		let faceBytes = 4 * 4 * 4;

		let writes = scope List<TextureUploadWrite>();
		Enumerate(record, faceBytes * 6, writes);

		Test.Assert(writes.Count == 6);
		for (uint32 face = 0; face < 6; face++)
		{
			Test.Assert(writes[face].ArrayLayer == face);
			Test.Assert(writes[face].MipLevel == 0);
			Test.Assert(writes[face].Offset == (int)face * faceBytes);
			Test.Assert(writes[face].ByteCount == faceBytes);
		}
	}

	/// A cube whose payload is short of six faces uploads the faces it has, rather than
	/// walking off the end of the buffer.
	[Test]
	public static void AShortCubePayloadStopsAtTheLastWholeFace()
	{
		let record = Record(4, 4, 1, .RGBA8Unorm, .Cubemap);
		defer delete record;
		let faceBytes = 4 * 4 * 4;

		let writes = scope List<TextureUploadWrite>();
		Enumerate(record, (faceBytes * 3) + 10, writes);
		Test.Assert(writes.Count == 3);
	}

	/// A compressed level is measured by its BLOCK footprint, and the row stride is a
	/// block row: measuring one per texel would read four times too much.
	[Test]
	public static void ACompressedChainIsMeasuredByBlock()
	{
		let record = Record(8, 8, 3, .BC7RGBAUnorm);
		defer delete record;
		let writes = scope List<TextureUploadWrite>();
		Enumerate(record, 1024, writes);

		Test.Assert(writes.Count == 3);
		// 8x8 is two by two blocks of sixteen bytes; 4x4 is one; 2x2 still pays for one.
		Test.Assert((writes[0].Offset == 0) && (writes[0].ByteCount == 64));
		Test.Assert((writes[1].Offset == 64) && (writes[1].ByteCount == 16));
		Test.Assert((writes[2].Offset == 80) && (writes[2].ByteCount == 16));

		Test.Assert(writes[0].Layout.BytesPerRow == 32, "two blocks across");
		Test.Assert(writes[0].Layout.RowsPerImage == 2, "two block rows, not eight texel rows");
		Test.Assert(writes[2].Layout.RowsPerImage == 1, "a 2x2 level is one partial block row");

		// The extent stays in TEXELS: it describes the region, not the storage.
		Test.Assert((writes[2].Extent.Width == 2) && (writes[2].Extent.Height == 2));
	}

	/// BC1 packs the same footprint into half the bytes, so the offsets differ from BC7's.
	[Test]
	public static void ABc1ChainUsesEightByteBlocks()
	{
		let record = Record(8, 8, 2, .BC1RGBAUnorm);
		defer delete record;
		let writes = scope List<TextureUploadWrite>();
		Enumerate(record, 1024, writes);

		Test.Assert(writes.Count == 2);
		Test.Assert((writes[0].Offset == 0) && (writes[0].ByteCount == 32));
		Test.Assert((writes[1].Offset == 32) && (writes[1].ByteCount == 8));
		Test.Assert(writes[0].Layout.BytesPerRow == 16);
	}

	/// A compressed CUBE sizes its faces by block too. Raptor measures a cube face per
	/// texel, which for a BC format gives zero bytes per pixel and so six empty writes: the
	/// faces silently never upload.
	[Test]
	public static void ACompressedCubeSizesItsFacesByBlock()
	{
		let record = Record(8, 8, 1, .BC7RGBAUnorm, .Cubemap);
		defer delete record;
		let writes = scope List<TextureUploadWrite>();
		Enumerate(record, 64 * 6, writes);

		Test.Assert(writes.Count == 6);
		for (uint32 face = 0; face < 6; face++)
		{
			Test.Assert(writes[face].ByteCount == 64, "one whole compressed face");
			Test.Assert(writes[face].Offset == (int)face * 64);
			Test.Assert(writes[face].ArrayLayer == face);
			Test.Assert(writes[face].Layout.BytesPerRow == 32);
			Test.Assert(writes[face].Layout.RowsPerImage == 2);
		}
	}
}
