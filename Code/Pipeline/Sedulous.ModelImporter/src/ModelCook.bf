using System;
using System.Collections;
using Sedulous.Animation.Pipeline;
using Sedulous.Animation.Resource;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Geometry.Pipeline;
using Sedulous.Model;
using Sedulous.Model.Resource;
using Sedulous.Pipeline.Core;

namespace Sedulous.ModelImporter;

/// Cooking a whole loaded model into a content database.
///
/// Everything a model carries becomes its own instance, and a MANIFEST records their
/// identities plus the node hierarchy. The runtime binds the manifest, which pulls the meshes
/// and materials in behind it and spawns the hierarchy the file described.
///
/// Hierarchy PRESERVING, deliberately: a node becomes an entity rather than every mesh being
/// merged into one, so what the author built is what arrives.
static class ModelCook
{
	/// Whether a mesh carries skinning at all.
	public static bool IsSkinned(ModelMesh mesh)
	{
		let elements = mesh.VertexElements;
		for (int i < elements.Length)
		{
			if (elements[i].Semantic == .Joints)
				return true;
		}
		return false;
	}

	/// Cooks the model and writes the manifest's identity, which is what to bind at runtime.
	///
	/// The prefix namespaces every instance created, so two models in one database cannot
	/// collide over a name they happen to share.
	public static Result<Guid, ErrorCode> Cook(Model model, ContentDatabase outDb,
		StringView namePrefix)
	{
		let root = outDb.RootGroup;
		if (root == null)
			return .Err(.Unknown);

		let manifest = scope ModelManifestSource();
		model.CalculateBounds();
		manifest.BoundsMin = model.Bounds.Min;
		manifest.BoundsMax = model.Bounds.Max;

		let textureGuids = scope List<Guid>();
		ModelCookTextures.Cook(model, root, namePrefix, textureGuids);
		ModelCookMaterials.Cook(model, root, namePrefix, textureGuids, manifest.MaterialGuid,
			manifest.MaterialAlbedo);

		// The skeleton and its animations, from the FIRST skin. A model with several is rare
		// and would need a manifest that can carry more than one.
		let boneToJoint = scope Dictionary<int32, int32>();
		let hasSkin = !model.Skins.IsEmpty;
		if (hasSkin)
			CookSkeletonAndAnimations(model, root, namePrefix, boneToJoint, manifest);

		if (CookMeshes(model, root, namePrefix, hasSkin, manifest) case .Err(let meshError))
			return .Err(meshError);

		CookNodes(model, manifest);

		let manifestInstance = root.CreateInstance(scope $"{namePrefix}.model",
			"Sedulous.Model.Resource.ModelManifestSource");
		if (manifestInstance == null)
			return .Err(.Unknown);
		if (manifestInstance.WriteObject(manifest) case .Err(let writeError))
			return .Err(writeError);

		return .Ok(manifestInstance.Id);
	}

	private static void CookSkeletonAndAnimations(Model model, Group root, StringView namePrefix,
		Dictionary<int32, int32> boneToJoint, ModelManifestSource manifest)
	{
		let skin = model.Skins[0];
		AnimConvert.BuildBoneToJoint(skin, boneToJoint);

		let skeletonAsset = scope SkeletonAsset();
		AnimConvert.SkeletonFromModel(model, skin, boneToJoint, skeletonAsset.Source);

		let skeletonInstance = root.CreateInstance(scope $"{namePrefix}.skeleton",
			"Sedulous.Animation.Resource.SkeletonSource");
		if (skeletonInstance != null)
		{
			let context = scope AssetBuildContext();
			context.Output = skeletonInstance;
			if (scope SkeletonAssetBuilder().Build(skeletonAsset, context) case .Ok)
				manifest.SkeletonGuid = skeletonInstance.Id;
		}

		let clipBuilder = scope AnimationClipAssetBuilder();
		let animations = model.Animations;
		for (int a < animations.Length)
		{
			let clipName = scope String();
			ImportedNames.ForAsset(animations[a].Name, "anim", a, clipName);
			let qualified = scope $"{namePrefix}.{clipName}";

			let clipAsset = scope AnimationClipAsset();
			AnimConvert.ClipFromModel(animations[a], boneToJoint, qualified, clipAsset.Source);

			let clipInstance = root.CreateInstance(qualified,
				"Sedulous.Animation.Resource.AnimationClipSource");
			if (clipInstance == null)
				continue;

			let context = scope AssetBuildContext();
			context.Output = clipInstance;
			if (clipBuilder.Build(clipAsset, context) case .Ok)
				manifest.AnimationGuid.Add(clipInstance.Id);
		}
	}

	private static Result<void, ErrorCode> CookMeshes(Model model, Group root,
		StringView namePrefix, bool hasSkin, ModelManifestSource manifest)
	{
		let staticBuilder = scope StaticMeshAssetBuilder();
		let skinnedBuilder = scope SkinnedMeshAssetBuilder();

		let meshes = model.Meshes;
		for (int i < meshes.Length)
		{
			let mesh = meshes[i];
			let skinned = IsSkinned(mesh) && hasSkin;

			let meshName = scope String();
			ImportedNames.ForAsset(mesh.Name, "mesh", i, meshName);

			let instance = root.CreateInstance(scope $"{namePrefix}.{meshName}",
				skinned ? "Sedulous.Geometry.SkinnedMeshSource" : "Sedulous.Geometry.StaticMeshSource");
			if (instance == null)
				return .Err(.Unknown);

			let context = scope AssetBuildContext();
			context.Output = instance;

			Result<void, ErrorCode> built;
			if (skinned)
			{
				let asset = scope SkinnedMeshAsset();
				MeshConvert.SkinnedFromModel(mesh, 0, asset.Source);
				built = skinnedBuilder.Build(asset, context);
			}
			else
			{
				let asset = scope StaticMeshAsset();
				MeshConvert.StaticFromModel(mesh, asset.Source);
				built = staticBuilder.Build(asset, context);
			}

			if (built case .Err(let buildError))
				return .Err(buildError);

			manifest.MeshGuid.Add(instance.Id);
			manifest.MeshSkinned.Add(skinned);
			// ONE material per mesh, taken from the first submesh, which is what a manifest
			// can carry: a mesh with several materials keeps them in its own submesh table.
			let parts = mesh.Parts;
			manifest.MeshMaterial.Add(parts.IsEmpty ? -1 : parts[0].MaterialIndex);
		}
		return .Ok;
	}

	private static void CookNodes(Model model, ModelManifestSource manifest)
	{
		let bones = model.Bones;
		for (int i < bones.Length)
		{
			let bone = bones[i];
			manifest.NodeName.Add(new String(bone.Name));
			manifest.NodeParent.Add(bone.ParentIndex);
			manifest.NodeTranslation.Add(bone.Translation);
			manifest.NodeRotation.Add(bone.Rotation);
			manifest.NodeScale.Add(bone.Scale);
			manifest.NodeMesh.Add(bone.MeshIndex);
		}
	}
}
