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
		let stem = ImportPaths.StemOf(ImportPaths.FileNameOf(sourcePath));

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
