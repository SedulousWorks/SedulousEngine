using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Settings;
using Sedulous.Engine.Render;
using Sedulous.Engine.Composition;
using Sedulous.Editor.Core;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.Scene.Tests;

/// The scene thumbnail generators' registration and staging protocol, against a resource
/// manager with nothing to give: what a missing asset looks like to a generator.
class SceneThumbnailTests
{
	private static void Scratch(String outPath)
	{
		PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_scene_thumb_tests", outPath);
	}

	[Test]
	public static void RegistrationAddsEveryGenerator()
	{
		let service = scope ThumbnailService();
		let context = scope EditorContext();
		SceneThumbnailGenerators.Register(service, context);
		Test.Assert(service.SceneGeneratorCount == 7);
	}

	[Test]
	public static void AMeshThatCannotBeBoundFailsAndUnstageParksTheDisplayEntity()
	{
		let dir = Scratch(.. scope .());
		RemoveDirectoryRecursive(dir);
		CreateDirectory(dir);
		defer RemoveDirectoryRecursive(dir);
		let mount = scope NativeFileSystem(dir);
		SerializerFactory factory = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(mount, factory, "asset");
		let resources = scope ResourceManager(database);

		let stage = scope Scene("stage");
		stage.AddSystem<MeshComponentManager>();
		stage.AddSystem<LightComponentManager>();

		let generator = scope MeshThumbnailGenerator();
		let names = scope List<StringView>();
		generator.AssetTypeNames(names);
		Test.Assert((names.Count == 2) && (names[0] == "StaticMeshAsset"));
		Test.Assert(!generator.NeedsPrivateScene);

		var framing = ThumbnailFraming();
		let missing = Guid(7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7);
		Test.Assert(generator.Stage(missing, stage, resources, ref framing) == .Failed);
		Test.Assert(stage.EntityCount == 2); // the display entity and its sun were made
		generator.Unstage(stage);
		stage.ForEachEntity(scope (e) => { Test.Assert(!stage.IsActive(e)); }); // parked, not destroyed

		// A stage without the managers cannot show anything.
		let bare = scope Scene("bare");
		Test.Assert(generator.Stage(missing, bare, resources, ref framing) == .Failed);
	}

	/// A scene's thumbnail is taken as its page last showed it: the view the page saved is part
	/// of the hash naming the picture, and the stage is handed that view; with none saved, a
	/// perspective shot from above that holds the scene's bounds.
	[Test]
	public static void ASceneIsShownAsItsPageLastShowedItTheViewNamingItsThumbnail()
	{
		let dir = PathJoin(Directory.GetCurrentDirectory(.. scope .()), "scratch_scene_thumb_view", .. scope .());
		RemoveDirectoryRecursive(dir);
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		SceneResources.RegisterAll();
		SceneEditorSerializables.RegisterAll();
		let store = scope Settings();
		let context = scope EditorContext();
		context.SetProject(project);
		context.ProjectEditorSettings = store;
		defer
		{
			context.ProjectEditorSettings = null;
			context.SetProject(null);
		}

		let level = project.SourceDb.RootGroup.CreateInstance("Level", typeof(SceneDocument).GetFullName(.. scope .()));
		Test.Assert(level != null);
		{
			let authored = scope Sedulous.Scene.Scene("authored");
			EngineSceneComposition.AddAllSceneManagers(authored);
			authored.CreateEntity("Crate");
			Test.Assert(SceneStorage.SaveScene(authored, level) case .Ok);
		}
		let resourceDir = PathJoin(dir, "resources", .. scope .());
		CreateDirectory(resourceDir);
		let mount = scope NativeFileSystem(resourceDir);
		SerializerFactory factory = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(mount, factory, "asset");
		let resources = scope ResourceManager(database);

		let generator = scope SceneThumbnailGenerator(context);
		let unviewed = generator.ContentHash(level);
		Test.Assert(unviewed != 0);
		Test.Assert(generator.ContentHash(level) == unviewed, "the same content, the same name");
		{
			let stage = scope Sedulous.Scene.Scene("stage");
			EngineSceneComposition.AddAllSceneManagers(stage);
			stage.AddSystem<FarBox>(); // the crate measured far from the origin
			var framing = ThumbnailFraming();
			Test.Assert(generator.Stage(level.Id, stage, resources, ref framing) == .Ready);
			// Never viewed: in perspective from above the middle, just far enough back to hold it.
			Test.Assert(framing.HasView);
			let center = FarBox.Box.Center();
			let radius = Length(FarBox.Box.Extents());
			Test.Assert(Math.Abs(Length(framing.Eye - center) - radius / Sin(0.5f * 1.0472f)) < 0.01f);
			Test.Assert(framing.Eye.Y > center.Y, "from above");
			generator.Unstage(stage);
		}

		// Its page closes having looked from somewhere: a new view, a new thumbnail, rendered
		// through that view.
		var camera = SceneViewCamera(.(40.0f, 12.0f, -8.0f), 1.2f, -0.3f, 12.0f);
		Test.Assert(SceneViewPrefs.SaveView(store, level.Id, camera, Span<Guid>()));
		let viewed = generator.ContentHash(level);
		Test.Assert(viewed != unviewed);
		{
			let stage = scope Sedulous.Scene.Scene("stage");
			EngineSceneComposition.AddAllSceneManagers(stage);
			var framing = ThumbnailFraming();
			Test.Assert(generator.Stage(level.Id, stage, resources, ref framing) == .Ready);
			Test.Assert(framing.HasView);
			// Perspective: the eye is the camera's own position.
			Test.Assert((Math.Abs(framing.Eye.X - 40.0f) < 0.001f) && (Math.Abs(framing.Eye.Z + 8.0f) < 0.001f));
			generator.Unstage(stage);
		}
		camera.Yaw = 0.4f;
		Test.Assert(SceneViewPrefs.SaveView(store, level.Id, camera, Span<Guid>()));
		Test.Assert(generator.ContentHash(level) != viewed, "turned: a new thumbnail");
	}

	[Test]
	public static void APrefabWithNoProjectFails()
	{
		let dir = Scratch(.. scope .());
		RemoveDirectoryRecursive(dir);
		CreateDirectory(dir);
		defer RemoveDirectoryRecursive(dir);
		let mount = scope NativeFileSystem(dir);
		SerializerFactory factory = scope (stream, mode) => new BinarySerializerContext(stream, mode);
		let database = scope ContentDatabase(mount, factory, "asset");
		let resources = scope ResourceManager(database);

		let context = scope EditorContext();
		let generator = scope PrefabThumbnailGenerator(context);
		Test.Assert(generator.NeedsPrivateScene);
		let stage = scope Scene("stage");
		var framing = ThumbnailFraming();
		Test.Assert(generator.Stage(Guid(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1), stage, resources, ref framing) == .Failed);
	}
}
