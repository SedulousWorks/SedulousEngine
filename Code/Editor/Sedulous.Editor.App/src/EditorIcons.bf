using System;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// SVG icon strings and shared drawable instances for editor UI elements.
/// Call Initialize() once at startup, Shutdown() on exit.
static class EditorIcons
{
	// Shared drawable instances (created once, used by all scene pages)
	public static SVGDrawable TranslateIcon;
	public static SVGDrawable RotateIcon;
	public static SVGDrawable ScaleIcon;
	public static SVGDrawable WorldSpaceIcon;
	public static SVGDrawable LocalSpaceIcon;
	public static SVGDrawable GridIcon;

	public static void Initialize()
	{
		TranslateIcon = SVGDrawable.FromString(Translate);
		RotateIcon = SVGDrawable.FromString(Rotate);
		ScaleIcon = SVGDrawable.FromString(Scale);
		WorldSpaceIcon = SVGDrawable.FromString(WorldSpace);
		LocalSpaceIcon = SVGDrawable.FromString(LocalSpace);
		GridIcon = SVGDrawable.FromString(Grid);
	}

	public static void Shutdown()
	{
		delete TranslateIcon; TranslateIcon = null;
		delete RotateIcon; RotateIcon = null;
		delete ScaleIcon; ScaleIcon = null;
		delete WorldSpaceIcon; WorldSpaceIcon = null;
		delete LocalSpaceIcon; LocalSpaceIcon = null;
		delete GridIcon; GridIcon = null;
	}

	/// Translate gizmo - four arrows pointing outward from center.
	public static readonly String Translate = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 2l3 3h-2v4h-2V5H9l3-3z" fill="#E0E0E0"/>
		  <path d="M12 22l-3-3h2v-4h2v4h2l-3 3z" fill="#E0E0E0"/>
		  <path d="M2 12l3-3v2h4v2H5v2l-3-3z" fill="#E0E0E0"/>
		  <path d="M22 12l-3 3v-2h-4v-2h4V9l3 3z" fill="#E0E0E0"/>
		</svg>
		""";

	/// Rotate gizmo - circular arrow.
	public static readonly String Rotate = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 4c4.42 0 8 3.58 8 8h-2.5c0-3.04-2.46-5.5-5.5-5.5S6.5 8.96 6.5 12s2.46 5.5 5.5 5.5c1.52 0 2.9-.62 3.89-1.61l1.77 1.77A7.96 7.96 0 0112 20c-4.42 0-8-3.58-8-8s3.58-8 8-8z" fill="#E0E0E0"/>
		  <path d="M20 12l3-3v6l-3-3z" fill="#E0E0E0"/>
		</svg>
		""";

	/// Scale gizmo - diagonal arrow with corner square.
	public static readonly String Scale = """
		<svg viewBox="0 0 24 24">
		  <rect x="3" y="3" width="5" height="5" fill="#E0E0E0"/>
		  <path d="M8 8l10 10" stroke="#E0E0E0" stroke-width="2" stroke-linecap="round"/>
		  <rect x="16" y="16" width="5" height="5" fill="#E0E0E0"/>
		  <path d="M14 20h6v-6" fill="none" stroke="#E0E0E0" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
		</svg>
		""";

	/// World space - globe/grid icon.
	public static readonly String WorldSpace = """
		<svg viewBox="0 0 24 24">
		  <circle cx="12" cy="12" r="9" fill="none" stroke="#E0E0E0" stroke-width="1.5"/>
		  <ellipse cx="12" cy="12" rx="4" ry="9" fill="none" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="3" y1="12" x2="21" y2="12" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="12" y1="3" x2="12" y2="21" stroke="#E0E0E0" stroke-width="1"/>
		</svg>
		""";

	/// Local space - cube icon.
	public static readonly String LocalSpace = """
		<svg viewBox="0 0 24 24">
		  <path d="M12 2L4 7v10l8 5 8-5V7l-8-5z" fill="none" stroke="#E0E0E0" stroke-width="1.5" stroke-linejoin="round"/>
		  <path d="M12 22V12M4 7l8 5 8-5" fill="none" stroke="#E0E0E0" stroke-width="1" stroke-linejoin="round"/>
		</svg>
		""";

	/// Debug grid - 4x4 grid pattern.
	public static readonly String Grid = """
		<svg viewBox="0 0 24 24">
		  <rect x="3" y="3" width="18" height="18" fill="none" stroke="#E0E0E0" stroke-width="1.4"/>
		  <line x1="9"  y1="3" x2="9"  y2="21" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="15" y1="3" x2="15" y2="21" stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="3" y1="9"  x2="21" y2="9"  stroke="#E0E0E0" stroke-width="1"/>
		  <line x1="3" y1="15" x2="21" y2="15" stroke="#E0E0E0" stroke-width="1"/>
		</svg>
		""";
}
