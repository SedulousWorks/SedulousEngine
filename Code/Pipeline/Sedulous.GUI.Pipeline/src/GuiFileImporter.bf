using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.GUI.Pipeline;

/// Imports a dropped `.gml` or `.css`: STAGED into the sources tree and LINKED, as a document or a
/// sheet by its extension.
class GuiFileImporter : IFileImporter
{
	private const String cDocumentType = "Sedulous.GUI.Pipeline.GuiDocumentAsset";
	private const String cStyleSheetType = "Sedulous.GUI.Pipeline.GuiStyleSheetAsset";

	public StringView Label => "GUI document or style sheet";

	public bool Accepts(StringView @extension) => (@extension == "gml") || (@extension == "css");

	public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared,
		ImportPlan outPlan) => ImportPaths.SingleAssetPlan(sourcePath, outPlan);

	public void StoredSelection(Group group, StringView sourcePath, ImportPlan outPlan)
		=> ImportPaths.SingleAssetStoredSelection(group, sourcePath, IsSheet(sourcePath) ? cStyleSheetType : cDocumentType, outPlan);

	public StringView AssetTypeName(StringView sourcePath) => IsSheet(sourcePath) ? cStyleSheetType : cDocumentType;

	public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
		Group group, ImportOptions options, Object prepared,
		List<DeferredImportWrite> deferredWrites)
	{
		let sheet = IsSheet(sourcePath);
		let fileName = scope String();
		// The name claimed by the clash rule, the file copied in beside any other's.
		let claimed = ImportPaths.ClaimSingleAsset(context, group, options, sourcePath, sheet ? cStyleSheetType : cDocumentType, fileName);
		if (claimed case .Err(let claimError))
			return .Err(claimError);
		let instance = claimed.Value;
		Result<void, ErrorCode> written;
		if (sheet)
		{
			let asset = scope GuiStyleSheetAsset();
			asset.FileName.Set(fileName);
			written = instance.WriteObject(asset);
		}
		else
		{
			let asset = scope GuiDocumentAsset();
			asset.FileName.Set(fileName);
			written = instance.WriteObject(asset);
		}
		if (written case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}

	private static bool IsSheet(StringView path)
	{
		let suffix = scope String();
		ImportPaths.ExtensionLower(path, suffix);
		return suffix == "css";
	}
}
