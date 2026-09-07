using System;
using Sedulous.Core;

namespace Sedulous.Fonts;

/// Renders a parsed font into an atlas.
///
/// The other half of the backend seam. A baker usually needs one particular concrete font
/// type, which is what CanBake tests.
abstract class IFontAtlasBaker
{
	/// The extensions this baker is paired with, WITH their dots.
	public abstract Span<StringView> SupportedExtensions { get; }
	public abstract bool SupportsExtension(StringView fileExtension);

	public abstract bool CanBake(IFont font);

	/// The options aware pick, which is how two bakers sharing one font type tell each
	/// other apart: the same TTF can go to a coverage baker or to a distance field baker,
	/// and only the requested mode separates them.
	public virtual bool CanBake(IFont font, FontLoadOptions options) => CanBake(font);

	public abstract Result<IFontAtlas, FontLoadResult> Bake(IFont font, FontLoadOptions options);
}
