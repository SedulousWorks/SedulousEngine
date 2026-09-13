using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Pipeline.Core;

namespace Sedulous.Pipeline.Cook.Tests;

/// Cooks a number that ENCODES the target, so a case can see which profile a product was built
/// under, plus a sidecar so the copy forward path's stream copy is exercised too.
class VariantBuilder : IAssetBuilder
{
	public Type AssetType => typeof(VariantAsset);
	public Type ProductType => typeof(CookWidgetProduct);
	public BuildVariance Variance => .PlatformVariant;

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		let product = scope CookWidgetProduct();
		product.CookedValue = context.Target.Astc ? 999 : 100;

		if (context.Output.WriteObject(product) case .Err(let writeError))
			return .Err(writeError);

		let payload = scope List<uint8>() { (uint8)product.CookedValue };
		return context.Output.WriteData("data", payload);
	}
}
