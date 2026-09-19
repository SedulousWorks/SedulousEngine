using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Script.Pipeline;

/// Imports a dropped script file: any extension a registered cook claims. No options; the
/// language is the extension's, and the class the cook's to find.
class ScriptFileImporter : IFileImporter
{
	private const String cAssetType = "Sedulous.Script.Pipeline.ScriptClassAsset";

	public StringView Label => "Script";

	public bool Accepts(StringView @extension)
	{
		let language = ScriptLanguageCooks.LanguageOf(@extension, .. scope .());
		return !language.IsEmpty;
	}

	public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared,
		ImportPlan outPlan) => ImportPaths.SingleAssetPlan(sourcePath, outPlan);

	public void StoredSelection(Group group, StringView sourcePath, ImportPlan outPlan)
		=> ImportPaths.SingleAssetStoredSelection(group, sourcePath, cAssetType, outPlan);

	public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
		Group group, ImportOptions options, Object prepared,
		List<DeferredImportWrite> deferredWrites)
	{
		let suffix = ImportPaths.ExtensionLower(sourcePath, .. scope .());
		let language = ScriptLanguageCooks.LanguageOf(suffix, .. scope .());
		if (language.IsEmpty)
		{
			GlobalLog(.Error, "Script: no cook claims '.{}', so '{}' was not imported", suffix, sourcePath);
			return .Err(.NotSupported);
		}

		let fileName = scope String();
		if (ImportPaths.CopyIntoSources(context, sourcePath, fileName) case .Err(let copyError))
			return .Err(copyError);

		let stem = ImportPaths.StemOf(fileName);
		let instance = group.CreateInstance(ImportPaths.SingleAssetName(options, stem), cAssetType);
		if (instance == null)
			return .Err(.Unknown);

		let asset = scope ScriptClassAsset();
		asset.FileName.Set(fileName);
		asset.Language.Set(language);
		if (instance.WriteObject(asset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}
