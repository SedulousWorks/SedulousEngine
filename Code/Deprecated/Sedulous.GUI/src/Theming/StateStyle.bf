using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;

namespace Sedulous.GUI;

/// Style overrides for a specific visual state.
/// Null values inherit from the base ControlStyle.
public struct StateStyle
{
	public Color? Background;
	public Color? Foreground;
	public Color? BorderColor;
	public float? BorderThickness;
	public float? CornerRadius;
	public Thickness? Padding;
	public ImageBrush? BackgroundImage;

	/// Creates an empty state style (all values inherit).
	public static StateStyle Empty => .();

	/// Creates a state style with just a background override.
	public static StateStyle WithBackground(Color bg) => .() { Background = bg };

	/// Creates a state style with background and foreground overrides.
	public static StateStyle WithColors(Color bg, Color fg) => .() { Background = bg, Foreground = fg };
}

/// Style definition for a control type.
/// Contains base style plus per-state overrides.
public struct ControlStyle
{
	// Base style (used for Normal state)
	public Color Background;
	public Color Foreground;
	public Color BorderColor;
	public float BorderThickness;
	public float CornerRadius;
	public Thickness Padding;
	public ImageBrush? BackgroundImage;

	// State overrides
	public StateStyle Hover;
	public StateStyle Pressed;
	public StateStyle Disabled;
	public StateStyle Focused;

	/// Gets the effective background color for the given state.
	public Color GetBackground(ControlState state)
	{
		switch (state)
		{
		case .Hover:
			return Hover.Background ?? Palette.ComputeHover(Background);
		case .Pressed:
			return Pressed.Background ?? Palette.ComputePressed(Background);
		case .Disabled:
			return Disabled.Background ?? Palette.ComputeDisabled(Background);
		case .Focused:
			return Focused.Background ?? Background;
		default:
			return Background;
		}
	}

	/// Gets the effective foreground color for the given state.
	public Color GetForeground(ControlState state)
	{
		switch (state)
		{
		case .Hover:
			return Hover.Foreground ?? Foreground;
		case .Pressed:
			return Pressed.Foreground ?? Foreground;
		case .Disabled:
			return Disabled.Foreground ?? Palette.ComputeDisabled(Foreground);
		case .Focused:
			return Focused.Foreground ?? Foreground;
		default:
			return Foreground;
		}
	}

	/// Gets the effective border color for the given state.
	public Color GetBorderColor(ControlState state)
	{
		switch (state)
		{
		case .Hover:
			return Hover.BorderColor ?? Palette.ComputeHover(BorderColor);
		case .Pressed:
			return Pressed.BorderColor ?? Palette.ComputePressed(BorderColor);
		case .Disabled:
			return Disabled.BorderColor ?? Palette.ComputeDisabled(BorderColor);
		case .Focused:
			return Focused.BorderColor ?? BorderColor;
		default:
			return BorderColor;
		}
	}

	/// Gets the effective border thickness for the given state.
	public float GetBorderThickness(ControlState state)
	{
		switch (state)
		{
		case .Hover:
			return Hover.BorderThickness ?? BorderThickness;
		case .Pressed:
			return Pressed.BorderThickness ?? BorderThickness;
		case .Disabled:
			return Disabled.BorderThickness ?? BorderThickness;
		case .Focused:
			return Focused.BorderThickness ?? BorderThickness + 1;
		default:
			return BorderThickness;
		}
	}

	/// Gets the effective padding for the given state.
	public Thickness GetPadding(ControlState state)
	{
		switch (state)
		{
		case .Hover:
			return Hover.Padding ?? Padding;
		case .Pressed:
			return Pressed.Padding ?? Padding;
		case .Disabled:
			return Disabled.Padding ?? Padding;
		case .Focused:
			return Focused.Padding ?? Padding;
		default:
			return Padding;
		}
	}

	/// Gets the effective background image for the given state.
	/// If a per-state image is set, returns it directly.
	/// If only a base image is set, applies automatic tint modulation for the state.
	public ImageBrush? GetBackgroundImage(ControlState state)
	{
		// Check for per-state image override first
		ImageBrush? stateImage;
		switch (state)
		{
		case .Hover:    stateImage = Hover.BackgroundImage;
		case .Pressed:  stateImage = Pressed.BackgroundImage;
		case .Disabled: stateImage = Disabled.BackgroundImage;
		case .Focused:  stateImage = Focused.BackgroundImage;
		default:        stateImage = null;
		}

		// Per-state image takes priority (no auto-tint)
		if (stateImage.HasValue)
			return stateImage;

		// Fall back to base image with automatic tint modulation
		if (BackgroundImage.HasValue)
		{
			var img = BackgroundImage.Value;
			img.Tint = ModulateTint(img.Tint, state);
			return img;
		}

		return null;
	}

	/// Applies automatic tint modulation based on control state.
	public static Color ModulateTint(Color tint, ControlState state)
	{
		switch (state)
		{
		case .Hover:
			return Palette.Lighten(tint, 0.15f);
		case .Pressed:
			return Palette.Darken(tint, 0.15f);
		case .Disabled:
			let desaturated = Palette.Desaturate(tint, 0.5f);
			return Color(desaturated.R, desaturated.G, desaturated.B, (uint8)(tint.A * 0.5f));
		default:
			return tint;
		}
	}
}
