using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// A color palette with seed colors and computed derived colors.
/// Provides consistent color schemes with automatic state variations.
public struct Palette
{
	// Seed colors (set by theme)
	public Color Primary;
	public Color Secondary;
	public Color Accent;
	public Color Background;
	public Color Surface;
	public Color Error;
	public Color Warning;
	public Color Success;
	public Color Text;
	public Color TextSecondary;
	public Color Border;
	public Color Link;
	public Color LinkVisited;

	/// Computes a hover color by lightening the input.
	public static Color ComputeHover(Color baseColor)
	{
		return Lighten(baseColor, 0.15f);
	}

	/// Computes a pressed color by darkening the input.
	public static Color ComputePressed(Color baseColor)
	{
		return Darken(baseColor, 0.15f);
	}

	/// Computes a disabled color by desaturating and fading.
	public static Color ComputeDisabled(Color baseColor)
	{
		let desaturated = Desaturate(baseColor, 0.5f);
		return Color(desaturated.R, desaturated.G, desaturated.B, (uint8)(baseColor.A * 0.5f));
	}

	/// Computes a focused color (typically adds accent tint).
	public static Color ComputeFocused(Color baseColor, Color accentColor)
	{
		return Lerp(baseColor, accentColor, 0.2f);
	}

	/// Lightens a color by the specified amount (0-1).
	public static Color Lighten(Color color, float amount)
	{
		let r = (uint8)Math.Min(255, (int)(color.R + (255 - color.R) * amount));
		let g = (uint8)Math.Min(255, (int)(color.G + (255 - color.G) * amount));
		let b = (uint8)Math.Min(255, (int)(color.B + (255 - color.B) * amount));
		return Color(r, g, b, color.A);
	}

	/// Darkens a color by the specified amount (0-1).
	public static Color Darken(Color color, float amount)
	{
		let r = (uint8)(color.R * (1 - amount));
		let g = (uint8)(color.G * (1 - amount));
		let b = (uint8)(color.B * (1 - amount));
		return Color(r, g, b, color.A);
	}

	/// Desaturates a color by the specified amount (0-1).
	public static Color Desaturate(Color color, float amount)
	{
		let gray = (uint8)((color.R * 0.299f + color.G * 0.587f + color.B * 0.114f));
		let r = (uint8)(color.R + (gray - color.R) * amount);
		let g = (uint8)(color.G + (gray - color.G) * amount);
		let b = (uint8)(color.B + (gray - color.B) * amount);
		return Color(r, g, b, color.A);
	}

	/// Linearly interpolates between two colors.
	public static Color Lerp(Color a, Color b, float t)
	{
		let r = (uint8)(a.R + (b.R - a.R) * t);
		let g = (uint8)(a.G + (b.G - a.G) * t);
		let bl = (uint8)(a.B + (b.B - a.B) * t);
		let alpha = (uint8)(a.A + (b.A - a.A) * t);
		return Color(r, g, bl, alpha);
	}
}
