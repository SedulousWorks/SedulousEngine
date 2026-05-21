using System;
using System.IO;
using System.Collections;
using Sedulous.Fonts;

namespace Sedulous.Fonts.IO;

/// Registry + dispatcher for `IFontParser` implementations. Extension-based
/// routing: each parser declares the file extensions it handles, and the
/// factory selects the matching parser at call time.
///
/// Implementations register themselves at startup via their own
/// initialization helpers (e.g., `TrueTypeFonts.Initialize()` registers
/// `TrueTypeFontParser` and the matching atlas baker).
public static class FontParserFactory
{
	private static List<IFontParser> sParsers = new .() ~ DeleteContainerAndItems!(_);

	public static void RegisterParser(IFontParser parser)
	{
		if (parser != null && !sParsers.Contains(parser))
			sParsers.Add(parser);
	}

	public static void UnregisterParser(IFontParser parser)
	{
		sParsers.Remove(parser);
	}

	/// First parser that claims to support the given extension, or null.
	public static IFontParser GetParserForExtension(StringView fileExtension)
	{
		for (let parser in sParsers)
		{
			if (parser.SupportsExtension(fileExtension))
				return parser;
		}
		return null;
	}

	/// Parse a font from a file. Extension dispatch from the path.
	public static Result<IFont, FontLoadResult> ParseFromFile(StringView filePath, FontLoadOptions options = .Default)
	{
		let ext = Path.GetExtension(filePath, .. scope .());
		let parser = GetParserForExtension(ext);
		if (parser == null)
			return .Err(.UnsupportedFormat);
		return parser.ParseFromFile(filePath, options);
	}

	/// Parse a font from an in-memory byte span. Caller must provide a
	/// format hint (e.g., ".ttf") so the factory can pick the right parser.
	public static Result<IFont, FontLoadResult> ParseFromMemory(Span<uint8> data, StringView formatHint, FontLoadOptions options = .Default)
	{
		let parser = GetParserForExtension(formatHint);
		if (parser == null)
			return .Err(.UnsupportedFormat);
		return parser.ParseFromMemory(data, options);
	}

	/// Canonical entry point - parse a font from a stream. The caller is
	/// responsible for the stream's lifetime. Used by VFS-aware loaders
	/// (open a stream through a mount, hand it here).
	public static Result<IFont, FontLoadResult> ParseFromStream(Stream stream, StringView formatHint, FontLoadOptions options = .Default)
	{
		let parser = GetParserForExtension(formatHint);
		if (parser == null)
			return .Err(.UnsupportedFormat);
		return parser.ParseFromStream(stream, options);
	}

	/// Number of registered parsers.
	public static int ParserCount => sParsers.Count;

	/// Any parsers registered?
	public static bool HasParsers => sParsers.Count > 0;

	/// Clear the registry and free the parsers it owned.
	public static void Shutdown()
	{
		DeleteContainerAndItems!(sParsers);
		sParsers = new .();
	}
}
