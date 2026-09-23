using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.Image.DDS.Tests;

/// The DDS container: both header forms parse, the payload layout of layers and levels is
/// addressed right, every block format decodes to the texels expected, the DX10 writer round
/// trips, and the refusals are the documented codes.
///
/// The blocks are hand built: a solid colour is one endpoint repeated with every index nought.
class DdsTests
{
	private static void PutU32(List<uint8> outBytes, uint32 value)
	{
		for (int i < 4)
			outBytes.Add((uint8)((value >> (8 * i)) & 0xFF));
	}

	private static void PutU16(List<uint8> outBytes, uint16 value)
	{
		outBytes.Add((uint8)(value & 0xFF));
		outBytes.Add((uint8)(value >> 8));
	}

	private static uint32 FourCC(StringView code)
		=> (uint32)(uint8)code[0] | ((uint32)(uint8)code[1] << 8) | ((uint32)(uint8)code[2] << 16)
			| ((uint32)(uint8)code[3] << 24);

	/// A legacy header DDS, with no DX10 block: a FourCC or a bit mask pixel format.
	private static void LegacyHeader(List<uint8> outBytes, uint32 width, uint32 height,
		uint32 mips, uint32 pfFlags, uint32 fourCC, uint32 bitCount, uint32 rMask, uint32 gMask,
		uint32 bMask, uint32 aMask, uint32 caps2 = 0)
	{
		PutU32(outBytes, 0x20534444);
		PutU32(outBytes, 124);
		PutU32(outBytes, 0x1 | 0x2 | 0x4 | 0x1000 | ((mips > 1) ? 0x20000 : 0));
		PutU32(outBytes, height);
		PutU32(outBytes, width);
		PutU32(outBytes, 0); // the pitch or linear size, which readers ignore
		PutU32(outBytes, 0); // depth
		PutU32(outBytes, mips);
		for (int i < 11)
			PutU32(outBytes, 0);
		PutU32(outBytes, 32);
		PutU32(outBytes, pfFlags);
		PutU32(outBytes, fourCC);
		PutU32(outBytes, bitCount);
		PutU32(outBytes, rMask);
		PutU32(outBytes, gMask);
		PutU32(outBytes, bMask);
		PutU32(outBytes, aMask);
		PutU32(outBytes, 0x1000);
		PutU32(outBytes, caps2);
		PutU32(outBytes, 0);
		PutU32(outBytes, 0);
		PutU32(outBytes, 0);
	}

	// ---- solid four by four blocks ----

	private static void Bc1Block(List<uint8> outBytes, uint16 rgb565)
	{
		PutU16(outBytes, rgb565);
		PutU16(outBytes, rgb565);
		PutU32(outBytes, 0); // every index nought, which is endpoint nought
	}

	private static void Bc4Block(List<uint8> outBytes, uint8 value)
	{
		outBytes.Add(value);
		outBytes.Add(value);
		for (int i < 6)
			outBytes.Add(0);
	}

	private static void Bc3Block(List<uint8> outBytes, uint8 alpha, uint16 rgb565)
	{
		Bc4Block(outBytes, alpha);
		Bc1Block(outBytes, rgb565);
	}

	private static void Bc5Block(List<uint8> outBytes, uint8 r, uint8 g)
	{
		Bc4Block(outBytes, r);
		Bc4Block(outBytes, g);
	}

	/// BC7 mode six, one subset, RGBA seven bits each with a per endpoint parity bit and four
	/// bit indices, written least significant bit first. Both endpoints the same colour with
	/// every index nought reproduces the seven bit value shifted up with the parity exactly.
	private static void Bc7SolidBlock(List<uint8> outBytes, uint8 r, uint8 g, uint8 b, uint8 a)
	{
		uint8[16] bytes = .();
		var at = 0;
		void Put(uint32 value, int bits)
		{
			for (int i < bits)
			{
				if (((value >> i) & 1) != 0)
					bytes[at / 8] |= (uint8)(1 << (at % 8));
				at++;
			}
		}

		Put(0b1000000, 7); // mode six
		uint8[4] channels = .(r, g, b, a);
		for (let c in channels)
		{
			Put((uint32)c >> 1, 7);
			Put((uint32)c >> 1, 7);
		}
		// The same parity in every channel, by construction.
		Put((uint32)r & 1, 1); // p0
		Put((uint32)r & 1, 1); // p1
		Put(0, 3); // the anchor index
		Put(0, 15 * 4); // and the other fifteen
		Test.Assert(at == 128);

		for (let byte in bytes)
			outBytes.Add(byte);
	}

	[Test]
	public static void IsDdsSniffsTheMagicRatherThanAnExtension()
	{
		uint8[8] png = .(0x89, (uint8)'P', (uint8)'N', (uint8)'G', 0x0D, 0x0A, 0x1A, 0x0A);
		Test.Assert(!Dds.IsDds(.(&png[0], 8)));

		uint8[4] dds = .((uint8)'D', (uint8)'D', (uint8)'S', (uint8)' ');
		Test.Assert(Dds.IsDds(.(&dds[0], 4)));
		Test.Assert(!Dds.IsDds(.(&dds[0], 3)));
	}

	[Test]
	public static void ALegacyDxt1FileIsBc1WithNoColourSpaceFactAndDecodesSolidRed()
	{
		let file = scope List<uint8>();
		LegacyHeader(file, 4, 4, 1, 0x4, FourCC("DXT1"), 0, 0, 0, 0, 0);
		Bc1Block(file, 0xF800); // RGB565 pure red

		let dds = scope DdsImage();
		Test.Assert(Dds.LoadDds(file, dds) case .Ok);
		Test.Assert(dds.Format == .BC1);
		Test.Assert(!dds.ColorSpaceKnown);
		Test.Assert(dds.Width == 4);
		Test.Assert(dds.MipLevels == 1);
		Test.Assert(dds.ArrayLayers == 1);
		Test.Assert(dds.Data.Count == 8);

		let image = scope Image();
		Test.Assert(DdsDecode.DecodeLevel(dds, 0, 0, image) case .Ok);
		Test.Assert(image.Format == .RGBA8);
		// A legacy colour format takes the authoring norm.
		Test.Assert(image.ColorSpace == .Srgb);

		let p = image.GetPixel(3, 3);
		Test.Assert(p.R == 255);
		Test.Assert(p.G == 0);
		Test.Assert(p.B == 0);
		Test.Assert(p.A == 255);
	}

	[Test]
	public static void TheLegacyFourCCTableCoversTheDxtAndBcSpellings()
	{
		StringView[8] codes = .("DXT3", "DXT5", "ATI1", "BC4U", "BC4S", "ATI2", "BC5U", "BC5S");
		DdsFormat[8] formats = .(.BC2, .BC3, .BC4, .BC4, .BC4Snorm, .BC5, .BC5, .BC5Snorm);

		for (int i < 8)
		{
			let file = scope List<uint8>();
			LegacyHeader(file, 4, 4, 1, 0x4, FourCC(codes[i]), 0, 0, 0, 0, 0);
			// One zeroed block, which is enough bytes for either block size.
			for (int b < 16)
				file.Add(0);

			let dds = scope DdsImage();
			Test.Assert(Dds.LoadDds(file, dds) case .Ok);
			Test.Assert(dds.Format == formats[i], scope $"{codes[i]}");
		}
	}

	[Test]
	public static void Bc3CarriesAlphaBc4ReplicatesAndBc5GetsAReconstructedZ()
	{
		{
			let file = scope List<uint8>();
			LegacyHeader(file, 4, 4, 1, 0x4, FourCC("DXT5"), 0, 0, 0, 0, 0);
			Bc3Block(file, 128, 0x07E0); // half alpha over pure green

			let dds = scope DdsImage();
			Test.Assert(Dds.LoadDds(file, dds) case .Ok);
			let image = scope Image();
			Test.Assert(DdsDecode.DecodeLevel(dds, 0, 0, image) case .Ok);
			let p = image.GetPixel(0, 0);
			Test.Assert(p.G == 255);
			Test.Assert(p.R == 0);
			Test.Assert(p.A == 128);
		}
		{
			let file = scope List<uint8>();
			LegacyHeader(file, 4, 4, 1, 0x4, FourCC("ATI1"), 0, 0, 0, 0, 0);
			Bc4Block(file, 77);

			let dds = scope DdsImage();
			Test.Assert(Dds.LoadDds(file, dds) case .Ok);
			let image = scope Image();
			Test.Assert(DdsDecode.DecodeLevel(dds, 0, 0, image) case .Ok);
			Test.Assert(image.ColorSpace == .Linear, "a data format");
			let p = image.GetPixel(2, 1);
			Test.Assert(p.R == 77);
			Test.Assert(p.G == 77);
			Test.Assert(p.B == 77);
			Test.Assert(p.A == 255);
		}
		{
			let file = scope List<uint8>();
			LegacyHeader(file, 4, 4, 1, 0x4, FourCC("ATI2"), 0, 0, 0, 0, 0);
			Bc5Block(file, 128, 128); // a flat normal's XY

			let dds = scope DdsImage();
			Test.Assert(Dds.LoadDds(file, dds) case .Ok);
			let image = scope Image();
			Test.Assert(DdsDecode.DecodeLevel(dds, 0, 0, image) case .Ok);
			let p = image.GetPixel(1, 1);
			Test.Assert(p.R == 128);
			Test.Assert(p.G == 128);
			// Z is the square root of one less x squared less y squared, so about one: a whole
			// flat normal.
			Test.Assert(p.B >= 254);
			Test.Assert(p.A == 255);
		}
	}

	[Test]
	public static void ADx10Bc7SrgbFileWithAMipChainRoundTripsAndDecodesEveryLevel()
	{
		let source = scope DdsImage();
		source.Width = 8;
		source.Height = 8;
		source.MipLevels = 4; // eight, four, two, one
		source.Format = .BC7Srgb;
		source.ColorSpaceKnown = true;
		for (uint32 level < 4)
		{
			let blocks = (level == 0) ? 4 : 1;
			for (int b < blocks)
				Bc7SolidBlock(source.Data, 201, 101, 51, 255);
		}
		Test.Assert(source.Data.Count == source.LayerSize());
		Test.Assert(source.LayerSize() == (64 + 16 + 16 + 16));
		Test.Assert(source.LevelOffset(0, 2) == 80);
		Test.Assert(source.LevelWidth(3) == 1);

		let file = scope List<uint8>();
		Test.Assert(Dds.WriteDds(source, file) case .Ok);
		Test.Assert(file.Count == (4 + 124 + 20 + source.LayerSize()));

		let dds = scope DdsImage();
		Test.Assert(Dds.LoadDds(file, dds) case .Ok);
		Test.Assert(dds.Format == .BC7Srgb);
		Test.Assert(dds.ColorSpaceKnown);
		Test.Assert(dds.MipLevels == 4);
		Test.Assert(dds.Width == 8);
		Test.Assert(dds.Data.Count == source.Data.Count);
		Test.Assert(Internal.MemCmp(dds.Data.Ptr, source.Data.Ptr, source.Data.Count) == 0);

		for (uint32 level < 4)
		{
			let image = scope Image();
			Test.Assert(DdsDecode.DecodeLevel(dds, 0, level, image) case .Ok);
			Test.Assert(image.Width == dds.LevelWidth(level));
			Test.Assert(image.ColorSpace == .Srgb);
			let p = image.GetPixel(image.Width - 1, image.Height - 1);
			Test.Assert(p.R == 201);
			Test.Assert(p.G == 101);
			Test.Assert(p.B == 51);
			Test.Assert(p.A == 255);
		}

		// A DX10 header naming the NON sRGB twin is a linear fact rather than a guess.
		source.Format = .BC7;
		Test.Assert(Dds.WriteDds(source, file) case .Ok);
		Test.Assert(Dds.LoadDds(file, dds) case .Ok);
		let linear = scope Image();
		Test.Assert(DdsDecode.DecodeLevel(dds, 0, 0, linear) case .Ok);
		Test.Assert(linear.ColorSpace == .Linear);

		Test.Assert(DdsFormats.WithSrgb(.BC7, true) == .BC7Srgb);
		Test.Assert(DdsFormats.WithSrgb(.BC5, true) == .BC5, "no twin");
	}

	[Test]
	public static void UncompressedLegacyA8R8G8B8IsBgraInMemoryAndSwizzles()
	{
		let file = scope List<uint8>();
		LegacyHeader(file, 2, 1, 1, 0x40 | 0x1, 0, 32, 0x00FF0000, 0x0000FF00, 0x000000FF,
			0xFF000000);
		uint8[8] texels = .(10, 20, 30, 40, 50, 60, 70, 80); // B, G, R then A per texel
		for (let b in texels)
			file.Add(b);

		let dds = scope DdsImage();
		Test.Assert(Dds.LoadDds(file, dds) case .Ok);
		Test.Assert(dds.Format == .BGRA8);

		let image = scope Image();
		Test.Assert(DdsDecode.DecodeLevel(dds, 0, 0, image) case .Ok);
		let p = image.GetPixel(1, 0);
		Test.Assert(p.R == 70);
		Test.Assert(p.G == 60);
		Test.Assert(p.B == 50);
		Test.Assert(p.A == 80);
	}

	[Test]
	public static void Rgba16FDecodesToRgba32FWithTheHalvesConverted()
	{
		let source = scope DdsImage();
		source.Width = 1;
		source.Height = 1;
		source.Format = .RGBA16F;
		source.ColorSpaceKnown = true;
		uint16[4] halves = .(0x3C00, 0x3800, 0x0000, 0xC000); // one, a half, nought, minus two
		for (let h in halves)
			PutU16(source.Data, h);

		let file = scope List<uint8>();
		Test.Assert(Dds.WriteDds(source, file) case .Ok);
		let dds = scope DdsImage();
		Test.Assert(Dds.LoadDds(file, dds) case .Ok);

		let image = scope Image();
		Test.Assert(DdsDecode.DecodeLevel(dds, 0, 0, image) case .Ok);
		Test.Assert(image.Format == .RGBA32F);
		Test.Assert(image.ColorSpace == .Linear);

		let f = (float*)image.PixelData.Ptr;
		Test.Assert(Math.Abs(f[0] - 1.0f) < 0.001f);
		Test.Assert(Math.Abs(f[1] - 0.5f) < 0.001f);
		Test.Assert(Math.Abs(f[2]) < 0.001f);
		Test.Assert(Math.Abs(f[3] + 2.0f) < 0.001f);
	}

	[Test]
	public static void ADx10CubemapIsSixLayersAddressedLayerMajor()
	{
		let source = scope DdsImage();
		source.Width = 4;
		source.Height = 4;
		source.Format = .BC1;
		source.Cubemap = true;
		source.ArrayLayers = 6;
		source.ColorSpaceKnown = true;
		uint16[6] faceColours = .(0xF800, 0x07E0, 0x001F, 0xFFFF, 0x0000, 0xF81F);
		for (let c in faceColours)
			Bc1Block(source.Data, c);

		let file = scope List<uint8>();
		Test.Assert(Dds.WriteDds(source, file) case .Ok);
		let dds = scope DdsImage();
		Test.Assert(Dds.LoadDds(file, dds) case .Ok);
		Test.Assert(dds.Cubemap);
		Test.Assert(dds.ArrayLayers == 6);
		Test.Assert(dds.LevelOffset(3, 0) == 24);

		let face = scope Image();
		Test.Assert(DdsDecode.DecodeLevel(dds, 2, 0, face) case .Ok); // the third face, pure blue
		let p = face.GetPixel(0, 0);
		Test.Assert(p.B == 255);
		Test.Assert(p.R == 0);

		Test.Assert(DdsDecode.DecodeLevel(dds, 6, 0, face) case .Err(.OutOfRange));
		Test.Assert(DdsDecode.DecodeLevel(dds, 0, 1, face) case .Err(.OutOfRange));
	}

	[Test]
	public static void TheRefusalsAreTheDocumentedCodes()
	{
		// A truncated payload.
		{
			let file = scope List<uint8>();
			LegacyHeader(file, 8, 8, 1, 0x4, FourCC("DXT1"), 0, 0, 0, 0, 0);
			Bc1Block(file, 0xF800); // one block where four are due
			let dds = scope DdsImage();
			Test.Assert(Dds.LoadDds(file, dds) case .Err(.InvalidArgument));
		}
		// A volume.
		{
			let file = scope List<uint8>();
			LegacyHeader(file, 4, 4, 1, 0x4, FourCC("DXT1"), 0, 0, 0, 0, 0, 0x200000);
			Bc1Block(file, 0xF800);
			let dds = scope DdsImage();
			Test.Assert(Dds.LoadDds(file, dds) case .Err(.NotSupported));
		}
		// A format outside the table.
		{
			let file = scope List<uint8>();
			LegacyHeader(file, 4, 4, 1, 0x4, FourCC("UYVY"), 0, 0, 0, 0, 0);
			for (int i < 64)
				file.Add(0);
			let dds = scope DdsImage();
			Test.Assert(Dds.LoadDds(file, dds) case .Err(.NotSupported));
		}
		// A partial cubemap, which has no fixed layout.
		{
			let file = scope List<uint8>();
			LegacyHeader(file, 4, 4, 1, 0x4, FourCC("DXT1"), 0, 0, 0, 0, 0, 0x200 | 0x400);
			Bc1Block(file, 0xF800);
			let dds = scope DdsImage();
			Test.Assert(Dds.LoadDds(file, dds) case .Err(.NotSupported));
		}
		// And something that is not a DDS at all.
		{
			uint8[3] junk = .((uint8)'D', (uint8)'D', (uint8)'S');
			let dds = scope DdsImage();
			Test.Assert(Dds.LoadDds(.(&junk[0], 3), dds) case .Err(.InvalidArgument));
		}
	}

	[Test]
	public static void LoadDdsAsImageIsLevelNoughtOfLayerNought()
	{
		let file = scope List<uint8>();
		LegacyHeader(file, 4, 4, 3, 0x4, FourCC("DXT1"), 0, 0, 0, 0, 0);
		Bc1Block(file, 0x001F); // level nought is blue
		Bc1Block(file, 0xF800); // level one
		Bc1Block(file, 0xF800); // level two

		let image = scope Image();
		Test.Assert(Dds.LoadDdsAsImage(file, image) case .Ok);
		Test.Assert(image.Width == 4);
		Test.Assert(image.GetPixel(0, 0).B == 255);
	}

	/// The SIGNED block formats go through bcdec's float entry points, which exist only
	/// because bcdec-c is built with BCDEC_BC4BC5_PRECISE.
	///
	/// A signed endpoint is the byte read as a signed char over 127, so minus 127 is the
	/// bottom of the range, nought its middle and 127 its top; mapped back through the signed
	/// range those are nought, 128 and 255. Decoded as UNSIGNED instead, 0x81 would read as
	/// 129 over 255, which is the failure this pins.
	[Test]
	public static void ASignedBlockDecodesThroughTheSignedRange()
	{
		uint8[3] endpoints = .(127, 0, 0x81); // one, nought, minus one
		uint8[3] expected = .(255, 128, 0);

		for (int i < 3)
		{
			let file = scope List<uint8>();
			LegacyHeader(file, 4, 4, 1, 0x4, FourCC("BC4S"), 0, 0, 0, 0, 0);
			Bc4Block(file, endpoints[i]);

			let dds = scope DdsImage();
			Test.Assert(Dds.LoadDds(file, dds) case .Ok);
			Test.Assert(dds.Format == .BC4Snorm);

			let image = scope Image();
			Test.Assert(DdsDecode.DecodeLevel(dds, 0, 0, image) case .Ok);
			let p = image.GetPixel(2, 2);
			Test.Assert(p.R == expected[i], scope $"endpoint {endpoints[i]} decoded to {p.R}");
			Test.Assert(p.G == expected[i]);
			Test.Assert(p.A == 255);
		}

		// And a signed flat normal, whose XY are both nought, reconstructs a Z of about one.
		let file = scope List<uint8>();
		LegacyHeader(file, 4, 4, 1, 0x4, FourCC("BC5S"), 0, 0, 0, 0, 0);
		Bc5Block(file, 0, 0);

		let dds = scope DdsImage();
		Test.Assert(Dds.LoadDds(file, dds) case .Ok);
		Test.Assert(dds.Format == .BC5Snorm);

		let image = scope Image();
		Test.Assert(DdsDecode.DecodeLevel(dds, 0, 0, image) case .Ok);
		let p = image.GetPixel(1, 3);
		Test.Assert(p.R == 128);
		Test.Assert(p.G == 128);
		Test.Assert(p.B >= 254);
	}
}
