using System;
using Sedulous.Fonts.Coverage;

namespace Sedulous.Fonts.Coverage.Baker;

/// The pair a bake produces, owned together.
///
/// A font is useless without the atlas its regions index into, so the two are handed over
/// as one object that frees both. Detach is what a caller uses to move them into something
/// with a longer life, a FontResource say, without this freeing them underneath it.
class BakedFontData
{
	private BakedFont mFont ~ delete _;
	private BakedFontAtlas mAtlas ~ delete _;

	public this(BakedFont font, BakedFontAtlas atlas)
	{
		mFont = font;
		mAtlas = atlas;
	}

	public BakedFont Font => mFont;
	public BakedFontAtlas Atlas => mAtlas;

	/// Hands both out and drops our claim on them, so deleting this afterwards is still
	/// correct and frees nothing.
	public void Detach(out BakedFont font, out BakedFontAtlas atlas)
	{
		font = mFont;
		atlas = mAtlas;
		mFont = null;
		mAtlas = null;
	}
}
