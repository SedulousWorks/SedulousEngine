namespace Sedulous.GUI;

// Note: TextAlignment is defined in Sedulous.Fonts.TextAlignment
// Use that enum instead of duplicating here.

/// Text trimming mode when text exceeds available width.
public enum TextTrimming
{
	/// No trimming, text may overflow.
	None,
	/// Trim with ellipsis (...) at character boundary.
	CharacterEllipsis,
	/// Trim with ellipsis (...) at word boundary.
	WordEllipsis
}

/// Text wrapping behavior.
public enum TextWrapping
{
	/// No wrapping, text stays on a single line.
	NoWrap,
	/// Wrap text at word boundaries when it exceeds available width.
	Wrap,
	/// Wrap at word boundaries, but allow long words to overflow.
	WrapWithOverflow
}
