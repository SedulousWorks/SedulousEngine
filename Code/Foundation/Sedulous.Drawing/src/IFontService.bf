using System;
using Sedulous.Fonts;

namespace Sedulous.Drawing;

/// Service interface for providing fonts to drawing and UI systems.
/// The implementation is responsible for managing font loading,
/// caching, and texture creation for font atlases.
public interface IFontService
{
	/// Gets the default font at the specified pixel height.
	/// Returns null if font cannot be loaded.
	CachedFont GetFont(float pixelHeight);

	/// Gets a font by family name at the specified pixel height.
	/// Returns null if font cannot be loaded.
	CachedFont GetFont(StringView familyName, float pixelHeight);

	/// Gets the texture for a font's atlas.
	/// Returns null if texture is not available.
	IImageData GetAtlasTexture(CachedFont font);

	/// Gets the texture for a font's atlas (creates if necessary).
	/// This is the primary method controls should use.
	IImageData GetAtlasTexture(StringView familyName, float pixelHeight);

	/// Releases a font reference when no longer needed.
	void ReleaseFont(CachedFont font);

	/// The default font family name.
	StringView DefaultFontFamily { get; }
}
