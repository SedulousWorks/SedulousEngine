namespace Sedulous.Fonts;

/// A loaded font with its atlas, and optionally a shaper: everything needed to draw text,
/// owned as one unit.
///
/// One unit because the three are useless apart. An atlas belongs to the font it was baked
/// from, at the size it was baked at, and freeing either separately leaves the other
/// pointing at a bake that no longer matches.
class CachedFont
{
	public IFont Font;
	public IFontAtlas Atlas;
	/// Optional: a font can be measured and drawn without one.
	public ITextShaper Shaper;

	/// Starts at one, for the caller that caused the load.
	public int32 RefCount = 1;

	public this(IFont font, IFontAtlas atlas, ITextShaper shaper = null)
	{
		Font = font; Atlas = atlas; Shaper = shaper;
	}

	public ~this()
	{
		// Shaper first, then atlas, then font: the reverse of how they were built, since a
		// shaper may hold the font and an atlas was baked from it.
		delete Shaper;
		delete Atlas;
		delete Font;
	}
}
