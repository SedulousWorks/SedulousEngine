using System;
using Sedulous.Animation.Resource;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;

namespace Sedulous.Animation.Pipeline;

/// Cooks the authored clip into its product: written verbatim, or, when the clip extracts root
/// motion, a working copy with the root's travel baked into its curve and stripped from its pose
/// (root-motion.md P0). The runtime factory rebuilds what it needs from the same wire.
class AnimationClipAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(AnimationClipAsset);
	public Type ProductType => typeof(AnimationClipSource);
	/// Two: the root motion bake and strip, and the record's appended fields; every clip re-cooks.
	public int32 Version => 2;

	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let authored = (AnimationClipAsset)asset;
		// A renamed or rebuilt skeleton re-cooks the clip.
		if (authored.Source.RootMotionAny && !authored.Skeleton.IsNil)
			outDeps.Reads.Add(authored.Skeleton);
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let authored = (AnimationClipAsset)asset;
		if (!authored.Source.RootMotionAny)
			return context.Output.WriteObject(authored.Source);

		let cooked = scope AnimationClipSource();
		cooked.CopyFrom(authored.Source);
		let root = RootMotionRoot(authored, context);
		if (root < -1)
			return .Err(.InvalidArgument);
		if (!RootMotionBake.Bake(cooked, root, authored.ModelRest))
		{
			GlobalLog(.Error, "Animation: clip '{}': root motion has no track to take from its root", authored.Source.Name);
			return .Err(.InvalidArgument);
		}
		return context.Output.WriteObject(cooked);
	}

	/// The root the clip's travel is taken from: the named bone, else the armature's own channels
	/// (model tracks) when the clip has them, else the skeleton's first root. Minus two, and a
	/// logged reason, when it cannot be found.
	private static int32 RootMotionRoot(AnimationClipAsset authored, AssetBuildContext context)
	{
		let name = authored.Source.RootBone;
		if (name.IsEmpty)
		{
			for (let bone in authored.Source.TrackBone)
			{
				if (bone < 0)
					return -1;
			}
		}
		let instance = ((context.SourceDatabase != null) && !authored.Skeleton.IsNil)
			? context.SourceDatabase.GetInstance(authored.Skeleton) : null;
		let object = (instance != null) ? instance.ReadObject() : null;
		defer { if (object != null) delete object; }
		let skeleton = object as SkeletonAsset;
		if (skeleton == null)
		{
			GlobalLog(.Error, "Animation: clip '{}': root motion needs its skeleton, which it does not name", authored.Source.Name);
			return -2;
		}
		let bones = skeleton.Source;
		for (int i < bones.BoneName.Count)
		{
			let match = name.IsEmpty ? ((i < bones.ParentIndex.Count) && (bones.ParentIndex[i] < 0)) : (bones.BoneName[i] == name);
			if (match)
				return (int32)i;
		}
		GlobalLog(.Error, "Animation: clip '{}': root motion's root bone '{}' is not in its skeleton", authored.Source.Name, name);
		return -2;
	}
}
