using System;
using Sedulous.Animation.Resource;
using Sedulous.Core;
using Sedulous.Pipeline.Core;

namespace Sedulous.Animation.Pipeline;

/// Cooks the authored skeleton into its product, written verbatim: the runtime factory rebuilds
/// what it needs from the same wire.
class SkeletonAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(SkeletonAsset);
	public Type ProductType => typeof(SkeletonSource);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let authored = (SkeletonAsset)asset;
		return context.Output.WriteObject(authored.Source);
	}
}
