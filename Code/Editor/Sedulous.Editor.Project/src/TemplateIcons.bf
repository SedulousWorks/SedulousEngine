using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.Editor.Project;

/// An export template carries its own icon: an SVG file in its bundle (cIconFile, named by the
/// manifest's Icon), which the editor reads wherever it shows the template. Creating a template
/// writes one in: the built-in icon its platform gets, one named (`handheld` for the Steam Deck
/// build), or any .svg given, so a template made elsewhere shows what its maker chose. The
/// built-in set is drawn for the engine, no third-party marks.
static class TemplateIcons
{
	/// The icon's file in a template bundle, the one creating a template writes.
	public const String cIconFile = "icon.svg";

	/// A desktop of no named OS: a monitor on a stand.
	private const String cDesktop = """
		<svg viewBox="0 0 24 24">
		  <rect x="2.5" y="4" width="19" height="13" rx="1.5" fill="none" stroke="#E0E0E0" stroke-width="1.5"/>
		  <path d="M9 21h6M12 17v4" fill="none" stroke="#E0E0E0" stroke-width="1.5" stroke-linecap="round"/>
		</svg>
		""";

	/// Windows desktop: a monitor on a stand, four panes on its screen.
	private const String cWindows = """
		<svg viewBox="0 0 24 24">
		  <rect x="2.5" y="4" width="19" height="13" rx="1.5" fill="none" stroke="#E0E0E0" stroke-width="1.5"/>
		  <path d="M9 21h6M12 17v4" fill="none" stroke="#E0E0E0" stroke-width="1.5" stroke-linecap="round"/>
		  <rect x="7.5" y="7" width="4" height="3" fill="#E0E0E0"/>
		  <rect x="12.5" y="7" width="4" height="3" fill="#E0E0E0"/>
		  <rect x="7.5" y="11" width="4" height="3" fill="#E0E0E0"/>
		  <rect x="12.5" y="11" width="4" height="3" fill="#E0E0E0"/>
		</svg>
		""";

	/// Linux desktop: a monitor on a stand, a shell prompt on its screen.
	private const String cLinux = """
		<svg viewBox="0 0 24 24">
		  <rect x="2.5" y="4" width="19" height="13" rx="1.5" fill="none" stroke="#E0E0E0" stroke-width="1.5"/>
		  <path d="M9 21h6M12 17v4" fill="none" stroke="#E0E0E0" stroke-width="1.5" stroke-linecap="round"/>
		  <path d="M6.5 8l3 2.5-3 2.5" fill="none" stroke="#E0E0E0" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>
		  <path d="M11 13.5h5" fill="none" stroke="#E0E0E0" stroke-width="1.6" stroke-linecap="round"/>
		</svg>
		""";

	/// Handheld: a wide body, its screen between a d-pad and two buttons.
	private const String cHandheld = """
		<svg viewBox="0 0 24 24">
		  <rect x="1.5" y="6.5" width="21" height="11" rx="3.5" fill="none" stroke="#E0E0E0" stroke-width="1.5"/>
		  <rect x="7.5" y="8.5" width="9" height="7" rx="0.8" fill="none" stroke="#E0E0E0" stroke-width="1.2"/>
		  <path d="M4.5 12h2M5.5 11v2" fill="none" stroke="#E0E0E0" stroke-width="1.2" stroke-linecap="round"/>
		  <circle cx="18.6" cy="11" r="0.9" fill="#E0E0E0"/>
		  <circle cx="19.6" cy="13.2" r="0.9" fill="#E0E0E0"/>
		</svg>
		""";

	/// Web: a globe, its outline, an equator and a meridian's two halves.
	private const String cWeb = """
		<svg viewBox="0 0 24 24">
		  <circle cx="12" cy="12" r="9" fill="none" stroke="#E0E0E0" stroke-width="1.5"/>
		  <path d="M3 12h18M12 3c-3 3.2-3 14.8 0 18M12 3c3 3.2 3 14.8 0 18" fill="none" stroke="#E0E0E0" stroke-width="1.3"/>
		  <path d="M4.6 7.5h14.8M4.6 16.5h14.8" fill="none" stroke="#E0E0E0" stroke-width="1"/>
		</svg>
		""";

	/// Phone: a tall rounded body, a speaker slot and a home bar.
	private const String cPhone = """
		<svg viewBox="0 0 24 24">
		  <rect x="6.5" y="2.5" width="11" height="19" rx="2.2" fill="none" stroke="#E0E0E0" stroke-width="1.5"/>
		  <path d="M10.5 5h3M10 18.5h4" fill="none" stroke="#E0E0E0" stroke-width="1.3" stroke-linecap="round"/>
		</svg>
		""";

	/// The built-in icons' names, as `Sedulous.Tools.Export --template create --icon` takes them.
	public static StringView[6] BuiltInNames = .("desktop", "windows", "linux", "handheld", "web", "phone");

	/// A built-in icon's SVG by name; empty when there is no such icon.
	public static StringView BuiltInSvg(StringView name)
	{
		switch (name)
		{
		case "desktop": return cDesktop;
		case "windows": return cWindows;
		case "linux": return cLinux;
		case "handheld": return cHandheld;
		case "web": return cWeb;
		case "phone": return cPhone;
		default: return default;
		}
	}

	/// The built-in icon a template for `platform` gets when its maker names none.
	public static StringView DefaultName(StringView platform)
	{
		if (platform == "Win64")
			return "windows";
		if (platform == "Linux64")
			return "linux";
		if (platform == BuildLayout.cWebPlatform)
			return "web";
		return "desktop";
	}

	/// The SVG a template is shown by: the icon file in its bundle, or (the host template, a
	/// bundle from before icons, an unreadable file) its platform's built-in icon.
	public static void SvgFor(ExportTemplate template, String outSvg)
	{
		if (!template.Icon.IsEmpty && !template.Directory.IsEmpty)
		{
			let bytes = scope List<uint8>();
			if ((ReadFile(PathJoin(template.Directory, template.Icon, .. scope .()), bytes) case .Ok) && !bytes.IsEmpty)
			{
				outSvg.Append((char8*)bytes.Ptr, bytes.Count);
				return;
			}
		}
		outSvg.Append(BuiltInSvg(DefaultName(template.Platform)));
	}
}
