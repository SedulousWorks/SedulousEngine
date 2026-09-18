using System;
using System.Threading;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// Injects the toolkit's own styling into every theme built after it is registered.
///
/// The styling itself is AUTHORED as `.sss` ([[EmbeddedToolkitThemes]]) rather than built rule
/// by rule here, so the toolkit's chrome is expressed in the same language a project's own
/// theme is. This class only picks the branch and merges.
///
/// Hand it to the registry before building a theme:
///   ThemeRegistry.RegisterExtension(new ToolkitThemeExtension());
class ToolkitThemeExtension : IThemeExtension
{
	private static bool sTypesRegistered = false;

	/// Makes the toolkit's controls addressable from a style sheet, which is the prerequisite
	/// for expressing any of this as `.sss` at all: a selector naming an unregistered type
	/// resolves to nothing and matches nothing, in silence.
	///
	/// Idempotent. Called by construction, and callable directly by a host that parses
	/// toolkit-styling sheets without registering the extension.
	public static void RegisterToolkitTypes()
	{
		// Under the type registry's own lock, flag included: this writes the same map the
		// built-ins do, so the two once guards have to be one another's.
		using (UITypeRegistry.RegistrationLock.Enter())
		{
			RegisterToolkitTypesLocked();
		}
	}

	private static void RegisterToolkitTypesLocked()
	{
		if (sTypesRegistered)
			return;

		sTypesRegistered = true;

		UITypeRegistry.Register("DockManager", typeof(DockManager));
		UITypeRegistry.Register("DockablePanel", typeof(DockablePanel));
		UITypeRegistry.Register("DockTabGroup", typeof(DockTabGroup));
		UITypeRegistry.Register("DockSplit", typeof(DockSplit));
		UITypeRegistry.Register("DockableWindow", typeof(DockableWindow));
		UITypeRegistry.Register("DockDragPreview", typeof(DockDragPreview));
		UITypeRegistry.Register("MenuBar", typeof(MenuBar));
		UITypeRegistry.Register("Toolbar", typeof(Toolbar));
		UITypeRegistry.Register("StatusBar", typeof(StatusBar));
		UITypeRegistry.Register("SplitView", typeof(SplitView));
		UITypeRegistry.Register("BreadcrumbBar", typeof(BreadcrumbBar));
		UITypeRegistry.Register("FloatingPanel", typeof(FloatingPanel));
		UITypeRegistry.Register("ColorPicker", typeof(ColorPicker));
		UITypeRegistry.Register("GradientEditor", typeof(GradientEditor));
		UITypeRegistry.Register("PropertyGrid", typeof(PropertyGrid));
		UITypeRegistry.Register("ToastCard", typeof(ToastCard));
		UITypeRegistry.Register("CurveCanvas", typeof(CurveCanvas));
		// DIVERGES from Raptor, which never registers Timeline even though both fragments
		// carry a Timeline block. Those rules resolved to nothing and styled nothing, and the
		// hand-kept type COUNT that was meant to be the tripwire agreed with the registrations
		// rather than with the sheets, so it could not catch it. The gate is a test that every
		// selector in the fragments resolves.
		UITypeRegistry.Register("Timeline", typeof(Timeline));
	}

	public this()
	{
		RegisterToolkitTypes();
	}

	public void Apply(StyleSheet sheet, ThemePalette palette)
	{
		// The palette decides the branch: a background darker than half is a dark look, so any
		// palette derived dark theme flows through the dark fragment unchanged.
		let isDark = palette.Background.R < 0.5f;

		let loader = scope StyleSheetLoader();
		loader.SetPalette(palette);

		let parsed = loader.Load(isDark ? EmbeddedToolkitThemes.Dark : EmbeddedToolkitThemes.Light);
		if (parsed == null)
			return;

		defer parsed.ReleaseRef();
		sheet.MergeFrom(parsed);
	}
}
