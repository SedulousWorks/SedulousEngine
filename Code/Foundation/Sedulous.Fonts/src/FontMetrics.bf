namespace Sedulous.Fonts;

/// A whole font's metrics at one pixel size.
struct FontMetrics
{
	/// Above the baseline, positive.
	public float Ascent = 0.0f;
	/// Below the baseline, and NEGATIVE, following the font formats.
	public float Descent = 0.0f;
	/// The designer's extra leading between lines, on top of the ascent and descent.
	public float LineGap = 0.0f;
	/// Derived, never passed in: ascent minus descent plus gap. Descent being negative is
	/// why this SUBTRACTS it.
	public float LineHeight = 0.0f;
	public float PixelHeight = 0.0f;
	/// Font units to pixels at this size.
	public float Scale = 1.0f;
	public TextDecorationMetrics Decorations = .();

	public this()
	{
		Ascent = 0; Descent = 0; LineGap = 0; LineHeight = 0; PixelHeight = 0; Scale = 1.0f;
		Decorations = .();
	}

	public this(float ascent, float descent, float lineGap, float pixelHeight, float scale)
	{
		Ascent = ascent; Descent = descent; LineGap = lineGap;
		LineHeight = ascent - descent + lineGap;
		PixelHeight = pixelHeight; Scale = scale;
		Decorations = TextDecorationMetrics.FromFontMetrics(ascent, pixelHeight);
	}

	/// For a font that carries its own decoration metrics rather than derived ones.
	public this(float ascent, float descent, float lineGap, float pixelHeight, float scale,
		TextDecorationMetrics decorations)
	{
		Ascent = ascent; Descent = descent; LineGap = lineGap;
		LineHeight = ascent - descent + lineGap;
		PixelHeight = pixelHeight; Scale = scale;
		Decorations = decorations;
	}

	public static FontMetrics Default() => .(0, 0, 0, 0, 1.0f);
}
