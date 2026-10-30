using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Image.Pipeline;

/// Imports an image file as a RAW image plus a colour space intent, which is a different thing
/// from a cooked texture.
///
/// Claims the SAME extensions the texture importer does, deliberately: dropping one file that
/// two importers want is what the chooser exists for.
class ImageFileImporter : IFileImporter
{
	public StringView Label => "Image";

	public bool Accepts(StringView @extension)
	{
		switch (@extension)
		{
		case "png", "jpg", "jpeg", "tga", "bmp", "hdr":
			return true;
		default:
			return false;
		}
	}

	public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared,
		ImportPlan outPlan) => ImportPaths.SingleAssetPlan(sourcePath, outPlan);

	public void StoredSelection(Group group, StringView sourcePath, ImportPlan outPlan)
		=> ImportPaths.SingleAssetStoredSelection(group, sourcePath,
			"Sedulous.Image.Pipeline.ImageAsset", outPlan);

	public StringView AssetTypeName(StringView sourcePath) => "Sedulous.Image.Pipeline.ImageAsset";

	public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
		Group group, ImportOptions options, Object prepared,
		List<DeferredImportWrite> deferredWrites)
	{
		let fileName = scope String();
		// The name claimed by the clash rule, the file copied in beside any other's.
		let claimed = ImportPaths.ClaimSingleAsset(context, group, options, sourcePath, "Sedulous.Image.Pipeline.ImageAsset", fileName);
		if (claimed case .Err(let claimError))
			return .Err(claimError);
		let instance = claimed.Value;

		let asset = scope ImageAsset();
		asset.FileName.Set(fileName);
		// A radiance file is LINEAR; every other format here is sRGB colour by default.
		let suffix = scope String();
		ImportPaths.ExtensionLower(sourcePath, suffix);
		asset.ColorSpace = (suffix == "hdr") ? .Linear : .Srgb;

		if (instance.WriteObject(asset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}
