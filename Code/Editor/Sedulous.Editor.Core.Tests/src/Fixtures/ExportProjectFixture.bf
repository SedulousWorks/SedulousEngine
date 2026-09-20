using System;
using System.Collections;
using System.IO;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Content;
using Sedulous.Geometry;
using Sedulous.Geometry.Pipeline;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Engine.Render;
using Sedulous.Pipeline.Core;
using Sedulous.VFS;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// A project with a cube mesh a scene references, an unreferenced one beside it, the scene
/// as the default, a mesh builder, a host template made of a stand in player, and the
/// scanner the pruning needs. The scratch directories are removed with the fixture.
class ExportProjectFixture
{
	public String ProjectDir = new .() ~ delete _;
	public String ToolDir = new .() ~ delete _;
	public String OutRoot = new .() ~ delete _;
	public EditorProject Project ~ delete _;
	public BuilderRegistry Builders = new .() ~ delete _;
	public TemplateRegistry Templates = new .() ~ delete _;
	public Guid ReferencedMeshId;
	public Guid UnreferencedMeshId;
	public Guid SceneId;
	public SceneReferenceScanner Scanner = new => Scan ~ delete _;

	public this(StringView name)
	{
		let cwd = Directory.GetCurrentDirectory(.. scope .());
		PathJoin(cwd, scope $"{name}_proj", ProjectDir);
		PathJoin(cwd, scope $"{name}_tool", ToolDir);
		PathJoin(cwd, scope $"{name}_out", OutRoot);
		RemoveDirectoryRecursive(ProjectDir);
		RemoveDirectoryRecursive(ToolDir);
		RemoveDirectoryRecursive(OutRoot);
		GeometryResources.RegisterAll();
		SceneResources.RegisterAll();
		GeometryPipeline.RegisterAll();

		Test.Assert(EditorProject.Create(ProjectDir, "Export") case .Ok);
		Project = EditorProject.Open(ProjectDir);
		Test.Assert(Project != null);
		let meshes = Project.SourceDb.RootGroup.CreateGroup("Meshes");
		ReferencedMeshId = AuthorMesh(meshes, "Referenced");
		UnreferencedMeshId = AuthorMesh(meshes, "Unreferenced");
		let scenes = Project.SourceDb.RootGroup.CreateGroup("Scenes");
		let sceneInstance = scenes.CreateInstance("Main", McpDocumentNames.cSceneDocument);
		Test.Assert(sceneInstance != null);
		SceneId = sceneInstance.Id;
		{
			let scene = scope Scene("Main");
			scene.AddSystem<MeshComponentManager>();
			let e = scene.CreateEntity("Box");
			scene.GetSystem<MeshComponentManager>().Add(e).Mesh.SetId(ReferencedMeshId);
			Test.Assert(SceneStorage.SaveScene(scene, sceneInstance) case .Ok);
		}
		Project.Settings.DefaultSceneId = SceneId;
		Project.Settings.DefaultScene.Set("Scenes/Main");
		Test.Assert(Project.SaveSettings() case .Ok);
		Builders.Register(new StaticMeshAssetBuilder());

		// The host template: a stand in player in the tool directory, with a sidecar.
		CreateDirectory(ToolDir);
		let player = "#!player\n";
		WriteFile(PathJoin(ToolDir, BuildLayout.ExecutableName(BuildLayout.cPlayerBaseName, .. scope .()), .. scope .()), .((uint8*)player.Ptr, player.Length)).IgnoreError();
		let lib = "so\n";
		WriteFile(PathJoin(ToolDir, "libfoo.so", .. scope .()), .((uint8*)lib.Ptr, lib.Length)).IgnoreError();
		Templates.Refresh("", ToolDir);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(ProjectDir);
		RemoveDirectoryRecursive(ToolDir);
		RemoveDirectoryRecursive(OutRoot);
	}

	public static Guid AuthorMesh(Group group, StringView name)
	{
		let instance = group.CreateInstance(name, typeof(StaticMeshAsset).GetFullName(.. scope .()));
		Test.Assert(instance != null);
		let cube = Primitives.Cube(2.0f);
		defer delete cube;
		let asset = scope StaticMeshAsset();
		MeshImporter.Import(cube, asset);
		Test.Assert(MeshAssetStorage.WriteStatic(instance, asset) case .Ok);
		return instance.Id;
	}

	/// The pruning scanner: the scene loaded over the mesh manager, its Refs collected
	/// through a factory less resource manager, plus its pending prefabs.
	private static void Scan(Instance instance, ContentDatabase db, SceneReferences outReferences)
	{
		let scene = scope Scene();
		scene.AddSystem<MeshComponentManager>();
		if (SceneStorage.LoadScene(instance, scene) case .Err)
			return;
		let collector = scope ResourceManager(db);
		SceneResolve.ResolveSceneResources(scene, collector);
		collector.CollectUnresolved(outReferences.Resources);
		scene.ForEachPendingPrefabInstance(scope [&](pending) => { outReferences.Prefabs.Add(pending.PrefabId); });
	}

	/// The engine data root the shader cook reads, found the way every executable does.
	public static void DataRoot(String outPath)
	{
		FindDataRoot(outPath);
		Test.Assert(!outPath.IsEmpty, "the Data/.dataroot walk from the test binary");
	}

	public static ExportPreset HostPreset(StringView name, StringView subdir)
	{
		let preset = new ExportPreset();
		preset.Name.Set(name);
		preset.Platform.Set(BuildLayout.HostPlatformName);
		preset.OutputSubdir.Set(subdir);
		return preset;
	}
}
