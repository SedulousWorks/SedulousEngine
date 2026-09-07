using System;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

/// A parser that claims ".fake" and turns any input at all into a StubFont.
///
/// Standing in for a real backend keeps these tests on the seam itself: registration,
/// extension routing and ownership, with no rasteriser in the way.
class FakeParser : IFontParser
{
	private static StringView[1] sExtensions = .(".fake");

	public override Span<StringView> SupportedExtensions => .(&sExtensions[0], 1);
	public override bool SupportsExtension(StringView fileExtension) => fileExtension == ".fake";

	public override Result<IFont, FontLoadResult> ParseFromStream(IStream stream, FontLoadOptions options)
		=> .Ok(new StubFont());

	public override Result<IFont, FontLoadResult> ParseFromMemory(Span<uint8> data, FontLoadOptions options)
		=> .Ok(new StubFont());

	public override Result<IFont, FontLoadResult> ParseFromFile(StringView filePath, FontLoadOptions options)
		=> .Ok(new StubFont());
}
