using System;
using System.Collections;

namespace Sedulous.UI;

/// The registered theme extensions, applied to every theme sheet the factories build.
///
/// The registry holds NON owning references: the application owns each extension's lifetime,
/// which stops a global outliving what registered with it.
static class ThemeRegistry
{
	private static List<IThemeExtension> sExtensions = new .() ~ delete _;

	/// Registers an extension, which then applies to every theme built afterwards. Registering
	/// twice does nothing.
	public static void RegisterExtension(IThemeExtension themeExtension)
	{
		if (themeExtension == null)
			return;
		if (sExtensions.Contains(themeExtension))
			return;
		sExtensions.Add(themeExtension);
	}

	public static void UnregisterExtension(IThemeExtension themeExtension)
	{
		sExtensions.Remove(themeExtension);
	}

	/// Applies every registered extension to a theme sheet.
	public static void ApplyExtensions(StyleSheet sheet, ThemePalette palette)
	{
		for (let themeExtension in sExtensions)
			themeExtension.Apply(sheet, palette);
	}
}
