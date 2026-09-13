using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Pipeline.Core;

namespace Sedulous.Pipeline.Cook.Tests;

/// Cooks the setting plus the size of its source file, so a case can tell which of the two
/// changed from the number alone.
class CookWidgetBuilder : IAssetBuilder
{
	/// Settable, so a case can bump it and watch every product of this builder re-cook.
	public static int32 CurrentVersion = 1;
	/// Settable, so a case can make the build fail on demand.
	public static bool ShouldFail = false;

	public Type AssetType => typeof(CookWidgetAsset);
	public Type ProductType => typeof(CookWidgetProduct);
	public int32 Version => CurrentVersion;

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (ShouldFail)
			return .Err(.Unknown);

		let widget = (CookWidgetAsset)asset;
		let product = scope CookWidgetProduct();
		product.CookedValue = widget.Quality;

		if (!widget.FileName.IsEmpty)
		{
			let bytes = scope List<uint8>();
			if (AssetSource.ReadBytes(context, widget.FileName.Value, bytes)
				case .Err(let readError))
			{
				return .Err(readError);
			}
			product.CookedValue += (int32)bytes.Count;
		}

		return context.Output.WriteObject(product);
	}
}
