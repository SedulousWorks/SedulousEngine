using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Fonts;
using Sedulous.Fonts.Coverage.Baker;
using Sedulous.Fonts.Resource;
using Sedulous.Fonts.TrueType;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.RHI.TestSupport;
using Sedulous.VG;

namespace Sedulous.VG.Backend.Tests;

/// The baked font net.
///
/// The SAME text at the SAME size, once through the service that rasterises on demand, which
/// is the development path, and once through the BAKED wrappers a cooked font resource loads
/// into, must come out as near enough the same pixels: the bake IS a snapshot of that same
/// rasteriser. A divergence means the baked draw path is lying about its regions, coordinates
/// or metrics, which is what jumbled text on screen actually is.
class BakedFontProbeTests
{
	private const String cProbeText = "AVWaji 42";
	private const uint32 cSize = VGSceneRenderer.Size;

	/// Walks up for the repository's own font, the same way the shader root is found.
	private static bool FindTestFont(String outPath)
	{
		let current = scope String();
		GetCurrentDirectory(current);

		for (int depth < 8)
		{
			let candidate = scope:: String();
			PathJoin(current, "Data/Assets/fonts/roboto/Roboto-Regular.ttf", candidate);
			if (File.Exists(candidate))
			{
				outPath.Set(candidate);
				return true;
			}

			let parent = scope:: String();
			PathParent(current, parent);
			if (parent.IsEmpty || (parent == current))
				break;
			current.Set(parent);
		}
		return false;
	}

	private static void SaveProbe(CapturedImage pixels, StringView name)
	{
		if ((pixels == null) || !pixels.Valid)
			return;

		let image = scope Image(cSize, cSize, .RGBA8, .(pixels.Rgba.Ptr, pixels.Rgba.Count));
		ImageIO.SaveImage(image, name, .PNG).IgnoreError();
	}

	/// How many pixels have no acceptable match anywhere in a one pixel neighbourhood.
	///
	/// The slack absorbs the sub pixel placement difference between the on demand path's
	/// floating point quads and the baked path's integer regions, while still catching the
	/// jumble: overlapping or wrongly scaled glyphs disagree however far you look.
	private static double MismatchFraction(CapturedImage a, CapturedImage b)
	{
		if ((a == null) || (b == null) || !a.Valid || !b.Valid)
			return 1.0;

		var mismatched = 0;
		for (uint32 y = 0; y < cSize; y++)
		{
			for (uint32 x = 0; x < cSize; x++)
			{
				let pa = a.At(x, y);
				var best = 255;

				for (int32 dy = -1; dy <= 1; dy++)
				{
					for (int32 dx = -1; dx <= 1; dx++)
					{
						let nx = (int32)x + dx;
						let ny = (int32)y + dy;
						if ((nx < 0) || (ny < 0) || (nx >= (int32)cSize) || (ny >= (int32)cSize))
							continue;

						best = Math.Min(best, ChannelDelta(pa, b.At((uint32)nx, (uint32)ny)));
					}
				}

				if (best > 32)
					mismatched++;
			}
		}

		return (double)mismatched / ((double)cSize * cSize);
	}

	private static int32 ChannelDelta(uint8* a, uint8* b)
	{
		var delta = (int32)0;
		for (int c < 3)
		{
			let d = (int32)a[c] - (int32)b[c];
			delta = Math.Max(delta, (d < 0) ? -d : d);
		}
		return delta;
	}

	private static int InkedPixels(CapturedImage image)
	{
		if ((image == null) || !image.Valid)
			return 0;

		var inked = 0;
		for (uint32 y = 0; y < cSize; y++)
		{
			for (uint32 x = 0; x < cSize; x++)
			{
				if (image.At(x, y)[0] > 40)
					inked++;
			}
		}
		return inked;
	}

	[Test]
	public static void TheBakedPathMatchesTheOnDemandPath()
	{
		let fixture = scope VGProbeFixture();
		if (!fixture.Ready)
			return;

		let fontPath = scope String();
		if (!FindTestFont(fontPath))
			return;

		let ttfBytes = scope List<uint8>();
		if (File.ReadAll(fontPath, ttfBytes) case .Err)
			return;
		Test.Assert(!ttfBytes.IsEmpty, "the font file was read");

		// Path A: rasterise on demand, which is the development path and the ground truth.
		let ttfService = scope TrueTypeFontService();
		Test.Assert(ttfService.LoadFont("Roboto", fontPath) == .Success);

		let ttfFont = ttfService.GetFont("Roboto", 20.0f);
		Test.Assert(ttfFont != null, "the on demand font loaded");

		// The service serves its CLOSEST loaded size rather than the one asked for, so the
		// bake has to target the size strip A actually rendered at, or this compares two
		// different sizes and calls the difference a bug.
		let servedSize = ttfFont.Font.PixelHeight;

		let ttfPixels = VGSceneRenderer.RenderScene(fixture, scope (context) =>
			{
				context.SetFontService(ttfService);
				context.DrawText(cProbeText, ttfFont, Float2(4.0f, 60.0f), Color(1, 1, 1, 1));
			});
		defer delete ttfPixels;

		// Path B: the BAKED wrappers, which are the very objects a cooked font resource loads
		// into.
		var options = FontLoadOptions.Default();
		options.PixelHeight = servedSize;

		if (!(FontBaker.Bake(.(ttfBytes.Ptr, ttfBytes.Count), options) case .Ok(let baked)))
		{
			Test.Assert(false, "the bake succeeded");
			return;
		}

		baked.Detach(let bakedFont, let bakedAtlas);
		delete baked;

		let product = new Font();
		product.SetFamily("Roboto");

		let entry = new FontEntry();
		entry.PixelHeight = servedSize;
		entry.Font = bakedFont;
		entry.Atlas = bakedAtlas;
		entry.AtlasImage = FontAtlasTexture.ExpandR8ToRGBA8(bakedAtlas);
		Test.Assert(entry.AtlasImage != null, "the atlas expanded");
		product.AddEntry(entry);

		let bakedService = scope ResourceFontService();
		bakedService.AddFont(product);
		defer delete product;

		let cookedFont = bakedService.GetFont("Roboto", servedSize);
		Test.Assert(cookedFont != null, "the baked font resolved");

		let bakedPixels = VGSceneRenderer.RenderScene(fixture, scope (context) =>
			{
				context.SetFontService(bakedService);
				context.DrawText(cProbeText, cookedFont, Float2(4.0f, 60.0f), Color(1, 1, 1, 1));
			});
		defer delete bakedPixels;

		// Written out for eyes on diagnosis when this fails.
		SaveProbe(ttfPixels, "font-probe-ttf.png");
		SaveProbe(bakedPixels, "font-probe-baked.png");

		Test.Assert((ttfPixels != null) && ttfPixels.Valid, "the on demand strip rendered");
		Test.Assert((bakedPixels != null) && bakedPixels.Valid, "the baked strip rendered");

		// Both drew SOMETHING...
		Test.Assert(InkedPixels(ttfPixels) > 100, "the on demand strip has ink");
		Test.Assert(InkedPixels(bakedPixels) > 100, "the baked strip has ink");

		// ...and the same something. Beyond the antialiasing noise the two must agree,
		// because one is a snapshot of the other.
		Test.Assert(MismatchFraction(ttfPixels, bakedPixels) < 0.02, "and they agree");
	}
}
