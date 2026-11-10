using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Editor.Core;
using Sedulous.Editor.App;
using Sedulous.Editor.Geometry;
using Sedulous.Pipeline.Importer; // ImportPlan, a texture part to show
using Sedulous.ModelImporter; // the importer's own read

namespace Sedulous.Editor.Geometry.Tests;

/// The import window's preview of a model file, without a host (no view): the file is read on the
/// editor's task pool, cooked into its cache folder and bound, and its facts and clips show; opened again
/// it binds from the cache at once. It takes the frame hooks the window drives. A file the loaders
/// cannot read opens nothing and says so.
class ModelFilePreviewTests
{
	[Test]
	public static void ReadOffTheMainThreadCookedAndBoundItsFactsAndClipsShownOpenedAgainFromTheCache()
	{
		let cache = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_model_file_preview", .. scope .());
		RemoveDirectoryRecursive(cache);
		Test.Assert(CreateDirectory(cache));
		defer RemoveDirectoryRecursive(cache);
		let root = FindDataRoot(.. scope .());
		Test.Assert(!root.IsEmpty);
		let fox = DataPath(root, "Tests/Models/FoxNested/glTF/Fox.gltf", .. scope .());
		let tasks = scope TaskPool(1);
		let services = scope AssetPageServices(); // no host: no view
		{
			let preview = scope ModelFilePreview(fox, cache, tasks, services);
			IImportPreviewFrames frames = preview;
			Test.Assert(frames != null, "the window drives its frames");
			int changed = 0;
			preview.SetOnChanged(new [&changed] () => { changed++; });
			Test.Assert(!preview.IsOpen, "still reading");
			Test.Assert(preview.Facts.IsEmpty);
			tasks.Finish();
			Test.Assert(preview.IsLoading, "cooked; its parts now load on the pool, a few a frame");
			Test.Assert(!preview.IsOpen);
			preview.FinishLoading();
			Test.Assert(changed == 1);
			Test.Assert(preview.IsOpen);
			// Fox.gltf: one mesh of 576 triangles, one material and texture, 24 bones, three clips.
			let facts = preview.Facts;
			Test.Assert(facts.Length == 6);
			Test.Assert(facts[0] == "Meshes 1");
			Test.Assert(facts[1] == "Triangles 576");
			Test.Assert(facts[2] == "Materials 1");
			Test.Assert(facts[3] == "Textures 1");
			Test.Assert(facts[4] == "Bones 24");
			Test.Assert(facts[5] == "Clips 3");
			Test.Assert(preview.Clips.Length == 3);
			Test.Assert(preview.Clips[0] == "Survey");
		}

		// Opened again, it loads what the first open cooked, with no read and no cook: its parts load
		// on the pool, never on the window's thread.
		{
			let again = scope ModelFilePreview(fox, cache, tasks, services);
			Test.Assert(again.IsLoading);
			Test.Assert(!again.IsOpen);
			again.FinishLoading();
			Test.Assert(again.IsOpen);
			Test.Assert(again.Facts.Length == 6);
		}

		// A file the loaders cannot read: nothing opens, no facts.
		let junk = PathJoin(cache, "junk.glb", .. scope .());
		let text = "not a model";
		Test.Assert(WriteFile(junk, .((uint8*)text.Ptr, text.Length)) case .Ok);
		let broken = scope ModelFilePreview(junk, cache, tasks, services);
		tasks.Finish();
		Test.Assert(!broken.IsOpen);
		Test.Assert(broken.Facts.IsEmpty);
	}

	/// Given the importer's read, it cooks that on the pool, never on the window's thread, and reads
	/// nothing itself.
	[Test]
	public static void GivenTheImportersReadItCooksThatOnThePoolAndReadsNothingItself()
	{
		let cache = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_model_file_preview_read", .. scope .());
		RemoveDirectoryRecursive(cache);
		Test.Assert(CreateDirectory(cache));
		defer RemoveDirectoryRecursive(cache);
		let root = FindDataRoot(.. scope .());
		Test.Assert(!root.IsEmpty);
		let fox = DataPath(root, "Tests/Models/FoxNested/glTF/Fox.gltf", .. scope .());
		let importer = scope ModelFileImporter();
		let prepared = importer.PrepareOnWorker(fox);
		defer delete prepared;
		let loaded = prepared as LoadedModel;
		Test.Assert(loaded != null);
		let tasks = scope TaskPool(1);
		let services = scope AssetPageServices(); // no host: no view
		let preview = scope ModelFilePreview(fox, cache, tasks, services, loaded.Model);
		Test.Assert(!preview.IsOpen, "its cook is a task: the window's thread goes on");
		Test.Assert(tasks.InFlight == 1, "the cook alone, no read of its own");
		tasks.Finish();
		preview.FinishLoading(); // its parts, then the bind
		Test.Assert(preview.IsOpen);
		Test.Assert(preview.Facts.Length == 6);
	}

	/// StopReading ends its cook before the import may change the importer's model; it then never
	/// opens.
	[Test]
	public static void StopReadingEndsItsCookBeforeTheImportMayChangeTheImportersModel()
	{
		let cache = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_model_file_preview_stop", .. scope .());
		RemoveDirectoryRecursive(cache);
		Test.Assert(CreateDirectory(cache));
		defer RemoveDirectoryRecursive(cache);
		let root = FindDataRoot(.. scope .());
		let fox = DataPath(root, "Tests/Models/FoxNested/glTF/Fox.gltf", .. scope .());
		let importer = scope ModelFileImporter();
		let prepared = importer.PrepareOnWorker(fox);
		defer delete prepared;
		let loaded = prepared as LoadedModel;
		Test.Assert(loaded != null);
		let tasks = scope TaskPool(1);
		let services = scope AssetPageServices(); // no host: no view
		let preview = scope ModelFilePreview(fox, cache, tasks, services, loaded.Model);
		preview.StopReading();
		Test.Assert(tasks.InFlight <= 1, "ended (cancelled, or finished just before), only its hand-back left");
		tasks.Finish();
		Test.Assert(!preview.IsOpen, "a stopped preview's completion does not run");
	}

	/// A texture part shows its picture in place of the model, from the importer's read; the whole
	/// file brings the model back, and a texture it has no picture of keeps the model.
	[Test]
	public static void ATexturePartShowsItsPictureInPlaceOfTheModelFromTheImportersReadTheWholeFileBringsItBack()
	{
		let cache = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_model_file_preview_texture", .. scope .());
		RemoveDirectoryRecursive(cache);
		Test.Assert(CreateDirectory(cache));
		defer RemoveDirectoryRecursive(cache);
		let root = FindDataRoot(.. scope .());
		let fox = DataPath(root, "Tests/Models/FoxNested/glTF/Fox.gltf", .. scope .());
		let importer = scope ModelFileImporter();
		let prepared = importer.PrepareOnWorker(fox);
		defer delete prepared;
		let loaded = prepared as LoadedModel;
		Test.Assert(loaded != null);
		let options = importer.CreateOptions();
		defer delete options;
		let plan = scope ImportPlan();
		importer.DescribeImport(fox, options, prepared, plan);
		ImportPlanEntry texture = null;
		for (let entry in plan.Entries)
		{
			if (entry.Kind == .Texture)
				texture = entry;
		}
		Test.Assert(texture != null);
		let tasks = scope TaskPool(1);
		let services = scope AssetPageServices(); // no host: no view
		{
			let preview = scope ModelFilePreview(fox, cache, tasks, services, loaded.Model);
			Test.Assert(!preview.ShowsPicture);
			Test.Assert(preview.ShowPart(texture), "the importer read it: its pixels are here");
			Test.Assert(preview.ShowsPicture);
			preview.ShowWhole();
			Test.Assert(!preview.ShowsPicture);
			let missing = scope ImportPlanEntry(.Texture, "no_such_texture", "no_such_texture");
			Test.Assert(!preview.ShowPart(missing), "no picture of that name: the model stays");
			Test.Assert(!preview.ShowsPicture);
			tasks.Finish();
			preview.FinishLoading(); // cooked into the cache, for the open after
		}
		{
			// Opened again, from the preview's cache (no cook): the picture still comes from the read.
			let again = scope ModelFilePreview(fox, cache, tasks, services, loaded.Model);
			Test.Assert(again.IsLoading, "bound from the cache, not cooked");
			Test.Assert(again.ShowPart(texture));
			Test.Assert(again.ShowsPicture);
			again.FinishLoading();
		}
	}

	/// The skeleton's details show its bones in a tree; a bone chosen there is the one drawn apart.
	[Test]
	public static void TheSkeletonsDetailsShowItsBonesInATreeABoneChosenThereIsTheOneDrawnApart()
	{
		let cache = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_model_file_preview_bones", .. scope .());
		RemoveDirectoryRecursive(cache);
		Test.Assert(CreateDirectory(cache));
		defer RemoveDirectoryRecursive(cache);
		let root = FindDataRoot(.. scope .());
		let fox = DataPath(root, "Tests/Models/FoxNested/glTF/Fox.gltf", .. scope .());
		let importer = scope ModelFileImporter();
		let prepared = importer.PrepareOnWorker(fox);
		defer delete prepared;
		let loaded = prepared as LoadedModel;
		Test.Assert(loaded != null);
		let options = importer.CreateOptions();
		defer delete options;
		let plan = scope ImportPlan();
		importer.DescribeImport(fox, options, prepared, plan);
		ImportPlanEntry skeleton = null;
		ImportPlanEntry mesh = null;
		for (let entry in plan.Entries)
		{
			if (entry.Kind == .Skeleton)
				skeleton = entry;
			if (entry.Kind == .Mesh)
				mesh = entry;
		}
		Test.Assert((skeleton != null) && (mesh != null));
		let tasks = scope TaskPool(1);
		let services = scope AssetPageServices(); // no host: no view
		{
			let preview = scope ModelFilePreview(fox, cache, tasks, services, loaded.Model);
			Test.Assert(preview.PartView(skeleton) == null, "not before the model is in");
			tasks.Finish();
			preview.FinishLoading();
			Test.Assert(preview.IsOpen);
			let bones = preview.PartView(skeleton);
			Test.Assert(bones != null, "the bones' tree");
			defer bones.ReleaseRef();
			Test.Assert(preview.PartView(mesh) == null, "a mesh has no view of its own");
			Test.Assert(preview.ChosenBone == -1);
			preview.ChooseBone(3);
			Test.Assert(preview.ChosenBone == 3);
		}
	}

	/// It draws the model as it will import: a material left out (all, or one) as the default, a
	/// texture left out (all, or one) not drawn.
	[Test]
	public static void ItDrawsTheModelAsItWillImportAMaterialLeftOutAsTheDefaultATextureLeftOutNotDrawn()
	{
		let cache = PathJoin(GetCurrentDirectory(.. scope .()), "scratch_model_file_preview_default_material", .. scope .());
		RemoveDirectoryRecursive(cache);
		Test.Assert(CreateDirectory(cache));
		defer RemoveDirectoryRecursive(cache);
		let root = FindDataRoot(.. scope .());
		let fox = DataPath(root, "Tests/Models/FoxNested/glTF/Fox.gltf", .. scope .());
		let importer = scope ModelFileImporter();
		let prepared = importer.PrepareOnWorker(fox);
		defer delete prepared;
		let loaded = prepared as LoadedModel;
		Test.Assert(loaded != null);
		let options = importer.CreateOptions() as ModelImportOptions;
		defer delete options;
		Test.Assert(options != null);
		options.ImportMaterials = false;
		let tasks = scope TaskPool(1);
		let services = scope AssetPageServices(); // no host: no view
		{
			let preview = scope ModelFilePreview(fox, cache, tasks, services, loaded.Model, options);
			tasks.Finish();
			preview.FinishLoading();
			Test.Assert(preview.IsOpen);
			Test.Assert(preview.DrawsDefaultMaterial, "as it will import: no materials");
			options.ImportMaterials = true;
			preview.OnSettingsChanged();
			Test.Assert(!preview.DrawsDefaultMaterial);
			options.ImportMaterials = false;
			preview.OnSettingsChanged();
			Test.Assert(preview.DrawsDefaultMaterial);

			// One material left out in the review (the plan as the window keeps it in the settings).
			options.ImportMaterials = true;
			let plan = scope ImportPlan();
			importer.DescribeImport(fox, options, prepared, plan);
			options.Selection.CopyFrom(plan);
			for (let entry in options.Selection.Entries)
			{
				if (entry.Kind == .Material)
					entry.Enabled = false;
			}
			preview.OnSettingsChanged();
			Test.Assert(preview.DrawsDefaultMaterial);
			Test.Assert(!preview.DrawsWithoutTextures);

			// (One texture left out is found by its texture, which a preview without a device has none
			// of: that case is the editor's to check.) All textures left out by the setting; then
			// nothing left out.
			options.Selection.CopyFrom(plan);
			options.ImportTextures = false;
			preview.OnSettingsChanged();
			Test.Assert(preview.DrawsWithoutTextures);
			options.ImportTextures = true;
			preview.OnSettingsChanged();
			Test.Assert(!preview.DrawsWithoutTextures);
			Test.Assert(!preview.DrawsDefaultMaterial);
		}
	}
}
