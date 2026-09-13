using System;
using Sedulous.Animation.Resource;
using Sedulous.Core;
using Sedulous.Pipeline.Core;

namespace Sedulous.Animation.Pipeline;

/// Cooks the authored animationGraph into its product, written verbatim: the runtime factory rebuilds
/// what it needs from the same wire.
class AnimationGraphAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(AnimationGraphAsset);
	public Type ProductType => typeof(AnimationGraphSource);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let authored = (AnimationGraphAsset)asset;
		return context.Output.WriteObject(authored.Source);
	}
}
