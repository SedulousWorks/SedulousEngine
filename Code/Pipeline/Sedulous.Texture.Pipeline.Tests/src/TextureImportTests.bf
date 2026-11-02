using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core.IO;
using Sedulous.Image;
using Sedulous.Pipeline.Importer;
using Sedulous.Texture;
using Sedulous.Texture.Compression;
using Sedulous.Texture.Pipeline;

namespace Sedulous.Texture.Pipeline.Tests;

/// The importer: what preset a dropped file gets, and what the plan says it would create.
class TextureImportTests
{
	[Test]
	public static void TheAuthoringHelpersApplyTheRightPreset()
	{
		let surface = scope TextureAsset();
		TextureImporter.Import2D("art/brick.png", .Srgb, surface);
		Test.Assert(surface.FileName.Value == "art/brick.png");
		Test.Assert(surface.ColorSpace == .Srgb);
		Test.Assert(surface.GenerateMipmaps);
		Test.Assert(surface.MinFilter == .MipmapLinear);

		let sky = scope TextureAsset();
		TextureImporter.ImportEquirectangular("sky/dusk.hdr", sky);
		Test.Assert(sky.ColorSpace == .Linear);
		Test.Assert(sky.WrapU == .ClampToEdge);
		Test.Assert(!sky.GenerateMipmaps);
	}

	[Test]
	public static void TheProfilesConfigureUsageAndColourSpaceWithTheSampler()
	{
		let asset = scope TextureAsset();

		asset.SetupForNormalMap();
		Test.Assert(asset.Usage == .Normal);
		Test.Assert(asset.ColorSpace == .Linear);
		Test.Assert(asset.GenerateMipmaps, "it rides the surface sampler");
		Test.Assert(asset.WrapU == .Repeat);

		asset.SetupForDataMask();
		Test.Assert(asset.Usage == .Mask);
		Test.Assert(asset.ColorSpace == .Linear);

		asset.SetupForUI();
		Test.Assert(asset.Usage == .Color);
		Test.Assert(asset.ColorSpace == .Srgb);
		Test.Assert(!asset.GenerateMipmaps);

		asset.SetupForEquirectangularSkybox();
		Test.Assert(asset.Usage == .HDR);
		Test.Assert(asset.ColorSpace == .Linear);

		asset.SetupForCubemapSkybox();
		Test.Assert(asset.Usage == .HDR);
		Test.Assert(asset.ColorSpace == .Linear);
		Test.Assert(asset.Shape == .Cubemap);
	}

	[Test]
	public static void UsageIsInferredFromTexturePackNameTokens()
	{
		Test.Assert(TextureUsageInference.Infer("foo_nor_gl_4k") == .Normal);
		Test.Assert(TextureUsageInference.Infer("brick_NORMAL") == .Normal);
		Test.Assert(TextureUsageInference.Infer("Rock030_NormalGL") == .Normal); // ambientCG
		Test.Assert(TextureUsageInference.Infer("Rock030_1K-JPG_NormalDX") == .Normal);
		Test.Assert(TextureUsageInference.Infer("bar_disp_2k") == .Mask);
		Test.Assert(TextureUsageInference.Infer("ground_rough_1k") == .Mask);
		Test.Assert(TextureUsageInference.Infer("kit_orm") == .Mask);
		Test.Assert(TextureUsageInference.Infer("trim_AO_2k") == .Mask);

		// Everything else keeps the colour default, including the near misses the boundary
		// rule exists for: a token only counts when a separator, a digit or the end follows it.
		Test.Assert(TextureUsageInference.Infer("grass_diff") == .Color);
		Test.Assert(TextureUsageInference.Infer("my_armor") == .Color);
		Test.Assert(TextureUsageInference.Infer("town_north") == .Color);

		// The token that decided it, for the import window's note.
		let token = scope String();
		Test.Assert(TextureUsageInference.Infer("foo_nor_gl_4k", token) == .Normal);
		Test.Assert(token == "_nor");
		Test.Assert(TextureUsageInference.Infer("kit_orm", token..Clear()) == .Mask);
		Test.Assert(token == "_orm");
		Test.Assert(TextureUsageInference.Infer("grass_diff", token..Clear()) == .Color);
		Test.Assert(token.IsEmpty);
	}

	/// The settings start as the file's preset, its usage guessed from its name with the reason
	/// in the usage's note; the import takes what is set.
	[Test]
	public static void TheSettingsStartAsTheFilesPresetItsUsageGuessedWithTheReasonTheImportTakesThem()
	{
		let importer = scope TextureFileImporter();
		let created = importer.CreateOptions();
		defer delete created;
		let options = created as TextureImportOptions;
		Test.Assert(options != null);
		Test.Assert(options.GetSettings(.. scope .()).Count == 5);
		Test.Assert(options.FindSetting("Usage", let usage));

		// A normal map by its name: Normal and linear, and the note says which token decided it.
		importer.InitializeOptions("/somewhere/rock_nor_gl.png", options);
		Test.Assert(options.Usage == .Normal);
		Test.Assert(options.ColorSpace == .Linear);
		Test.Assert(options.GenerateMipmaps);
		let effect = scope String();
		let reason = scope String();
		importer.DescribeSetting("/somewhere/rock_nor_gl.png", options, null, usage, effect, reason);
		Test.Assert(effect == "Its name has \"_nor\"", scope String(effect));
		Test.Assert(reason.IsEmpty);
		// Another usage chosen: the note says what the name suggested.
		options.Usage = .Mask;
		importer.DescribeSetting("/somewhere/rock_nor_gl.png", options, null, usage, effect..Clear(), reason);
		Test.Assert(effect == "Its name suggests Normal", scope String(effect));
		// A plain name: Color, sRGB, and nothing to say.
		importer.InitializeOptions("/somewhere/brick.png", options);
		Test.Assert(options.Usage == .Color);
		Test.Assert(options.ColorSpace == .Srgb);
		importer.DescribeSetting("/somewhere/brick.png", options, null, usage, effect..Clear(), reason);
		Test.Assert(effect.IsEmpty);
		// An .hdr: an environment, said so.
		importer.InitializeOptions("/somewhere/dusk.hdr", options);
		Test.Assert(options.Usage == .HDR);
		Test.Assert(!options.GenerateMipmaps);
		importer.DescribeSetting("/somewhere/dusk.hdr", options, null, usage, effect..Clear(), reason);
		Test.Assert(effect == "An .hdr is an environment");

		// The import takes what is set: a mask with no mipmaps, clamped.
		let fixture = scope TexturePipelineFixture("import_settings");
		let loose = scope String();
		fixture.PathIn("brick.png", loose);
		WriteFile(loose, scope List<uint8>() { 0x89, 0x50, 0x4E, 0x47, 1, 2 }).IgnoreError();
		options.Usage = .Mask;
		options.ColorSpace = .Linear;
		options.GenerateMipmaps = false;
		options.Wrap = .ClampToEdge;
		let context = scope ImportContext(fixture.Root);
		let instance = importer.Import(loose, context, fixture.Database.RootGroup, options, null, null);
		Test.Assert(instance case .Ok);
		let object = instance.Value.ReadObject();
		defer delete object;
		let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as TextureAsset;
		Test.Assert(asset != null);
		Test.Assert(asset.Usage == .Mask);
		Test.Assert(asset.ColorSpace == .Linear);
		Test.Assert(!asset.GenerateMipmaps);
		Test.Assert(asset.WrapU == .ClampToEdge);
		Test.Assert(asset.WrapV == .ClampToEdge);
	}

	[Test]
	public static void ADroppedFileIsCopiedIntoSourcesAndLinked()
	{
		let fixture = scope TexturePipelineFixture("import");

		// A loose file outside the project. The bytes need not be a real image: the IMPORT
		// copies and links, and the cook is what would decode.
		let loose = scope String();
		fixture.PathIn("loose_wall.png", loose);
		WriteFile(loose, scope List<uint8>() { 0x89, 0x50, 0x4E, 0x47, 4, 5 }).IgnoreError();

		let importer = scope TextureFileImporter();
		let context = scope ImportContext(fixture.Root);
		let instance = importer.Import(loose, context, fixture.Database.RootGroup, null, null, null);
		Test.Assert(instance case .Ok);

		let object = instance.Value.ReadObject();
		defer delete object;
		let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as TextureAsset;
		Test.Assert(asset != null);
		Test.Assert(asset.FileName.Value == "loose_wall.png");
		// An unrecognised name takes the surface preset.
		Test.Assert(asset.Usage == .Color);
		Test.Assert(asset.GenerateMipmaps);
	}

	[Test]
	public static void ANormalMapSuffixImportsAsLinearNormalUsage()
	{
		let fixture = scope TexturePipelineFixture("import_normal");

		let loose = scope String();
		fixture.PathIn("loose_wall_nor_4k.png", loose);
		WriteFile(loose, scope List<uint8>() { 0x89, 0x50, 0x4E, 0x47 }).IgnoreError();

		let importer = scope TextureFileImporter();
		let context = scope ImportContext(fixture.Root);
		let instance = importer.Import(loose, context, fixture.Database.RootGroup, null, null, null);
		Test.Assert(instance case .Ok);

		let object = instance.Value.ReadObject();
		defer delete object;
		let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as TextureAsset;
		Test.Assert(asset != null);
		Test.Assert(asset.Usage == .Normal);
		Test.Assert(asset.ColorSpace == .Linear);
	}

	[Test]
	public static void DescribeImportListsOneAssetAndASelectionRenamesIt()
	{
		let importer = scope TextureFileImporter();

		let plan = scope ImportPlan();
		importer.DescribeImport("wall.png", null, null, plan);
		Test.Assert(plan.Entries.Count == 1);
		Test.Assert(plan.Entries[0].Kind == .Asset);
		Test.Assert(plan.Entries[0].SourceName == "wall");
		Test.Assert(plan.Entries[0].TargetName == "wall");

		// The review dialog's rename travels on the BASE options, this importer having none of
		// its own, and the creation site reads it back through the selection accessor.
		let options = scope ImportOptions();
		options.Selection.Add(new ImportPlanEntry(.Asset, "wall", "wall_albedo"));
		Test.Assert(options.SelectionName(.Asset, "wall") == "wall_albedo");
		Test.Assert(options.SelectionEnabled(.Asset, "wall"));

		// And a resource the selection says nothing about is still imported: no opinion is not
		// the same as an exclusion.
		Test.Assert(options.SelectionEnabled(.Asset, "something-else"));
	}
}
