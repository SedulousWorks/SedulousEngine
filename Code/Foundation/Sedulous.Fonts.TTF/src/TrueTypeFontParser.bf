using System;
using System.IO;
using System.Collections;
using Sedulous.Fonts;
using Sedulous.Fonts.IO;

namespace Sedulous.Fonts.TTF;

/// IFontParser implementation for TrueType / OpenType (TTF / TTC / OTF).
///
/// Produces a `TrueTypeFont` from source bytes. Atlas baking is a separate
/// step - see `TrueTypeFontAtlasBaker`. Both are typically registered
/// together by `TrueTypeFonts.Initialize()`.
public class TrueTypeFontParser : IFontParser
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

	public Result<IFont, FontLoadResult> ParseFromStream(Stream stream, FontLoadOptions options)
	{
		// stb_truetype needs the whole buffer addressable for offset lookups,
		// so we copy the stream contents into a fresh owned array and hand
		// it to TrueTypeFont (which takes ownership).
		let length = (int)stream.Length - (int)stream.Position;
		if (length <= 0)
			return .Err(.CorruptedData);

		let fontData = new uint8[length];
		if (stream.TryRead(.(fontData.Ptr, length)) case .Err)
		{
			delete fontData;
			return .Err(.CorruptedData);
		}

		let font = new TrueTypeFont();
		if (font.Initialize(fontData, options.PixelHeight) case .Err(let err))
		{
			delete font;
			return .Err(err);
		}

		return .Ok(font);
	}

	public Result<IFont, FontLoadResult> ParseFromMemory(Span<uint8> data, FontLoadOptions options)
	{
		// Copy data since we need to own it.
		let fontData = new uint8[data.Length];
		Internal.MemCpy(fontData.Ptr, data.Ptr, data.Length);

		let font = new TrueTypeFont();
		if (font.Initialize(fontData, options.PixelHeight) case .Err(let err))
		{
			delete font;
			return .Err(err);
		}

		return .Ok(font);
	}

	public Result<IFont, FontLoadResult> ParseFromFile(StringView filePath, FontLoadOptions options)
	{
		let file = scope FileStream();
		if (file.Open(filePath, .Read, .Read) case .Err)
			return .Err(.FileNotFound);

		return ParseFromStream(file, options);
	}
}
