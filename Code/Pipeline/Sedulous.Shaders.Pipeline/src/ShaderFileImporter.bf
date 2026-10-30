using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Shaders.Pipeline;

/// Imports a dropped .hlsl: the file is STAGED into the project's sources tree and a shader
/// asset, named after its stem (the name materials find it by), LINKS it, as a script and a UI
/// document do. The entry points stay VSMain and PSMain; the shader page edits them.
class ShaderFileImporter : IFileImporter
{
	public StringView Label => "Shader";

	public bool Accepts(StringView @extension) => @extension == "hlsl";

	public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared,
		ImportPlan outPlan) => ImportPaths.SingleAssetPlan(sourcePath, outPlan);

	public void StoredSelection(Group group, StringView sourcePath, ImportPlan outPlan)
		=> ImportPaths.SingleAssetStoredSelection(group, sourcePath, typeof(ShaderAsset).GetFullName(.. scope .()), outPlan);

	public StringView AssetTypeName(StringView sourcePath) => "Sedulous.Shaders.Pipeline.ShaderAsset";

	public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
		Group group, ImportOptions options, Object prepared,
		List<DeferredImportWrite> deferredWrites)
	{
		let fileName = scope String();
		// The name claimed by the clash rule, the file copied in beside any other's.
		let claimed = ImportPaths.ClaimSingleAsset(context, group, options, sourcePath, typeof(ShaderAsset).GetFullName(.. scope .()), fileName);
		if (claimed case .Err(let claimError))
			return .Err(claimError);
		let instance = claimed.Value;
		let asset = scope ShaderAsset();
		asset.Name.Set(instance.Name); // materials find it by this name
		asset.FileName.Set(fileName);
		if (instance.WriteObject(asset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}
