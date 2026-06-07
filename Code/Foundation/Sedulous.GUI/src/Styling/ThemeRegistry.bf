namespace Sedulous.GUI;

using System;
using System.Collections;

/// Central registry for theme extensions. Extensions are applied to every
/// theme StyleSheet created by DarkTheme/LightTheme factories.
public static class ThemeRegistry
{
	private static List<IThemeExtension> sExtensions = new .() ~ { for (let e in _) delete e; delete _; };

	/// Register an extension. Applied to all themes created after registration.
	public static void RegisterExtension(IThemeExtension ext)
	{
		if (!sExtensions.Contains(ext))
			sExtensions.Add(ext);
	}

	/// Unregister an extension.
	public static void UnregisterExtension(IThemeExtension ext)
	{
		sExtensions.Remove(ext);
	}

	/// Apply all registered extensions to a theme sheet.
	public static void ApplyExtensions(StyleSheet sheet, ThemePalette palette)
	{
		for (let ext in sExtensions)
			ext.Apply(sheet, palette);
	}
}
