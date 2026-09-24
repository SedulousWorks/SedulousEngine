using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Resource;
using Sedulous.Materials;
using Sedulous.Scene;
using Sedulous.Scene.Resource;
using Sedulous.Model.Resource;
using Sedulous.ModelImporter;
using Sedulous.Engine.Render;
using Sedulous.Engine.Animation;
using Sedulous.Engine.Physics;

namespace Sedulous.Editor.Scene;

/// A model manifest as a prefab or a scene: its node tree under one root, a mesh component
/// per meshed node with the manifest's materials, a cooked collider where the import made
/// one, and one skeletal animator on the root feeding every skinned mesh.
static class ModelPrefab
{
	/// Builds the model's entities into `scene`, answering the root; false when the manifest
	/// does not read back.
	public static bool BuildModelScene(Instance manifestInstance, Sedulous.Scene.Scene scene,
		out EntityHandle outRoot)
	{
		outRoot = .Invalid;
		let object = manifestInstance.ReadObject();
		defer delete object;
		let asset = object as ModelManifestAsset;
		if (asset == null)
		{
			GlobalLog(.Error, "Editor: model prefab/scene: manifest '{}' failed to read back", manifestInstance.Name);
			return false;
		}
		let manifest = asset.Manifest;
		let nodes = scope List<ModelNode>();
		defer { ClearAndDeleteItems(nodes); }
		manifest.FillNodes(nodes);

		let meshes = scene.AddSystem<MeshComponentManager>();
		let anims = scene.AddSystem<SkeletalAnimationComponentManager>();
		let hasCollision = !manifest.CollisionGuid.IsEmpty;
		let rigidBodies = hasCollision ? scene.AddSystem<RigidBodyComponentManager>() : null;
		let colliders = hasCollision ? scene.AddSystem<ColliderComponentManager>() : null;

		let root = scene.CreateEntity(manifestInstance.Name);
		let entities = scope List<EntityHandle>();
		for (let node in nodes)
		{
			let e = scene.CreateEntity(node.Name);
			scene.SetLocalTransform(e, node.LocalTransform);
			entities.Add(e);
		}
		let animated = !manifest.SkeletonGuid.IsNil && !manifest.AnimationGuid.IsEmpty;
		let skinnedEntities = scope List<EntityHandle>();
		for (int i < nodes.Count)
		{
			let node = nodes[i];
			if ((node.ParentIndex >= 0) && (node.ParentIndex < entities.Count))
				scene.SetParent(entities[i], entities[node.ParentIndex]);
			else
				scene.SetParent(entities[i], root); // a top level node hangs off the prefab root
			if ((node.MeshIndex < 0) || (node.MeshIndex >= manifest.MeshGuid.Count))
				continue;
			let meshIndex = node.MeshIndex;
			if (manifest.MeshGuid[meshIndex].IsNil)
				continue;
			let mc = meshes.Add(entities[i]);
			mc.Mesh.SetId(manifest.MeshGuid[meshIndex]);
			BindMeshMaterials(manifest, meshIndex, mc.Materials);

			if ((colliders != null) && (meshIndex < manifest.CollisionGuid.Count)
				&& !manifest.CollisionGuid[meshIndex].IsNil)
			{
				let cc = colliders.Add(entities[i]);
				cc.Shape = .Cooked;
				cc.CollisionShape.SetId(manifest.CollisionGuid[meshIndex]);
			}

			let skinned = (meshIndex < manifest.MeshSkinned.Count) && manifest.MeshSkinned[meshIndex];
			if (skinned && animated)
				skinnedEntities.Add(entities[i]);
		}

		if (!skinnedEntities.IsEmpty)
		{
			let ac = anims.Add(root);
			ac.Skeleton.SetId(manifest.SkeletonGuid);
			ac.Clip.SetId(manifest.AnimationGuid[0]);
			for (let e in skinnedEntities)
				ac.MeshEntities.Add(EntityRef(scene.GetEntityId(e)));
		}

		if (rigidBodies != null)
		{
			var anyCollider = false;
			for (let g in manifest.CollisionGuid)
				anyCollider = anyCollider || !g.IsNil;
			if (anyCollider)
			{
				// A static body on the root, so the child colliders have something to hang off.
				let body = rigidBodies.Add(root);
				body.Motion = .Static;
				body.Layer = .Static;
				body.HalfExtents = .(0.01f, 0.01f, 0.01f);
			}
		}

		outRoot = root;
		return true;
	}

	/// Writes the model as "Prefab" beside its manifest, refreshing an existing one.
	public static ModelPrefabResult GenerateModelPrefab(Instance manifestInstance)
	{
		var result = ModelPrefabResult();
		let scene = scope Sedulous.Scene.Scene(manifestInstance.Name);
		EntityHandle root = ?;
		if (!BuildModelScene(manifestInstance, scene, out root))
			return result;

		let payload = scope MemoryStream();
		if (!(PrefabCapture.Capture(scene, root, payload) case .Ok))
		{
			GlobalLog(.Error, "Editor: model prefab: capture failed for '{}'", manifestInstance.Name);
			return result;
		}

		let prefab = SiblingInstance(manifestInstance.OwningGroup, "Prefab", typeof(PrefabDocument).GetFullName(.. scope .()), out result.Regenerated);
		if (prefab == null)
		{
			GlobalLog(.Error, "Editor: model prefab: could not create the 'Prefab' instance beside '{}'", manifestInstance.Name);
			return result;
		}

		let doc = scope PrefabDocument();
		doc.Name.Set(manifestInstance.Name);
		if (!(prefab.WriteObject(doc) case .Ok) || !(prefab.WriteData("scene", payload.Bytes, .Text) case .Ok))
		{
			GlobalLog(.Error, "Editor: model prefab write failed for '{}'", manifestInstance.Name);
			result.Regenerated = false;
			return result;
		}
		result.Instance = prefab;
		return result;
	}

	/// Writes the model as a standalone "Scene" beside its manifest, refreshing an existing
	/// one.
	public static ModelPrefabResult GenerateModelScene(Instance manifestInstance)
	{
		var result = ModelPrefabResult();
		let scene = scope Sedulous.Scene.Scene(manifestInstance.Name);
		EntityHandle root = ?;
		if (!BuildModelScene(manifestInstance, scene, out root))
			return result;

		let sceneInstance = SiblingInstance(manifestInstance.OwningGroup, "Scene", typeof(SceneDocument).GetFullName(.. scope .()), out result.Regenerated);
		if (sceneInstance == null)
		{
			GlobalLog(.Error, "Editor: model scene: could not create the 'Scene' instance beside '{}'", manifestInstance.Name);
			return result;
		}

		if (!(SceneStorage.SaveScene(scene, sceneInstance) case .Ok))
		{
			GlobalLog(.Error, "Editor: model scene write failed for '{}'", manifestInstance.Name);
			result.Regenerated = false;
			return result;
		}
		result.Instance = sceneInstance;
		return result;
	}

	/// The instance named `name` in the group, reused when it already is a `typeName`; a
	/// same named instance of another type is left alone and "<name>.2" is used instead.
	private static Instance SiblingInstance(Group group, StringView name, StringView typeName,
		out bool regenerated)
	{
		var instance = group.GetInstance(name);
		if ((instance != null) && (instance.TypeName != typeName))
		{
			let alternate = scope $"{name}.2";
			instance = group.GetInstance(alternate);
			if (instance == null)
				instance = group.CreateInstance(alternate, typeName);
		}
		regenerated = instance != null;
		if (instance == null)
			instance = group.CreateInstance(name, typeName);
		return instance;
	}

	/// Fills a mesh component's material list from the manifest.
	///
	/// The manifest records the slots each mesh uses and its submeshes index THAT run, so an
	/// entity binds only the materials it draws rather than the model's whole table: a model
	/// sharing one table across thousands of nodes gave every one of them all of it. A
	/// manifest recording no slots leaves the whole table, which is what its submeshes index.
	public static void BindMeshMaterials(ModelManifestSource manifest, int meshIndex,
		List<Ref<Material>> outMaterials)
	{
		let slots = manifest.MaterialSlotsOf(meshIndex);
		if (slots.IsEmpty)
		{
			for (let g in manifest.MaterialGuid)
				outMaterials.Add(Ref<Material>(g));
			return;
		}
		for (let slot in slots)
		{
			// An unresolvable slot stays an EMPTY ref rather than shifting the ones after it,
			// which would bind every later submesh to the wrong material.
			let resolved = ((slot >= 0) && (slot < manifest.MaterialGuid.Count))
				? manifest.MaterialGuid[slot] : Guid.Empty;
			outMaterials.Add(Ref<Material>(resolved));
		}
	}
}
