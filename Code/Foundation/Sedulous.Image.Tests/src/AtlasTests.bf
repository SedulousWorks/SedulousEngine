using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;

namespace Sedulous.Image.Tests;

/// The atlas packer and the nine slice insets.
class AtlasTests
{
	[Test]
	public static void NineSliceInsetsAddUp()
	{
		let none = NineSlice();
		Test.Assert(!none.IsValid, "no border is not a nine slice");
		Test.Assert(none.HorizontalBorder == 0.0f);

		let uniform = NineSlice(4.0f);
		Test.Assert(uniform.Left == 4.0f && uniform.Right == 4.0f);
		Test.Assert(uniform.HorizontalBorder == 8.0f);
		Test.Assert(uniform.VerticalBorder == 8.0f);
		Test.Assert(uniform.IsValid);

		let axes = NineSlice(3.0f, 5.0f);
		Test.Assert(axes.Left == 3.0f && axes.Right == 3.0f, "horizontal on both sides");
		Test.Assert(axes.Top == 5.0f && axes.Bottom == 5.0f);

		let each = NineSlice(1.0f, 2.0f, 3.0f, 4.0f);
		Test.Assert(each.HorizontalBorder == 4.0f);
		Test.Assert(each.VerticalBorder == 6.0f);

		// One border alone is still a nine slice.
		Test.Assert(NineSlice(0.0f, 0.0f, 0.0f, 1.0f).IsValid);
	}

	[Test]
	public static void AnEmptyAtlasStillBuildsSomethingBindable()
	{
		let builder = scope ImageAtlasBuilder(64, 256, 1);
		Test.Assert(builder.EntryCount == 0);
		Test.Assert(builder.Atlas == null, "nothing until it is built");

		Test.Assert(builder.Build());
		Test.Assert(builder.Atlas != null, "a valid one by one, not null");
		Test.Assert(builder.Atlas.Width == 1);
		Test.Assert(builder.Atlas.GetPixel(0, 0) == Color32.Transparent);
	}

	[Test]
	public static void PackedImagesGetDistinctNonOverlappingRegions()
	{
		let a = Image.CreateSolidColor(8, 8, Color32.Red);
		let b = Image.CreateSolidColor(16, 4, Color32.Green);
		let c = Image.CreateSolidColor(4, 16, Color32.Blue);
		defer { delete a; delete b; delete c; }

		let builder = scope ImageAtlasBuilder(64, 256, 1);
		builder.AddImage("a", a);
		builder.AddImage("b", b);
		builder.AddImage("c", c);
		Test.Assert(builder.EntryCount == 3);

		Test.Assert(builder.Build());
		Test.Assert(builder.Atlas.Format == .RGBA8);

		Test.Assert(builder.GetRegion("a", let ra));
		Test.Assert(builder.GetRegion("b", let rb));
		Test.Assert(builder.GetRegion("c", let rc));

		Test.Assert(ra.Width == 8 && ra.Height == 8, "the region is the image's own size");
		Test.Assert(rb.Width == 16 && rb.Height == 4);
		Test.Assert(rc.Width == 4 && rc.Height == 16);

		let regions = scope List<RectI>()..Add(ra)..Add(rb)..Add(rc);
		for (int i < regions.Count)
		{
			for (int j = i + 1; j < regions.Count; j++)
				Test.Assert(!Overlaps(regions[i], regions[j]), scope $"regions {i} and {j} overlap");
		}

		Test.Assert(!builder.GetRegion("missing", let _), "a name that was never added");
	}

	/// The packed pixels really are in the atlas, at the region reported for them. A packer
	/// that reported plausible rectangles but copied nothing would pass everything above.
	[Test]
	public static void ThePackedPixelsLandAtTheirReportedRegion()
	{
		let red = Image.CreateSolidColor(8, 8, Color32.Red);
		let green = Image.CreateSolidColor(8, 8, Color32.Green);
		defer { delete red; delete green; }

		let builder = scope ImageAtlasBuilder(64, 256, 1);
		builder.AddImage("red", red);
		builder.AddImage("green", green);
		Test.Assert(builder.Build());

		Test.Assert(builder.GetRegion("red", let redRegion));
		Test.Assert(builder.GetRegion("green", let greenRegion));

		let atlas = builder.Atlas;
		Test.Assert(atlas.GetPixel((uint32)redRegion.X, (uint32)redRegion.Y) == Color32.Red);
		Test.Assert(atlas.GetPixel((uint32)redRegion.X + 7, (uint32)redRegion.Y + 7) == Color32.Red,
			"the far corner too, so the whole image was copied");
		Test.Assert(atlas.GetPixel((uint32)greenRegion.X, (uint32)greenRegion.Y) == Color32.Green);
	}

	/// Images that do not fit across the atlas start a new shelf, which is the whole idea
	/// of shelf packing. Without the wrap they would march off the right edge and either
	/// overlap or spill.
	[Test]
	public static void ARowThatIsFullWrapsToTheNextShelf()
	{
		let images = scope List<Image>();
		defer { for (let image in images) delete image; }
		for (int i < 4)
			images.Add(Image.CreateSolidColor(16, 8, .((uint8)(i * 60), 0, 0, 255)));

		// Four 16 wide images cannot sit side by side in 32 pixels, so the packer has to
		// use more than one row.
		let builder = scope ImageAtlasBuilder(32, 256, 1);
		for (int i < 4)
			builder.AddImage(scope $"image{i}", images[i]);
		Test.Assert(builder.Build());

		let regions = scope List<RectI>();
		for (int i < 4)
		{
			Test.Assert(builder.GetRegion(scope $"image{i}", let region), scope $"image{i} was packed");
			regions.Add(region);
		}

		var rows = scope List<int32>();
		for (let region in regions)
		{
			if (!rows.Contains(region.Y))
				rows.Add(region.Y);
		}
		Test.Assert(rows.Count >= 2, scope $"everything landed on {rows.Count} row");

		// And wrapping did not make anything overlap.
		for (int i < regions.Count)
		{
			for (int j = i + 1; j < regions.Count; j++)
				Test.Assert(!Overlaps(regions[i], regions[j]), scope $"regions {i} and {j} overlap");
		}

		// Everything is inside the atlas.
		for (let region in regions)
		{
			Test.Assert(region.X + region.Width <= (int32)builder.Atlas.Width, "within the width");
			Test.Assert(region.Y + region.Height <= (int32)builder.Atlas.Height, "and the height");
		}
	}

	/// Padding keeps a gap between packed images, so a linear sampler at the edge of one
	/// does not pick up its neighbour.
	[Test]
	public static void PaddingLeavesAGapBetweenImages()
	{
		let a = Image.CreateSolidColor(8, 8, Color32.Red);
		let b = Image.CreateSolidColor(8, 8, Color32.Green);
		defer { delete a; delete b; }

		let builder = scope ImageAtlasBuilder(64, 256, 2);
		builder.AddImage("a", a);
		builder.AddImage("b", b);
		Test.Assert(builder.Build());

		Test.Assert(builder.GetRegion("a", let ra));
		Test.Assert(builder.GetRegion("b", let rb));

		let gap = (rb.X > ra.X) ? (rb.X - (ra.X + ra.Width)) : (ra.X - (rb.X + rb.Width));
		Test.Assert(gap >= 2, scope $"only {gap} pixels between them");
	}

	/// Too much to fit, even at the largest size allowed, is a real answer rather than a
	/// silently truncated atlas.
	[Test]
	public static void MoreThanFitsFailsRatherThanTruncating()
	{
		let big = Image.CreateSolidColor(64, 64, Color32.White);
		defer delete big;

		// A maximum of 32 cannot hold a 64 pixel image at any size it is allowed to try.
		let builder = scope ImageAtlasBuilder(16, 32, 1);
		builder.AddImage("big", big);

		Test.Assert(!builder.Build(), "it said so instead of packing part of it");
		Test.Assert(builder.Atlas == null, "and produced no atlas to mistake for a good one");
	}

	/// The atlas grows to the first power of two that fits, rather than starting at the
	/// maximum.
	[Test]
	public static void TheAtlasGrowsOnlyAsFarAsItNeedsTo()
	{
		let small = Image.CreateSolidColor(8, 8, Color32.White);
		defer delete small;

		let builder = scope ImageAtlasBuilder(16, 512, 1);
		builder.AddImage("small", small);
		Test.Assert(builder.Build());

		Test.Assert(builder.Atlas.Width == 16, scope $"grew to {builder.Atlas.Width} for one small image");
		Test.Assert(builder.Atlas.Height == 16);
	}

	/// A size that is not a power of two is rounded up, and zero is lifted to one rather
	/// than wrapping around.
	[Test]
	public static void SizesAreRoundedUpToPowersOfTwo()
	{
		let image = Image.CreateSolidColor(4, 4, Color32.White);
		defer delete image;

		let odd = scope ImageAtlasBuilder(100, 300, 1);
		odd.AddImage("a", image);
		Test.Assert(odd.Build());
		Test.Assert(odd.Atlas.Width == 128, scope $"100 rounded to {odd.Atlas.Width}");

		// Zero is the case the wrapping arithmetic exists for.
		let zero = scope ImageAtlasBuilder(0, 64, 1);
		zero.AddImage("a", image);
		Test.Assert(zero.Build());
		Test.Assert(zero.Atlas.Width >= 1, scope $"zero became {zero.Atlas.Width}");
	}

	/// Rebuilding replaces the previous result rather than accumulating regions from it.
	[Test]
	public static void RebuildingReplacesThePreviousResult()
	{
		let image = Image.CreateSolidColor(8, 8, Color32.White);
		defer delete image;

		let builder = scope ImageAtlasBuilder(32, 256, 1);
		builder.AddImage("only", image);

		Test.Assert(builder.Build());
		let firstWidth = builder.Atlas.Width;
		Test.Assert(builder.Build(), "building twice is allowed");
		Test.Assert(builder.Atlas.Width == firstWidth, "and gives the same answer");
		Test.Assert(builder.GetRegion("only", let _));
	}

	private static bool Overlaps(RectI a, RectI b)
	{
		return (a.X < b.X + b.Width) && (b.X < a.X + a.Width)
			&& (a.Y < b.Y + b.Height) && (b.Y < a.Y + a.Height);
	}
}
