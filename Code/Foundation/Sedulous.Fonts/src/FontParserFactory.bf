using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Fonts;

/// The registered parsers, and dispatch to them by file extension.
///
/// Process global on purpose: a backend registers itself once at startup and every font
/// load in the process routes through the same table, which is what lets Fonts name no
/// format and a game link only the formats it ships.
///
/// The registry OWNS what is registered and deletes it on Shutdown. Unregister hands
/// ownership back to the caller.
static class FontParserFactory
{
	private static List<IFontParser> sParsers = new .() ~ DeleteContainerAndItems!(_);

	/// Registering the same parser twice is ignored rather than an error, so a module
	/// brought up twice does not get consulted twice, and does not get deleted twice.
	public static void RegisterParser(IFontParser parser)
	{
		if (parser == null)
			return;
		for (let existing in sParsers)
		{
			if (existing === parser)
				return;
		}
		sParsers.Add(parser);
	}

	/// Takes a parser back out AND gives ownership back: the caller deletes it.
	public static void UnregisterParser(IFontParser parser)
	{
		for (int i < sParsers.Count)
		{
			if (sParsers[i] === parser)
			{
				sParsers.RemoveAt(i);
				return;
			}
		}
	}

	/// The FIRST parser claiming the extension, so a later registration is consulted only
	/// where no earlier one handles the format.
	public static IFontParser GetParserForExtension(StringView fileExtension)
	{
		for (let parser in sParsers)
		{
			if (parser.SupportsExtension(fileExtension))
				return parser;
		}
		return null;
	}

	public static Result<IFont, FontLoadResult> ParseFromFile(StringView filePath, FontLoadOptions options)
	{
		let @extension = scope String();
		PathExtension(filePath, @extension);
		let parser = GetParserForExtension(@extension);
		if (parser == null)
			return .Err(.UnsupportedFormat);
		return parser.ParseFromFile(filePath, options);
	}

	/// From memory there is no path to take an extension from, so the caller states the
	/// format.
	public static Result<IFont, FontLoadResult> ParseFromMemory(Span<uint8> data, StringView formatHint,
		FontLoadOptions options)
	{
		let parser = GetParserForExtension(formatHint);
		if (parser == null)
			return .Err(.UnsupportedFormat);
		return parser.ParseFromMemory(data, options);
	}

	public static Result<IFont, FontLoadResult> ParseFromStream(IStream stream, StringView formatHint,
		FontLoadOptions options)
	{
		let parser = GetParserForExtension(formatHint);
		if (parser == null)
			return .Err(.UnsupportedFormat);
		return parser.ParseFromStream(stream, options);
	}

	public static int ParserCount => sParsers.Count;
	public static bool HasParsers => !sParsers.IsEmpty;

	/// Empties the registry and deletes the parsers it still owns.
	public static void Shutdown()
	{
		ClearAndDeleteItems!(sParsers);
	}
}
