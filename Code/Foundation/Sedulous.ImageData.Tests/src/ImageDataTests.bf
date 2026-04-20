namespace Sedulous.Images.Tests;

using System;
using Sedulous.Images;

class ImageDataTests
{
	// ==========================================================
	// OwnedImageData
	// ==========================================================

	[Test]
	public static void OwnedImageData_ConstructFromSpan()
	{
		uint8[16] pixels = .();
		for (int i = 0; i < 16; i++)
			pixels[i] = (uint8)i;

		let img = scope OwnedImageData(2, 2, .RGBA8, Span<uint8>(&pixels, 16));
		Test.Assert(img.Width == 2);
		Test.Assert(img.Height == 2);
		Test.Assert(img.Format == .RGBA8);
		Test.Assert(img.PixelData.Length == 16);
		Test.Assert(img.PixelData[0] == 0);
		Test.Assert(img.PixelData[4] == 4);
	}

	[Test]
	public static void OwnedImageData_ConstructFromArray()
	{
		let data = new uint8[8];
		data[0] = 255;
		data[7] = 128;
		let img = scope OwnedImageData(2, 1, .RGBA8, data);
		Test.Assert(img.Width == 2);
		Test.Assert(img.Height == 1);
		Test.Assert(img.PixelData[0] == 255);
		Test.Assert(img.PixelData[7] == 128);
	}

	[Test]
	public static void OwnedImageData_ConstructWithNewArray()
	{
		let data = new uint8[64]; // 4x4 RGBA8
		let img = scope OwnedImageData(4, 4, .RGBA8, data);
		Test.Assert(img.Width == 4);
		Test.Assert(img.Height == 4);
		Test.Assert(img.Format == .RGBA8);
		Test.Assert(img.PixelData.Length == 64);
	}

	[Test]
	public static void OwnedImageData_R8Format()
	{
		let data = new uint8[4];
		let img = scope OwnedImageData(2, 2, .R8, data);
		Test.Assert(img.Format == .R8);
		Test.Assert(img.PixelData.Length == 4);
	}

	// ==========================================================
	// NineSlice
	// ==========================================================

	[Test]
	public static void NineSlice_ConstructFourValues()
	{
		let ns = NineSlice(4, 6, 8, 10);
		Test.Assert(ns.Left == 4);
		Test.Assert(ns.Top == 6);
		Test.Assert(ns.Right == 8);
		Test.Assert(ns.Bottom == 10);
	}

	[Test]
	public static void NineSlice_ConstructUniform()
	{
		let ns = NineSlice(5);
		Test.Assert(ns.Left == 5);
		Test.Assert(ns.Top == 5);
		Test.Assert(ns.Right == 5);
		Test.Assert(ns.Bottom == 5);
	}

	[Test]
	public static void NineSlice_ConstructSymmetric()
	{
		let ns = NineSlice(3, 7);
		Test.Assert(ns.Left == 3);
		Test.Assert(ns.Right == 3);
		Test.Assert(ns.Top == 7);
		Test.Assert(ns.Bottom == 7);
	}

	[Test]
	public static void NineSlice_HorizontalBorder()
	{
		let ns = NineSlice(4, 0, 6, 0);
		Test.Assert(ns.HorizontalBorder == 10);
	}

	[Test]
	public static void NineSlice_VerticalBorder()
	{
		let ns = NineSlice(0, 3, 0, 5);
		Test.Assert(ns.VerticalBorder == 8);
	}

	[Test]
	public static void NineSlice_IsValid_NonZero()
	{
		let ns = NineSlice(1, 0, 0, 0);
		Test.Assert(ns.IsValid);
	}

	[Test]
	public static void NineSlice_IsValid_AllZero()
	{
		let ns = NineSlice(0, 0, 0, 0);
		Test.Assert(!ns.IsValid);
	}

	// ==========================================================
	// ImageAtlasBuilder
	// ==========================================================

	private static OwnedImageData MakeImage(uint32 w, uint32 h, uint8 fill)
	{
		let data = new uint8[w * h * 4];
		for (int i = 0; i < data.Count; i++)
			data[i] = fill;
		return new OwnedImageData(w, h, .RGBA8, data);
	}

	[Test]
	public static void AtlasBuilder_EmptyBuild()
	{
		let builder = scope ImageAtlasBuilder();
		Test.Assert(builder.Build());
		Test.Assert(builder.Atlas != null);
		Test.Assert(builder.Atlas.Width >= 1);
		Test.Assert(builder.Atlas.Height >= 1);
	}

	[Test]
	public static void AtlasBuilder_SingleImage()
	{
		let img = MakeImage(32, 32, 128);
		defer delete img;

		let builder = scope ImageAtlasBuilder();
		builder.AddImage("test", img);
		Test.Assert(builder.Build());

		let region = builder.GetRegion("test");
		Test.Assert(region.HasValue);
		Test.Assert(region.Value.Width == 32);
		Test.Assert(region.Value.Height == 32);
	}

	[Test]
	public static void AtlasBuilder_MultipleImages()
	{
		let img1 = MakeImage(64, 64, 100);
		let img2 = MakeImage(32, 32, 200);
		let img3 = MakeImage(48, 48, 150);
		defer { delete img1; delete img2; delete img3; }

		let builder = scope ImageAtlasBuilder();
		builder.AddImage("a", img1);
		builder.AddImage("b", img2);
		builder.AddImage("c", img3);
		Test.Assert(builder.Build());

		let r1 = builder.GetRegion("a");
		let r2 = builder.GetRegion("b");
		let r3 = builder.GetRegion("c");
		Test.Assert(r1.HasValue);
		Test.Assert(r2.HasValue);
		Test.Assert(r3.HasValue);

		// No overlap.
		Test.Assert(!Overlaps(r1.Value, r2.Value));
		Test.Assert(!Overlaps(r1.Value, r3.Value));
		Test.Assert(!Overlaps(r2.Value, r3.Value));
	}

	[Test]
	public static void AtlasBuilder_PowerOf2()
	{
		let img = MakeImage(100, 100, 0);
		defer delete img;

		let builder = scope ImageAtlasBuilder();
		builder.AddImage("big", img);
		Test.Assert(builder.Build());

		Test.Assert(IsPow2(builder.Atlas.Width));
		Test.Assert(IsPow2(builder.Atlas.Height));
	}

	[Test]
	public static void AtlasBuilder_GrowsWhenNeeded()
	{
		// Fill a 256x256 atlas with many images to force growth.
		let builder = scope ImageAtlasBuilder(256, 4096);
		var images = scope System.Collections.List<OwnedImageData>();

		for (int i = 0; i < 20; i++)
		{
			let img = MakeImage(64, 64, (uint8)i);
			images.Add(img);
			let name = scope $"img{i}";
			builder.AddImage(name, img);
		}

		Test.Assert(builder.Build());
		// 20 × 64x64 images = 81920 pixels. 256x256=65536 is too small.
		// Should have grown to at least 512.
		Test.Assert(builder.Atlas.Width >= 512 || builder.Atlas.Height >= 512);

		for (let img in images) delete img;
	}

	[Test]
	public static void AtlasBuilder_GetRegion_Missing()
	{
		let builder = scope ImageAtlasBuilder();
		builder.Build();
		Test.Assert(!builder.GetRegion("nonexistent").HasValue);
	}

	[Test]
	public static void AtlasBuilder_PixelDataCopied()
	{
		let img = MakeImage(4, 4, 42);
		defer delete img;

		let builder = scope ImageAtlasBuilder(256);
		builder.AddImage("px", img);
		Test.Assert(builder.Build());

		let region = builder.GetRegion("px").Value;
		let atlas = builder.Atlas;
		let stride = atlas.Width * 4;

		// Check that the pixel at the region's origin matches the source.
		let offset = (int)(region.Y * (int32)stride + region.X * 4);
		Test.Assert(atlas.PixelData[offset] == 42);
	}

	[Test]
	public static void AtlasBuilder_LargeImage()
	{
		// Image larger than min atlas size.
		let img = MakeImage(300, 300, 77);
		defer delete img;

		let builder = scope ImageAtlasBuilder(256, 4096);
		builder.AddImage("large", img);
		Test.Assert(builder.Build());

		let region = builder.GetRegion("large");
		Test.Assert(region.HasValue);
		Test.Assert(region.Value.Width == 300);
		Test.Assert(region.Value.Height == 300);
		Test.Assert(builder.Atlas.Width >= 302); // 300 + padding
	}

	// ==========================================================
	// PixelFormat
	// ==========================================================

	[Test]
	public static void PixelFormat_Values()
	{
		Test.Assert(PixelFormat.R8 != .RGBA8);
		Test.Assert(PixelFormat.RGBA8 != .BGRA8);
	}

	// ==========================================================
	// Helpers
	// ==========================================================

	private static bool Overlaps(RectangleI a, RectangleI b)
	{
		return a.X < b.X + b.Width && a.X + a.Width > b.X &&
			a.Y < b.Y + b.Height && a.Y + a.Height > b.Y;
	}

	private static bool IsPow2(uint32 v)
	{
		return v > 0 && (v & (v - 1)) == 0;
	}
}
