using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.ModelImporter.Tests;

/// What the import dialog offers, and what turning it off actually stops.
class ModelImportOptionTests
{
	[Test]
	public static void TheDefaultsImportEverythingAndTheRestAreOptIn()
	{
		let importer = scope ModelFileImporter();
		let created = importer.CreateOptions();
		Test.Assert(created != null);
		defer delete created;

		let options = created as ModelImportOptions;
		Test.Assert(options != null);
		Test.Assert(options.ImportTextures);
		Test.Assert(options.ImportMaterials);
		Test.Assert(options.ImportAnimations);
		Test.Assert(options.GeneratePrefab);
		Test.Assert(options.GenerateLods);
		Test.Assert(!options.GenerateScene);
		Test.Assert(!options.GenerateCollision);
		Test.Assert(!options.CollisionConvex);
		Test.Assert(!options.RootMotion);

		let settings = options.GetSettings(.. scope .());
		Test.Assert(settings.Count == 11); // Scale and Up axis first, then Root motion and Generate LODs among the rest
		Test.Assert(ImportOptions.SettingLabel(settings[0], .. scope .()) == "Scale");
		Test.Assert(ImportOptions.SettingLabel(settings[2], .. scope .()) == "Textures");
		Test.Assert(options.Scale == 1.0f);
		Test.Assert(options.UpAxis == .Y);
		Test.Assert(options.FindSetting("Generate collision", ?));
		Test.Assert(options.FindSetting("convex collision", let convex));
		Test.Assert(convex.GetCustomAttribute<VisibleWhenAttribute>() case .Ok, "shown only while Generate collision is on");
	}

	/// Geometry ALWAYS imports; the three toggles gate everything else, and nothing of those
	/// types is left in the group.
	[Test]
	public static void TurningTheTogglesOffLeavesGeometryAlone()
	{
		let fixture = scope ImportFixture("scratch_model_options");
		let dropped = scope String();
		fixture.WriteDroppedFile("character.glb", "x", dropped);

		let prepared = scope LoadedModel();
		ModelFixture.Character(prepared.Model);

		let options = scope ModelImportOptions();
		options.ImportTextures = false;
		options.ImportMaterials = false;
		options.ImportAnimations = false;

		let importer = scope ModelFileImporter();
		let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, options,
			prepared, null);
		Test.Assert(imported case .Ok);

		let manifest = ImportFixture.ReadManifest(imported.Value);
		Test.Assert(manifest != null);
		defer delete manifest;
		Test.Assert(manifest.Manifest.MeshGuid.Count == 2);
		Test.Assert(manifest.Manifest.MaterialGuid.IsEmpty);
		Test.Assert(manifest.Manifest.SkeletonGuid == Guid.Empty);
		Test.Assert(manifest.Manifest.AnimationGuid.IsEmpty);

		for (let instance in imported.Value.OwningGroup.Instances)
		{
			Test.Assert(instance.TypeName != "Sedulous.Texture.Pipeline.TextureAsset");
			Test.Assert(instance.TypeName != "Sedulous.Materials.Pipeline.MaterialAsset");
			Test.Assert(instance.TypeName != "Sedulous.Animation.Pipeline.SkeletonAsset");
			Test.Assert(instance.TypeName != "Sedulous.Animation.Pipeline.AnimationClipAsset");
		}
	}
}
