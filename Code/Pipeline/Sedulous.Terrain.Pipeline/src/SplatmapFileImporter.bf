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

	public StringView AssetTypeName(StringView sourcePath) => cAssetType;

	public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
		Group group, ImportOptions options, Object prepared,
		List<DeferredImportWrite> deferredWrites)
	{
		let fileName = scope String();
		// The name claimed by the clash rule, the file copied in beside any other's.
		let claimed = ImportPaths.ClaimSingleAsset(context, group, options, sourcePath, cAssetType, fileName);
		if (claimed case .Err(let claimError))
			return .Err(claimError);
		let instance = claimed.Value;

		let asset = scope SplatmapAsset();
		asset.FileName.Set(fileName);
		if (instance.WriteObject(asset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}
