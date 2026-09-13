using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Pipeline.Core;

namespace Sedulous.Geometry.Pipeline;

/// Cooks a static mesh: pulls the geometry sidecar, reorders it, and writes the product.
class StaticMeshAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(StaticMeshAsset);
	public Type ProductType => typeof(StaticMeshSource);

	/// Two: the source layout changed to a four component tangent plus a level of detail
	/// chain, with geometry never inline. The reader REFUSES a product cooked under the older
	/// record version, so the recipe hash has to change to re-cook it.
	public int32 Version => 2;

	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		// The geometry sidecar IS a build input, so the recipe hash has to cover it: the
		// envelope does not carry geometry, and without this a geometry only change would not
		// dirty the cook.
		outDeps.AddSourceStream(MeshAssetStorage.cGeometryStreamName);
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let mesh = (StaticMeshAsset)asset;
		if (context.Source != null)
		{
			if (MeshAssetStorage.EnsureStaticLoaded(context.Source, mesh) case .Err(let loadError))
				return .Err(loadError);
		}

		// The same triangles in a better order, plus dead vertex compaction. In place on this
		// cook's own copy, and idempotent on a re-cook.
		MeshOptimize.OptimizeStaticMeshSource(mesh.Source);
		return context.Output.WriteObject(mesh.Source);
	}
}
