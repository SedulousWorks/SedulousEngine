namespace Sedulous.GUI.Tests;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Images;

class ThemeAtlasTests
{
	private static OwnedImageData MakeTestImage(uint32 w, uint32 h, uint8 r, uint8 g, uint8 b)
	{
		let data = new uint8[w * h * 4];
		for (uint32 i = 0; i < w * h; i++)
		{
			data[i * 4] = r;
			data[i * 4 + 1] = g;
			data[i * 4 + 2] = b;
			data[i * 4 + 3] = 255;
		}
		return new OwnedImageData(w, h, .RGBA8, data);
	}

	// === ThemeAtlas ===

	[Test]
	public static void ThemeAtlas_CreateImageDrawable()
	{
		let atlas = scope ThemeAtlas();
		let img = MakeTestImage(32, 32, 255, 0, 0);
		defer delete img;

		atlas.AddImage("button", img);
		Test.Assert(atlas.Build());

		let drawable = atlas.CreateImageDrawable("button");
		defer delete drawable;
		Test.Assert(drawable != null);
		Test.Assert(drawable.AtlasImage != null);
	}

	[Test]
	public static void ThemeAtlas_CreateNineSliceDrawable()
	{
		let atlas = scope ThemeAtlas();
		let img = MakeTestImage(32, 32, 255, 0, 0);
		defer delete img;

		atlas.AddImage("panel", img);
		Test.Assert(atlas.Build());

		let slices = NineSlice(4, 4, 4, 4);
		let drawable = atlas.CreateNineSliceDrawable("panel", slices);
		defer delete drawable;
		Test.Assert(drawable != null);
		Test.Assert(drawable.Slices.Left == 4);
	}

	[Test]
	public static void ThemeAtlas_CreateDrawable_BeforeBuild_ReturnsNull()
	{
		let atlas = scope ThemeAtlas();
		let drawable = atlas.CreateImageDrawable("missing");
		Test.Assert(drawable == null);
	}

	[Test]
	public static void ThemeAtlas_CreateStateDrawable()
	{
		let atlas = scope ThemeAtlas();
		let imgNormal = MakeTestImage(16, 16, 200, 200, 200);
		let imgHover = MakeTestImage(16, 16, 220, 220, 220);
		defer { delete imgNormal; delete imgHover; }

		atlas.AddImage("btn_normal", imgNormal);
		atlas.AddImage("btn_hover", imgHover);
		Test.Assert(atlas.Build());

		(ControlState, StringView)[2] states = .((.Normal, "btn_normal"), (.Hover, "btn_hover"));
		let stateDrawable = atlas.CreateStateDrawable(states);
		defer delete stateDrawable;
		Test.Assert(stateDrawable != null);
	}

	[Test]
	public static void ThemeAtlas_MultipleImages_AllPackable()
	{
		let atlas = scope ThemeAtlas();
		let img1 = MakeTestImage(64, 64, 255, 0, 0);
		let img2 = MakeTestImage(32, 32, 0, 255, 0);
		let img3 = MakeTestImage(48, 48, 0, 0, 255);
		defer { delete img1; delete img2; delete img3; }

		atlas.AddImage("red", img1);
		atlas.AddImage("green", img2);
		atlas.AddImage("blue", img3);
		Test.Assert(atlas.Build());

		let d1 = atlas.CreateImageDrawable("red");
		let d2 = atlas.CreateImageDrawable("green");
		let d3 = atlas.CreateImageDrawable("blue");
		defer { delete d1; delete d2; delete d3; }

		Test.Assert(d1 != null);
		Test.Assert(d2 != null);
		Test.Assert(d3 != null);
	}

	// === ThemeImageSet ===

	[Test]
	public static void ThemeImageSet_AddImage()
	{
		let set = scope ThemeImageSet();
		let img = MakeTestImage(16, 16, 255, 0, 0);
		defer delete img;

		set.AddImage("button:Background", img);
		let entry = set.GetEntry("button:Background");
		Test.Assert(entry.HasValue);
		Test.Assert(!entry.Value.IsNineSlice);
	}

	[Test]
	public static void ThemeImageSet_AddImage_NineSlice()
	{
		let set = scope ThemeImageSet();
		let img = MakeTestImage(32, 32, 255, 0, 0);
		defer delete img;

		set.AddImage("panel:Background", img, NineSlice(4, 4, 4, 4));
		let entry = set.GetEntry("panel:Background");
		Test.Assert(entry.HasValue);
		Test.Assert(entry.Value.IsNineSlice);
		Test.Assert(entry.Value.Slices.Left == 4);
	}

	[Test]
	public static void ThemeImageSet_AddStateImages()
	{
		let set = scope ThemeImageSet();
		let normal = MakeTestImage(16, 16, 200, 200, 200);
		let hover = MakeTestImage(16, 16, 220, 220, 220);
		defer { delete normal; delete hover; }

		set.AddStateImages("button:Background", normal, hover);

		// State images are added with internal keys.
		let normalEntry = set.GetEntry("button:Background_Normal");
		Test.Assert(normalEntry.HasValue);
		let hoverEntry = set.GetEntry("button:Background_Hover");
		Test.Assert(hoverEntry.HasValue);
	}

	[Test]
	public static void ThemeImageSet_NullImage_Ignored()
	{
		let set = scope ThemeImageSet();
		set.AddImage("key", null);
		Test.Assert(!set.GetEntry("key").HasValue);
	}
}
