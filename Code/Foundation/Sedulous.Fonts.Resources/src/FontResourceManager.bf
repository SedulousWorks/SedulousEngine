using System;
using System.IO;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Resources;

namespace Sedulous.Fonts.Resources;

/// Resource manager for fonts
public class FontResourceManager : ResourceManager<FontResource>
{
	private FontLoadOptions mDefaultOptions;
	private Dictionary<String, FontResource> mCache ~ DeleteDictionaryAndKeys!(_);

	public this(FontLoadOptions defaultOptions = .Default)
	{
		mDefaultOptions = defaultOptions;
		mCache = new .();
	}

	/// Load a font with custom options
	public Result<FontResource, ResourceLoadError> LoadFont(StringView path, FontLoadOptions options)
	{
		// Check cache first
		let cacheKey = scope String(path);
		if (mCache.TryGetValue(cacheKey, let cached))
			return .Ok(cached);

		// Load the font
		if (FontLoaderFactory.LoadFont(path, options) case .Ok(let font))
		{
			// Create atlas
			if (FontLoaderFactory.CreateAtlas(font, options) case .Ok(let atlas))
			{
				let resource = new FontResource(font, atlas, options);

				// Cache it
				let key = new String(path);
				mCache[key] = resource;
				resource.AddRef(); // Internal cache ref - released in Unload/ClearCache
				resource.AddRef(); // Manager's ownership ref - released in Unload

				return .Ok(resource);
			}

			delete (Object)font;
			return .Err(.InvalidFormat);
		}

		return .Err(.NotFound);
	}

	protected override Result<FontResource, ResourceLoadError> LoadFromMemory(MemoryStream memory)
	{
		let length = memory.Length;
		let data = scope uint8[length];
		if (memory.TryRead(data) case .Err)
			return .Err(.ReadError);

		// Try to load as TTF by default
		if (FontLoaderFactory.LoadFontFromMemory(data, ".ttf", mDefaultOptions) case .Ok(let font))
		{
			if (FontLoaderFactory.CreateAtlas(font, mDefaultOptions) case .Ok(let atlas))
			{
				let resource = new FontResource(font, atlas, mDefaultOptions);
				resource.AddRef(); // Manager's ownership ref - released in Unload
				return .Ok(resource);
			}
			delete (Object)font;
			return .Err(.InvalidFormat);
		}

		return .Err(.InvalidFormat);
	}

	protected override Result<FontResource, ResourceLoadError> LoadFromFile(StringView path)
	{
		return LoadFont(path, mDefaultOptions);
	}

	public override void Unload(FontResource resource)
	{
		if (resource == null)
			return;

		// Remove from internal font cache and release that ref
		for (let (key, cached) in mCache)
		{
			if (cached == resource)
			{
				mCache.Remove(key);
				delete key;
				resource.ReleaseRef(); // Release internal cache ref
				break;
			}
		}

		resource.ReleaseRef(); // Release manager's ownership ref
	}

	/// Clear all cached resources
	public void ClearCache()
	{
		for (let (key, resource) in mCache)
		{
			resource.ReleaseRef(); // Release cache's reference
			delete key;
		}
		mCache.Clear();
	}

	protected override Result<void, ResourceLoadError> ReloadResource(FontResource resource, StringView path)
	{
		let options = resource.Options;
		if (FontLoaderFactory.LoadFont(path, options) case .Ok(let font))
		{
			if (FontLoaderFactory.CreateAtlas(font, options) case .Ok(let atlas))
			{
				resource.SetFont(font);
				resource.SetAtlas(atlas);
				return .Ok;
			}
			delete (Object)font;
			return .Err(.InvalidFormat);
		}
		return .Err(.NotFound);
	}

	/// Get default load options
	public FontLoadOptions DefaultOptions
	{
		get => mDefaultOptions;
		set => mDefaultOptions = value;
	}
}
