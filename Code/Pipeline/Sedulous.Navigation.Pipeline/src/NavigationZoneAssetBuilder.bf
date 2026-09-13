using System;
using Sedulous.Core;
using Sedulous.Navigation.Resource;
using Sedulous.Pipeline.Core;

namespace Sedulous.Navigation.Pipeline;

/// Cooks a zone's baked navmesh into its product.
class NavigationZoneAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(NavigationZoneAsset);
	public Type ProductType => typeof(NavigationZoneSource);

	/// Three: the product lost the frame convention stamp, every bake being rigid frame.
	public int32 Version => 3;

	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		// The baked sidecar IS the build's input, so the recipe hash has to cover it: the
		// envelope carries nothing, and without this a re-bake would not dirty the cook.
		outDeps.AddSourceStream(NavigationZoneStorage.cNavMeshStreamName);
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let zone = (NavigationZoneAsset)asset;
		if (context.Source != null)
		{
			if (NavigationZoneStorage.EnsureNavMeshLoaded(context.Source, zone) case .Err(let error))
				return .Err(error);
		}

		let product = scope NavigationZoneSource();
		product.NavMeshBlob.AddRange(zone.NavMeshBlob);
		return context.Output.WriteObject(product);
	}
}
