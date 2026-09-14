using System;
using System.Collections;
using Sedulous.Animation.Pipeline;
using Sedulous.Content;
using Sedulous.Model;
using Sedulous.Model.Resource;
using Sedulous.Pipeline.Importer;

namespace Sedulous.ModelImporter;

/// Fanning a model's skin out as a skeleton asset and its animations as clip assets.
///
/// The FIRST skin only: a model carrying several is rare, and a manifest that could name more
/// than one skeleton would have to say which mesh belongs to which.
static class ModelImportSkeleton
{
	private const String cSkeletonType = "Sedulous.Animation.Pipeline.SkeletonAsset";
	private const String cClipType = "Sedulous.Animation.Pipeline.AnimationClipAsset";

	public static void Import(Model model, Group group, ModelManifestSource manifest,
		List<String> claimed, ImportOptions options)
	{
		if (model.Skins.IsEmpty)
			return;

		let skin = model.Skins[0];
		let boneToJoint = scope Dictionary<int32, int32>();
		AnimConvert.BuildBoneToJoint(skin, boneToJoint);

		let skeletonName = scope String();
		ImportedNames.ForSkeleton(skin, skeletonName);
		if (options.SelectionEnabled(.Skeleton, skeletonName))
		{
			let asset = scope SkeletonAsset();
			AnimConvert.SkeletonFromModel(model, skin, boneToJoint, asset.Source);

			let instance = ClaimedInstances.Claim(group,
				options.SelectionName(.Skeleton, skeletonName), cSkeletonType, claimed);
			if ((instance != null) && (instance.WriteObject(asset) case .Ok))
				manifest.SkeletonGuid = instance.Id;
		}

		let animations = model.Animations;
		for (int a < animations.Length)
		{
			let clipName = scope String();
			ImportedNames.ForAsset(animations[a].Name, "anim", a, clipName);
			// A plain list with no slot to hold, so a deselected clip simply is not there.
			if (!options.SelectionEnabled(.AnimationClip, clipName))
				continue;

			let instance = ClaimedInstances.Claim(group,
				options.SelectionName(.AnimationClip, clipName), cClipType, claimed);

			let asset = scope AnimationClipAsset();
			AnimConvert.ClipFromModel(animations[a], boneToJoint,
				(instance != null) ? instance.Name : "anim", asset.Source);

			if ((instance != null) && (instance.WriteObject(asset) case .Ok))
				manifest.AnimationGuid.Add(instance.Id);
		}
	}
}
