using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.VFS;
using Sedulous.Scene;
using Sedulous.Model;
using Sedulous.Model.Resource;
using Sedulous.Image;
using Sedulous.Image.IO;
using Sedulous.Engine.Render;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Model;
using Sedulous.Editor.ModelPreview;

namespace Sedulous.Editor.ModelPreview.Tests;

/// A model file opened for viewing without a project (the import window's model preview). It opens
/// into its own cache folder and binds, with its stats counted from the file; opened again it binds
/// what was cooked before, stats included. The bound model goes into a scene as entities, a skinned
/// one playing its first clip, and its clips are driven. Also covered: the record beside the cooked
/// files, which files open by extension, the materials and textures listed, and the loose texture
/// rule. No GPU.
class ModelPreviewTests
{
	static void TestModel(StringView relative, String outPath)
	{
		let root = FindDataRoot(.. scope .());
		Test.Assert(!root.IsEmpty);
		DataPath(root, relative, outPath);
	}

	/// A fresh folder under the test's working directory.
	static void FreshCache(StringView name, String outPath)
	{
		PathJoin(GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
		Test.Assert(CreateDirectory(outPath));
	}

	static bool Near(float a, float b, float tolerance = 0.001f) => Math.Abs(a - b) <= tolerance;

	const String cFox = "Tests/Models/FoxNested/glTF/Fox.gltf";

	[Test]
	public static void AModelFileIsOneOpenedByItsExtension()
	{
		Test.Assert(ModelLibrary.IsModelFile("a/b/Fox.gltf"));
		Test.Assert(ModelLibrary.IsModelFile("Fox.GLB"));
		Test.Assert(ModelLibrary.IsModelFile("/x/Unit.FBX"));
		Test.Assert(ModelLibrary.IsModelFile("crate.obj"));
		Test.Assert(!ModelLibrary.IsModelFile("texture.png"));
		Test.Assert(!ModelLibrary.IsModelFile("fbx"));
		Test.Assert(!ModelLibrary.IsModelFile("folder.fbx/readme"));
	}

	[Test]
	public static void TheRecordBesideACookedModelReadsBackAsItWasWritten()
	{
		let stats = scope ModelStats();
		stats.Meshes = 3;
		stats.Vertices = 1234;
		stats.Triangles = 999;
		stats.Materials = 2;
		stats.Textures = 1;
		stats.Bones = 24;
		stats.Skins = 1;
		stats.Size = .(1.5f, 2.0f, 0.25f);
		stats.Clips.Add(new .("Run"));
		stats.ClipSeconds.Add(0.75f);
		stats.Clips.Add(new .("Idle and look"));
		stats.ClipSeconds.Add(3.0f);
		let model = Guid(0x12345678, 0x9abc, 0xdef0, 0x0f, 0xed, 0xcb, 0xa9, 0x87, 0x65, 0x43, 0x21);

		let read = scope ModelStats();
		Test.Assert(ModelLibrary.ReadRecord(ModelLibrary.WriteRecord(model, stats, .. scope .()), let readModel, read));
		Test.Assert(readModel == model);
		Test.Assert((read.Meshes == 3) && (read.Vertices == 1234) && (read.Triangles == 999));
		Test.Assert((read.Materials == 2) && (read.Textures == 1) && (read.Bones == 24) && (read.Skins == 1));
		Test.Assert(Near(read.Size.Y, 2.0f));
		Test.Assert(read.Clips.Count == 2);
		Test.Assert(read.Clips[1] == "Idle and look", "a name with spaces survives");
		Test.Assert(Near(read.ClipSeconds[0], 0.75f));
		let ignored = scope ModelStats();
		Test.Assert(!ModelLibrary.ReadRecord("meshes 3\n", ?, ignored), "no model guid: the model cooks again");
	}

	[Test]
	public static void ASkinnedGltfOpensIntoItsCacheCountedAndBindsAgainFromIt()
	{
		let fox = TestModel(cFox, .. scope .());
		let cache = FreshCache("scratch_model_preview_cache", .. scope .());
		defer RemoveDirectoryRecursive(cache);

		let folder = scope String();
		uint32 triangles = 0;
		int clips = 0;
		{
			let open = scope OpenModel();
			Test.Assert(open.Open(fox, cache, null) == .Opened);
			Test.Assert(open.IsOpen);
			let first = open.Stats;
			folder.Set(open.CacheFolder);
			Test.Assert((first.Meshes > 0) && (first.Triangles > 0) && (first.Bones > 0));
			Test.Assert(!first.Clips.IsEmpty);
			Test.Assert(open.Model.Meshes.Count > 0);
			Test.Assert(open.Model.Skeleton.Get != null);
			triangles = first.Triangles;
			clips = first.Clips.Count;
		}
		Test.Assert(FileExists(PathJoin(folder, OpenModel.cRecordName, .. scope .())));

		// Opened again: bound from the cache with the same stats, nothing cooked.
		let again = scope OpenModel();
		Test.Assert(again.Open(fox, cache, null) == .FromCache);
		Test.Assert(again.CacheFolder == folder);
		Test.Assert(again.Stats.Triangles == triangles);
		Test.Assert(again.Stats.Clips.Count == clips);
		Test.Assert(again.Model.Animations.Count == clips);

		// A missing file gets no folder, and does not open.
		Test.Assert(ModelLibrary.CacheFolderFor(cache, "/no/such/model.fbx", .. scope .()).IsEmpty);
		let missing = scope OpenModel();
		Test.Assert(missing.Open("/no/such/model.fbx", cache, null) == .NotFound);
	}

	[Test]
	public static void TheBoundModelGoesIntoASceneASkinnedOnePlayingItsFirstClip()
	{
		let fox = TestModel(cFox, .. scope .());
		let cache = FreshCache("scratch_model_preview_scene", .. scope .());
		defer RemoveDirectoryRecursive(cache);
		let open = scope OpenModel();
		Test.Assert(!open.IsOpen);
		Test.Assert(open.Open(fox, cache, null) == .Opened);

		let level = scope Scene("preview");
		level.AddSystem<MeshComponentManager>();
		AnimationScene.AddAnimationSceneManagers(level);
		var options = InstantiateOptions();
		options.RootTransform.Scale = .(0.5f, 0.5f, 0.5f);
		let instance = scope ModelInstance();
		ModelInstances.Instantiate(level, open.Model, "Fox", options, instance);
		Test.Assert(level.IsValid(instance.Root));
		Test.Assert(Near(level.GetLocalTransform(instance.Root).Scale.X, 0.5f));
		Test.Assert(!instance.Skinned.IsEmpty);
		Test.Assert(instance.Animated);
		let animators = level.GetSystem<SkeletalAnimationComponentManager>();
		Test.Assert(animators != null);
		let animator = animators.Get(instance.Root);
		Test.Assert(animator != null);
		Test.Assert(animator.MeshEntities.Count == instance.Skinned.Count);
		// A skinned mesh sits in its skeleton's space: at identity under the skeleton's parent node
		// (the root when it has none), as the project's model prefab places it.
		let model = open.Model;
		Test.Assert(model.SkeletonParentNode >= -1);
		for (let skinned in instance.Skinned)
		{
			let local = level.GetLocalTransform(skinned);
			Test.Assert(Near(local.Position.X, 0.0f) && Near(local.Scale.Y, 1.0f));
			if (model.SkeletonParentNode == -1)
				Test.Assert(level.GetParent(skinned) == instance.Root);
			else
				Test.Assert(level.GetEntityName(level.GetParent(skinned)) == model.Nodes[model.SkeletonParentNode].Name);
		}

		// Without the animation managers it still shows, unanimated, and the same when asked not to
		// animate.
		let still = scope Scene("still");
		still.AddSystem<MeshComponentManager>();
		let plain = scope ModelInstance();
		ModelInstances.Instantiate(still, open.Model, "Fox", .(), plain);
		Test.Assert(still.IsValid(plain.Root));
		Test.Assert(!plain.Animated);
		var frozen = InstantiateOptions();
		frozen.Animate = false;
		let held = scope ModelInstance();
		ModelInstances.Instantiate(level, open.Model, "Fox2", frozen, held);
		Test.Assert(!held.Animated);
	}

	[Test]
	public static void TheAnimationBarPicksAClipPausesStepsScrubsLoopsAndSpeedsUp()
	{
		let fox = TestModel(cFox, .. scope .());
		let cache = FreshCache("scratch_model_preview_playback", .. scope .());
		defer RemoveDirectoryRecursive(cache);
		let open = scope OpenModel();
		Test.Assert(open.Open(fox, cache, null) == .Opened);
		let level = scope Scene("preview");
		level.AddSystem<MeshComponentManager>();
		AnimationScene.AddAnimationSceneManagers(level);
		let instance = scope ModelInstance();
		ModelInstances.Instantiate(level, open.Model, "Fox", .(), instance);
		let playback = scope ClipPlayback(level, instance.Root, open.Model);
		Test.Assert(playback.HasClips);
		Test.Assert(playback.ClipCount == 3);
		Test.Assert(playback.Selected == 0, "Instantiate plays the first");
		Test.Assert(playback.ClipName(1, .. scope .()) == "Walk");
		level.Update(0.1f); // the manager builds the player and starts the clip
		Test.Assert(playback.Player != null);
		Test.Assert(playback.Playing);

		// A selected clip plays from its start on the next update.
		playback.Select(1);
		level.Update(0.0f);
		Test.Assert(playback.Player.CurrentClip === open.Model.Animations[1].Get);
		Test.Assert(Near(playback.Time, 0.0f));

		// While paused, time stands still; a scrub and a step move it and stay paused.
		playback.SetPlaying(false);
		level.Update(0.5f);
		Test.Assert(Near(playback.Time, 0.0f));
		playback.Scrub(0.4f);
		Test.Assert(Near(playback.Time, 0.4f));
		playback.Step(1);
		Test.Assert(Near(playback.Time, 0.4f + 1.0f / ClipPlayback.cStepFps));
		Test.Assert(!playback.Playing);
		playback.Scrub(1000.0f);
		Test.Assert(Near(playback.Time, playback.Duration), "clamped to the clip");
		playback.Stop();
		Test.Assert(Near(playback.Time, 0.0f));
		Test.Assert(!playback.Playing);

		// Twice the speed advances twice the time.
		playback.SetSpeed(2.0f);
		playback.SetPlaying(true);
		level.Update(0.1f);
		Test.Assert(Near(playback.Time, 0.2f));
		playback.SetSpeed(1.0f);

		// Without looping it stops at the end, and playing again starts it over.
		playback.SetLooping(false);
		level.Update(playback.Duration + 1.0f);
		Test.Assert(!playback.Playing);
		Test.Assert(Near(playback.Time, playback.Duration));
		playback.SetPlaying(true);
		Test.Assert(playback.Playing);
		Test.Assert(Near(playback.Time, 0.0f));
		// With looping it starts over past the end.
		playback.SetLooping(true);
		level.Update(playback.Duration + 0.25f);
		Test.Assert(playback.Playing);
		Test.Assert(Near(playback.Time, 0.25f, 0.01f));
	}

	[Test]
	public static void AMaterialWithoutItsTextureTakesTheImageBesideTheModel()
	{
		let folder = FreshCache("scratch_model_preview_loose", .. scope .());
		defer RemoveDirectoryRecursive(folder);
		let pixel = scope Sedulous.Image.Image(2, 2, .RGBA8);
		for (let name in StringView[3]("Body.png", "Knight.png", "aaa.png"))
			Test.Assert(ImageIO.SaveImage(pixel, PathJoin(folder, name, .. scope .()), .PNG) case .Ok);
		let path = PathJoin(folder, "Knight.fbx", .. scope .());

		let model = scope Model();
		int32 Material(Model into, StringView name, int32 texture)
		{
			let material = new ModelMaterial();
			material.Name.Set(name);
			material.BaseColorTextureIndex = texture;
			return into.AddMaterial(material);
		}
		let own = model.AddTexture(new ModelTexture());
		let body = Material(model, "body", -1); // takes the image named like it (ignoring case)
		let cloak = Material(model, "Cloak", -1); // no image named like it: takes the model's
		let kept = Material(model, "Sword", own); // already linked: left alone
		Test.Assert(ModelLibrary.ApplyLooseTextures(model, path) == 2);
		Test.Assert(model.Textures[model.Materials[body].BaseColorTextureIndex].Uri == "Body.png");
		Test.Assert(model.Textures[model.Materials[cloak].BaseColorTextureIndex].Uri == "Knight.png");
		Test.Assert(model.Materials[kept].BaseColorTextureIndex == own);

		// With neither name's image present, the first image in name order.
		let other = scope Model();
		Material(other, "Helm", -1);
		Test.Assert(ModelLibrary.ApplyLooseTextures(other, PathJoin(folder, "Squire.fbx", .. scope .())) == 1);
		Test.Assert(other.Textures[0].Uri == "Body.png");
		// A folder without images: nothing is applied.
		let bare = scope Model();
		Material(bare, "", -1);
		Test.Assert(ModelLibrary.ApplyLooseTextures(bare, "/no/such/folder/x.fbx") == 0);
		Test.Assert(bare.Materials[0].BaseColorTextureIndex == -1);
	}

	/// The materials and textures listed: they round-trip through the record (names with spaces, a
	/// texture inside the file with no file name) and are counted from a known model (the Fox: one
	/// PBR material whose base color is its one texture, an image beside the file).
	[Test]
	public static void TheMaterialsAndTexturesAreListedKeptInTheRecordCountedFromTheFile()
	{
		let stats = scope ModelStats();
		let skin = new ModelTextureInfo();
		skin.Name.Set("Body Skin");
		skin.Width = 1024;
		skin.Height = 512;
		skin.File.Set("skin.png");
		stats.TextureList.Add(skin);
		let inside = new ModelTextureInfo();
		inside.Name.Set("inside");
		inside.Width = 64;
		inside.Height = 64;
		stats.TextureList.Add(inside);
		let coat = new ModelMaterialInfo();
		coat.Name.Set("Fur coat");
		coat.Shading.Set("Phong");
		void AddSlot(StringView name, uint32 texture)
		{
			let slot = new ModelMaterialInfo.Slot();
			slot.SlotName.Set(name);
			slot.Texture = texture;
			coat.Slots.Add(slot);
		}
		AddSlot("base color", 0);
		AddSlot("normal", 1);
		stats.MaterialList.Add(coat);
		let bare = new ModelMaterialInfo();
		bare.Name.Set("Bare");
		bare.Shading.Set("PBR");
		stats.MaterialList.Add(bare);

		let read = scope ModelStats();
		Test.Assert(ModelLibrary.ReadRecord(ModelLibrary.WriteRecord(Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2), stats, .. scope .()), ?, read));
		Test.Assert(read.TextureList.Count == 2);
		Test.Assert(read.TextureList[0].Name == "Body Skin");
		Test.Assert((read.TextureList[0].Width == 1024) && (read.TextureList[0].Height == 512));
		Test.Assert(read.TextureList[0].File == "skin.png");
		Test.Assert(read.TextureList[1].File.IsEmpty);
		Test.Assert(read.MaterialList.Count == 2);
		Test.Assert((read.MaterialList[0].Name == "Fur coat") && (read.MaterialList[0].Shading == "Phong"));
		Test.Assert(read.MaterialList[0].Slots.Count == 2);
		Test.Assert((read.MaterialList[0].Slots[1].SlotName == "normal") && (read.MaterialList[0].Slots[1].Texture == 1));
		Test.Assert(read.MaterialList[1].Slots.IsEmpty);

		// Counted from the Fox.
		let fox = TestModel(cFox, .. scope .());
		let model = scope Model();
		let counted = scope ModelStats();
		Test.Assert(OpenModel.LoadFile(fox, true, model, counted) == .Opened);
		Test.Assert(counted.MaterialList.Count == 1);
		Test.Assert(counted.MaterialList[0].Name == "fox_material");
		Test.Assert(counted.MaterialList[0].Shading == "PBR");
		Test.Assert(counted.MaterialList[0].Slots.Count == 1);
		Test.Assert(counted.MaterialList[0].Slots[0].SlotName == "base color");
		Test.Assert(counted.TextureList.Count == 1);
		Test.Assert(counted.TextureList[0].File == "Texture.png");
		Test.Assert(counted.TextureList[0].Width > 0);
	}
}
