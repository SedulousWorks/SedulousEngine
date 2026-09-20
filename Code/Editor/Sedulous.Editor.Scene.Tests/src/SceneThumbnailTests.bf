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
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;

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
