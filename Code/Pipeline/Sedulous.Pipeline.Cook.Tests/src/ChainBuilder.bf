using System;
using Sedulous.Core;
using Sedulous.Pipeline.Core;

namespace Sedulous.Pipeline.Cook.Tests;

/// Declares whichever dependencies its asset names and cooks a constant, since the VALUE is
/// not what a dependency case is about.
class ChainBuilder : IAssetBuilder
{
	public Type AssetType => typeof(ChainAsset);
	public Type ProductType => typeof(CookWidgetProduct);

	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let chain = (ChainAsset)asset;
		if (chain.ReadDep != Guid.Empty)
			outDeps.Reads.Add(chain.ReadDep);
		if (chain.RefDep != Guid.Empty)
			outDeps.References.Add(chain.RefDep);
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		let product = scope CookWidgetProduct();
		product.CookedValue = 42;
		return context.Output.WriteObject(product);
	}
}
