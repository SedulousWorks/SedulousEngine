using System;
using Sedulous.Image;

namespace Sedulous.Fonts;

/// Where drawing and UI code gets its fonts, without knowing how they are loaded or cached.
///
/// The seam exists so a headless test or a tool can run the whole text path against a
/// service that returns nothing, instead of needing a font file on disk.
abstract class IFontService
{
	/// The default family at a size.
	public abstract CachedFont GetFont(float pixelHeight);
	public abstract CachedFont GetFont(StringView familyName, float pixelHeight);

	/// The atlas as an image a renderer can upload. BORROWED: the service owns it and
	/// keeps it alive, because it is uploaded once and used every frame.
	public abstract ImageData GetAtlasTexture(CachedFont font);
	public abstract ImageData GetAtlasTexture(StringView familyName, float pixelHeight);

	/// Gives a reference back. The font usually stays cached, since the next frame will
	/// almost certainly ask for it again.
	public abstract void ReleaseFont(CachedFont font);

	public abstract void GetDefaultFontFamily(String outFamily);

	/// Whether a family by this name is loaded. GetFont falls back to the default family for one
	/// that is not, and a font's own family name comes from its file, so asking GetFont cannot
	/// tell: rich text asks this to take a bold or italic face where a project loads one.
	public abstract bool HasFamily(StringView familyName);
}
