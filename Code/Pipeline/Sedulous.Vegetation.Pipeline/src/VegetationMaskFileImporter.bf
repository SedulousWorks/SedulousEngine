using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Vegetation.Pipeline;

/// Imports an image as a vegetation mask: one density plane per channel.
///
/// An eight bit image is the authoring format, so a mask painted in another tool comes in as
/// it is; the cook reads each channel into its own plane.
class VegetationMaskFileImporter : IFileImporter
{
	private const String cAssetType = "Sedulous.Vegetation.Pipeline.VegetationMaskAsset";

	public StringView Label => "Vegetation Mask";

	public bool Accepts(StringView @extension) => (@extension == "png") || (@extension == "tga");

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

		let asset = scope VegetationMaskAsset();
		asset.FileName.Set(fileName);
		// One plane per channel; the cook reads the image's own size.
		asset.PlaneCount = 4;
		if (instance.WriteObject(asset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}
