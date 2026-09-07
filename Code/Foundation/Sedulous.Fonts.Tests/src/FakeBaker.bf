using System;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

/// A baker that claims ".fake" and bakes anything into a StubAtlas.
class FakeBaker : IFontAtlasBaker
{
	private static StringView[1] sExtensions = .(".fake");

	public override Span<StringView> SupportedExtensions => .(&sExtensions[0], 1);
	public override bool SupportsExtension(StringView fileExtension) => fileExtension == ".fake";
	public override bool CanBake(IFont font) => true;

	public override Result<IFontAtlas, FontLoadResult> Bake(IFont font, FontLoadOptions options)
		=> .Ok(new StubAtlas());
}
