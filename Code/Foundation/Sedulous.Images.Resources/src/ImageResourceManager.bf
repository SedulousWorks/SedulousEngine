using System;
using System.IO;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Images;

namespace Sedulous.Images.Resources;

/// Resource manager for `ImageResource`.
///
/// Handles the cooked text + sidecar format only:
///   - `*.image` - serialised metadata (width / height / format / color
///     space). Pixel bytes live in the conventional "<assetLocator>.bin"
///     sidecar opened through `ctx.Mount`.
///
/// Raw image decoding (PNG / JPG / TGA / ...) is the importer's job,
/// not this manager's. `Sedulous.Images.Importer` cooks source images
/// into `ImageResource` files; this manager only loads what the importer
/// produced. Apps that ship cooked assets need no image-loader registered
/// at runtime.
class ImageResourceManager : ResourceManager<ImageResource>
{
	protected override Result<ImageResource, ResourceLoadError> LoadFromContext(ResourceLoadContext ctx)
	{
		if (!ctx.Locator.EndsWith(".image"))
			return .Err(.NotSupported);
		return LoadTextFormat(ctx);
	}

	public override void Unload(ImageResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(ImageResource resource, ResourceLoadContext ctx)
	{
		if (!ctx.Locator.EndsWith(".image"))
			return .Err(.NotSupported);

		let result = LoadTextFormat(ctx);
		if (result case .Ok(let reloaded))
		{
			TransferData(resource, reloaded);
			// LoadTextFormat AddRef'd the temporary. Releasing the ref
			// instead of `delete` so refcount machinery sees the owning
			// drop.
			reloaded.ReleaseRef();
			return .Ok;
		}
		return .Err(.ReadError);
	}

	// === Text + sidecar format ===

	private Result<ImageResource, ResourceLoadError> LoadTextFormat(ResourceLoadContext ctx)
	{
		if (SerializerProvider == null)
			return .Err(.NotSupported);

		let text = scope String();
		Try!(ReadAllText(ctx.Stream, text));

		let reader = SerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err(.InvalidFormat);
		defer delete reader;

		let resource = new ImageResource();
		if (resource.Serialize(reader) != .Ok)
		{
			delete resource;
			return .Err(.InvalidFormat);
		}

		// Pixel sidecar lives at "<locator>.bin" by convention - same as
		// TextureResource. Rename / delete stay pure-convention (no
		// metadata rewrite needed).
		if (ctx.Mount == null)
		{
			delete resource;
			return .Err(.InvalidFormat);
		}

		let sidecarLocator = scope String()..AppendF("{}.bin", ctx.Locator);

		let sidecarResult = ctx.Mount.Open(sidecarLocator);
		if (sidecarResult case .Err)
		{
			delete resource;
			return .Err(.NotFound);
		}
		let binStream = sidecarResult.Value;
		defer delete binStream;

		let binBytes = scope List<uint8>();
		if (ReadAllBytes(binStream, binBytes) case .Err)
		{
			delete resource;
			return .Err(.ReadError);
		}

		let pixelArr = new uint8[binBytes.Count];
		defer delete pixelArr;
		binBytes.CopyTo(pixelArr);
		let image = new Image(
			(uint32)resource.ImageWidth,
			(uint32)resource.ImageHeight,
			(PixelFormat)resource.ImageFormat,
			pixelArr,
			(ImageColorSpace)resource.ImageColorSpaceField);
		resource.SetImage(image, true);
		resource.AddRef();
		return .Ok(resource);
	}

	/// Transfers data from a newly loaded resource into an existing one
	/// for reload. Updates the target's `Image` buffer in place so
	/// outside references stay valid.
	private void TransferData(ImageResource target, ImageResource source)
	{
		let srcImg = source.[Friend]mImage;
		if (srcImg != null)
			target.UpdateImageInPlace(srcImg.Width, srcImg.Height, srcImg.Format, srcImg.Data, srcImg.ColorSpace);
		target.Name.Set(source.Name);
	}
}
