using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Fonts;

namespace Sedulous.Fonts.TrueType;

/// Parses TrueType, OpenType and collection files into a queryable font.
class TrueTypeFontParser : IFontParser
{
	public override Span<StringView> SupportedExtensions => TrueTypeCommon.Extensions;

	public override bool SupportsExtension(StringView fileExtension)
		=> TrueTypeCommon.IsSupportedExtension(fileExtension);

	/// The canonical entry point. Reads the WHOLE stream: stb_truetype indexes into the
	/// bytes rather than streaming them, so there is nothing to gain by reading in pieces
	/// and the font would have to hold the stream open for its whole life.
	public override Result<IFont, FontLoadResult> ParseFromStream(IStream stream, FontLoadOptions options)
	{
		if (stream == null)
			return .Err(.FileNotFound);

		let size = stream.Size();
		if (size <= 0)
			return .Err(.InvalidFormat);

		let bytes = new List<uint8>();
		bytes.Resize((int)size);
		if (stream.Read(.(bytes.Ptr, bytes.Count)) != bytes.Count)
		{
			delete bytes;
			return .Err(.CorruptedData);
		}
		return Adopt(bytes, options);
	}

	public override Result<IFont, FontLoadResult> ParseFromMemory(Span<uint8> data, FontLoadOptions options)
	{
		if (data.IsEmpty)
			return .Err(.InvalidFormat);

		// COPIED, because the font outlives this call and stb keeps pointing into the
		// bytes; borrowing the caller's span would dangle the moment it went away.
		let bytes = new List<uint8>();
		bytes.AddRange(data);
		return Adopt(bytes, options);
	}

	public override Result<IFont, FontLoadResult> ParseFromFile(StringView filePath, FontLoadOptions options)
	{
		let bytes = new List<uint8>();
		if (ReadFile(filePath, bytes) case .Err)
		{
			delete bytes;
			return .Err(.FileNotFound);
		}
		return Adopt(bytes, options);
	}

	/// Hands the bytes to a font, which takes them. On failure they are freed here: the
	/// caller gave up ownership when it called in, and returning an error with the buffer
	/// still allocated would leak on every rejected file.
	private Result<IFont, FontLoadResult> Adopt(List<uint8> bytes, FontLoadOptions options)
	{
		let font = new TrueTypeFont();
		let result = font.Initialize(bytes, options.PixelHeight);
		if (result != .Success)
		{
			delete font; // Which frees the bytes it took.
			return .Err(result);
		}
		return .Ok(font);
	}
}
