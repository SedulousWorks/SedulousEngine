using System;
using Sedulous.Core;
using Sedulous.Model.Resource;
using Sedulous.Pipeline.Core;

namespace Sedulous.ModelImporter;

/// Writes the manifest through: the authored manifest IS the cooked one.
class ModelManifestAssetBuilder : IAssetBuilder
{
	public Type AssetType => typeof(ModelManifestAsset);
	public Type ProductType => typeof(ModelManifestSource);

	/// Everything a manifest names is a runtime REFERENCE: the products have to exist, but
	/// none of their content ever re-cooks the manifest, which holds identities only.
	public void ScanDependencies(Asset asset, AssetBuildContext context, AssetDependencies outDeps)
	{
		let manifest = ((ModelManifestAsset)asset).Manifest;
		for (let id in manifest.MeshGuid)
		{
			if (id != Guid.Empty)
				outDeps.References.Add(id);
		}
		for (let id in manifest.MaterialGuid)
		{
			if (id != Guid.Empty)
				outDeps.References.Add(id);
		}
		for (let id in manifest.MaterialAlbedo)
		{
			if (id != Guid.Empty)
				outDeps.References.Add(id);
		}
		for (let id in manifest.AnimationGuid)
		{
			if (id != Guid.Empty)
				outDeps.References.Add(id);
		}
		if (manifest.SkeletonGuid != Guid.Empty)
			outDeps.References.Add(manifest.SkeletonGuid);
	}

	public Result<void, ErrorCode> Build(Asset asset, AssetBuildContext context)
	{
		if (context.Output == null)
			return .Err(.InvalidArgument);
		return context.Output.WriteObject(((ModelManifestAsset)asset).Manifest);
	}
}
