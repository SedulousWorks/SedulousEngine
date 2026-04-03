using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// Light theme variant.
public class LightTheme : ITheme
{
	private Palette mPalette;
	private Dictionary<String, ControlStyle> mStyles = new .() ~ DeleteDictionaryAndKeys!(_);

	public this()
	{
		// Initialize palette
		mPalette = .()
		{
			Primary = Color(98, 0, 238, 255),      // Purple
			Secondary = Color(0, 150, 136, 255),   // Teal
			Accent = Color(33, 150, 243, 255),     // Blue
			Background = Color(250, 250, 250, 255), // Near white
			Surface = Color(255, 255, 255, 255),   // White
			Error = Color(211, 47, 47, 255),       // Red
			Warning = Color(255, 152, 0, 255),     // Orange
			Success = Color(76, 175, 80, 255),     // Green
			Text = Color(33, 33, 33, 255),         // Near black
			TextSecondary = Color(117, 117, 117, 255), // Gray
			Border = Color(200, 200, 200, 255),    // Light gray
			Link = Color(0, 102, 204, 255),        // Standard link blue
			LinkVisited = Color(128, 0, 128, 255)  // Purple
		};

		// Define control styles
		InitializeStyles();
	}

	private void InitializeStyles()
	{
		// Precompute derived colors (using fully qualified type to avoid conflict with property)
		let buttonBase = Color(240, 240, 240, 255);
		let buttonHover = Sedulous.GUI.Palette.Darken(buttonBase, 0.04f);
		let buttonPressed = Sedulous.GUI.Palette.Darken(buttonBase, 0.12f);
		let hoverBorder = Sedulous.GUI.Palette.Darken(mPalette.Border, 0.25f);
		let separatorBorder = Sedulous.GUI.Palette.Lighten(mPalette.Border, 0.1f);
		let checkBorder = Sedulous.GUI.Palette.Darken(mPalette.Border, 0.25f);
		let checkHoverBorder = Sedulous.GUI.Palette.Darken(checkBorder, 0.25f);
		let toggleBase = mPalette.Border;
		let toggleBorder = Sedulous.GUI.Palette.Darken(toggleBase, 0.1f);
		let toggleHoverBorder = Sedulous.GUI.Palette.Darken(toggleBase, 0.25f);
		let hyperlinkHover = Sedulous.GUI.Palette.Darken(mPalette.Accent, 0.15f);
		let scrollTrack = Sedulous.GUI.Palette.Lighten(mPalette.Border, 0.18f);
		let scrollThumb = Sedulous.GUI.Palette.Darken(mPalette.Border, 0.1f);
		let scrollThumbHover = Sedulous.GUI.Palette.Darken(scrollThumb, 0.12f);
		let splitterBase = Sedulous.GUI.Palette.Lighten(mPalette.Border, 0.1f);
		let splitterHover = Sedulous.GUI.Palette.Darken(splitterBase, 0.1f);
		let splitterGrip = Sedulous.GUI.Palette.Darken(mPalette.Border, 0.2f);
		let itemHover = Sedulous.GUI.Palette.Darken(mPalette.Surface, 0.1f);
		let tabItemBase = Sedulous.GUI.Palette.Darken(mPalette.Surface, 0.1f);
		let tabItemHover = Sedulous.GUI.Palette.Darken(tabItemBase, 0.04f);
		let expanderHover = Sedulous.GUI.Palette.Darken(mPalette.Background, 0.02f);

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
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 4,
			Padding = .(10, 4, 10, 4),
			Hover = .() { Background = buttonHover },
			Pressed = .() { Background = buttonPressed },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// Panel style
		mStyles[new String("Panel")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// StackPanel style (layout container - transparent)
		mStyles[new String("StackPanel")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// DockPanel style (layout container - transparent)
		mStyles[new String("DockPanel")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// Canvas style (layout container - transparent)
		mStyles[new String("Canvas")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// WrapPanel style (layout container - transparent)
		mStyles[new String("WrapPanel")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// Grid style (layout container - transparent)
		mStyles[new String("Grid")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// TextBox style
		mStyles[new String("TextBox")] = .()
		{
			Background = mPalette.Surface,
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
			Background = mPalette.Surface,
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
			Background = mPalette.Surface,
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
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// TextBlock style
		mStyles[new String("TextBlock")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// Border style
		mStyles[new String("Border")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0
		};

		// Separator style
		mStyles[new String("Separator")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = separatorBorder,  // Subtle line color
			BorderThickness = 1,
			CornerRadius = 0
		};

		// ProgressBar style
		mStyles[new String("ProgressBar")] = .()
		{
			Background = Color(230, 230, 230, 255),  // Track color
			Foreground = mPalette.Accent,            // Fill color
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 4
		};

		// RepeatButton style (same as Button)
		mStyles[new String("RepeatButton")] = .()
		{
			Background = buttonBase,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
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
			BorderColor = mPalette.Border,
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
			BorderColor = checkBorder,
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
			BorderColor = checkBorder,
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
			Background = Color.Transparent,
			Foreground = mPalette.Accent,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(2, 2, 2, 2),
			Hover = .() { Foreground = hyperlinkHover }  // Darker accent
		};

		// Slider style
		mStyles[new String("Slider")] = .()
		{
			Background = Color(200, 200, 200, 255),  // Track color
			Foreground = mPalette.Accent,            // Thumb color
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// ScrollBar style
		mStyles[new String("ScrollBar")] = .()
		{
			Background = scrollTrack,  // Track color
			Foreground = scrollThumb,  // Thumb color
			BorderColor = Color.Transparent,
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
			BorderColor = Color.Transparent,
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
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 4,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// ListBoxItem style
		mStyles[new String("ListBoxItem")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(8, 4, 8, 4),
			Hover = .() { Background = itemHover }
		};

		// ComboBox style
		mStyles[new String("ComboBox")] = .()
		{
			Background = mPalette.Surface,
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
			Background = Color(245, 245, 245, 255),
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
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(12, 6, 12, 6),
			Hover = .() { Background = tabItemHover }
		};

		// Expander style
		mStyles[new String("Expander")] = .()
		{
			Background = mPalette.Background,
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
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0,
			Padding = .(8, 8, 8, 8)
		};

		// Breadcrumb style
		mStyles[new String("Breadcrumb")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.TextSecondary,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// BreadcrumbItem style
		mStyles[new String("BreadcrumbItem")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Accent,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 2,
			Padding = .(4, 2, 4, 2),
			Hover = .() { Background = itemHover }
		};

		// TreeView style
		mStyles[new String("TreeView")] = .()
		{
			Background = Color(255, 255, 255, 255),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 4,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// TreeViewItem style
		mStyles[new String("TreeViewItem")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(4, 2, 4, 2),
			Hover = .() { Background = itemHover }
		};

		// TileView style
		mStyles[new String("TileView")] = .()
		{
			Background = Color(255, 255, 255, 255),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 4,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// TileViewItem style
		mStyles[new String("TileViewItem")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 4,
			Padding = .(4, 4, 4, 4),
			Hover = .() { Background = itemHover }
		};

		// DockablePanel style
		mStyles[new String("DockablePanel")] = .()
		{
			Background = Color(245, 245, 245, 255),  // Content background
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// DockablePanelHeader style (title bar)
		mStyles[new String("DockablePanelHeader")] = .()
		{
			Background = Color(230, 230, 230, 255),  // Title bar background
			Foreground = Color(50, 50, 50, 255),  // Title text
			BorderColor = Color(200, 200, 200, 255),  // Bottom border
			BorderThickness = 1,
			CornerRadius = 0
		};

		// DockTabGroup style
		mStyles[new String("DockTabGroup")] = .()
		{
			Background = Color(240, 240, 240, 255),  // Tab strip background
			Foreground = mPalette.TextSecondary,  // Empty text
			BorderColor = Color(200, 200, 200, 255),  // Tab strip bottom border
			BorderThickness = 1,
			CornerRadius = 0
		};

		// DockTab style
		mStyles[new String("DockTab")] = .()
		{
			Background = Color(235, 235, 235, 255),  // Normal tab
			Foreground = Color(80, 80, 80, 255),  // Normal text
			BorderColor = mPalette.Accent,  // Selected tab top border
			BorderThickness = 2,
			CornerRadius = 0,
			Hover = .() { Background = Color(225, 225, 225, 255) },
			Pressed = .() { Background = Color(255, 255, 255, 255), Foreground = Color(33, 33, 33, 255) }  // Selected state
		};

		// DataGrid style
		mStyles[new String("DataGrid")] = .()
		{
			Background = Color(255, 255, 255, 255),  // White background
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0
		};

		// DataGridHeader style
		mStyles[new String("DataGridHeader")] = .()
		{
			Background = Color(245, 245, 245, 255),  // Light gray header
			Foreground = mPalette.Text,
			BorderColor = Color(220, 220, 220, 255),
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color(235, 235, 235, 255) }
		};

		// DataGridCell style (for rows)
		mStyles[new String("DataGridCell")] = .()
		{
			Background = Color(255, 255, 255, 255),  // White row background
			Foreground = mPalette.Text,
			BorderColor = Color(235, 235, 235, 255),  // Light cell border
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color(245, 245, 245, 255) },
			Pressed = .() { Background = Color(200, 220, 250, 255) }  // Light blue selection
		};

		// PropertyGrid style
		mStyles[new String("PropertyGrid")] = .()
		{
			Background = Color(255, 255, 255, 255),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0
		};

		// PropertyGridCategory style
		mStyles[new String("PropertyGridCategory")] = .()
		{
			Background = Color(240, 240, 240, 255),  // Light gray category header
			Foreground = mPalette.Text,
			BorderColor = Color(220, 220, 220, 255),
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color(230, 230, 230, 255) }
		};

		// PropertyGridProperty style
		mStyles[new String("PropertyGridProperty")] = .()
		{
			Background = Color(252, 252, 252, 255),  // Near-white property row
			Foreground = mPalette.Text,
			BorderColor = Color(240, 240, 240, 255),
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color(245, 245, 245, 255) }
		};
	}

	public StringView Name => "Light";

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

	public Color FocusIndicatorColor => mPalette.Accent;
	public float FocusIndicatorThickness => 2;
	public Color SelectionColor => Color(33, 150, 243, 80);
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
