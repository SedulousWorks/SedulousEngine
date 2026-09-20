using System;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Render;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene.Tests;

/// The scene and prefab creators over a real project.
class SceneAssetCreatorTests
{
	private static void Scratch(StringView name, String outPath)
	{
		PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, outPath);
		RemoveDirectoryRecursive(outPath);
	}

	[Test]
	public static void CreateSceneInstanceMakesUniquelyNamedSceneDocuments()
	{
		SceneResources.RegisterAll();
		let dir = Scratch("scratch_editor_scene_test_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		let ctx = scope EditorContext();
		ctx.SetProject(project);

		// No project: nothing.
		let empty = scope EditorContext();
		Test.Assert(SceneAssetCreators.CreateSceneInstance(empty) == null);

		let first = SceneAssetCreators.CreateSceneInstance(ctx);
		Test.Assert(first != null);
		Test.Assert(first.Name == "Scene");
		Test.Assert(first.GetPath(.. scope .()) == "Scenes/Scene");
		Test.Assert(AssetTypeNames.Matches(first.TypeName, "SceneDocument"));

		// The primary object materialised and round trips.
		let doc = first.ReadObject();
		Test.Assert(doc != null);
		defer delete doc;
		let sceneDoc = doc as SceneDocument;
		Test.Assert((sceneDoc != null) && (sceneDoc.Name == "Scene"));

		// A second create picks a unique name in the same group.
		let second = SceneAssetCreators.CreateSceneInstance(ctx);
		Test.Assert(second != null);
		Test.Assert(second.Name == "Scene.2");
		Test.Assert(second.Id != first.Id);

		// A prefab lands under Prefabs/ with one root entity in its payload.
		let prefab = SceneAssetCreators.CreatePrefabInstance(ctx);
		Test.Assert(prefab != null);
		Test.Assert(prefab.GetPath(.. scope .()) == "Prefabs/Prefab");
		let payload = prefab.ReadData("scene");
		Test.Assert(payload != null);
		defer delete payload;
		let level = scope Scene("level");
		let root = PrefabSpawn.Spawn(level, payload, prefab.Id);
		Test.Assert(root.IsAssigned && (level.GetEntityName(root) == "Prefab") && (level.EntityCount == 1));
	}

	[Test]
	public static void ANewSceneInstanceIsSeededWithADirectionalSun()
	{
		SceneResources.RegisterAll();
		let dir = Scratch("scratch_newscene_seed_project", .. scope .());
		defer RemoveDirectoryRecursive(dir);
		Test.Assert(EditorProject.Create(dir, "P") case .Ok);
		let project = EditorProject.Open(dir);
		Test.Assert(project != null);
		defer delete project;
		let ctx = scope EditorContext();
		ctx.SetProject(project);

		let instance = SceneAssetCreators.CreateSceneInstance(ctx);
		Test.Assert(instance != null);

		let loaded = scope Scene();
		loaded.AddSystem<LightComponentManager>();
		Test.Assert(SceneStorage.LoadScene(instance, loaded) case .Ok);

		let sun = loaded.FindEntityByName("Sun");
		Test.Assert(sun.IsAssigned);
		let light = loaded.GetSystem<LightComponentManager>().Get(sun);
		Test.Assert(light != null);
		Test.Assert(light.Type == .Directional);
		Test.Assert(light.CastsShadows);
		// Angled, not identity: the light's forward has a downward component.
		let forward = RotateVector(loaded.GetLocalTransform(sun).Rotation, Float3(0, 0, -1));
		Test.Assert(forward.Y < -0.5f);
	}
}
