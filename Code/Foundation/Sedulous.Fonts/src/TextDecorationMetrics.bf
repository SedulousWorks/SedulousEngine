using System;

namespace Sedulous.Fonts;

/// Metrics for text decoration rendering (underline, strikethrough)
public struct TextDecorationMetrics
{
	/// Vertical position of underline relative to baseline (positive = below baseline)
	public float UnderlinePosition;
	/// Thickness of underline in pixels
	public float UnderlineThickness;
	/// Vertical position of strikethrough relative to baseline (negative = above baseline)
	public float StrikethroughPosition;
	/// Thickness of strikethrough in pixels
	public float StrikethroughThickness;

	public this()
	{
		UnderlinePosition = 0;
		UnderlineThickness = 1;
		StrikethroughPosition = 0;
		StrikethroughThickness = 1;
	}

	public this(float underlinePos, float underlineThick, float strikePos, float strikeThick)
	{
		UnderlinePosition = underlinePos;
		UnderlineThickness = underlineThick;
		StrikethroughPosition = strikePos;
		StrikethroughThickness = strikeThick;
	}

	/// Create default metrics based on font metrics
	public static TextDecorationMetrics FromFontMetrics(float ascent, float pixelHeight)
	{
		// Underline: approximately 12% below baseline
		float underlinePos = pixelHeight * 0.12f;
		float thickness = Math.Max(1.0f, pixelHeight * 0.05f);

		// Strikethrough: approximately at x-height middle (35% of ascent above baseline)
		float strikePos = -ascent * 0.35f;

		return .(underlinePos, thickness, strikePos, thickness);
	}
}
