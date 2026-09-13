using System;
using Sedulous.Core;
using Sedulous.Materials.Resource;
using Sedulous.Pipeline.Core;

namespace Sedulous.Materials.Pipeline;

/// Cooks the authored material into its product.
class MaterialAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(MaterialAsset);
	public Type ProductType => typeof(MaterialSource);

	/// Two: the property arrays carry full names now, and the reader REFUSES a product cooked
	/// under the older record version, so the recipe hash has to change to re-cook it.
	public int32 Version => 2;

	/// A bound texture is a runtime REFERENCE: its product has to exist, but editing the
	/// texture never re-cooks the material, since the factory re-binds when it loads.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let material = (MaterialAsset)asset;
		for (let id in material.Source.TextureIds)
		{
			if (id != Guid())
				outDeps.References.Add(id);
		}
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let material = (MaterialAsset)asset;
		return context.Output.WriteObject(material.Source);
	}
}
