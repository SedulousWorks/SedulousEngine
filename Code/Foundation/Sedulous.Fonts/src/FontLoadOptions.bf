namespace Sedulous.Fonts;

/// Options for loading a font
public struct FontLoadOptions
{
	/// Pixel height to render the font at
	public float PixelHeight;

	/// First Unicode codepoint to include (default: 32 = space)
	public int32 FirstCodepoint;

	/// Last Unicode codepoint to include (default: 126 = tilde)
	public int32 LastCodepoint;

	/// Atlas texture width (power of 2 recommended)
	public uint32 AtlasWidth;

	/// Atlas texture height (power of 2 recommended)
	public uint32 AtlasHeight;

	/// Oversampling for improved quality (1-4)
	public uint8 OversampleX;
	public uint8 OversampleY;

	/// Padding between glyphs in atlas
	public uint8 Padding;

	/// Default options for typical usage (ASCII printable characters)
	public static FontLoadOptions Default => .()
	{
		PixelHeight = 32.0f,
		FirstCodepoint = 32,
		LastCodepoint = 126,
		AtlasWidth = 512,
		AtlasHeight = 512,
		OversampleX = 2,
		OversampleY = 2,
		Padding = 2
	};

	/// Options including extended Latin characters (Latin-1 Supplement)
	public static FontLoadOptions ExtendedLatin => .()
	{
		PixelHeight = 32.0f,
		FirstCodepoint = 32,
		LastCodepoint = 255,
		AtlasWidth = 1024,
		AtlasHeight = 1024,
		OversampleX = 2,
		OversampleY = 2,
		Padding = 2
	};

	/// Options for small text rendering
	public static FontLoadOptions Small => .()
	{
		PixelHeight = 16.0f,
		FirstCodepoint = 32,
		LastCodepoint = 126,
		AtlasWidth = 256,
		AtlasHeight = 256,
		OversampleX = 2,
		OversampleY = 2,
		Padding = 2
	};

	/// Options for large text / headings
	public static FontLoadOptions Large => .()
	{
		PixelHeight = 64.0f,
		FirstCodepoint = 32,
		LastCodepoint = 126,
		AtlasWidth = 1024,
		AtlasHeight = 1024,
		OversampleX = 2,
		OversampleY = 2,
		Padding = 2
	};

	public this()
	{
		PixelHeight = 32.0f;
		FirstCodepoint = 32;
		LastCodepoint = 126;
		AtlasWidth = 512;
		AtlasHeight = 512;
		OversampleX = 2;
		OversampleY = 2;
		Padding = 2;
	}

	/// Get the number of characters in this range
	public int32 CharacterCount => LastCodepoint - FirstCodepoint + 1;
}
