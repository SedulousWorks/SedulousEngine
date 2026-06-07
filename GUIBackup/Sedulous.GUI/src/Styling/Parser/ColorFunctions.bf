namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Built-in color manipulation functions for .sss stylesheets.
/// lighten($color, 10%), darken($color, 10%), alpha($color, 0.5), mix($a, $b, 0.5)
public static class ColorFunctions
{
	/// Lighten a color by amount (0-1, specified as percentage in .sss).
	public static Color Lighten(Color color, float amount)
	{
		return Palette.Lighten(color, amount);
	}

	/// Darken a color by amount (0-1).
	public static Color Darken(Color color, float amount)
	{
		return Palette.Darken(color, amount);
	}

	/// Set the alpha channel of a color.
	public static Color Alpha(Color color, float alpha)
	{
		return .(color.R, color.G, color.B, (uint8)(Math.Clamp(alpha, 0, 1) * 255));
	}

	/// Linear blend between two colors. t=0 returns a, t=1 returns b.
	public static Color Mix(Color a, Color b, float t)
	{
		let f = Math.Clamp(t, 0, 1);
		return .(
			(uint8)((int)a.R + (int)((int)b.R - (int)a.R) * f),
			(uint8)((int)a.G + (int)((int)b.G - (int)a.G) * f),
			(uint8)((int)a.B + (int)((int)b.B - (int)a.B) * f),
			(uint8)((int)a.A + (int)((int)b.A - (int)a.A) * f));
	}
}
