using System;
using System.IO;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.VFS;
using Sedulous.Content;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.ModelImporter;
using Sedulous.Engine.Render;
using Sedulous.Engine.Animation;

namespace Sedulous.Editor.Scene.Tests;

/// A model manifest becoming a spawnable prefab or a standalone scene beside it, and a
/// regeneration refreshing the same instance.
class ModelPrefabTests
{
	private class Fixture
	{
		public NativeFileSystem Mount ~ delete _;
		public SerializerFactory Factory ~ delete _;
		public SerializableRegistry Serializables = new .() ~ delete _;
		public ContentDatabase Database ~ delete _;
		private String mRoot = new .() ~ delete _;

		public this(StringView name)
		{
			PathJoin(Directory.GetCurrentDirectory(.. scope .()), name, mRoot);
			RemoveDirectoryRecursive(mRoot);
			CreateDirectory(mRoot);
			SceneResources.RegisterAll(Serializables);
			ModelImporterPipeline.RegisterAll(Serializables);
			Mount = new NativeFileSystem(mRoot);
			Factory = new (stream, mode) => new BinarySerializerContext(stream, mode);
			Database = new ContentDatabase(Mount, Factory, "asset", Serializables);
		}

		public ~this()
		{
			RemoveDirectoryRecursive(mRoot);
		}
	}

	private static Guid G(uint8 a, uint8 b) => .(a, 0, 0, 0, 0, 0, 0, 0, 0, 0, b);

	private static void AddNode(ModelManifestAsset asset, StringView name, int32 parent, int32 mesh, Float3 position)
	{
		let m = asset.Manifest;
		m.NodeName.Add(new String(name));
		m.NodeParent.Add(parent);
		m.NodeTranslation.Add(position);
		m.NodeRotation.Add(.Identity);
		m.NodeScale.Add(.(1, 1, 1));
		m.NodeMesh.Add(mesh);
	}

	[Test]
	public static void AManifestBecomesASpawnablePrefabAndRegenerationReusesTheInstance()
	{
		let fx = scope Fixture("scratch_model_prefab_test_db");
		let meshStatic = G(0x51, 1);
		let meshSkinned = G(0x52, 2);
		let matA = G(0x61, 1);
		let matB = G(0x62, 2);
		let skeleton = G(0x71, 1);
		let clip = G(0x72, 1);

		let asset = scope ModelManifestAsset();
		asset.Manifest.MeshGuid.Add(meshStatic);
		asset.Manifest.MeshGuid.Add(meshSkinned);
		asset.Manifest.MeshSkinned.Add(false);
		asset.Manifest.MeshSkinned.Add(true);
		asset.Manifest.MeshMaterial.Add(1);
		asset.Manifest.MeshMaterial.Add(0);
		asset.Manifest.MaterialGuid.Add(matA);
		asset.Manifest.MaterialGuid.Add(matB);
		asset.Manifest.SkeletonGuid = skeleton;
		asset.Manifest.AnimationGuid.Add(clip);
		AddNode(asset, "Armature", -1, -1, .(0, 0, 0));
		AddNode(asset, "Body", 0, 0, .(1, 2, 3));
		AddNode(asset, "Skin", 0, 1, .(0, 0, 0));

		let group = fx.Database.RootGroup.CreateGroup("Fox");
		Test.Assert(group != null);
		let manifest = group.CreateInstance("Fox", typeof(ModelManifestAsset).GetFullName(.. scope .()));
		Test.Assert(manifest != null);
		Test.Assert(manifest.WriteObject(asset) case .Ok);

		let generated = ModelPrefab.GenerateModelPrefab(manifest);
		Test.Assert(generated.Instance != null);
		Test.Assert(!generated.Regenerated);
		Test.Assert(generated.Instance.Name == "Prefab");
		Test.Assert(generated.Instance.TypeName.EndsWith(".PrefabDocument"));
		let prefabId = generated.Instance.Id;

		// The payload spawns: the root named after the model, the node tree under it.
		let payload = generated.Instance.ReadData("scene");
		Test.Assert(payload != null);
		defer delete payload;
		let level = scope Scene("level");
		let meshes = level.AddSystem<MeshComponentManager>();
		let anims = level.AddSystem<SkeletalAnimationComponentManager>();
		let root = PrefabSpawn.Spawn(level, payload, prefabId);
		Test.Assert(root.IsAssigned);
		Test.Assert(level.GetEntityName(root) == "Fox");
		let armature = level.GetFirstChild(root);
		Test.Assert(armature.IsAssigned);
		Test.Assert(level.GetEntityName(armature) == "Armature");

		var meshCount = 0;
		var sawStatic = false, sawSkinned = false;
		meshes.ForEach(scope [&](c, e) =>
		{
			meshCount++;
			if (c.Mesh.Id == meshStatic)
			{
				sawStatic = true;
				Test.Assert(c.Materials.Count == 2); // the unified material list
				Test.Assert(c.Materials[0].Id == matA);
				Test.Assert(c.Materials[1].Id == matB);
				Test.Assert(level.GetLocalTransform(e).Position.X == 1.0f);
			}
			if (c.Mesh.Id == meshSkinned)
			{
				sawSkinned = true;
				Test.Assert(c.Materials.Count == 2);
			}
		});
		Test.Assert((meshCount == 2) && sawStatic && sawSkinned);

		// One animator for the whole model, on the root, feeding the skinned mesh only.
		var animCount = 0;
		anims.ForEach(scope [&](c, e) =>
		{
			animCount++;
			Test.Assert(c.Skeleton.Id == skeleton);
			Test.Assert(c.Clip.Id == clip);
			Test.Assert(e == root);
			Test.Assert(c.MeshEntities.Count == 1);
			let fed = level.FindEntity(c.MeshEntities[0].Id);
			Test.Assert(fed.IsAssigned);
			let fedMesh = meshes.Get(fed);
			Test.Assert((fedMesh != null) && (fedMesh.Mesh.Id == meshSkinned));
		});
		Test.Assert(animCount == 1);

		let again = ModelPrefab.GenerateModelPrefab(manifest);
		Test.Assert(again.Instance != null);
		Test.Assert(again.Regenerated);
		Test.Assert(again.Instance.Id == prefabId);
	}

	/// A manifest that records slots binds only what each mesh draws; one that records none
	/// keeps the whole table, which is what its submeshes index.
	[Test]
	public static void ASlottedMeshBindsOnlyItsOwnMaterials()
	{
		let fx = scope Fixture("scratch_model_prefab_slot_db");
		let meshNarrow = G(0x53, 1);
		let meshWhole = G(0x54, 2);
		let matA = G(0x61, 1);
		let matB = G(0x62, 2);
		let matC = G(0x63, 3);

		let asset = scope ModelManifestAsset();
		let m = asset.Manifest;
		m.MeshGuid.Add(meshNarrow);
		m.MeshGuid.Add(meshWhole);
		m.MeshSkinned.Add(false);
		m.MeshSkinned.Add(false);
		m.MaterialGuid.Add(matA);
		m.MaterialGuid.Add(matB);
		m.MaterialGuid.Add(matC);
		int32[2] narrow = .(2, 0); // the third material, then the first
		m.AddMeshMaterialSlots(.(&narrow[0], narrow.Count));
		m.AddMeshMaterialSlots(.()); // no slots recorded for the second
		AddNode(asset, "Root", -1, -1, .(0, 0, 0));
		AddNode(asset, "Narrow", 0, 0, .(0, 0, 0));
		AddNode(asset, "Whole", 0, 1, .(0, 0, 0));

		let group = fx.Database.RootGroup.CreateGroup("Slots");
		Test.Assert(group != null);
		let manifest = group.CreateInstance("Slots", typeof(ModelManifestAsset).GetFullName(.. scope .()));
		Test.Assert(manifest != null);
		Test.Assert(manifest.WriteObject(asset) case .Ok);

		let generated = ModelPrefab.GenerateModelPrefab(manifest);
		Test.Assert(generated.Instance != null);
		let payload = generated.Instance.ReadData("scene");
		Test.Assert(payload != null);
		defer delete payload;
		let level = scope Scene("level");
		let meshes = level.AddSystem<MeshComponentManager>();
		Test.Assert(PrefabSpawn.Spawn(level, payload, generated.Instance.Id).IsAssigned);

		var sawNarrow = false, sawWhole = false;
		meshes.ForEach(scope [&](c, e) =>
		{
			if (c.Mesh.Id == meshNarrow)
			{
				sawNarrow = true;
				// The slots in their own order, which is what its submeshes index.
				Test.Assert(c.Materials.Count == 2);
				Test.Assert(c.Materials[0].Id == matC);
				Test.Assert(c.Materials[1].Id == matA);
			}
			if (c.Mesh.Id == meshWhole)
			{
				sawWhole = true;
				Test.Assert(c.Materials.Count == 3);
			}
		});
		Test.Assert(sawNarrow && sawWhole);
	}

	[Test]
	public static void AManifestBecomesAStandaloneSceneAndRegenerationReusesTheInstance()
	{
		let fx = scope Fixture("scratch_model_scene_test_db");
		let meshStatic = G(0x51, 1);
		let matA = G(0x61, 1);
		let asset = scope ModelManifestAsset();
		asset.Manifest.MeshGuid.Add(meshStatic);
		asset.Manifest.MeshSkinned.Add(false);
		asset.Manifest.MaterialGuid.Add(matA);
		AddNode(asset, "Root", -1, -1, .(0, 0, 0));
		AddNode(asset, "Body", 0, 0, .(4, 5, 6));

		let group = fx.Database.RootGroup.CreateGroup("Crate");
		Test.Assert(group != null);
		let manifest = group.CreateInstance("Crate", typeof(ModelManifestAsset).GetFullName(.. scope .()));
		Test.Assert(manifest != null);
		Test.Assert(manifest.WriteObject(asset) case .Ok);

		let generated = ModelPrefab.GenerateModelScene(manifest);
		Test.Assert(generated.Instance != null);
		Test.Assert(!generated.Regenerated);
		Test.Assert(generated.Instance.Name == "Scene");
		Test.Assert(generated.Instance.TypeName.EndsWith(".SceneDocument"));
		let sceneId = generated.Instance.Id;

		let doc = generated.Instance.ReadObject();
		defer delete doc;
		let sd = doc as SceneDocument;
		Test.Assert(sd != null);
		Test.Assert(sd.Name == "Crate");

		let loaded = scope Scene();
		let meshes = loaded.AddSystem<MeshComponentManager>();
		loaded.AddSystem<SkeletalAnimationComponentManager>();
		Test.Assert(SceneStorage.LoadScene(generated.Instance, loaded) case .Ok);
		Test.Assert(loaded.EntityCount == 3); // the Crate root, Root, Body; nothing auto added

		Test.Assert(loaded.FindEntityByName("Crate").IsAssigned);
		let body = loaded.FindEntityByName("Body");
		Test.Assert(body.IsAssigned);
		Test.Assert(loaded.GetLocalTransform(body).Position.X == 4.0f);

		var meshCount = 0;
		meshes.ForEach(scope [&](c, e) =>
		{
			meshCount++;
			Test.Assert(c.Mesh.Id == meshStatic);
			Test.Assert(c.Materials.Count == 1);
			Test.Assert(c.Materials[0].Id == matA);
		});
		Test.Assert(meshCount == 1);

		let regen = ModelPrefab.GenerateModelScene(manifest);
		Test.Assert(regen.Instance != null);
		Test.Assert(regen.Regenerated);
		Test.Assert(regen.Instance.Id == sceneId);
	}
}
