using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Model;
using Sedulous.Texture.Pipeline;

namespace Sedulous.ModelImporter.Tests;

/// Dropping a model file: what lands in the project.
class ModelFanOutTests
{
	[Test]
	public static void TheImporterClaimsTheModelExtensions()
	{
		let importer = scope ModelFileImporter();
		Test.Assert(importer.Accepts("glb"));
		Test.Assert(importer.Accepts("gltf"));
		Test.Assert(importer.Accepts("fbx"));
		Test.Assert(importer.Accepts("obj"));
		Test.Assert(!importer.Accepts("png"));
	}

	/// Everything inside the file becomes its own asset in a subgroup named after the file,
	/// and the manifest records what they are and how the hierarchy arranges them.
	[Test]
	public static void EverythingInTheModelFansOutIntoItsOwnSubgroup()
	{
		let fixture = scope ImportFixture("scratch_model_fanout");
		let dropped = scope String();
		fixture.WriteDroppedFile("character.glb", "not read: the model arrives prepared",
			dropped);

		let prepared = scope LoadedModel();
		ModelFixture.Character(prepared.Model);

		let importer = scope ModelFileImporter();
		let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, null,
			prepared, null);
		Test.Assert(imported case .Ok);
		let instance = imported.Value;
		Test.Assert(instance.TypeName == "Sedulous.ModelImporter.ModelManifestAsset");

		let group = fixture.RootGroup.GetGroup("character");
		Test.Assert(group != null);

		let manifest = ImportFixture.ReadManifest(instance);
		Test.Assert(manifest != null);
		defer delete manifest;

		Test.Assert(manifest.Manifest.MeshGuid.Count == 2);
		Test.Assert(manifest.Manifest.MaterialGuid.Count == 1);
		Test.Assert(manifest.Manifest.SkeletonGuid != Guid.Empty);
		Test.Assert(manifest.Manifest.AnimationGuid.Count == 1);
		Test.Assert(manifest.Manifest.NodeParent.Count == 4);
		// The skinned mesh is flagged as one, and the prop beside it is not.
		Test.Assert(manifest.Manifest.MeshSkinned[0]);
		Test.Assert(!manifest.Manifest.MeshSkinned[1]);

		// The provenance copy lands in the sources tree under the dropped file's own name.
		let copied = scope String();
		fixture.SubPath("Sources/character.glb", copied);
		Test.Assert(FileExists(copied));
	}

	/// The asset takes the image's FILE STEM, not the name authored inside the model: the
	/// fixture's image is named after something it is not, which is the shape that once
	/// produced an asset matching neither its file nor its contents.
	[Test]
	public static void ATextureIsNamedAfterItsFileAndRecordsItsProvenance()
	{
		let fixture = scope ImportFixture("scratch_model_texture_names");
		let dropped = scope String();
		fixture.WriteDroppedFile("character.glb", "x", dropped);

		let prepared = scope LoadedModel();
		ModelFixture.Character(prepared.Model);

		let importer = scope ModelFileImporter();
		let imported = importer.Import(dropped, fixture.Context, fixture.RootGroup, null,
			prepared, null);
		Test.Assert(imported case .Ok);

		let group = imported.Value.OwningGroup;
		Test.Assert(group.GetInstance("authored_name_lies") == null);
		let texture = group.GetInstance("Texture");
		Test.Assert(texture != null);

		let object = texture.ReadObject();
		Test.Assert(object != null);
		let asset = Internal.UnsafeCastToObject(Internal.UnsafeCastToPtr(object)) as TextureAsset;
		Test.Assert(asset != null);
		defer delete asset;
		Test.Assert(asset.SourceHint == "textures/Texture.png");
		Test.Assert(asset.EmbeddedWidth == 2);
		Test.Assert(asset.EmbeddedHeight == 2);
	}

	/// Re-dropping the SAME file with the group intact REUSES every instance: the identities
	/// survive, so placed references and generated prefabs keep working, and nothing
	/// duplicates itself under a numbered name.
	[Test]
	public static void ReImportingReusesTheInstancesItAlreadyCreated()
	{
		let fixture = scope ImportFixture("scratch_model_reimport");
		let dropped = scope String();
		fixture.WriteDroppedFile("character.glb", "x", dropped);

		let importer = scope ModelFileImporter();

		let first = scope LoadedModel();
		ModelFixture.Character(first.Model);
		let firstImport = importer.Import(dropped, fixture.Context, fixture.RootGroup, null,
			first, null);
		Test.Assert(firstImport case .Ok);

		let group = fixture.RootGroup.GetGroup("character");
		Test.Assert(group != null);
		let before = scope Dictionary<String, Guid>();
		defer { for (let name in before.Keys) delete name; }
		for (let instance in group.Instances)
			before[new String(instance.Name)] = instance.Id;
		Test.Assert(before.Count >= 3);

		let second = scope LoadedModel();
		ModelFixture.Character(second.Model);
		let secondImport = importer.Import(dropped, fixture.Context, fixture.RootGroup, null,
			second, null);
		Test.Assert(secondImport case .Ok);
		Test.Assert(secondImport.Value.Id == firstImport.Value.Id);

		let after = fixture.RootGroup.GetGroup("character");
		Test.Assert(after.Instances.Count == before.Count); // nothing duplicated
		for (let instance in after.Instances)
		{
			Test.Assert(before.TryGetValue(scope String(instance.Name), let id));
			Test.Assert(id == instance.Id); // the same identity, not a fresh one
		}
	}
}
