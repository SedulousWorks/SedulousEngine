using System;

namespace Sedulous.Fonts;

/// Cached font entry containing font, atlas, and optional shaper
public class CachedFont
{
	/// The loaded font
	public IFont Font;
	/// The font atlas for rendering
	public IFontAtlas Atlas;
	/// Optional text shaper instance
	public ITextShaper Shaper;
	/// Reference count for cache management
	public int32 RefCount;

	public this(IFont font, IFontAtlas atlas, ITextShaper shaper = null)
	{
		Font = font;
		Atlas = atlas;
		Shaper = shaper;
		RefCount = 1;
	}

	public ~this()
	{
		if (Shaper != null)
			delete (Object)Shaper;
		if (Atlas != null)
			delete (Object)Atlas;
		if (Font != null)
			delete (Object)Font;
	}
}
