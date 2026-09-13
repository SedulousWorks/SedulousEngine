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
		Test.Assert(TextureUsageInference.Infer("bar_disp_2k") == .Mask);
		Test.Assert(TextureUsageInference.Infer("ground_rough_1k") == .Mask);
		Test.Assert(TextureUsageInference.Infer("kit_orm") == .Mask);
		Test.Assert(TextureUsageInference.Infer("trim_AO_2k") == .Mask);

		// Everything else keeps the colour default, including the near misses the boundary
		// rule exists for: a token only counts when a separator, a digit or the end follows it.
		Test.Assert(TextureUsageInference.Infer("grass_diff") == .Color);
		Test.Assert(TextureUsageInference.Infer("my_armor") == .Color);
		Test.Assert(TextureUsageInference.Infer("town_north") == .Color);
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
