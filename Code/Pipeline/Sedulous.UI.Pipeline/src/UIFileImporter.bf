using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.UI.Pipeline;

/// Imports a markup, stylesheet or vector image file.
///
/// The dropped file is STAGED into the project's sources tree and the asset LINKS it; the
/// authored text is never embedded, so the file on disk stays the one true copy and the cook
/// reads it back through the mount.
class UIFileImporter : IFileImporter
{
	private const String cDocumentType = "Sedulous.UI.Pipeline.UIDocumentAsset";
	private const String cThemeType = "Sedulous.UI.Pipeline.UIThemeAsset";
	private const String cVectorImageType = "Sedulous.UI.Pipeline.UIVectorImageAsset";

	public StringView Label => "UI";

	public bool Accepts(StringView @extension) => (@extension == "sml") || (@extension == "sss") || (@extension == "svg");

	public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared,
		ImportPlan outPlan) => ImportPaths.SingleAssetPlan(sourcePath, outPlan);

	public void StoredSelection(Group group, StringView sourcePath, ImportPlan outPlan)
		=> ImportPaths.SingleAssetStoredSelection(group, sourcePath, AssetTypeNameFor(sourcePath), outPlan);

	public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
		Group group, ImportOptions options, Object prepared,
		List<DeferredImportWrite> deferredWrites)
	{
		let typeName = AssetTypeNameFor(sourcePath);

		let fileName = scope String();
		if (ImportPaths.CopyIntoSources(context, sourcePath, fileName) case .Err(let copyError))
			return .Err(copyError);

		let stem = ImportPaths.StemOf(fileName);
		let instance = group.CreateInstance(ImportPaths.SingleAssetName(options, stem), typeName);
		if (instance == null)
			return .Err(.Unknown);

		Result<void, ErrorCode> written;
		if (typeName == cThemeType)
		{
			let asset = scope UIThemeAsset();
			asset.FileName.Set(fileName);
			written = instance.WriteObject(asset);
		}
		else if (typeName == cVectorImageType)
		{
			let asset = scope UIVectorImageAsset();
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

	/// The asset a UI source file becomes, by its extension.
	private static String AssetTypeNameFor(StringView sourcePath)
	{
		let suffix = scope String();
		ImportPaths.ExtensionLower(sourcePath, suffix);
		if (suffix == "sss")
			return cThemeType;
		if (suffix == "svg")
			return cVectorImageType;
		return cDocumentType;
	}
}
