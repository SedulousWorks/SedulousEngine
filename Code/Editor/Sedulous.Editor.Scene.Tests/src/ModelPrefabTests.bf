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
using Sedulous.Scene.Pipeline;
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

	/// The animator starts on the model's idle, found among the manifest's sibling clips by
	/// name, not on whichever clip sorts first (a kit's "Death" or "Bite_Front").
	[Test]
	public static void TheAnimatorStartsOnTheModelsIdle()
	{
		let fx = scope Fixture("scratch_model_resting_clip_db");
		let group = fx.Database.RootGroup.CreateGroup("Hero");
		let manifest = group.CreateInstance("Hero", typeof(ModelManifestAsset).GetFullName(.. scope .()));
		let asset = scope ModelManifestAsset();
		let clipType = "Sedulous.Animation.Pipeline.AnimationClipAsset";
		Guid Clip(uint8 tag, StringView name)
		{
			let id = G(tag, 1);
			group.CreateInstanceWithId(id, name, clipType);
			asset.Manifest.AnimationGuid.Add(id);
			return id;
		}
		Clip(0x81, "Death");
		Clip(0x82, "Idle_Gun");
		Clip(0x83, "Idle");
		Test.Assert(ModelPrefab.RestingClip(manifest, asset.Manifest) == 2, "the exact name");
		asset.Manifest.AnimationGuid.RemoveAt(2);
		Test.Assert(ModelPrefab.RestingClip(manifest, asset.Manifest) == 1, "else one containing it");
		asset.Manifest.AnimationGuid.RemoveAt(1);
		Test.Assert(ModelPrefab.RestingClip(manifest, asset.Manifest) == 0, "else the first");
	}

	/// A skin draws in its skeleton's parent's space and glTF ignores a skinned mesh node's own
	/// transform: the prefab puts the mesh entity under that parent at identity, so its world is
	/// the skeleton's model space (inverse-kinematics.md P0a). Nodes: Root; Armature (moved and
	/// turned, the skeleton's parent); Hips (a joint); Skin (the skinned mesh, a sibling of the
	/// armature carrying an offset the file says to ignore); Rig (a node under the mesh).
	[Test]
	public static void ASkinnedMeshSitsAtIdentityUnderTheSkeletonsParentNode()
	{
		let fx = scope Fixture("scratch_model_prefab_skeleton_space_db");
		var generation = 0;
		// Generates and spawns the model with `skeletonParentNode`; answers the skinned mesh.
		EntityHandle Spawn(Scene level, int32 skeletonParentNode)
		{
			let asset = scope ModelManifestAsset();
			let m = asset.Manifest;
			m.MeshGuid.Add(G(0x52, 7));
			m.MeshSkinned.Add(true);
			m.MeshMaterial.Add(-1);
			m.AddMeshMaterialSlots(.());
			m.SkeletonGuid = G(0x71, 7);
			m.AnimationGuid.Add(G(0x72, 7));
			m.SkeletonParentNode = skeletonParentNode;
			AddNode(asset, "Root", -1, -1, .(0, 0, 0));
			AddNode(asset, "Armature", 0, -1, .(2, 0, 1));
			m.NodeRotation[1] = Quaternion.FromAxisAngle(.(0, 1, 0), 1.5707964f);
			AddNode(asset, "Hips", 1, -1, .(0, 0, 0));
			AddNode(asset, "Skin", 0, 0, .(5, 5, 5));
			AddNode(asset, "Rig", 3, -1, .(0, 0, 0));

			let name = scope $"Rider{generation++}";
			let group = fx.Database.RootGroup.CreateGroup(name);
			Test.Assert(group != null);
			let manifest = group.CreateInstance(name, typeof(ModelManifestAsset).GetFullName(.. scope .()));
			Test.Assert(manifest != null);
			Test.Assert(manifest.WriteObject(asset) case .Ok);
			let generated = ModelPrefab.GenerateModelPrefab(manifest);
			Test.Assert(generated.Instance != null);
			let payload = generated.Instance.ReadData("scene");
			Test.Assert(payload != null);
			defer delete payload;
			level.AddSystem<MeshComponentManager>();
			level.AddSystem<SkeletalAnimationComponentManager>();
			Test.Assert(PrefabSpawn.Spawn(level, payload, generated.Instance.Id).IsAssigned);
			level.UpdateTransforms();
			let skin = level.FindEntityByName("Skin");
			Test.Assert(skin.IsAssigned);
			return skin;
		}
		bool SameMatrix(Float4x4 a, Float4x4 b)
		{
			for (int r < 4)
			{
				for (int c < 4)
				{
					if (Math.Abs(a.M[r][c] - b.M[r][c]) > 1e-5f)
						return false;
				}
			}
			return true;
		}

		// Under the armature: the mesh's world is the armature's.
		{
			let level = scope Scene("level");
			let skin = Spawn(level, 1);
			let armature = level.FindEntityByName("Armature");
			Test.Assert(level.GetParent(skin) == armature);
			Test.Assert(level.GetLocalTransform(skin).Position == Float3(0, 0, 0));
			Test.Assert(SameMatrix(level.GetWorldMatrix(skin), level.GetWorldMatrix(armature)));
			// The armature itself keeps the file's placement.
			Test.Assert(level.GetLocalTransform(armature).Position.X == 2.0f);
		}
		// A skeleton with no parent: the mesh sits on the prefab root.
		{
			let level = scope Scene("level");
			let skin = Spawn(level, -1);
			let root = level.GetParent(level.FindEntityByName("Root"));
			Test.Assert(level.GetParent(skin) == root);
			Test.Assert(level.GetLocalTransform(skin).Position.Y == 0.0f);
		}
		// A manifest from before the parent was recorded keeps the file's placement.
		{
			let level = scope Scene("level");
			let skin = Spawn(level, -2);
			Test.Assert(level.GetParent(skin) == level.FindEntityByName("Root"));
			Test.Assert(level.GetLocalTransform(skin).Position.Y == 5.0f);
		}
		// A parent under the mesh itself is left alone: no cycle.
		{
			let level = scope Scene("level");
			let skin = Spawn(level, 4);
			Test.Assert(level.GetParent(skin) == level.FindEntityByName("Root"));
			Test.Assert(level.GetParent(level.FindEntityByName("Rig")) == skin);
		}
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
