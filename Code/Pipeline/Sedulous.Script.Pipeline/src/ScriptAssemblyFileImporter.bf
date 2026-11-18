using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Pipeline.Importer;
using Sedulous.VFS;

namespace Sedulous.Script.Pipeline;

/// Imports a dropped project file: any extension a registered project build claims, copied into
/// the sources as a ScriptAssemblyAsset of that language. No options.
class ScriptAssemblyFileImporter : IFileImporter
{
	public StringView Label => "Script project";

	public bool Accepts(StringView @extension)
	{
		let language = ScriptAssemblyCooks.LanguageOfProject(@extension, .. scope .());
		return !language.IsEmpty;
	}

	public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared,
		ImportPlan outPlan) => ImportPaths.SingleAssetPlan(sourcePath, outPlan);

	public void StoredSelection(Group group, StringView sourcePath, ImportPlan outPlan)
		=> ImportPaths.SingleAssetStoredSelection(group, sourcePath, ScriptAssemblies.cAssetType, outPlan);

	public StringView AssetTypeName(StringView sourcePath) => ScriptAssemblies.cAssetType;

	public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
		Group group, ImportOptions options, Object prepared,
		List<DeferredImportWrite> deferredWrites)
	{
		let suffix = ImportPaths.ExtensionLower(sourcePath, .. scope .());
		let language = ScriptAssemblyCooks.LanguageOfProject(suffix, .. scope .());
		if (language.IsEmpty)
		{
			GlobalLog(.Error, "Script: no project build claims '.{}', so '{}' was not imported", suffix, sourcePath);
			return .Err(.NotSupported);
		}

		let fileName = scope String();
		// A project file is code: in the project's Code/ folder, in its group's folder there.
		let claimed = ImportPaths.ClaimSingleAsset(context, group, options, sourcePath, ScriptAssemblies.cAssetType, fileName, null,
			SourcePath.CodeFolder);
		if (claimed case .Err(let claimError))
			return .Err(claimError);
		let instance = claimed.Value;

		let asset = scope ScriptAssemblyAsset();
		asset.FileName.Set(fileName);
		asset.Language.Set(language);
		if (instance.WriteObject(asset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}
