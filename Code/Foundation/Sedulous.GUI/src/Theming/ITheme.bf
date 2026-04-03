using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// Interface for theme providers.
/// Themes define the visual appearance of controls.
public interface ITheme
{
	/// The name of the theme.
	StringView Name { get; }

	/// The color palette for this theme.
	Palette Palette { get; }

	/// Gets the style for a specific control type.
	/// Returns a default style if no specific style is defined.
	ControlStyle GetControlStyle(StringView controlType);

	/// Gets the focus indicator color.
	Color FocusIndicatorColor { get; }

	/// Gets the focus indicator thickness.
	float FocusIndicatorThickness { get; }

	/// Gets the selection highlight color.
	Color SelectionColor { get; }

	/// Gets the default font size.
	float DefaultFontSize { get; }

	// === Control Dimensions ===

	/// Gets the default menu item height.
	float MenuItemHeight { get; }

	/// Gets the menu check area width.
	float MenuCheckWidth { get; }

	/// Gets the submenu arrow width.
	float MenuArrowWidth { get; }

	/// Gets the menu shortcut gap width.
	float MenuShortcutGap { get; }

	/// Gets the tab strip height.
	float TabStripHeight { get; }

	/// Gets the scrollbar thickness.
	float ScrollBarThickness { get; }

	/// Gets the slider track thickness.
	float SliderTrackThickness { get; }

	/// Gets the slider thumb size.
	float SliderThumbSize { get; }

	/// Gets the checkbox indicator size.
	float CheckBoxSize { get; }

	/// Gets the checkbox content spacing.
	float CheckBoxSpacing { get; }

	/// Gets the radio button circle size.
	float RadioButtonSize { get; }

	/// Gets the radio button content spacing.
	float RadioButtonSpacing { get; }

	/// Gets the toggle switch track width.
	float ToggleSwitchTrackWidth { get; }

	/// Gets the toggle switch track height.
	float ToggleSwitchTrackHeight { get; }

	/// Gets the toggle switch knob size.
	float ToggleSwitchKnobSize { get; }

	/// Gets the separator line thickness.
	float SeparatorThickness { get; }

	/// Gets the default corner radius.
	float DefaultCornerRadius { get; }

	/// Gets the combo box dropdown button width.
	float ComboBoxDropDownButtonWidth { get; }

	/// Gets the combo box dropdown max height.
	float ComboBoxDropDownMaxHeight { get; }

	/// Gets the default icon size for message boxes.
	float MessageBoxIconSize { get; }

	// === Docking System Dimensions ===

	/// Gets the dock panel title bar height.
	float DockPanelTitleBarHeight { get; }

	/// Gets the dock tab strip height.
	float DockTabHeight { get; }

	/// Gets the dock panel/tab font size.
	float DockFontSize { get; }

	/// Gets the dock tab text padding from left edge.
	float DockTabPadding { get; }
}
