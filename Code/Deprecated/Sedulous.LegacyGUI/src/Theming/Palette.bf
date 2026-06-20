using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.LegacyGUI;

/// A color palette with seed colors and computed derived colors.
/// Provides consistent color schemes with automatic state variations.
public struct Palette
{
	// Seed colors (set by theme)
	public Color32 Primary;
	public Color32 Secondary;
	public Color32 Accent;
	public Color32 Background;
	public Color32 Surface;
	public Color32 Error;
	public Color32 Warning;
	public Color32 Success;
	public Color32 Text;
	public Color32 TextSecondary;
	public Color32 Border;
	public Color32 Link;
	public Color32 LinkVisited;

	/// Computes a hover color by lightening the input.
	public static Color32 ComputeHover(Color32 baseColor)
	{
		return Lighten(baseColor, 0.15f);
	}

	/// Computes a pressed color by darkening the input.
	public static Color32 ComputePressed(Color32 baseColor)
	{
		return Darken(baseColor, 0.15f);
	}

	/// Computes a disabled color by desaturating and fading.
	public static Color32 ComputeDisabled(Color32 baseColor)
	{
		let desaturated = Desaturate(baseColor, 0.5f);
		return Color32(desaturated.R, desaturated.G, desaturated.B, (uint8)(baseColor.A * 0.5f));
	}

	/// Computes a focused color (typically adds accent tint).
	public static Color32 ComputeFocused(Color32 baseColor, Color32 accentColor)
	{
		return Lerp(baseColor, accentColor, 0.2f);
	}

	/// Lightens a color by the specified amount (0-1).
	public static Color32 Lighten(Color32 color, float amount)
	{
		let r = (uint8)Math.Min(255, (int)(color.R + (255 - color.R) * amount));
		let g = (uint8)Math.Min(255, (int)(color.G + (255 - color.G) * amount));
		let b = (uint8)Math.Min(255, (int)(color.B + (255 - color.B) * amount));
		return Color32(r, g, b, color.A);
	}

	/// Darkens a color by the specified amount (0-1).
	public static Color32 Darken(Color32 color, float amount)
	{
		let r = (uint8)(color.R * (1 - amount));
		let g = (uint8)(color.G * (1 - amount));
		let b = (uint8)(color.B * (1 - amount));
		return Color32(r, g, b, color.A);
	}

	/// Desaturates a color by the specified amount (0-1).
	public static Color32 Desaturate(Color32 color, float amount)
	{
		let gray = (uint8)((color.R * 0.299f + color.G * 0.587f + color.B * 0.114f));
		let r = (uint8)(color.R + (gray - color.R) * amount);
		let g = (uint8)(color.G + (gray - color.G) * amount);
		let b = (uint8)(color.B + (gray - color.B) * amount);
		return Color32(r, g, b, color.A);
	}

	/// Linearly interpolates between two colors.
	public static Color32 Lerp(Color32 a, Color32 b, float t)
	{
		let r = (uint8)(a.R + (b.R - a.R) * t);
		let g = (uint8)(a.G + (b.G - a.G) * t);
		let bl = (uint8)(a.B + (b.B - a.B) * t);
		let alpha = (uint8)(a.A + (b.A - a.A) * t);
		return Color32(r, g, bl, alpha);
	}
}
