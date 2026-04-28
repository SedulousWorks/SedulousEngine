namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.Images;
using Sedulous.Textures.Resources;
using Sedulous.Geometry.Tooling.Resources;

/// Imports image files (.png, .jpg, .tga, .bmp, .hdr) as TextureResource.
/// Produces a single .texture file per source image.
class TextureAssetImporter : IAssetImporter
{
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
			item.Extension = new String(".texture");
			item.TypeLabel = new String(scope $"Texture ({image.Width}x{image.Height})");
			item.InternalIndex = 0;
			preview.Items.Add(item);

			return .Ok(preview);
		}

		return .Err;
	}

	public Result<void> Import(ImportPreview preview, StringView outputDir,
		ResourceRegistry registry, Sedulous.Serialization.ISerializerProvider serializer)
	{
		if (preview.Items.Count == 0 || !preview.Items[0].Selected)
			return .Ok;

		// Load the image
		Image image;
		if (ImageLoaderFactory.LoadImage(preview.SourcePath) case .Ok(var img))
			image = img;
		else
			return .Err;

		// Create texture resource (takes ownership of image)
		let texRes = new TextureResource(image, true);
		texRes.Name.Set(preview.Items[0].Name);
		texRes.SourcePath.Set(preview.SourcePath);
		texRes.SetupFor3D();

		defer delete texRes;

		// Ensure output directory exists
		if (!System.IO.Directory.Exists(outputDir))
			System.IO.Directory.CreateDirectory(outputDir);

		// Save to disk
		let fileName = scope String();
		fileName.AppendF("{}.texture", preview.Items[0].Name);
		ResourceSerializer.SanitizePath(fileName);

		let fullPath = scope String();
		System.IO.Path.InternalCombine(fullPath, outputDir, fileName);

		if (texRes.SaveToFile(fullPath, serializer) case .Err)
			return .Err;

		// Register in registry
		let relPrefix = scope String();
		if (registry.RootPath.Length > 0 && StringView(outputDir).StartsWith(registry.RootPath))
		{
			let after = StringView(outputDir)[registry.RootPath.Length...];
			if (after.StartsWith('/') || after.StartsWith('\\'))
				relPrefix.Set(after[1...]);
			else
				relPrefix.Set(after);
			relPrefix.Replace('\\', '/');
		}

		let relPath = scope String();
		if (relPrefix.Length > 0)
			relPath.AppendF("{}/{}", relPrefix, fileName);
		else
			relPath.Set(fileName);

		registry.Register(texRes.Id, relPath);

		// Save registry
		let regFile = scope String();
		System.IO.Path.InternalCombine(regFile, registry.RootPath, scope $"{registry.Name}.registry");
		registry.SaveToFile(regFile);

		return .Ok;
	}
}
