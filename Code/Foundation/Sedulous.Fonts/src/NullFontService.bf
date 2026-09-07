using System;
using Sedulous.Image;

namespace Sedulous.Fonts;

/// A font service that has no fonts.
///
/// For headless runs and for tests of code that merely has to hold a service. Every
/// lookup answers null, which is the same answer a real service gives for a font it cannot
/// load, so a caller that handles this handles the real failure too.
class NullFontService : IFontService
{
	public override CachedFont GetFont(float pixelHeight) => null;
	public override CachedFont GetFont(StringView familyName, float pixelHeight) => null;
	public override ImageData GetAtlasTexture(CachedFont font) => null;
	public override ImageData GetAtlasTexture(StringView familyName, float pixelHeight) => null;
	public override void ReleaseFont(CachedFont font) {}
	public override void GetDefaultFontFamily(String outFamily) {}
}
