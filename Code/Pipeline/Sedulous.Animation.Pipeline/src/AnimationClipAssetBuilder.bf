using System;
using Sedulous.Animation.Resource;
using Sedulous.Core;
using Sedulous.Pipeline.Core;

namespace Sedulous.Animation.Pipeline;

/// Cooks the authored clip into its product, written verbatim: the runtime factory rebuilds
/// what it needs from the same wire.
class AnimationClipAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(AnimationClipAsset);
	public Type ProductType => typeof(AnimationClipSource);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let authored = (AnimationClipAsset)asset;
		return context.Output.WriteObject(authored.Source);
	}
}
