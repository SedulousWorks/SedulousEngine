namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Built-in color manipulation functions for .sss stylesheets.
/// lighten($color, 10%), darken($color, 10%), alpha($color, 0.5), mix($a, $b, 0.5)
public static class ColorFunctions
{
	/// Lighten a color by amount (0-1, specified as percentage in .sss).
	public static Color32 Lighten(Color32 color, float amount)
	{
		return Palette.Lighten(color, amount);
	}

	/// Darken a color by amount (0-1).
	public static Color32 Darken(Color32 color, float amount)
	{
		return Palette.Darken(color, amount);
	}

	/// Set the alpha channel of a color.
	public static Color32 Alpha(Color32 color, float alpha)
	{
		return .(color.R, color.G, color.B, (uint8)(Math.Clamp(alpha, 0, 1) * 255));
	}

	/// Linear blend between two colors. t=0 returns a, t=1 returns b.
	public static Color32 Mix(Color32 a, Color32 b, float t)
	{
		let f = Math.Clamp(t, 0, 1);
		return .(
			(uint8)((float)a.R + ((float)b.R - (float)a.R) * f),
			(uint8)((float)a.G + ((float)b.G - (float)a.G) * f),
			(uint8)((float)a.B + ((float)b.B - (float)a.B) * f),
			(uint8)((float)a.A + ((float)b.A - (float)a.A) * f));
	}
}
