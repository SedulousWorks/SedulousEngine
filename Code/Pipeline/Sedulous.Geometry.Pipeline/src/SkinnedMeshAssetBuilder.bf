using System;
using Sedulous.Core;
using Sedulous.Geometry;
using Sedulous.Pipeline.Core;

namespace Sedulous.Geometry.Pipeline;

/// Cooks a skinned mesh, in lockstep with the static one.
class SkinnedMeshAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(SkinnedMeshAsset);
	public Type ProductType => typeof(SkinnedMeshSource);

	/// Two, moving with the static builder: the mesh source layout is shared.
	public int32 Version => 2;

	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		outDeps.AddSourceStream(MeshAssetStorage.cGeometryStreamName);
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);

		let mesh = (SkinnedMeshAsset)asset;
		if (context.Source != null)
		{
			if (MeshAssetStorage.EnsureSkinnedLoaded(context.Source, mesh) case .Err(let loadError))
				return .Err(loadError);
		}

		// The parallel skinning stream is permuted with the IDENTICAL remap, so the two
		// streams cannot diverge.
		MeshOptimize.OptimizeStaticMeshSource(mesh.Source);
		return context.Output.WriteObject(mesh.Source);
	}
}
