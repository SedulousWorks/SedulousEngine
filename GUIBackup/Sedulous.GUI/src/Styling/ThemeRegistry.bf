namespace Sedulous.GUI;

using System;
using System.Collections;

/// Central registry for theme extensions. Extensions are applied to every
/// theme StyleSheet created by theme factories.
public static class ThemeRegistry
{
	private static List<IThemeExtension> sExtensions = new .() ~ { for (let e in _) delete e; delete _; };

	public static void RegisterExtension(IThemeExtension ext)
	{
		if (!sExtensions.Contains(ext))
			sExtensions.Add(ext);
	}

	public static void UnregisterExtension(IThemeExtension ext)
	{
		sExtensions.Remove(ext);
	}

	public static void ApplyExtensions(StyleSheet sheet, ThemePalette palette)
	{
		for (let ext in sExtensions)
			ext.Apply(sheet, palette);
	}
}
