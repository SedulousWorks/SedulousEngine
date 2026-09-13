using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;
using Sedulous.PropertyAnimation.Resource;

namespace Sedulous.PropertyAnimation.Pipeline;

/// Cooks the authored clip into its product, written verbatim: the runtime factory is what
/// rebuilds the evaluate ready clip from it.
class PropertyAnimationClipAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(PropertyAnimationClipAsset);
	public Type ProductType => typeof(PropertyAnimationClipSource);

	/// Two, since the dead loop field went: looping is the animator component's business.
	public int32 Version => 2;

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let clip = (PropertyAnimationClipAsset)asset;
		return context.Output.WriteObject(clip.Source);
	}
}
