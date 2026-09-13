using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Heightfield.Pipeline;

/// Imports a sixteen bit heightmap.
///
/// Claims the raw extension and also the common image one, which puts it in the chooser
/// alongside the image and texture importers: the same file is a legitimate heightmap or a
/// legitimate picture, and only the author knows which.
class HeightfieldFileImporter : IFileImporter
{
	private const String cAssetType = "Sedulous.Heightfield.Pipeline.HeightfieldAsset";

	public StringView Label => "Heightfield";

	public bool Accepts(StringView @extension) => (@extension == "png") || (@extension == "r16");

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

		let asset = scope HeightfieldAsset();
		asset.FileName.Set(fileName);
		if (instance.WriteObject(asset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}
