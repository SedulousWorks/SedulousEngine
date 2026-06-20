namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Generates derived colors from seed colors for control states.
/// Used to build consistent themes without manually specifying every state color.
public static class Palette
{
	/// Lighten a color by a factor (0-1).
	public static Color Lighten(Color color, float amount)
	{
		let a = Math.Clamp(amount, 0, 1);
		return .(
			Math.Min(1.0f, color.R + (1.0f - color.R) * a),
			Math.Min(1.0f, color.G + (1.0f - color.G) * a),
			Math.Min(1.0f, color.B + (1.0f - color.B) * a),
			color.A);
	}

	/// Darken a color by a factor (0-1).
	public static Color Darken(Color color, float amount)
	{
		let a = Math.Clamp(amount, 0, 1);
		return .(
			color.R * (1 - a),
			color.G * (1 - a),
			color.B * (1 - a),
			color.A);
	}

	/// Compute hover variant of a color (slightly lighter for dark themes).
	public static Color ComputeHover(Color baseColor)
	{
		return Lighten(baseColor, 0.15f);
	}

	/// Compute pressed variant of a color (slightly darker).
	public static Color ComputePressed(Color baseColor)
	{
		return Darken(baseColor, 0.1f);
	}

	/// Compute disabled variant of a color (desaturated and faded).
	public static Color ComputeDisabled(Color baseColor)
	{
		let gray = baseColor.R * 0.30f + baseColor.G * 0.59f + baseColor.B * 0.11f;
		return .((gray + baseColor.R) * 0.5f,
				 (gray + baseColor.G) * 0.5f,
				 (gray + baseColor.B) * 0.5f,
				 baseColor.A * 0.6f);
	}

	/// Compute focused variant of a color (tinted toward accent).
	public static Color ComputeFocused(Color baseColor, Color accentColor = .(60, 130, 220, 255))
	{
		return .(
			baseColor.R * 0.8f + accentColor.R * 0.2f,
			baseColor.G * 0.8f + accentColor.G * 0.2f,
			baseColor.B * 0.8f + accentColor.B * 0.2f,
			baseColor.A);
	}

	/// Create a StateListDrawable from a base color, automatically generating
	/// hover/pressed/disabled/focused variants.
	public static StateListDrawable CreateStateColors(Color baseColor)
	{
		let sl = new StateListDrawable();
		sl.Set(.Normal, new ColorDrawable(baseColor));
		sl.Set(.Hover, new ColorDrawable(ComputeHover(baseColor)));
		sl.Set(.Pressed, new ColorDrawable(ComputePressed(baseColor)));
		sl.Set(.Disabled, new ColorDrawable(ComputeDisabled(baseColor)));
		sl.Set(.Focused, new ColorDrawable(ComputeFocused(baseColor)));
		return sl;
	}

	/// Create a StateListDrawable with RoundedRectDrawable per state and per-corner radii.
	public static StateListDrawable CreateStateRounded(Color baseColor, Sedulous.VG.CornerRadii radii)
	{
		let sl = new StateListDrawable();
		sl.Set(.Normal, new RoundedRectDrawable(baseColor, radii));
		sl.Set(.Hover, new RoundedRectDrawable(ComputeHover(baseColor), radii));
		sl.Set(.Pressed, new RoundedRectDrawable(ComputePressed(baseColor), radii));
		sl.Set(.Disabled, new RoundedRectDrawable(ComputeDisabled(baseColor), radii));
		sl.Set(.Focused, new RoundedRectDrawable(ComputeFocused(baseColor), radii));
		return sl;
	}
}
