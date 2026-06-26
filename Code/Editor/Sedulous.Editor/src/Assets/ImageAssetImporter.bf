namespace Sedulous.Editor;

using System;
using System.IO;
using System.Collections;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.Images;
using Sedulous.Images.Resources;
using Sedulous.Images.Importer;
using Sedulous.VFS;
using Sedulous.Core.Logging.Abstractions;

/// Imports raw image files (.png, .jpg, .tga, .bmp, .hdr) as
/// `ImageResource`. Sits alongside `TextureAssetImporter` - that one
/// produces a sampler-bound `TextureResource` for GPU upload; this one
/// produces a plain pixel-data `ImageResource` for non-texture
/// consumers (UI icons, particle sprites, anything that loads a raw
/// image at runtime without needing a sampler).
///
/// Single 2D image only. Cubemap detection / equirectangular / sampler
/// presets are texture concerns and live in `TextureAssetImporter`.
class ImageAssetImporter : IAssetImporter
{
	private ILogger mLogger;

	public this(ILogger logger = null)
	{
		mLogger = logger;
	}

	public StringView DisplayName => "Image";

	public void GetSupportedExtensions(List<String> outExtensions)
	{
		outExtensions.Add(new .(".png"));
		outExtensions.Add(new .(".jpg"));
		outExtensions.Add(new .(".jpeg"));
		outExtensions.Add(new .(".tga"));
		outExtensions.Add(new .(".bmp"));
		outExtensions.Add(new .(".hdr"));
	}

	public Result<ImportPreview> CreatePreview(StringView sourcePath)
	{
		// Verify the file can be decoded by the registered image loader
		// before showing the import dialog.
		if (ImageLoaderFactory.LoadImage(sourcePath) case .Ok(var image))
		{
			defer delete image;

			let preview = new ImportPreview();
			preview.SourcePath = new String(sourcePath);

			let fileName = scope String();
			Path.GetFileNameWithoutExtension(sourcePath, fileName);

			let item = new ImportPreviewItem();
			item.Name = new String(fileName);
			item.OriginalName = new String(fileName);
			item.Extension = new String(".image");
			item.TypeLabel = new String(scope $"Image ({image.Width}x{image.Height})");
			item.InternalIndex = 0;
			preview.Items.Add(item);

			return .Ok(preview);
		}

		mLogger?.LogError("Image import preview: load failed for {}", sourcePath);
		return .Err;
	}

	public Result<void> Import(ImportPreview preview, AssetImportContext ctx)
	{
		if (preview.Items.Count == 0 || !preview.Items[0].Selected)
			return .Ok;

		ctx.Logger?.LogInformation("Image import: {} -> {}{}",
			preview.SourcePath, ctx.UriPrefix, preview.Items[0].Name);

		ImageResource imgRes = null;
		defer { if (imgRes != null) delete imgRes; }

		// Color-space heuristic: HDR formats are linear by convention
		// (they carry radiance, not display-encoded color). Everything
		// else defaults to sRGB - the right call for 8-bit color images.
		let ext = scope String();
		Path.GetExtension(preview.SourcePath, ext);
		ext.ToLower();
		let colorSpace = (ext == ".hdr") ? ImageColorSpace.Linear : ImageColorSpace.Srgb;

		if (ImageImporter.Import(preview.SourcePath, colorSpace) case .Ok(let res))
			imgRes = res;
		else
		{
			ctx.Logger?.LogError("Image import: load failed for {}", preview.SourcePath);
			return .Err;
		}

		imgRes.Name.Set(preview.Items[0].Name);

		// Build filename, locator, sidecar locator, URI. Sanitization
		// inlined: replace backslashes with forward slashes and replace
		// Windows-illegal filename chars with underscores. The same logic
		// lives in TextureAssetImporter via ResourceSerializer.SanitizePath
		// (under Sedulous.Geometry.Tooling.Resources) - that's a layering
		// smell since neither importer needs the geometry tooling lib,
		// but moving SanitizePath is a separate cleanup. Inlined here to
		// avoid pulling Sedulous.Geometry.Tooling.Resources into the
		// image importer.
		let fileName = scope String();
		fileName.AppendF("{}.image", preview.Items[0].Name);
		SanitizeFileName(fileName);

		let sidecarName = scope String();
		sidecarName.AppendF("{}.bin", fileName);

		let locator = scope String();
		locator.Append(ctx.BaseLocator);
		locator.Append(fileName);

		let sidecarLocator = scope String();
		sidecarLocator.Append(ctx.BaseLocator);
		sidecarLocator.Append(sidecarName);

		let uri = scope String();
		uri.Append(ctx.UriPrefix);
		uri.Append(fileName);

		// Save text metadata through the mount.
		{
			let memStream = scope MemoryStream();
			if (imgRes.WriteToStream(memStream, ctx.Serializer) case .Err)
			{
				ctx.Logger?.LogError("Image import: metadata serialization failed for {}", locator);
				return .Err;
			}
			memStream.Position = 0;
			if (ctx.Mount.Save(locator, memStream) case .Err(let err))
			{
				ctx.Logger?.LogError("Image import: mount save failed for {}: {}", locator, err);
				return .Err;
			}
		}

		// Save pixel sidecar.
		{
			let pixelStream = scope MemoryStream();
			if (imgRes.WritePixelsToStream(pixelStream) case .Err)
			{
				ctx.Logger?.LogError("Image import: pixel sidecar serialization failed for {}", sidecarLocator);
				return .Err;
			}
			pixelStream.Position = 0;
			if (ctx.Mount.Save(sidecarLocator, pixelStream) case .Err(let err))
			{
				ctx.Logger?.LogError("Image import: pixel sidecar save failed for {}: {}", sidecarLocator, err);
				return .Err;
			}
		}

		ctx.Index.Register(imgRes.Id, uri);

		ctx.Logger?.LogInformation("Image import: wrote {}", uri);
		return .Ok;
	}

	private static void SanitizeFileName(String path)
	{
		path.Replace("\\", "/");
		for (int i = 0; i < path.Length; i++)
		{
			char8 c = path[i];
			if (c == '<' || c == '>' || c == '"' || c == '|' || c == '?' || c == '*')
				path[i] = '_';
		}
	}
}
