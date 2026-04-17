namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Seed colors + state-derivation helpers. Themes build their dictionaries
/// from a Palette so state variants are mathematically consistent.
public struct Palette
{
	public Color Primary = .(60, 120, 215, 255);
	public Color PrimaryAccent = .(80, 150, 240, 255);
	public Color Background = .(30, 30, 35, 255);
	public Color Surface = .(42, 44, 54, 255);
	public Color SurfaceBright = .(55, 58, 70, 255);
	public Color Border = .(65, 70, 85, 255);
	public Color Text = .(220, 225, 235, 255);
	public Color TextDim = .(140, 150, 170, 255);
	public Color Error = .(210, 60, 60, 255);
	public Color Success = .(60, 180, 80, 255);
	public Color Warning = .(220, 180, 50, 255);

	public static Color Lighten(Color c, float amount)
	{
		return .(
			(uint8)Math.Min(255, (int)(c.R + (255 - c.R) * amount)),
			(uint8)Math.Min(255, (int)(c.G + (255 - c.G) * amount)),
			(uint8)Math.Min(255, (int)(c.B + (255 - c.B) * amount)),
			c.A);
	}

	public static Color Darken(Color c, float amount)
	{
		return .(
			(uint8)Math.Max(0, (int)(c.R * (1 - amount))),
			(uint8)Math.Max(0, (int)(c.G * (1 - amount))),
			(uint8)Math.Max(0, (int)(c.B * (1 - amount))),
			c.A);
	}

	public static Color Desaturate(Color c, float amount)
	{
		let gray = (uint8)((c.R + c.G + c.B) / 3);
		return .(
			(uint8)(c.R + (gray - c.R) * amount),
			(uint8)(c.G + (gray - c.G) * amount),
			(uint8)(c.B + (gray - c.B) * amount),
			(uint8)(c.A * (1 - amount * 0.5f)));
	}

	/// +15% lightness
	public static Color ComputeHover(Color baseColor) => Lighten(baseColor, 0.15f);
	/// -15% lightness
	public static Color ComputePressed(Color baseColor) => Darken(baseColor, 0.15f);
	/// -50% saturation, 50% alpha
	public static Color ComputeDisabled(Color baseColor) => Desaturate(baseColor, 0.5f);
	/// Tint toward accent
	public static Color ComputeFocused(Color baseColor, Color accent)
	{
		return .((uint8)((baseColor.R + accent.R) / 2),
				 (uint8)((baseColor.G + accent.G) / 2),
				 (uint8)((baseColor.B + accent.B) / 2),
				 baseColor.A);
	}

	/// Resolve a base color to the appropriate state variant.
	public Color ResolveState(Color baseColor, ControlState state)
	{
		switch (state)
		{
		case .Hover:    return ComputeHover(baseColor);
		case .Pressed:  return ComputePressed(baseColor);
		case .Disabled: return ComputeDisabled(baseColor);
		case .Focused:  return ComputeFocused(baseColor, PrimaryAccent);
		default:        return baseColor;
		}
	}
}
