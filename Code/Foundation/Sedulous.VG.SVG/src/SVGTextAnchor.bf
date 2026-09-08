namespace Sedulous.VG.SVG;

/// Where the text position sits relative to the text, from the text-anchor attribute.
enum SVGTextAnchor
{
	/// The position is the text's left edge.
	case Start;
	case Middle;
	/// The position is the text's right edge.
	case End;
}
