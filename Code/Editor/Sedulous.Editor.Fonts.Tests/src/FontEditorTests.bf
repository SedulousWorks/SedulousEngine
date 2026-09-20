using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Image;
using Sedulous.VFS;
using Sedulous.Fonts.Pipeline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Fonts.Tests;

/// The font editor's registration, size list, undo snapshot and thumbnail.
class FontEditorTests
{
	[Test]
	public static void RegisteringRoutesFontAssetToTheFactory()
	{
		let context = scope EditorContext();
		FontEditor.Register(context);
		let found = context.Pages.FindFactory(typeof(FontAsset));
		Test.Assert((found != null) && (found.PrimaryType == typeof(FontAsset)));
	}

	[Test]
	public static void TheSizeListParsesAndFormatsAsThePageShowsIt()
	{
		let sizes = scope List<float>();
		Test.Assert(FontSizes.Parse("12, 14.5; 24 32", sizes));
		Test.Assert(sizes.Count == 4);
		Test.Assert((sizes[0] == 12.0f) && (Math.Abs(sizes[1] - 14.5f) < 1e-4f) && (sizes[3] == 32.0f));
		Test.Assert(FontSizes.Format(sizes, .. scope .()) == "12, 14.5, 24, 32");

		// Junk, an empty list, zero and an oversize entry are refused, leaving the list alone.
		Test.Assert(!FontSizes.Parse("12, abc", sizes));
		Test.Assert(!FontSizes.Parse("", sizes));
		Test.Assert(!FontSizes.Parse("0, 12", sizes));
		Test.Assert(!FontSizes.Parse("600", sizes));
		Test.Assert(sizes.Count == 4);
	}

	[Test]
	public static void TheSnapshotRoundTripsTheBakeSettings()
	{
		FontsPipeline.RegisterAll();
		let a = scope FontAsset();
		a.FileName.Set("Fonts/Roboto-Bold.ttf");
		a.Family.Set("Roboto");
		a.Mode = .DistanceField;
		a.Sizes.Clear();
		a.Sizes.Add(18.0f);
		a.DistanceFieldSize = 64.0f;
		a.FirstCodepoint = 65;
		a.LastCodepoint = 90;
		a.AtlasWidth = 256;
		a.AtlasHeight = 128;
		let blob = scope List<uint8>();
		FontAssetEdit.Snapshot(a, blob);
		let b = scope FontAsset();
		Test.Assert(FontAssetEdit.Apply(b, blob));
		Test.Assert(b.FileName.Value == "Fonts/Roboto-Bold.ttf");
		Test.Assert((b.Family == "Roboto") && (b.Mode == .DistanceField));
		Test.Assert((b.Sizes.Count == 1) && (b.Sizes[0] == 18.0f));
		Test.Assert((b.DistanceFieldSize == 64.0f) && (b.FirstCodepoint == 65) && (b.LastCodepoint == 90));
		Test.Assert((b.AtlasWidth == 256) && (b.AtlasHeight == 128));
		Test.Assert(!FontAssetEdit.Apply(b, blob));
	}

	[Test]
	public static void TheThumbnailRasterizesAGlyphSampleFromTtfBytes()
	{
		let root = FindDataRoot(.. scope .());
		Test.Assert(!root.IsEmpty);
		let ttf = scope List<uint8>();
		Test.Assert(File.ReadAll(DataPath(root, "Assets/fonts/roboto/Roboto-Bold.ttf", .. scope .()), ttf) case .Ok);
		Test.Assert(ttf.Count > 0);

		let generator = scope FontThumbnailGenerator();
		let tile = scope Image();
		Test.Assert(generator.Generate(ttf, tile) case .Ok);
		Test.Assert(tile.Width == ThumbnailService.cThumbnailSize);
		let px = tile.PixelData;
		int inked = 0;
		for (int p = 0; p < px.Length; p += 4)
		{
			if (px[p] > 60)
				inked++;
		}
		Test.Assert(inked > 200); // "Ag" at 72px covers far more than noise

		// A coverage bake through the page's path lands an atlas too.
		let request = scope FontBakeRequest();
		request.Valid = true;
		request.Path.Set(DataPath(root, "Assets/fonts/roboto/Roboto-Bold.ttf", .. scope .()));
		request.Size = 24.0f;
		request.FirstCodepoint = (int32)'A';
		request.LastCodepoint = (int32)'Z';
		request.AtlasWidth = 256;
		request.AtlasHeight = 256;
		let outcome = scope FontBakeOutcome();
		FontBake.Run(request, outcome);
		Test.Assert((outcome.Image != null) && (outcome.Glyphs == 26) && (outcome.Size == 24.0f));
	}

	[Test]
	public static void TheThumbnailRejectsNonFontBytes()
	{
		let junk = scope uint8[32];
		let generator = scope FontThumbnailGenerator();
		let tile = scope Image();
		Test.Assert(generator.Generate(junk, tile) case .Err);

		// An invalid request bakes nothing, and keeps its generation.
		let request = scope FontBakeRequest();
		request.Generation = 7;
		let outcome = scope FontBakeOutcome();
		FontBake.Run(request, outcome);
		Test.Assert((outcome.Image == null) && (outcome.Generation == 7));
	}
}
