namespace Sedulous.Fonts;

/// A glyph placed by layout.
///
/// A shaper maps a string's characters to glyphs N to M: several glyphs may share a cluster (a
/// base and its mark), one glyph may cover several characters (a ligature), and characters such
/// as a line break may have no glyph at all. Clusters count characters (codepoints) of the source
/// string, the unit text editing works in, not bytes. Positions keep logical order.
struct GlyphPosition
{
	/// The first character of the cluster this glyph belongs to.
	public int32 Cluster;
	/// What the atlas draws: the font's glyph index (0: none).
	public int32 GlyphId;
	/// The pen position: the baseline origin, before the offsets.
	public float X;
	public float Y;
	public float Advance;
	public GlyphInfo GlyphInfo;
	/// The characters its cluster covers.
	public int32 ClusterLength;
	/// A shaper's placement deltas: drawn, never advanced.
	public float XOffset;
	public float YOffset;
	/// Which font of the shape request's list drew it (0: the first, or the only).
	public uint8 Font;
	/// In a right-to-left run: its cluster's start is on its right.
	public bool RightToLeft;

	public this()
	{
		Cluster = 0; GlyphId = 0; X = 0; Y = 0; Advance = 0; GlyphInfo = .();
		ClusterLength = 1; XOffset = 0; YOffset = 0; Font = 0; RightToLeft = false;
	}

	/// The character after this glyph's cluster.
	public int32 ClusterEnd => Cluster + ClusterLength;
}
