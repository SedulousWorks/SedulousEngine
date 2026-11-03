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
			Test.Assert((preview as IImportPreviewFrames) != null, "the window drives its frames");
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
		}
	}
}
