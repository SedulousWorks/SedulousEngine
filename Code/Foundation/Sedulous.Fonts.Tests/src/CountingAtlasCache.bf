using System;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

/// An atlas cache that records what it was asked and can be told to hit or to decline.
class CountingAtlasCache : IFontAtlasCache
{
	public int LoadAttempts;
	public int Stores;
	/// When set, TryLoad hands this back and the bake never happens. Ownership goes to the
	/// caller, so it is handed out at most once.
	public IFontAtlas Preloaded;

	public override IFontAtlas TryLoad(IFont font, FontLoadOptions options)
	{
		LoadAttempts++;
		let result = Preloaded;
		Preloaded = null;
		return result;
	}

	public override void Store(IFont font, FontLoadOptions options, IFontAtlas atlas)
	{
		Stores++;
	}
}
