namespace Sedulous.Fonts;

/// What to load a font as: the size, the codepoint range to bake, and the atlas to bake
/// into.
///
/// The range matters as much as the size. An atlas holds what was asked for and nothing
/// else, so a range that misses the text produces a page of missing glyph boxes rather
/// than a load failure.
struct FontLoadOptions
{
	public float PixelHeight = 32.0f;
	/// Space.
	public int32 FirstCodepoint = 32;
	/// Tilde: the printable ASCII range.
	public int32 LastCodepoint = 126;
	public uint32 AtlasWidth = 512;
	public uint32 AtlasHeight = 512;
	/// Rasterise larger and downsample, which is what keeps small text from looking
	/// chunky.
	public uint8 OversampleX = 2;
	public uint8 OversampleY = 2;
	/// Blank texels around each glyph, so a linear sample near an edge does not pick up
	/// its neighbour.
	public uint8 Padding = 2;
	public AtlasMode AtlasMode = .Coverage;

	public this()
	{
		PixelHeight = 32.0f; FirstCodepoint = 32; LastCodepoint = 126;
		AtlasWidth = 512; AtlasHeight = 512;
		OversampleX = 2; OversampleY = 2; Padding = 2; AtlasMode = .Coverage;
	}

	/// Inclusive of both ends, so the default ASCII range is 95 characters and not 94.
	public int32 CharacterCount => LastCodepoint - FirstCodepoint + 1;

	public static FontLoadOptions Default() => .();

	/// Latin-1 rather than ASCII, in a bigger atlas to hold it.
	public static FontLoadOptions ExtendedLatin()
	{
		var o = FontLoadOptions();
		o.LastCodepoint = 255;
		o.AtlasWidth = 1024;
		o.AtlasHeight = 1024;
		return o;
	}

	/// Small text, which needs far less atlas.
	public static FontLoadOptions Small()
	{
		var o = FontLoadOptions();
		o.PixelHeight = 16.0f;
		o.AtlasWidth = 256;
		o.AtlasHeight = 256;
		return o;
	}

	public static FontLoadOptions Large()
	{
		var o = FontLoadOptions();
		o.PixelHeight = 64.0f;
		o.AtlasWidth = 1024;
		o.AtlasHeight = 1024;
		return o;
	}

	/// A distance field atlas: baked once and sampled crisp at any scale.
	///
	/// No oversampling, because the field is analytic rather than rasterised, and wider
	/// padding to hold the distance spread.
	public static FontLoadOptions DistanceField()
	{
		var o = FontLoadOptions();
		o.AtlasMode = .DistanceField;
		o.OversampleX = 1;
		o.OversampleY = 1;
		o.Padding = 4;
		return o;
	}
}
