using System;
using Sedulous.Fonts;

namespace Sedulous.Fonts.IO;

/// Bakes a parsed `IFont` into a renderable `IFontAtlas`. Part of the
/// source-format load pipeline: the parser produces an IFont, then the
/// matching baker turns it into a usable atlas. Lives in
/// `Sedulous.Fonts.IO` alongside `IFontParser` because both abstractions
/// belong to the same pipeline.
///
/// Implementations typically require the IFont to be of a specific concrete
/// type (e.g., `TrueTypeFontAtlasBaker` expects `TrueTypeFont`) - the
/// factory dispatches by extension to pair each parser with its matching
/// baker.
///
/// Baked fonts (`.font` resources) don't go through a baker - their atlas
/// is part of the serialized payload, loaded directly by
/// `BakedFontService`.
public interface IFontAtlasBaker
{
	/// File extensions this baker is paired with (e.g., ".ttf", ".otf").
	/// Factory dispatch uses this to match a parser's output to a baker.
	Span<StringView> SupportedExtensions { get; }

	/// Quick predicate over the extension list.
	bool SupportsExtension(StringView fileExtension);

	/// Returns true if this baker can produce an atlas from the given font
	/// instance. Typically tests the IFont's concrete type.
	bool CanBake(IFont font);

	/// Produce a new atlas for the given font + options. Caller takes
	/// ownership of the returned atlas.
	Result<IFontAtlas, FontLoadResult> Bake(IFont font, FontLoadOptions options);
}
