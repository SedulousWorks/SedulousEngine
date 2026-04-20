namespace Sedulous.UI;

using System;

/// Built-in SVG icon definitions for theme drawable keys.
/// These are string constants compiled into the binary - no file loading needed.
/// A theme can register these as SVGDrawables for icon keys.
public static class ThemeIcons
{
	/// Checkmark icon for CheckBox.
	public static StringView Checkmark =>
		"""
		<svg viewBox="0 0 16 16">
		  <path d="M3 8 L6.5 11.5 L13 5" fill="none" stroke="white" stroke-width="2"/>
		</svg>
		""";

	/// Down-pointing arrow for ComboBox dropdown.
	public static StringView ArrowDown =>
		"""
		<svg viewBox="0 0 12 12">
		  <path d="M2 4 L6 8 L10 4" fill="none" stroke="white" stroke-width="1.5"/>
		</svg>
		""";

	/// Up-pointing arrow for NumericField increment.
	public static StringView ArrowUp =>
		"""
		<svg viewBox="0 0 12 12">
		  <path d="M2 8 L6 4 L10 8" fill="none" stroke="white" stroke-width="1.5"/>
		</svg>
		""";

	/// Right-pointing chevron for collapsed Expander/TreeView.
	public static StringView ChevronRight =>
		"""
		<svg viewBox="0 0 10 12">
		  <path d="M3 2 L7 6 L3 10" fill="none" stroke="white" stroke-width="1.5"/>
		</svg>
		""";

	/// Down-pointing chevron for expanded Expander/TreeView.
	public static StringView ChevronDown =>
		"""
		<svg viewBox="0 0 12 10">
		  <path d="M2 3 L6 7 L10 3" fill="none" stroke="white" stroke-width="1.5"/>
		</svg>
		""";

	/// Close (X) icon for tab close buttons, panel close buttons.
	public static StringView Close =>
		"""
		<svg viewBox="0 0 12 12">
		  <path d="M2 2 L10 10 M10 2 L2 10" fill="none" stroke="white" stroke-width="1.5"/>
		</svg>
		""";

	/// Plus icon (for add buttons, etc.)
	public static StringView Plus =>
		"""
		<svg viewBox="0 0 12 12">
		  <path d="M6 2 L6 10 M2 6 L10 6" fill="none" stroke="white" stroke-width="1.5"/>
		</svg>
		""";

	/// Minus icon (for remove buttons, etc.)
	public static StringView Minus =>
		"""
		<svg viewBox="0 0 12 12">
		  <path d="M2 6 L10 6" fill="none" stroke="white" stroke-width="1.5"/>
		</svg>
		""";

	/// Filled circle for RadioButton dot.
	public static StringView RadioDot =>
		"""
		<svg viewBox="0 0 8 8">
		  <circle cx="4" cy="4" r="3" fill="white"/>
		</svg>
		""";
}
