using System;

namespace Sedulous.Fonts;

/// An optional store of already baked atlases, consulted before a bake.
///
/// Installed by the APP, never by Fonts: where the cache lives, how it keys, and when it
/// evicts are all policy decisions that belong with whoever ships the game. An
/// implementation may decline anything it does not understand by returning null and
/// ignoring the Store; the bake then just happens.
abstract class IFontAtlasCache
{
	/// A cached atlas for this font and these options, or null on a miss or a decline. The
	/// caller takes ownership of what comes back.
	public abstract IFontAtlas TryLoad(IFont font, FontLoadOptions options);

	/// Offers a fresh bake for storage. A failure here is the cache's own problem: the
	/// bake is returned to the caller either way, so a broken cache costs speed and never
	/// correctness.
	public abstract void Store(IFont font, FontLoadOptions options, IFontAtlas atlas);
}
