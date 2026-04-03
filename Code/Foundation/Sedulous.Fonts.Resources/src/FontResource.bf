using System;
using Sedulous.Fonts;
using Sedulous.Resources;
using Sedulous.Serialization;

namespace Sedulous.Fonts.Resources;

/// Font as a loadable resource
public class FontResource : Resource
{
	private IFont mFont ~ if (_ != null) delete (Object)_;
	private IFontAtlas mAtlas ~ if (_ != null) delete (Object)_;
	private FontLoadOptions mOptions;

	/// The loaded font
	public IFont Font => mFont;

	/// The font atlas for GPU rendering
	public IFontAtlas Atlas => mAtlas;

	/// The options used to load this font
	public FontLoadOptions Options => mOptions;

	public this() { }

	public this(IFont font, IFontAtlas atlas, FontLoadOptions options)
	{
		mFont = font;
		mAtlas = atlas;
		mOptions = options;
	}

	/// Set the font (takes ownership)
	public void SetFont(IFont font)
	{
		if (mFont != null)
			delete (Object)mFont;
		mFont = font;
	}

	/// Set the atlas (takes ownership)
	public void SetAtlas(IFontAtlas atlas)
	{
		if (mAtlas != null)
			delete (Object)mAtlas;
		mAtlas = atlas;
	}

	/// Check if the resource is valid
	public bool IsValid => mFont != null && mAtlas != null;

	public override int32 SerializationVersion => 1;

	protected override SerializationResult OnSerialize(Serializer s)
	{
		// Font resources are typically loaded from files, not serialized
		// But we can serialize the options for reference
		s.Float("pixelHeight", ref mOptions.PixelHeight);
		s.Int32("firstCodepoint", ref mOptions.FirstCodepoint);
		s.Int32("lastCodepoint", ref mOptions.LastCodepoint);
		s.UInt32("atlasWidth", ref mOptions.AtlasWidth);
		s.UInt32("atlasHeight", ref mOptions.AtlasHeight);

		return .Ok;
	}
}
