using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.VG.Pipeline;

/// Imports an `.svg` file as a vector image.
///
/// The dropped file is STAGED into the project's sources tree and the asset LINKS it, as the
/// UI's files are; the cook reads it back through the mount.
class VectorImageFileImporter : IFileImporter
{
	private const String cVectorImageType = "Sedulous.VG.Pipeline.VectorImageAsset";

	public StringView Label => "Vector image";

	public bool Accepts(StringView @extension) => @extension == "svg";

	public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared,
		ImportPlan outPlan) => ImportPaths.SingleAssetPlan(sourcePath, outPlan);

	public void StoredSelection(Group group, StringView sourcePath, ImportPlan outPlan)
		=> ImportPaths.SingleAssetStoredSelection(group, sourcePath, cVectorImageType, outPlan);

	public StringView AssetTypeName(StringView sourcePath) => cVectorImageType;

	public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
		Group group, ImportOptions options, Object prepared,
		List<DeferredImportWrite> deferredWrites)
	{
		let fileName = scope String();
		// The name claimed by the clash rule, the file copied in beside any other's.
		let claimed = ImportPaths.ClaimSingleAsset(context, group, options, sourcePath, cVectorImageType, fileName);
		if (claimed case .Err(let claimError))
			return .Err(claimError);
		let instance = claimed.Value;

		let asset = scope VectorImageAsset();
		asset.FileName.Set(fileName);
		if (instance.WriteObject(asset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}
