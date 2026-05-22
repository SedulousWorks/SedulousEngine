using System;
using System.IO;
using System.Collections;
using Sedulous.Resources;
using Sedulous.Serialization;
using Sedulous.Images;

namespace Sedulous.Textures.Resources;

/// Resource manager for TextureResource.
///
/// Two locator shapes are recognized:
///   - `*.texture` - serialized metadata (filter, wrap, format). The pixel
///     bytes live in the conventional "<assetLocator>.bin" sidecar, derived
///     from the asset locator and opened through `ctx.Mount`.
///   - any other extension - raw image bytes parsed by `ImageLoaderFactory`.
class TextureResourceManager : ResourceManager<TextureResource>
{
	protected override Result<TextureResource, ResourceLoadError> LoadFromContext(ResourceLoadContext ctx)
	{
		// Handle .texture files (text metadata + binary sidecar)
		if (ctx.Locator.EndsWith(".texture"))
			return LoadTextFormat(ctx);

		// Load standard image files via ImageLoaderFactory
		return LoadImageBytes(ctx);
	}

	public override void Unload(TextureResource resource)
	{
		if (resource != null)
			resource.ReleaseRef();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(TextureResource resource, ResourceLoadContext ctx)
	{
		if (ctx.Locator.EndsWith(".texture"))
		{
			let result = LoadTextFormat(ctx);
			if (result case .Ok(let reloaded))
			{
				TransferData(resource, reloaded);
				// LoadTextFormat AddRef'd the temporary. Calling delete
				// directly would skip the refcount path and either trip
				// the ~Resource refcount assert (debug) or corrupt any
				// outside refs (release).
				reloaded.ReleaseRef();
				return .Ok;
			}
			return .Err(.ReadError);
		}

		let bytes = scope List<uint8>();
		Try!(ReadAllBytes(ctx.Stream, bytes));
		if (ImageLoaderFactory.LoadImageFromMemory(.(bytes.Ptr, bytes.Count)) case .Ok(let image))
		{
			// Update in place so any outside reference to resource.Image
			// stays valid (renderer's texture-upload cache, thumbnail
			// views, etc.). The transient `image` is consumed here.
			resource.UpdateImageInPlace(image.Width, image.Height, image.Format, image.Data);
			delete image;
			return .Ok;
		}
		return .Err(.NotFound);
	}

	// === Text + sidecar format ===

	private Result<TextureResource, ResourceLoadError> LoadTextFormat(ResourceLoadContext ctx)
	{
		if (SerializerProvider == null)
			return .Err(.NotSupported);

		let text = scope String();
		Try!(ReadAllText(ctx.Stream, text));

		let reader = SerializerProvider.CreateReader(text);
		if (reader == null)
			return .Err(.InvalidFormat);
		defer delete reader;

		let resource = new TextureResource();
		if (resource.Serialize(reader) != .Ok)
		{
			delete resource;
			return .Err(.InvalidFormat);
		}

		// Load pixel data from the binary sidecar. The sidecar is always
		// "<mainLocator>.bin" by convention, so it's derived from the asset
		// locator - rename/delete stay pure-convention (no metadata
		// rewrite, no resource load).
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

		// Create image from serialized dimensions/format + sidecar pixel data.
		// Image's constructor copies the pixel bytes into its own buffer, so
		// the temporary array we allocate to feed it has to be freed here.
		let pixelArr = new uint8[binBytes.Count];
		defer delete pixelArr;
		binBytes.CopyTo(pixelArr);
		let image = new Image(
			(uint32)resource.ImageWidth,
			(uint32)resource.ImageHeight,
			(PixelFormat)resource.ImageFormat,
			pixelArr);
		resource.SetImage(image, true);
		resource.AddRef();
		return .Ok(resource);
	}

	// === Raw image bytes ===

	private Result<TextureResource, ResourceLoadError> LoadImageBytes(ResourceLoadContext ctx)
	{
		let bytes = scope List<uint8>();
		Try!(ReadAllBytes(ctx.Stream, bytes));

		if (ImageLoaderFactory.LoadImageFromMemory(.(bytes.Ptr, bytes.Count)) case .Ok(let image))
		{
			let resource = new TextureResource(image, true);
			if (ctx.Locator.Length > 0)
				resource.Name.Set(ctx.Locator);
			resource.SetupFor3D();
			resource.AddRef();
			return .Ok(resource);
		}

		return .Err(.NotFound);
	}

	/// Transfers data from a newly loaded resource into an existing one (for reload).
	/// Updates the target's Image buffer in place rather than swapping
	/// the Image pointer, so any outside reference to `target.Image`
	/// stays valid across hot-reload.
	private void TransferData(TextureResource target, TextureResource source)
	{
		let srcImg = source.[Friend]mImage;
		if (srcImg != null)
			target.UpdateImageInPlace(srcImg.Width, srcImg.Height, srcImg.Format, srcImg.Data);
		target.Name.Set(source.Name);
		target.MinFilter = source.MinFilter;
		target.MagFilter = source.MagFilter;
		target.WrapU = source.WrapU;
		target.WrapV = source.WrapV;
		target.WrapW = source.WrapW;
		target.GenerateMipmaps = source.GenerateMipmaps;
		target.Anisotropy = source.Anisotropy;
	}

}
