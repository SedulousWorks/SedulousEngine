namespace Sedulous.Editor;

using System;
using System.IO;
using System.Collections;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.Images;
using Sedulous.Textures.Resources;
using Sedulous.Textures.Importer;
using Sedulous.Geometry.Tooling.Resources;
using Sedulous.VFS;
using Sedulous.Core.Logging.Abstractions;

/// Imports image files (.png, .jpg, .tga, .bmp, .hdr) as TextureResource.
/// Supports 2D textures with preset selection (3D, Sprite, UI, Sky) and
/// cubemap import when 6 face images are detected.
class TextureAssetImporter : IAssetImporter
{
	private ILogger mLogger;

	public this(ILogger logger = null)
	{
		mLogger = logger;
	}

	public StringView DisplayName => "Texture";

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
		// Verify the file can be loaded
		if (ImageLoaderFactory.LoadImage(sourcePath) case .Ok(var image))
		{
			defer delete image;

			let preview = new ImportPreview();
			preview.SourcePath = new String(sourcePath);

			// Derive name from filename without extension
			let fileName = scope String();
			System.IO.Path.GetFileNameWithoutExtension(sourcePath, fileName);

			let item = new ImportPreviewItem();
			item.Name = new String(fileName);
			item.OriginalName = new String(fileName);
			item.Extension = new String(".texture");
			item.TypeLabel = new String(scope $"Texture ({image.Width}x{image.Height})");
			item.InternalIndex = 0;
			preview.Items.Add(item);

			// Build import options with smart defaults
			let options = new TextureImportOptions();

			// Detect HDR -> default to equirectangular sky
			let ext = scope String();
			System.IO.Path.GetExtension(sourcePath, ext);
			ext.ToLower();
			if (ext == ".hdr")
				options.Preset = .EquirectangularSky;

			// Detect cubemap face files
			if (TextureImporter.DetectCubemapFaces(sourcePath, options.CubemapFacePaths) case .Ok)
			{
				options.CubemapDetected = true;
				options.Preset = .CubemapSky;

				// Update item label to indicate cubemap
				delete item.TypeLabel;
				item.TypeLabel = new String(scope $"Cubemap ({image.Width}x{image.Height} per face)");
			}

			preview.Options = options;

			return .Ok(preview);
		}

		mLogger?.LogError("Texture import preview: load failed for {}", sourcePath);
		return .Err;
	}

	public Result<void> Import(ImportPreview preview, AssetImportContext ctx)
	{
		if (preview.Items.Count == 0 || !preview.Items[0].Selected)
			return .Ok;

		let options = (preview.Options as TextureImportOptions) ?? scope TextureImportOptions();

		ctx.Logger?.LogInformation("Texture import: {} (preset={}) -> {}{}",
			preview.SourcePath, options.Preset, ctx.UriPrefix, preview.Items[0].Name);

		TextureResource texRes = null;
		defer { if (texRes != null) delete texRes; }

		// Import based on preset
		switch (options.Preset)
		{
		case .CubemapSky:
			if (options.CubemapDetected)
			{
				StringView[6] facePaths = .();
				for (int i = 0; i < 6; i++)
					facePaths[i] = options.CubemapFacePaths[i];

				if (TextureImporter.ImportCubemap(facePaths) case .Ok(let res))
					texRes = res;
				else
				{
					ctx.Logger?.LogError("Texture import: cubemap import failed for {}", preview.SourcePath);
					return .Err;
				}
			}
			else
			{
				// Fallback to equirectangular if cubemap not detected
				if (TextureImporter.ImportEquirectangular(preview.SourcePath) case .Ok(let res))
					texRes = res;
				else
				{
					ctx.Logger?.LogError("Texture import: equirectangular fallback import failed for {}", preview.SourcePath);
					return .Err;
				}
			}

		case .EquirectangularSky:
			if (TextureImporter.ImportEquirectangular(preview.SourcePath) case .Ok(let res))
				texRes = res;
			else
			{
				ctx.Logger?.LogError("Texture import: equirectangular import failed for {}", preview.SourcePath);
				return .Err;
			}

		case .Sprite:
			if (TextureImporter.Import2D(preview.SourcePath) case .Ok(let res))
			{
				res.SetupForSprite();
				texRes = res;
			}
			else
			{
				ctx.Logger?.LogError("Texture import: sprite 2D import failed for {}", preview.SourcePath);
				return .Err;
			}

		case .UI:
			if (TextureImporter.Import2D(preview.SourcePath) case .Ok(let res))
			{
				res.SetupForUI();
				texRes = res;
			}
			else
			{
				ctx.Logger?.LogError("Texture import: UI 2D import failed for {}", preview.SourcePath);
				return .Err;
			}

		case .Texture3D:
			if (TextureImporter.Import2D(preview.SourcePath) case .Ok(let res))
				texRes = res;
			else
			{
				ctx.Logger?.LogError("Texture import: 3D 2D import failed for {}", preview.SourcePath);
				return .Err;
			}
		}

		// Use user-provided name from preview
		texRes.Name.Set(preview.Items[0].Name);

		// Build filename, locator, sidecar locator, and URI
		let fileName = scope String();
		fileName.AppendF("{}.texture", preview.Items[0].Name);
		ResourceSerializer.SanitizePath(fileName);

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

		// Save text metadata through the mount
		{
			let memStream = scope MemoryStream();
			if (texRes.WriteToStream(memStream, ctx.Serializer) case .Err)
			{
				ctx.Logger?.LogError("Texture import: metadata serialization failed for {}", locator);
				return .Err;
			}
			memStream.Position = 0;
			if (ctx.Mount.Save(locator, memStream) case .Err(let err))
			{
				ctx.Logger?.LogError("Texture import: mount save failed for {}: {}", locator, err);
				return .Err;
			}
		}

		// Save pixel sidecar through the mount
		{
			let pixelStream = scope MemoryStream();
			if (texRes.WritePixelsToStream(pixelStream) case .Err)
			{
				ctx.Logger?.LogError("Texture import: pixel sidecar serialization failed for {}", sidecarLocator);
				return .Err;
			}
			pixelStream.Position = 0;
			if (ctx.Mount.Save(sidecarLocator, pixelStream) case .Err(let err))
			{
				ctx.Logger?.LogError("Texture import: pixel sidecar save failed for {}: {}", sidecarLocator, err);
				return .Err;
			}
		}

		// Register the GUID -> URI mapping. Caller is responsible for
		// persisting the index after the import.
		ctx.Index.Register(texRes.Id, uri);

		ctx.Logger?.LogInformation("Texture import: wrote {}", uri);
		return .Ok;
	}
}
