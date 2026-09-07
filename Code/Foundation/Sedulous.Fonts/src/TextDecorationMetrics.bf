namespace Sedulous.Fonts;

/// Where to draw an underline or a strikethrough, and how thick.
struct TextDecorationMetrics
{
	public float UnderlinePosition = 0.0f;
	public float UnderlineThickness = 1.0f;
	public float StrikethroughPosition = 0.0f;
	public float StrikethroughThickness = 1.0f;

	public this()
	{
		UnderlinePosition = 0; UnderlineThickness = 1;
		StrikethroughPosition = 0; StrikethroughThickness = 1;
	}

	public this(float underlinePosition, float underlineThickness,
		float strikethroughPosition, float strikethroughThickness)
	{
		UnderlinePosition = underlinePosition; UnderlineThickness = underlineThickness;
		StrikethroughPosition = strikethroughPosition; StrikethroughThickness = strikethroughThickness;
	}

	/// Decorations derived from the size, for a font that does not carry its own.
	///
	/// A thickness of at least one pixel, because a hairline that rounds to zero is a
	/// decoration that disappears at small sizes.
	///
	/// The strikethrough is placed from the ASCENT rather than from the pixel height, so it
	/// sits across the middle of the letters rather than across the middle of the line box;
	/// it comes out negative because up is negative from the baseline.
	public static TextDecorationMetrics FromFontMetrics(float ascent, float pixelHeight)
	{
		let underlinePos = pixelHeight * 0.12f;
		let thickness = (pixelHeight * 0.05f > 1.0f) ? (pixelHeight * 0.05f) : 1.0f;
		let strikePos = -ascent * 0.35f;
		return .(underlinePos, thickness, strikePos, thickness);
	}
}
