using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Fonts;

/// Turns the bytes of a source format font (TTF, OTF) into something queryable.
///
/// Half of the backend seam, and the reason Fonts names no format: a backend registers a
/// parser and a baker, and the factories route by extension. A baked `.font` resource
/// skips this entirely, being already a finished font and atlas pair.
abstract class IFontParser
{
	/// The extensions this parser claims, WITH their dots.
	public abstract Span<StringView> SupportedExtensions { get; }
	public abstract bool SupportsExtension(StringView fileExtension);

	/// The canonical entry point: a BORROWED stream, not retained past the call. Engine and
	/// packaged game callers should prefer this, since it is the one that goes through the
	/// virtual file system.
	public abstract Result<IFont, FontLoadResult> ParseFromStream(IStream stream, FontLoadOptions options);

	public abstract Result<IFont, FontLoadResult> ParseFromMemory(Span<uint8> data, FontLoadOptions options);

	/// Straight from disk, which only a tool or a test should be doing.
	public abstract Result<IFont, FontLoadResult> ParseFromFile(StringView filePath, FontLoadOptions options);
}
