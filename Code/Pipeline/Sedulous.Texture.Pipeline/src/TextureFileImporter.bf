using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Image;
using Sedulous.Image.DDS;
using Sedulous.Pipeline.Core;
using Sedulous.Pipeline.Importer;

namespace Sedulous.Texture.Pipeline;

/// Imports an image file as a texture, preset by intent.
///
/// A radiance file becomes an equirectangular sky. A file whose name matches a cube face
/// convention, with all six siblings beside it, becomes ONE cube asset. A DDS names its own
/// facts, its block format saying what it holds. Anything else takes the surface preset, with
/// its usage inferred from the name.
class TextureFileImporter : IFileImporter
{
	private const String cAssetType = "Sedulous.Texture.Pipeline.TextureAsset";

	public StringView Label => "Texture";

	public bool Accepts(StringView @extension)
	{
		switch (@extension)
		{
		case "png", "jpg", "jpeg", "tga", "bmp", "hdr", "dds":
			return true;
		default:
			return false;
		}
	}

	public void DescribeImport(StringView sourcePath, ImportOptions options, Object prepared,
		ImportPlan outPlan) => ImportPaths.SingleAssetPlan(sourcePath, outPlan);

	public void StoredSelection(Group group, StringView sourcePath, ImportPlan outPlan)
		=> ImportPaths.SingleAssetStoredSelection(group, sourcePath, cAssetType, outPlan);

	public Result<Instance, ErrorCode> Import(StringView sourcePath, ImportContext context,
		Group group, ImportOptions options, Object prepared,
		List<DeferredImportWrite> deferredWrites)
	{
		// Cube intent: the dropped file's name matches a face convention AND all six siblings
		// exist beside it. ANY face can be dropped, and the asset stores the +X one.
		{
			let facePaths = scope List<String>();
			defer { ClearAndDeleteItems!(facePaths); }
			if (CubemapFaces.Detect(sourcePath, facePaths) case .Ok)
			{
				var allPresent = facePaths.Count == 6;
				for (let face in facePaths)
				{
					if (!FileExists(face))
					{
						allPresent = false;
						break;
					}
				}
				if (allPresent)
					return ImportCube(facePaths, context, group);
			}
		}

		let fileName = scope String();
		if (ImportPaths.CopyIntoSources(context, sourcePath, fileName) case .Err(let copyError))
			return .Err(copyError);

		let stem = ImportPaths.StemOf(fileName);
		let instance = group.CreateInstance(ImportPaths.SingleAssetName(options, stem), cAssetType);
		if (instance == null)
			return .Err(.Unknown);

		let asset = scope TextureAsset();
		asset.FileName.Set(fileName);

		let suffix = scope String();
		ImportPaths.ExtensionLower(sourcePath, suffix);
		if (suffix == "hdr")
			asset.SetupForEquirectangularSkybox(); // radiance is an environment, not a surface
		else if (suffix == "dds")
			SetupForDds(asset, sourcePath, stem);
		else
			SetupForInferredUsage(asset, stem);

		if (instance.WriteObject(asset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}

	/// The usage the universal texture pack name tokens imply.
	///
	/// The inference only sets the STORED fields: the page shows what it guessed and the
	/// author corrects it like any other edit. A name nobody recognises keeps the colour
	/// default.
	private static void SetupForInferredUsage(TextureAsset asset, StringView stem)
	{
		switch (TextureUsageInference.Infer(stem))
		{
		case .Normal:
			asset.SetupForNormalMap();
		case .Mask:
			asset.SetupForDataMask();
		default:
			asset.SetupFor3D();
		}
	}

	/// A DDS names its OWN facts: BC5 is a normal map, BC4 a data mask, a float format an HDR
	/// environment, and a DX10 header settles the colour space for a colour map. The name
	/// tokens decide whatever the file does not.
	///
	/// A DDS that cannot be read imports like any other file, and the cook is what says why.
	private static void SetupForDds(TextureAsset asset, StringView sourcePath, StringView stem)
	{
		let bytes = scope List<uint8>();
		let dds = scope DdsImage();
		if ((System.IO.File.ReadAll(scope String(sourcePath), bytes) case .Err)
			|| (Dds.LoadDds(bytes, dds) case .Err))
		{
			SetupForInferredUsage(asset, stem);
			return;
		}

		if (DdsFormats.IsHdr(dds.Format))
			asset.SetupForEquirectangularSkybox();
		else if ((dds.Format == .BC5) || (dds.Format == .BC5Snorm))
			asset.SetupForNormalMap();
		else if ((dds.Format == .BC4) || (dds.Format == .BC4Snorm))
			asset.SetupForDataMask();
		else
			SetupForInferredUsage(asset, stem);

		if (dds.ColorSpaceKnown && (asset.Usage == .Color))
			asset.ColorSpace = DdsFormats.IsSrgb(dds.Format) ? .Srgb : .Linear;
	}

	/// Copies all six faces into the sources tree and creates ONE cube asset naming the +X
	/// face; the builder re-derives the set at cook time.
	private static Result<Instance, ErrorCode> ImportCube(List<String> facePaths,
		ImportContext context, Group group)
	{
		let posXName = scope String();
		for (int i < facePaths.Count)
		{
			let copied = scope String();
			if (ImportPaths.CopyIntoSources(context, facePaths[i], copied)
				case .Err(let copyError))
			{
				return .Err(copyError);
			}
			if (i == 0)
				posXName.Set(copied);
		}

		// "sky_px" names the cube "sky": the face suffix and any trailing separator come off,
		// and the full stem stands in when the convention leaves nothing behind.
		let name = scope String();
		let derived = scope List<String>();
		defer { ClearAndDeleteItems!(derived); }
		if (CubemapFaces.Detect(posXName, derived) case .Ok)
		{
			var common = 0;
			let a = derived[0];
			let b = derived[1];
			while ((common < a.Length) && (common < b.Length) && (a[common] == b[common]))
				common++;

			let sharedStem = ImportPaths.StemOf(StringView(a, 0, common));
			var trimmed = sharedStem.Length;
			while ((trimmed > 0) && ((sharedStem[trimmed - 1] == '_')
				|| (sharedStem[trimmed - 1] == '-')))
			{
				trimmed--;
			}
			name.Append(StringView(sharedStem, 0, trimmed));
		}
		if (name.IsEmpty)
			name.Append(ImportPaths.StemOf(posXName));

		let instance = group.CreateInstance(name, cAssetType);
		if (instance == null)
			return .Err(.Unknown);

		let asset = scope TextureAsset();
		TextureImporter.ImportCubemap(posXName, asset);
		if (instance.WriteObject(asset) case .Err(let writeError))
			return .Err(writeError);
		return .Ok(instance);
	}
}
