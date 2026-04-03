using System;
using System.IO;
using System.Collections;

namespace Sedulous.Fonts;

/// Factory for loading fonts using registered loaders
public static class FontLoaderFactory
{
	private static List<IFontLoader> sLoaders = new .() ~ DeleteContainerAndItems!(_);

	/// Register a font loader
	public static void RegisterLoader(IFontLoader loader)
	{
		if (loader != null && !sLoaders.Contains(loader))
			sLoaders.Add(loader);
	}

	/// Unregister a font loader
	public static void UnregisterLoader(IFontLoader loader)
	{
		sLoaders.Remove(loader);
	}

	/// Get a loader that supports the given file extension
	public static IFontLoader GetLoaderForExtension(StringView fileExtension)
	{
		for (let loader in sLoaders)
		{
			if (loader.SupportsExtension(fileExtension))
				return loader;
		}
		return null;
	}

	/// Load a font from file
	public static Result<IFont, FontLoadResult> LoadFont(StringView filePath, FontLoadOptions options = .Default)
	{
		let ext = Path.GetExtension(filePath, .. scope .());
		let loader = GetLoaderForExtension(ext);

		if (loader == null)
			return .Err(.UnsupportedFormat);

		return loader.LoadFromFile(filePath, options);
	}

	/// Load a font from memory with explicit format hint
	public static Result<IFont, FontLoadResult> LoadFontFromMemory(Span<uint8> data, StringView formatHint, FontLoadOptions options = .Default)
	{
		let loader = GetLoaderForExtension(formatHint);

		if (loader == null)
			return .Err(.UnsupportedFormat);

		return loader.LoadFromMemory(data, options);
	}

	/// Create an atlas for a font using registered loaders
	public static Result<IFontAtlas, FontLoadResult> CreateAtlas(IFont font, FontLoadOptions options = .Default)
	{
		// Try each loader until one succeeds
		for (let loader in sLoaders)
		{
			if (loader.CreateAtlas(font, options) case .Ok(let atlas))
				return .Ok(atlas);
		}
		return .Err(.UnsupportedFormat);
	}

	/// Get number of registered loaders
	public static int LoaderCount => sLoaders.Count;

	/// Check if any loaders are registered
	public static bool HasLoaders => sLoaders.Count > 0;

	/// Cleanup all registered loaders
	public static void Shutdown()
	{
		DeleteContainerAndItems!(sLoaders);
		sLoaders = new .();
	}
}
