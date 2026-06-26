namespace Sedulous.Images.Importer;

using System;
using System.IO;
using Sedulous.Images;
using Sedulous.Images.Resources;

/// Imports source image files (PNG / JPG / HDR / TGA / ...) into
/// `ImageResource` objects. Mirrors `Sedulous.Textures.Importer` -
/// importers live separately from resource managers so the runtime
/// doesn't have to pull in `ImageLoaderFactory` (or any raw-image
/// decoder) just to consume cooked assets.
///
/// Bootstrap / editor authoring code uses this to cook PNGs into
/// `ImageResource` files. `ImageResourceManager` only loads what the
/// importer produced.
class ImageImporter
{
	/// Imports a single image file. The source file's pixel data is
	/// decoded via `ImageLoaderFactory.LoadImage` (caller must have
	/// registered an image loader - typically `STBImageLoader`) and
	/// wrapped in an `ImageResource` that owns the decoded `Image`.
	///
	/// `colorSpace` defaults to sRGB - correct for 8-bit color images
	/// (UI icons, photos). Pass `.Linear` for normal maps, masks, or
	/// HDR data textures so the GPU samples the values as-is.
	public static Result<ImageResource> Import(StringView path, ImageColorSpace colorSpace = .Srgb)
	{
		let image = Try!(ImageLoaderFactory.LoadImage(path));
		image.ColorSpace = colorSpace;

		let resource = new ImageResource(image, true);
		let name = scope String();
		Path.GetFileNameWithoutExtension(path, name);
		resource.Name.Set(name);
		resource.SourcePath.Set(path);
		return .Ok(resource);
	}
}
