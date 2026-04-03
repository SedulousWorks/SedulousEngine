namespace Sedulous.Fonts;

/// Metrics for an entire font at a specific size
public struct FontMetrics
{
	/// Pixels from baseline to top of tallest character
	public float Ascent;
	/// Pixels from baseline to bottom of lowest descender (typically negative)
	public float Descent;
	/// Recommended spacing between lines
	public float LineGap;
	/// Total line height (Ascent - Descent + LineGap)
	public float LineHeight;
	/// The pixel height this font was rasterized at
	public float PixelHeight;
	/// Scale factor from font units to pixels
	public float Scale;
	/// Metrics for text decorations (underline, strikethrough)
	public TextDecorationMetrics Decorations;

	public this(float ascent, float descent, float lineGap, float pixelHeight, float scale)
	{
		Ascent = ascent;
		Descent = descent;
		LineGap = lineGap;
		LineHeight = ascent - descent + lineGap;
		PixelHeight = pixelHeight;
		Scale = scale;
		Decorations = TextDecorationMetrics.FromFontMetrics(ascent, pixelHeight);
	}

	public this(float ascent, float descent, float lineGap, float pixelHeight, float scale, TextDecorationMetrics decorations)
	{
		Ascent = ascent;
		Descent = descent;
		LineGap = lineGap;
		LineHeight = ascent - descent + lineGap;
		PixelHeight = pixelHeight;
		Scale = scale;
		Decorations = decorations;
	}

	public static FontMetrics Default => .(0, 0, 0, 0, 1.0f);
}
