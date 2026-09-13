using System;
using Sedulous.Core;
using Sedulous.Physics.Resource;
using Sedulous.Pipeline.Core;

namespace Sedulous.Physics.Pipeline;

/// Cooks the authored surface properties into their product.
class PhysicalMaterialAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(PhysicalMaterialAsset);
	public Type ProductType => typeof(PhysicalMaterialSource);

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let authored = (PhysicalMaterialAsset)asset;
		let cooked = scope PhysicalMaterialSource();
		cooked.Friction = authored.Friction;
		cooked.Restitution = authored.Restitution;
		cooked.Density = authored.Density;
		return context.Output.WriteObject(cooked);
	}
}
