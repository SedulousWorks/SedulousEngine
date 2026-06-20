using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.LegacyGUI;

/// Default dark theme with modern styling.
public class DarkTheme : ITheme
{
	private Palette mPalette;
	private Dictionary<String, ControlStyle> mStyles = new .() ~ DeleteDictionaryAndKeys!(_);

	public this()
	{
		// Initialize palette
		mPalette = .()
		{
			Primary = Color32(98, 0, 238, 255),      // Purple
			Secondary = Color32(3, 218, 198, 255),   // Teal
			Accent = Color32(100, 149, 237, 255),    // Cornflower blue
			Background = Color32(18, 18, 18, 255),   // Near black
			Surface = Color32(30, 30, 30, 255),      // Dark gray
			Error = Color32(207, 102, 121, 255),     // Soft red
			Warning = Color32(255, 200, 0, 255),     // Yellow
			Success = Color32(76, 175, 80, 255),     // Green
			Text = Color32(255, 255, 255, 255),      // White
			TextSecondary = Color32(180, 180, 180, 255), // Light gray
			Border = Color32(60, 60, 60, 255),       // Medium gray
			Link = Color32(100, 149, 237, 255),      // Cornflower blue (same as Accent)
			LinkVisited = Color32(149, 117, 205, 255) // Light purple
		};

		// Define control styles
		InitializeStyles();
	}

	private void InitializeStyles()
	{
		// Precompute derived colors (using type alias to avoid conflict with property)
		let buttonBase = Color32(55, 55, 55, 255);
		let buttonHover = Sedulous.LegacyGUI.Palette.ComputeHover(buttonBase);
		let buttonPressed = Sedulous.LegacyGUI.Palette.ComputePressed(buttonBase);
		let inputBase = Color32(25, 25, 25, 255);
		let hoverBorder = Sedulous.LegacyGUI.Palette.ComputeHover(mPalette.Border);
		let separatorBorder = Sedulous.LegacyGUI.Palette.Darken(mPalette.Border, 0.15f);
		let checkHoverBorder = Sedulous.LegacyGUI.Palette.ComputeHover(mPalette.Border);
		let toggleBase = Color32(60, 60, 60, 255);
		let toggleBorder = Sedulous.LegacyGUI.Palette.ComputeHover(toggleBase);
		let toggleHoverBorder = Sedulous.LegacyGUI.Palette.ComputeHover(toggleBorder);
		let hyperlinkHover = Sedulous.LegacyGUI.Palette.ComputeHover(mPalette.Accent);
		let scrollThumb = Color32(80, 80, 80, 255);
		let scrollThumbHover = Sedulous.LegacyGUI.Palette.ComputeHover(scrollThumb);
		let splitterBase = Color32(45, 45, 45, 255);
		let splitterHover = Sedulous.LegacyGUI.Palette.ComputeHover(splitterBase);
		let splitterGrip = Sedulous.LegacyGUI.Palette.ComputeHover(mPalette.Border);
		let itemHover = Sedulous.LegacyGUI.Palette.ComputeHover(mPalette.Surface);
		let tabItemBase = Color32(60, 60, 60, 255);
		let tabItemHover = Sedulous.LegacyGUI.Palette.ComputeHover(tabItemBase);
		let expanderBase = Color32(40, 40, 40, 255);
		let expanderHover = Sedulous.LegacyGUI.Palette.ComputeHover(expanderBase);

		// Default control style
		mStyles[new String("Control")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 4,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// Button style
		mStyles[new String("Button")] = .()
		{
			Background = buttonBase,
			Foreground = mPalette.Text,
			BorderColor = buttonHover,
			BorderThickness = 1,
			CornerRadius = 4,
			Padding = .(10, 4, 10, 4),  // Horizontal 10px, vertical 4px
			Hover = .() { Background = buttonHover },
			Pressed = .() { Background = buttonPressed },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// Panel style
		mStyles[new String("Panel")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// StackPanel style (layout container - transparent)
		mStyles[new String("StackPanel")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// DockPanel style (layout container - transparent)
		mStyles[new String("DockPanel")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// Canvas style (layout container - transparent)
		mStyles[new String("Canvas")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// WrapPanel style (layout container - transparent)
		mStyles[new String("WrapPanel")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// Grid style (layout container - transparent)
		mStyles[new String("Grid")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// TextBox style
		mStyles[new String("TextBox")] = .()
		{
			Background = inputBase,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 4,
			Padding = .(6, 4, 6, 4),
			Hover = .() { BorderColor = hoverBorder },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// PasswordBox style (same as TextBox)
		mStyles[new String("PasswordBox")] = .()
		{
			Background = inputBase,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 4,
			Padding = .(6, 4, 6, 4),
			Hover = .() { BorderColor = hoverBorder },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// NumericUpDown style
		mStyles[new String("NumericUpDown")] = .()
		{
			Background = inputBase,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 4,
			Padding = .(4, 2, 4, 2),
			Hover = .() { BorderColor = hoverBorder },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// Label style
		mStyles[new String("Label")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// TextBlock style
		mStyles[new String("TextBlock")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// Border style
		mStyles[new String("Border")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0
		};

		// Separator style
		mStyles[new String("Separator")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = separatorBorder,  // Subtle line color
			BorderThickness = 1,
			CornerRadius = 0
		};

		// ProgressBar style
		mStyles[new String("ProgressBar")] = .()
		{
			Background = Color32(40, 40, 40, 255),  // Track color
			Foreground = mPalette.Accent,         // Fill color
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 4
		};

		// RepeatButton style (same as Button)
		mStyles[new String("RepeatButton")] = .()
		{
			Background = buttonBase,
			Foreground = mPalette.Text,
			BorderColor = buttonHover,
			BorderThickness = 1,
			CornerRadius = 4,
			Padding = .(10, 4, 10, 4),
			Hover = .() { Background = buttonHover },
			Pressed = .() { Background = buttonPressed },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// ToggleButton style
		mStyles[new String("ToggleButton")] = .()
		{
			Background = buttonBase,
			Foreground = mPalette.Text,
			BorderColor = buttonHover,
			BorderThickness = 1,
			CornerRadius = 4,
			Padding = .(10, 4, 10, 4),
			Hover = .() { Background = buttonHover },
			Pressed = .() { Background = buttonPressed },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// CheckBox style
		mStyles[new String("CheckBox")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 3,
			Hover = .() { BorderColor = checkHoverBorder },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// RadioButton style
		mStyles[new String("RadioButton")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 0, // Circles don't use corner radius
			Hover = .() { BorderColor = checkHoverBorder },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// ToggleSwitch style
		mStyles[new String("ToggleSwitch")] = .()
		{
			Background = toggleBase,  // Track off color
			Foreground = mPalette.Text,
			BorderColor = toggleBorder,
			BorderThickness = 1,
			CornerRadius = 12,
			Hover = .() { BorderColor = toggleHoverBorder },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// Hyperlink style
		mStyles[new String("Hyperlink")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Accent,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(2, 2, 2, 2),  // Minimal padding for hyperlinks
			Hover = .() { Foreground = hyperlinkHover }  // Lighter accent
		};

		// Slider style
		mStyles[new String("Slider")] = .()
		{
			Background = Color32(50, 50, 50, 255),  // Track color
			Foreground = mPalette.Accent,         // Thumb color
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// ScrollBar style
		mStyles[new String("ScrollBar")] = .()
		{
			Background = mPalette.Surface,  // Track color
			Foreground = scrollThumb,  // Thumb color
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Hover = .() { Foreground = scrollThumbHover }
		};

		// ScrollViewer style
		mStyles[new String("ScrollViewer")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0
		};

		// Splitter style
		mStyles[new String("Splitter")] = .()
		{
			Background = splitterBase,
			Foreground = splitterGrip,  // Grip color
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Hover = .() { Background = splitterHover }
		};

		// ItemsControl style
		mStyles[new String("ItemsControl")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0
		};

		// ListBox style
		mStyles[new String("ListBox")] = .()
		{
			Background = Color32(25, 25, 25, 255),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 4,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// ListBoxItem style
		mStyles[new String("ListBoxItem")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(8, 4, 8, 4),
			Hover = .() { Background = itemHover }
		};

		// ComboBox style
		mStyles[new String("ComboBox")] = .()
		{
			Background = inputBase,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 4,
			Padding = .(8, 4, 8, 4),
			Hover = .() { BorderColor = hoverBorder },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// TabControl style
		mStyles[new String("TabControl")] = .()
		{
			Background = Color32(45, 45, 45, 255),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// TabItem style
		mStyles[new String("TabItem")] = .()
		{
			Background = tabItemBase,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(12, 6, 12, 6),
			Hover = .() { Background = tabItemHover }
		};

		// Expander style
		mStyles[new String("Expander")] = .()
		{
			Background = expanderBase,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 4,
			Hover = .() { Background = expanderHover },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// GroupBox style
		mStyles[new String("GroupBox")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0,
			Padding = .(8, 8, 8, 8)
		};

		// Breadcrumb style
		mStyles[new String("Breadcrumb")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.TextSecondary,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// BreadcrumbItem style
		mStyles[new String("BreadcrumbItem")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Accent,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 2,
			Padding = .(4, 2, 4, 2),
			Hover = .() { Background = itemHover }
		};

		// TreeView style
		mStyles[new String("TreeView")] = .()
		{
			Background = Color32(25, 25, 25, 255),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 4,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// TreeViewItem style
		mStyles[new String("TreeViewItem")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(4, 2, 4, 2),
			Hover = .() { Background = itemHover }
		};

		// TileView style
		mStyles[new String("TileView")] = .()
		{
			Background = Color32(25, 25, 25, 255),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 4,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// TileViewItem style
		mStyles[new String("TileViewItem")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 4,
			Padding = .(4, 4, 4, 4),
			Hover = .() { Background = itemHover }
		};

		// DockablePanel style
		mStyles[new String("DockablePanel")] = .()
		{
			Background = Color32(40, 40, 40, 255),  // Content background
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// DockablePanelHeader style (title bar)
		mStyles[new String("DockablePanelHeader")] = .()
		{
			Background = Color32(50, 50, 50, 255),  // Title bar background
			Foreground = Color32(220, 220, 220, 255),  // Title text
			BorderColor = Color32(80, 80, 80, 255),  // Bottom border
			BorderThickness = 1,
			CornerRadius = 0
		};

		// DockTabGroup style
		mStyles[new String("DockTabGroup")] = .()
		{
			Background = Color32(35, 35, 35, 255),  // Tab strip background
			Foreground = mPalette.TextSecondary,  // Empty text
			BorderColor = Color32(80, 80, 80, 255),  // Tab strip bottom border
			BorderThickness = 1,
			CornerRadius = 0
		};

		// DockTab style
		mStyles[new String("DockTab")] = .()
		{
			Background = Color32(38, 38, 38, 255),  // Normal tab
			Foreground = Color32(180, 180, 180, 255),  // Normal text
			BorderColor = mPalette.Accent,  // Selected tab top border
			BorderThickness = 2,
			CornerRadius = 0,
			Hover = .() { Background = Color32(45, 45, 45, 255) },
			Pressed = .() { Background = Color32(50, 50, 50, 255), Foreground = Color32(255, 255, 255, 255) }  // Selected state
		};

		// DataGrid style
		mStyles[new String("DataGrid")] = .()
		{
			Background = Color32(22, 22, 22, 255),  // Slightly lighter than Background for contrast
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0
		};

		// DataGridHeader style
		mStyles[new String("DataGridHeader")] = .()
		{
			Background = Color32(35, 35, 35, 255),  // Header background
			Foreground = mPalette.Text,
			BorderColor = Color32(50, 50, 50, 255),
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color32(45, 45, 45, 255) }
		};

		// DataGridCell style (for rows)
		mStyles[new String("DataGridCell")] = .()
		{
			Background = Color32(22, 22, 22, 255),  // Row background
			Foreground = mPalette.Text,
			BorderColor = Color32(35, 35, 35, 255),  // Cell border
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color32(35, 35, 35, 255) },
			Pressed = .() { Background = Color32(50, 80, 120, 255) }  // Selection color
		};

		// PropertyGrid style
		mStyles[new String("PropertyGrid")] = .()
		{
			Background = Color32(22, 22, 22, 255),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0
		};

		// PropertyGridCategory style
		mStyles[new String("PropertyGridCategory")] = .()
		{
			Background = Color32(35, 35, 35, 255),  // Category header background
			Foreground = mPalette.Text,
			BorderColor = Color32(45, 45, 45, 255),
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color32(45, 45, 45, 255) }
		};

		// PropertyGridProperty style
		mStyles[new String("PropertyGridProperty")] = .()
		{
			Background = Color32(25, 25, 25, 255),  // Property row background
			Foreground = mPalette.Text,
			BorderColor = Color32(32, 32, 32, 255),
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color32(35, 35, 35, 255) }
		};
	}

	public StringView Name => "Dark";

	public Palette Palette => mPalette;

	public ControlStyle GetControlStyle(StringView controlType)
	{
		for (let kv in mStyles)
		{
			if (StringView(kv.key) == controlType)
				return kv.value;
		}
		// Return default Control style
		for (let kv in mStyles)
		{
			if (StringView(kv.key) == "Control")
				return kv.value;
		}
		// Fallback
		return .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 4
		};
	}

	public Color32 FocusIndicatorColor => mPalette.Accent;
	public float FocusIndicatorThickness => 2;
	public Color32 SelectionColor => Color32(100, 149, 237, 100);
	public float DefaultFontSize => 14;

	// Control dimensions
	public float MenuItemHeight => 24;
	public float MenuCheckWidth => 20;
	public float MenuArrowWidth => 16;
	public float MenuShortcutGap => 24;
	public float TabStripHeight => 30;
	public float ScrollBarThickness => 16;
	public float SliderTrackThickness => 4;
	public float SliderThumbSize => 16;
	public float CheckBoxSize => 18;
	public float CheckBoxSpacing => 8;
	public float RadioButtonSize => 18;
	public float RadioButtonSpacing => 8;
	public float ToggleSwitchTrackWidth => 44;
	public float ToggleSwitchTrackHeight => 24;
	public float ToggleSwitchKnobSize => 20;
	public float SeparatorThickness => 1;
	public float DefaultCornerRadius => 4;
	public float ComboBoxDropDownButtonWidth => 20;
	public float ComboBoxDropDownMaxHeight => 200;
	public float MessageBoxIconSize => 24;

	// Docking system dimensions
	public float DockPanelTitleBarHeight => 24;
	public float DockTabHeight => 24;
	public float DockFontSize => 12;
	public float DockTabPadding => 8;
}
