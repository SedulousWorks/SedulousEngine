namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Generates derived colors from seed colors for control states.
public static class Palette
{
	/// Lighten a color by a factor (0-1).
	public static Color Lighten(Color color, float amount)
	{
		let a = Math.Clamp(amount, 0, 1);
		return .(
			(uint8)Math.Min(255, (int)(color.R + (255 - color.R) * a)),
			(uint8)Math.Min(255, (int)(color.G + (255 - color.G) * a)),
			(uint8)Math.Min(255, (int)(color.B + (255 - color.B) * a)),
			color.A);
	}

	/// Darken a color by a factor (0-1).
	public static Color Darken(Color color, float amount)
	{
		let a = Math.Clamp(amount, 0, 1);
		return .(
			(uint8)(color.R * (1 - a)),
			(uint8)(color.G * (1 - a)),
			(uint8)(color.B * (1 - a)),
			color.A);
	}

	public static Color ComputeHover(Color baseColor) => Lighten(baseColor, 0.15f);
	public static Color ComputePressed(Color baseColor) => Darken(baseColor, 0.1f);

	public static Color ComputeDisabled(Color baseColor)
	{
		let gray = (int)baseColor.R * 30 / 100 + (int)baseColor.G * 59 / 100 + (int)baseColor.B * 11 / 100;
		return .((uint8)((gray + (int)baseColor.R) / 2),
				 (uint8)((gray + (int)baseColor.G) / 2),
				 (uint8)((gray + (int)baseColor.B) / 2),
				 (uint8)((int)baseColor.A * 60 / 100));
	}

	public static Color ComputeFocused(Color baseColor, Color accentColor = .(60, 130, 220, 255))
	{
		return .(
			(uint8)(((int)baseColor.R * 80 + (int)accentColor.R * 20) / 100),
			(uint8)(((int)baseColor.G * 80 + (int)accentColor.G * 20) / 100),
			(uint8)(((int)baseColor.B * 80 + (int)accentColor.B * 20) / 100),
			baseColor.A);
	}
}
