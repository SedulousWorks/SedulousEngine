using Sedulous.Fonts;

namespace Sedulous.Fonts.DistanceField.Baker;

/// One glyph's packing decision, made before any field is generated.
///
/// Splitting the bake this way is what keeps it deterministic: the packing runs in
/// codepoint order on one thread and fills these in, and only then does the expensive
/// generation fan out. The atlas layout never depends on which worker finished first.
struct GlyphWork
{
	public int32 Codepoint;
	public int32 CellWidth;
	public int32 CellHeight;
	public uint32 PackX;
	public uint32 PackY;
	/// In FONT UNITS, added before the scale: msdfgen projects as scale * (coord + translate).
	public double TranslateX;
	public double TranslateY;
	public AtlasRegion Region;
	/// Set by the worker. A cell whose field failed must not get a region, or it would
	/// point at blank texels.
	public bool Generated;
}
