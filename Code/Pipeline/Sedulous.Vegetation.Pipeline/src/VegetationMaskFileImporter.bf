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

		let asset = scope VegetationMaskAsset();
		asset.FileName.Set(fileName);
		// One plane per channel; the cook reads the image's own size.
		asset.PlaneCount = 4;
		if (instance.WriteObject(asset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}
