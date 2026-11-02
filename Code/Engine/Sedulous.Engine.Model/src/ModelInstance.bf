using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Animation;
using Sedulous.Model.Resource;
using Sedulous.Engine.Render;
using Sedulous.Engine.Animation;

namespace Sedulous.Engine.Model;

// A cooked model (ModelResource) put into a scene as entities, outside any project's prefabs: what
// a host that cooks a model file at run time does with it (the import window's model preview). One
// entity per model node under a root, and a mesh component per node with a mesh (its own material
// list, from the manifest's slots). When the model is skinned, the root gets a skeletal animation
// component feeding its skinned meshes: the first clip playing, or none (the rig's rest pose; a
// skinned mesh fed nothing draws its raw vertices). Each unskinned mesh gets a bone attachment on
// the nearest bone node above it, which moves it with the animation (ModelPlacement.RigidMeshBone).
// A skinned mesh sits in its skeleton's space, as the project's model prefab puts it
// (ModelPlacement.SkinnedMeshParent). The model's resources stay alive while the caller keeps them.

/// What ModelInstances.Instantiate made: the root every node hangs from, the entities with a skinned
/// mesh, and whether the root plays a clip.
class ModelInstance
{
	public EntityHandle Root = .Invalid;
	public List<EntityHandle> Skinned = new .() ~ delete _;
	public bool Animated = false;
}

struct InstantiateOptions
{
	/// The root's own transform (its scale fits the model to a size, as the caller wants).
	public Transform RootTransform = .();
	/// The root's skeletal animation component plays the first clip (a skinned model with clips);
	/// off, it holds the rest pose. Either way a skinned model gets the component, which the caller
	/// may drive itself.
	public bool Animate = true;

	public this() {}
}

static class ModelInstances
{
	/// Puts `model` into `scene` under a new root named `name`, into `outInstance`. Needs the
	/// scene's mesh component manager (and the skeletal animation one to animate); without the mesh
	/// manager it makes nothing and the root stays invalid.
	public static void Instantiate(Scene scene, ModelResource model, StringView name, InstantiateOptions options,
		ModelInstance outInstance)
	{
		let meshes = scene.GetSystem<MeshComponentManager>();
		if (meshes == null)
			return;
		outInstance.Root = scene.CreateEntity(name);
		scene.SetLocalTransform(outInstance.Root, options.RootTransform);

		let entities = scope List<EntityHandle>();
		for (let node in model.Nodes)
		{
			let entity = scene.CreateEntity(node.Name);
			scene.SetLocalTransform(entity, node.LocalTransform);
			entities.Add(entity);
		}
		let slots = scope List<int32>();
		let materials = scope List<Material>();
		for (int i < model.Nodes.Count)
		{
			let node = model.Nodes[i];
			let hasParent = (node.ParentIndex >= 0) && (node.ParentIndex < entities.Count);
			scene.SetParent(entities[i], hasParent ? entities[node.ParentIndex] : outInstance.Root);
			if ((node.MeshIndex < 0) || (node.MeshIndex >= model.Meshes.Count))
				continue;
			let mesh = model.Mesh(node.MeshIndex);
			if (mesh == null)
				continue;
			let component = meshes.Add(entities[i]);
			component.Mesh.SetDirect(mesh);
			component.Color = .(1.0f, 1.0f, 1.0f, 1.0f);
			// The mesh's own material list: its submeshes index it, slot 0 covering anything out of range.
			model.MeshMaterialIndices(node.MeshIndex, slots);
			materials.Clear();
			for (let slot in slots)
				materials.Add(((slot >= 0) && (slot < model.Materials.Count)) ? model.Materials[slot].Get : null);
			component.SetMaterials(materials);
			if (model.MeshSkinned[node.MeshIndex])
			{
				// In the skeleton's space: under its parent node at identity (SkinnedMeshParent).
				let parent = ModelPlacement.SkinnedMeshParent(model.Nodes, model.SkeletonParentNode, i);
				if (parent != ModelPlacement.cSkinnedMeshKeepsPlace)
				{
					scene.SetParent(entities[i], (parent >= 0) ? entities[parent] : outInstance.Root);
					scene.SetLocalTransform(entities[i], .());
				}
				outInstance.Skinned.Add(entities[i]);
			}
		}

		// An unskinned mesh under a bone (a weapon in a hand) follows that bone: one attachment on
		// the nearest bone node above it, its children riding along.
		let skeleton = model.Skeleton.Get;
		let attachments = scene.GetSystem<BoneAttachmentComponentManager>();
		if ((skeleton != null) && (attachments != null))
		{
			for (int i < model.Nodes.Count)
			{
				let meshIndex = model.Nodes[i].MeshIndex;
				if ((meshIndex < 0) || (meshIndex >= model.Meshes.Count) || (model.Mesh(meshIndex) == null)
					|| model.MeshSkinned[meshIndex])
					continue;
				let bone = ModelPlacement.RigidMeshBone(model.Nodes, i, scope (boneName) => skeleton.FindBone(boneName) >= 0);
				if ((bone >= 0) && (attachments.Get(entities[bone]) == null))
					attachments.Add(entities[bone]).Bone.Set(model.Nodes[bone].Name);
			}
		}

		// A skinned model: the root feeds its skinned meshes, playing the first clip when asked and
		// there is one, else holding the rest pose.
		if ((skeleton != null) && !outInstance.Skinned.IsEmpty)
		{
			if (let animators = scene.GetSystem<SkeletalAnimationComponentManager>())
			{
				let animator = animators.Add(outInstance.Root);
				animator.Skeleton.SetDirect(skeleton);
				if (options.Animate && !model.Animations.IsEmpty && (model.Animations[0].Get != null))
				{
					animator.Clip.SetDirect(model.Animations[0].Get);
					outInstance.Animated = true;
				}
				for (let entity in outInstance.Skinned)
					animator.MeshEntities.Add(.(scene.GetEntityId(entity)));
			}
		}
	}
}
