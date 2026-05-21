using System;
using System.IO;
using Sedulous.Fonts;

namespace Sedulous.Fonts.IO;

/// Parses a source-format font (TTF, OTF, etc.) into a queryable IFont
/// instance. The atlas is a separate step - see `IFontAtlasBaker`.
///
/// Baked fonts (`.font` resources) are NOT parsers - they're pre-completed
/// (IFont, IFontAtlas) pairs loaded through `FontResourceManager`. The
/// parser/baker hierarchy is for live source formats only.
public interface IFontParser
{
	/// File extensions this parser supports (e.g., ".ttf", ".otf"). Used by
	/// `FontParserFactory` for extension-based dispatch.
	Span<StringView> SupportedExtensions { get; }

	/// Quick predicate over the extension list.
	bool SupportsExtension(StringView fileExtension);

	/// Canonical entry point. Parse a font from a stream. The stream is
	/// read-only borrowed for the duration of the call; the parser does not
	/// retain it.
	Result<IFont, FontLoadResult> ParseFromStream(Stream stream, FontLoadOptions options);

	/// Parse a font from an in-memory byte span. Convenience over
	/// `ParseFromStream` - useful for callers that already have the bytes.
	Result<IFont, FontLoadResult> ParseFromMemory(Span<uint8> data, FontLoadOptions options);

	/// Parse a font from a file on disk. Convenience over `ParseFromStream` -
	/// useful for tests / CLI tools. Engine / shipped-game callers should
	/// route through the VFS-aware `FontParserFactory.ParseFromStream`.
	Result<IFont, FontLoadResult> ParseFromFile(StringView filePath, FontLoadOptions options);
}
