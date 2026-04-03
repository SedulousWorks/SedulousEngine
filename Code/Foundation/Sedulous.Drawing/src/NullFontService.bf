using System;
using Sedulous.Fonts;

namespace Sedulous.Drawing;

/// A minimal font service implementation that returns null for all fonts.
/// Use this for testing when font service is required but actual fonts aren't needed.
public class NullFontService : IFontService
{
	public CachedFont GetFont(float pixelHeight) => null;

	public CachedFont GetFont(StringView familyName, float pixelHeight) => null;

	public IImageData GetAtlasTexture(CachedFont font) => null;

	public IImageData GetAtlasTexture(StringView familyName, float pixelHeight) => null;

	public void ReleaseFont(CachedFont font) { }

	public StringView DefaultFontFamily => "";
}
