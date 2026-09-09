using System;
using Sedulous.Animation;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Materials;
using Sedulous.Resource;
using Sedulous.Texture.Resource;

namespace Sedulous.Model.Resource;

/// Assembles a cooked manifest into a runtime model, resolving every leaf through the
/// manager.
///
/// SYNCHRONOUS: those binds ARE the model's dependency edges, and an edge is the manager's to
/// write on the thread that owns it. Each leaf still loads asynchronously on its own.
class ModelFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<ModelResource>();

	public Object Create(ResourceManager manager, Instance instance)
	{
		let stored = instance.ReadObject();
		if (stored == null)
			return null;

		let source = stored as ModelManifestSource;
		if (source == null)
		{
			delete stored;
			return null;
		}
		defer delete source;

		let model = new ModelResource();
		source.FillNodes(model.Nodes);
		model.MeshSkinned.AddRange(source.MeshSkinned);
		model.MeshMaterial.AddRange(source.MeshMaterial);
		model.BoundsMin = source.BoundsMin;
		model.BoundsMax = source.BoundsMax;

		BindMeshes(manager, source, model);
		BindSkeletonAndClips(manager, source, model);
		BindMaterials(manager, source, model);
		return model;
	}

	/// A skinned mesh binds as the skinned type and is kept as the base one: the renderer asks
	/// whether it is skinned and uploads the skin stream, so storing it twice would be two
	/// answers to one question.
	private static void BindMeshes(ResourceManager manager, ModelManifestSource source,
		ModelResource model)
	{
		for (int i = 0; i < source.MeshGuid.Count; i++)
		{
			let skinned = (i < source.MeshSkinned.Count) && source.MeshSkinned[i];
			model.Meshes.Add(skinned
				? .(manager.Bind<SkinnedMesh>(source.MeshGuid[i]).Handle)
				: manager.Bind<StaticMesh>(source.MeshGuid[i]));
		}
	}

	private static void BindSkeletonAndClips(ResourceManager manager, ModelManifestSource source,
		ModelResource model)
	{
		// A nil id is a model with no skin, which is most of them.
		if (source.SkeletonGuid != Guid())
			model.Skeleton = manager.Bind<Skeleton>(source.SkeletonGuid);

		for (let id in source.AnimationGuid)
		{
			if (id != Guid())
				model.Animations.Add(manager.Bind<AnimationClip>(id));
		}
	}

	/// The albedo is wired in as the MATERIAL'S OWN default rather than assigned per instance,
	/// because the renderer reads a material's defaults when it builds the instance: setting
	/// it here means every mesh drawing with this material already has it.
	private static void BindMaterials(ResourceManager manager, ModelManifestSource source,
		ModelResource model)
	{
		for (int i = 0; i < source.MaterialGuid.Count; i++)
		{
			let material = manager.Bind<Material>(source.MaterialGuid[i]);
			model.Materials.Add(material);

			if ((material.Get == null) || (i >= source.MaterialAlbedo.Count)
				|| (source.MaterialAlbedo[i] == Guid()))
				continue;

			let albedo = manager.Bind<Texture>(source.MaterialAlbedo[i]);
			// Still decoding, or failed: the slot stays unbound and the recorded edge brings
			// this material back once the texture settles.
			if ((albedo.Get == null) || (albedo.Get.View == null))
				continue;

			material.Get.SetDefaultTexture("AlbedoMap", albedo.Get.View);
		}
	}
}
