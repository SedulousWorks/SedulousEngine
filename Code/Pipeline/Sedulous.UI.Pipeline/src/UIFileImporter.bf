using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.UI.Pipeline;

/// Imports a markup or stylesheet file.
///
/// The dropped file is STAGED into the project's sources tree and the asset LINKS it; the
/// authored text is never embedded, so the file on disk stays the one true copy and the cook
/// reads it back through the mount.
class UIFileImporter : IFileImporter
{
	private const String cDocumentType = "Sedulous.UI.Pipeline.UIDocumentAsset";
	private const String cThemeType = "Sedulous.UI.Pipeline.UIThemeAsset";

	public StringView Label => "UI";

	public bool Accepts(StringView @extension) => (@extension == "sml") || (@extension == "sss");

	public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared,
		ImportPlan outPlan) => ImportPaths.SingleAssetPlan(sourcePath, outPlan);

	public void StoredSelection(Group group, StringView sourcePath, ImportPlan outPlan)
		=> ImportPaths.SingleAssetStoredSelection(group, sourcePath,
			IsTheme(sourcePath) ? cThemeType : cDocumentType, outPlan);

	public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
		Group group, ImportOptions options, Object prepared,
		List<DeferredImportWrite> deferredWrites)
	{
		let isTheme = IsTheme(sourcePath);

		let fileName = scope String();
		if (ImportPaths.CopyIntoSources(context, sourcePath, fileName) case .Err(let copyError))
			return .Err(copyError);

		let stem = ImportPaths.StemOf(fileName);
		let instance = group.CreateInstance(ImportPaths.SingleAssetName(options, stem),
			isTheme ? cThemeType : cDocumentType);
		if (instance == null)
			return .Err(.Unknown);

		Result<void, ErrorCode> written;
		if (isTheme)
		{
			let asset = scope UIThemeAsset();
			asset.FileName.Set(fileName);
			written = instance.WriteObject(asset);
		}
		else
		{
			let asset = scope UIDocumentAsset();
			asset.FileName.Set(fileName);
			written = instance.WriteObject(asset);
		}

		if (written case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}

	private static bool IsTheme(StringView sourcePath)
	{
		let suffix = scope String();
		ImportPaths.ExtensionLower(sourcePath, suffix);
		return suffix == "sss";
	}
}
