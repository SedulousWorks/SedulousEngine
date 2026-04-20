using System;
using System.IO;
using System.Collections;

namespace Sedulous.Images;

// Factory class for managing different image loaders
public static class ImageLoaderFactory
{
	private static List<ImageLoader> sLoaders = new .() ~ DeleteContainerAndItems!(_);

	public static void RegisterLoader(ImageLoader loader)
	{
		sLoaders.Add(loader);
	}

	public static Result<Image> LoadImage(StringView filePath)
	{
		// Get file extension
        var @extension = scope String();
        Path.GetExtension(filePath, @extension);
        @extension.ToLower();

		// Find appropriate loader
		ImageLoader selectedLoader = null;
		for (var loader in sLoaders)
		{
            if (loader.SupportsExtension(@extension))
			{
				selectedLoader = loader;
				break;
			}
		}

		if (selectedLoader == null)
			return .Err;

		// Load using selected loader
		var loadResult = selectedLoader.LoadFromFile(filePath);
		if (loadResult case .Err)
			return .Err;

		var loadInfo = loadResult.Value;
        defer loadInfo.Dispose(); // Clean up the LoadInfo

		return ImageLoader.CreateImageFromLoadInfo(loadInfo);
	}

	public static Result<Image> LoadImageFromMemory(Span<uint8> data, StringView formatHint = "")
	{
		// Try loaders until one succeeds
		for (var loader in sLoaders)
		{
			if (!formatHint.IsEmpty)
			{
				if (!loader.SupportsExtension(formatHint))
					continue;
			}

			var loadResult = loader.LoadFromMemory(data);
			if (loadResult case .Ok(var loadInfo))
			{
                defer loadInfo.Dispose(); // Clean up the LoadInfo
                
				return ImageLoader.CreateImageFromLoadInfo(loadInfo);
			}
		}

		return .Err;
	}

	public static void GetSupportedExtensions(List<StringView> outExtensions)
	{
		for (var loader in sLoaders)
		{
			loader.GetSupportedExtensions(outExtensions);
		}
	}
}