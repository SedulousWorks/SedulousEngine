using System;
using System.IO;
using Sedulous.Fonts;

namespace Sedulous.Fonts.TTF;

/// TrueType font loader implementation
public class TrueTypeFontLoader : IFontLoader
{
	private static StringView[?] sSupportedExtensions = .(".ttf", ".ttc", ".otf");

	public Span<StringView> SupportedExtensions => sSupportedExtensions;

	public bool SupportsExtension(StringView fileExtension)
	{
		let lowerExt = scope String(fileExtension);
		lowerExt.ToLower();

		for (let ext in sSupportedExtensions)
		{
			if (lowerExt == ext)
				return true;
		}
		return false;
	}

	public Result<IFont, FontLoadResult> LoadFromFile(StringView filePath, FontLoadOptions options)
	{
		// Read file into memory
		let file = scope FileStream();
		if (file.Open(filePath, .Read, .Read) case .Err)
			return .Err(.FileNotFound);

		let fileSize = file.Length;
		let fontData = new uint8[fileSize];

		if (file.TryRead(fontData) case .Err)
		{
			delete fontData;
			return .Err(.CorruptedData);
		}

		file.Close();

		// Create font (takes ownership of fontData)
		let font = new TrueTypeFont();
		if (font.Initialize(fontData, options.PixelHeight) case .Err(let err))
		{
			delete font;
			return .Err(err);
		}

		return .Ok(font);
	}

	public Result<IFont, FontLoadResult> LoadFromMemory(Span<uint8> data, FontLoadOptions options)
	{
		// Copy data since we need to own it
		let fontData = new uint8[data.Length];
		Internal.MemCpy(fontData.Ptr, data.Ptr, data.Length);

		// Create font (takes ownership of fontData)
		let font = new TrueTypeFont();
		if (font.Initialize(fontData, options.PixelHeight) case .Err(let err))
		{
			delete font;
			return .Err(err);
		}

		return .Ok(font);
	}

	public Result<IFontAtlas, FontLoadResult> CreateAtlas(IFont font, FontLoadOptions options)
	{
		// Must be a TrueTypeFont
		let ttfFont = font as TrueTypeFont;
		if (ttfFont == null)
			return .Err(.UnsupportedFormat);

		let atlas = new TrueTypeFontAtlas();
		if (atlas.Create(ttfFont, options) case .Err(let err))
		{
			delete atlas;
			return .Err(err);
		}

		return .Ok(atlas);
	}
}
