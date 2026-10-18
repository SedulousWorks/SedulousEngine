namespace Sedulous.Fonts;

/// The direction a run of text reads in. Auto: from its script (Arabic and Hebrew right to
/// left, the rest left to right).
enum TextDirection : uint8
{
	Auto,
	LeftToRight,
	RightToLeft
}
