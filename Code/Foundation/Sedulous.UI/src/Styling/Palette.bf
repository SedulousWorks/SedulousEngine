using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.UI;

/// Derives the hover, pressed, disabled and focused colours from a seed colour, and builds
/// state list drawables out of them.
///
/// This is what lets a theme state one colour per control and get a consistent set of states
/// for free, rather than authoring five colours that drift apart.
static class Palette
{
	/// Toward white by a factor.
	public static Color Lighten(Color color, float amount)
	{
		let a = Clamp(amount, 0.0f, 1.0f);
		return .(Min(1.0f, color.R + (1.0f - color.R) * a),
			Min(1.0f, color.G + (1.0f - color.G) * a),
			Min(1.0f, color.B + (1.0f - color.B) * a), color.A);
	}

	/// Toward black by a factor.
	public static Color Darken(Color color, float amount)
	{
		let a = Clamp(amount, 0.0f, 1.0f);
		return .(color.R * (1.0f - a), color.G * (1.0f - a), color.B * (1.0f - a), color.A);
	}

	public static Color ComputeHover(Color baseColor) => Lighten(baseColor, 0.15f);
	public static Color ComputePressed(Color baseColor) => Darken(baseColor, 0.1f);

	/// Desaturated and faded: half way to its own luminance, at sixty percent alpha.
	public static Color ComputeDisabled(Color baseColor)
	{
		let gray = baseColor.R * 0.30f + baseColor.G * 0.59f + baseColor.B * 0.11f;
		return .((gray + baseColor.R) * 0.5f, (gray + baseColor.G) * 0.5f,
			(gray + baseColor.B) * 0.5f, baseColor.A * 0.6f);
	}

	/// Tinted a fifth of the way toward the accent.
	public static Color ComputeFocused(Color baseColor,
		Color accentColor = .(60.0f / 255.0f, 130.0f / 255.0f, 220.0f / 255.0f, 1.0f))
	{
		return .(baseColor.R * 0.8f + accentColor.R * 0.2f,
			baseColor.G * 0.8f + accentColor.G * 0.2f,
			baseColor.B * 0.8f + accentColor.B * 0.2f, baseColor.A);
	}

	/// A state list of flat colours, with the variants derived. The caller OWNS the result.
	public static StateListDrawable CreateStateColors(Color baseColor)
	{
		let list = new StateListDrawable();
		list.Set(.Normal, new ColorDrawable(baseColor));
		list.Set(.Hover, new ColorDrawable(ComputeHover(baseColor)));
		list.Set(.Pressed, new ColorDrawable(ComputePressed(baseColor)));
		list.Set(.Disabled, new ColorDrawable(ComputeDisabled(baseColor)));
		list.Set(.Focused, new ColorDrawable(ComputeFocused(baseColor)));
		return list;
	}

	/// A state list of rounded rectangles, with the variants derived. The caller OWNS the
	/// result.
	public static StateListDrawable CreateStateRounded(Color baseColor, CornerRadii radii)
	{
		let list = new StateListDrawable();
		list.Set(.Normal, new RoundedRectDrawable(baseColor, radii));
		list.Set(.Hover, new RoundedRectDrawable(ComputeHover(baseColor), radii));
		list.Set(.Pressed, new RoundedRectDrawable(ComputePressed(baseColor), radii));
		list.Set(.Disabled, new RoundedRectDrawable(ComputeDisabled(baseColor), radii));
		list.Set(.Focused, new RoundedRectDrawable(ComputeFocused(baseColor), radii));
		return list;
	}
}
