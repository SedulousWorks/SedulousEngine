using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Terrain.Pipeline;

/// Imports an image as splat weights.
///
/// The builder reads it as a fixed layer raster, red being the base's share and the rest the
/// first three palette layers, which is how a flat image enters the top weights model.
class SplatmapFileImporter : IFileImporter
{
	private const String cAssetType = "Sedulous.Terrain.Pipeline.SplatmapAsset";

	public StringView Label => "Splatmap";

	public bool Accepts(StringView @extension) => @extension == "png";

	public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared,
		ImportPlan outPlan) => ImportPaths.SingleAssetPlan(sourcePath, outPlan);

	public void StoredSelection(Group group, StringView sourcePath, ImportPlan outPlan)
		=> ImportPaths.SingleAssetStoredSelection(group, sourcePath, cAssetType, outPlan);

	public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
		Group group, ImportOptions options, Object prepared,
		List<DeferredImportWrite> deferredWrites)
	{
		let fileName = scope String();
		if (ImportPaths.CopyIntoSources(context, sourcePath, fileName) case .Err(let copyError))
			return .Err(copyError);

		let stem = ImportPaths.StemOf(fileName);
		let instance = group.CreateInstance(ImportPaths.SingleAssetName(options, stem), cAssetType);
		if (instance == null)
			return .Err(.Unknown);

		let asset = scope SplatmapAsset();
		asset.FileName.Set(fileName);
		if (instance.WriteObject(asset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}
