using System;

namespace Sedulous.UI;

/// The built in SVG icons a theme registers for its drawable keys.
///
/// String constants compiled into the binary, so a theme needs no files on disk to draw a
/// checkbox tick or a combo box arrow.
///
/// Every icon is stroked or filled in WHITE and recoloured by the theme through the
/// drawable's tint, so one icon serves a light theme and a dark one.
static class ThemeIcons
{
	/// For CheckBox.
	public const String Checkmark = """
		<svg viewBox="0 0 16 16">
		  <path d="M3 8 L6.5 11.5 L13 5" fill="none" stroke="white" stroke-width="2"/>
		</svg>
		""";

	/// For the ComboBox dropdown.
	public const String ArrowDown = """
		<svg viewBox="0 0 12 12">
		  <path d="M2 4 L6 8 L10 4" fill="none" stroke="white" stroke-width="1.5"/>
		</svg>
		""";

	/// For a NumericField's increment.
	public const String ArrowUp = """
		<svg viewBox="0 0 12 12">
		  <path d="M2 8 L6 4 L10 8" fill="none" stroke="white" stroke-width="1.5"/>
		</svg>
		""";

	/// For a collapsed Expander or TreeView node.
	public const String ChevronRight = """
		<svg viewBox="0 0 10 12">
		  <path d="M3 2 L7 6 L3 10" fill="none" stroke="white" stroke-width="1.5"/>
		</svg>
		""";

	/// For an expanded Expander or TreeView node.
	public const String ChevronDown = """
		<svg viewBox="0 0 12 10">
		  <path d="M2 3 L6 7 L10 3" fill="none" stroke="white" stroke-width="1.5"/>
		</svg>
		""";

	/// For a tab or panel close button.
	public const String Close = """
		<svg viewBox="0 0 12 12">
		  <path d="M2 2 L10 10 M10 2 L2 10" fill="none" stroke="white" stroke-width="1.5"/>
		</svg>
		""";

	public const String Plus = """
		<svg viewBox="0 0 12 12">
		  <path d="M6 2 L6 10 M2 6 L10 6" fill="none" stroke="white" stroke-width="1.5"/>
		</svg>
		""";

	public const String Minus = """
		<svg viewBox="0 0 12 12">
		  <path d="M2 6 L10 6" fill="none" stroke="white" stroke-width="1.5"/>
		</svg>
		""";

	/// For a RadioButton in a flat theme.
	public const String RadioMarkSquare = """
		<svg viewBox="0 0 8 8">
		  <rect x="1" y="1" width="6" height="6" fill="white"/>
		</svg>
		""";

	/// For a RadioButton in a rounded theme.
	public const String RadioMarkRound = """
		<svg viewBox="0 0 8 8">
		  <circle cx="4" cy="4" r="3" fill="white"/>
		</svg>
		""";
}
