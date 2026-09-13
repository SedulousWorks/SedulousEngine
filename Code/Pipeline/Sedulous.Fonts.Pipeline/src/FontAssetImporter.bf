using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Fonts.Pipeline;

/// Imports a dropped font file.
class FontAssetImporter : IFileImporter
{
	private const String cAssetType = "Sedulous.Fonts.Pipeline.FontAsset";

	public StringView Label => "Font";

	public bool Accepts(StringView @extension)
		=> (@extension == "ttf") || (@extension == "otf") || (@extension == "ttc");

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

		let asset = scope FontAsset();
		asset.FileName.Set(fileName);
		// A sensible default; the cook falls back to the file's own family when this is empty,
		// and the author can replace it with either.
		asset.Family.Set(stem);

		if (instance.WriteObject(asset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}
