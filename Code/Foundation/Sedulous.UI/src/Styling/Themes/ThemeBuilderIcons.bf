using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// Binding the built in chrome glyphs onto a hand built theme sheet.
///
/// It is shared by the three legacy rule builders because all three bind the SAME set of glyphs
/// to the same pseudo elements and differ only in the tint: one copy is the same styling with
/// one place to change it.
static class ThemeBuilderIcons
{
	/// A missing glyph is SKIPPED rather than substituted: the control's own fallback drawing
	/// is closer to right than somebody else's icon.
	public static void Bind(StyleSheet sheet, ThemeIcon icon, Color? tint, Type type,
		StringView pseudo, ControlState? state)
	{
		let drawable = Acquire(icon, tint);
		if (drawable == null)
			return;

		sheet.OwnDrawable(drawable);

		if (state.HasValue)
			sheet.ForTypePseudoState(type, pseudo, state.Value).Set(.Background, drawable);
		else
			sheet.ForTypePseudo(type, pseudo).Set(.Background, drawable);
	}

	/// The submenu arrow hangs off a CLASS rather than a type, so its rule is built by hand:
	/// the context menu and the combo box dropdown share the class and neither owns the rule.
	public static void BindSubmenuArrow(StyleSheet sheet, Color? tint)
	{
		let drawable = Acquire(.ChevronRight, tint);
		if (drawable == null)
			return;

		sheet.OwnDrawable(drawable);

		let rule = new StyleRule();
		rule.Selector.AddClass("contextmenu");
		rule.Selector.SetPseudoElement("submenu-arrow");
		rule.Set(.Background, drawable);
		sheet.AddRule(rule);
	}

	/// The shared BAKED glyph where the icon set is live, so these join the bake pass rather
	/// than each theme rasterising its own copy.
	private static Drawable Acquire(ThemeIcon icon, Color? tint) =>
		tint.HasValue ? ThemeIconSet.Acquire(icon, tint.Value) : ThemeIconSet.Acquire(icon);
}
