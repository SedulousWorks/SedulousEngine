using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.LegacyGUI;

/// Game-oriented theme with vibrant colors and larger controls.
/// Features gold accents, high contrast, and a fantasy/adventure aesthetic.
public class GameTheme : ITheme
{
	private Palette mPalette;
	private Dictionary<String, ControlStyle> mStyles = new .() ~ DeleteDictionaryAndKeys!(_);

	public this()
	{
		// Initialize palette with game-oriented colors
		mPalette = .()
		{
			Primary = Color32(180, 140, 60, 255),      // Gold
			Secondary = Color32(60, 140, 180, 255),   // Steel blue
			Accent = Color32(255, 200, 80, 255),      // Bright gold/yellow
			Background = Color32(20, 22, 28, 255),    // Deep blue-black
			Surface = Color32(35, 40, 50, 255),       // Dark slate blue
			Error = Color32(220, 60, 60, 255),        // Vibrant red (damage)
			Warning = Color32(255, 180, 40, 255),     // Orange-gold
			Success = Color32(60, 200, 80, 255),      // Vibrant green (health)
			Text = Color32(240, 235, 220, 255),       // Warm white/parchment
			TextSecondary = Color32(160, 155, 145, 255), // Muted tan
			Border = Color32(80, 85, 95, 255),        // Steel gray
			Link = Color32(120, 180, 255, 255),       // Sky blue
			LinkVisited = Color32(180, 140, 200, 255) // Mystic purple
		};

		// Define control styles
		InitializeStyles();
	}

	private void InitializeStyles()
	{
		// Precompute derived colors
		let buttonBase = Color32(50, 55, 65, 255);
		let buttonHover = Sedulous.LegacyGUI.Palette.ComputeHover(buttonBase);
		let buttonPressed = Sedulous.LegacyGUI.Palette.ComputePressed(buttonBase);
		let inputBase = Color32(25, 28, 35, 255);
		let hoverBorder = mPalette.Accent;  // Gold border on hover
		let separatorBorder = Sedulous.LegacyGUI.Palette.Darken(mPalette.Border, 0.1f);
		let checkHoverBorder = mPalette.Accent;
		let toggleBase = Color32(55, 60, 70, 255);
		let toggleBorder = Sedulous.LegacyGUI.Palette.ComputeHover(toggleBase);
		let toggleHoverBorder = mPalette.Accent;
		let hyperlinkHover = Sedulous.LegacyGUI.Palette.ComputeHover(mPalette.Link);
		let scrollThumb = Color32(70, 75, 85, 255);
		let scrollThumbHover = Sedulous.LegacyGUI.Palette.ComputeHover(scrollThumb);
		let splitterBase = Color32(40, 45, 55, 255);
		let splitterHover = Sedulous.LegacyGUI.Palette.ComputeHover(splitterBase);
		let splitterGrip = mPalette.Border;
		let itemHover = Color32(50, 55, 70, 255);
		let tabItemBase = Color32(45, 50, 60, 255);
		let tabItemHover = Sedulous.LegacyGUI.Palette.ComputeHover(tabItemBase);
		let expanderBase = Color32(38, 42, 52, 255);
		let expanderHover = Sedulous.LegacyGUI.Palette.ComputeHover(expanderBase);

		// Default control style
		mStyles[new String("Control")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 6,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// Button style - prominent with gold accents
		mStyles[new String("Button")] = .()
		{
			Background = buttonBase,
			Foreground = mPalette.Text,
			BorderColor = Color32(90, 95, 105, 255),
			BorderThickness = 2,
			CornerRadius = 8,
			Padding = .(14, 6, 14, 6),
			Hover = .() { Background = buttonHover, BorderColor = mPalette.Accent },
			Pressed = .() { Background = buttonPressed, BorderColor = mPalette.Primary },
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
			BorderThickness = 2,
			CornerRadius = 6,
			Padding = .(8, 5, 8, 5),
			Hover = .() { BorderColor = hoverBorder },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// PasswordBox style
		mStyles[new String("PasswordBox")] = .()
		{
			Background = inputBase,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 6,
			Padding = .(8, 5, 8, 5),
			Hover = .() { BorderColor = hoverBorder },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// NumericUpDown style
		mStyles[new String("NumericUpDown")] = .()
		{
			Background = inputBase,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 6,
			Padding = .(6, 3, 6, 3),
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
			BorderThickness = 2,
			CornerRadius = 6
		};

		// Separator style
		mStyles[new String("Separator")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = separatorBorder,
			BorderThickness = 1,
			CornerRadius = 0
		};

		// ProgressBar style - health bar aesthetic
		mStyles[new String("ProgressBar")] = .()
		{
			Background = Color32(30, 35, 45, 255),  // Dark track
			Foreground = mPalette.Success,        // Green fill (health bar)
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 6
		};

		// RepeatButton style
		mStyles[new String("RepeatButton")] = .()
		{
			Background = buttonBase,
			Foreground = mPalette.Text,
			BorderColor = Color32(90, 95, 105, 255),
			BorderThickness = 2,
			CornerRadius = 8,
			Padding = .(14, 6, 14, 6),
			Hover = .() { Background = buttonHover, BorderColor = mPalette.Accent },
			Pressed = .() { Background = buttonPressed, BorderColor = mPalette.Primary },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// ToggleButton style
		mStyles[new String("ToggleButton")] = .()
		{
			Background = buttonBase,
			Foreground = mPalette.Text,
			BorderColor = Color32(90, 95, 105, 255),
			BorderThickness = 2,
			CornerRadius = 8,
			Padding = .(14, 6, 14, 6),
			Hover = .() { Background = buttonHover, BorderColor = mPalette.Accent },
			Pressed = .() { Background = buttonPressed, BorderColor = mPalette.Primary },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// CheckBox style
		mStyles[new String("CheckBox")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 4,
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
			CornerRadius = 0,
			Hover = .() { BorderColor = checkHoverBorder },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// ToggleSwitch style
		mStyles[new String("ToggleSwitch")] = .()
		{
			Background = toggleBase,
			Foreground = mPalette.Text,
			BorderColor = toggleBorder,
			BorderThickness = 2,
			CornerRadius = 14,
			Hover = .() { BorderColor = toggleHoverBorder },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// Hyperlink style
		mStyles[new String("Hyperlink")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Link,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(2, 2, 2, 2),
			Hover = .() { Foreground = hyperlinkHover }
		};

		// Slider style
		mStyles[new String("Slider")] = .()
		{
			Background = Color32(40, 45, 55, 255),  // Track
			Foreground = mPalette.Accent,         // Thumb (gold)
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// ScrollBar style
		mStyles[new String("ScrollBar")] = .()
		{
			Background = Color32(30, 35, 45, 255),
			Foreground = scrollThumb,
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
			BorderThickness = 2,
			CornerRadius = 6
		};

		// Splitter style
		mStyles[new String("Splitter")] = .()
		{
			Background = splitterBase,
			Foreground = splitterGrip,
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
			BorderThickness = 2,
			CornerRadius = 6
		};

		// ListBox style
		mStyles[new String("ListBox")] = .()
		{
			Background = Color32(25, 28, 35, 255),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 6,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// ListBoxItem style
		mStyles[new String("ListBoxItem")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 4,
			Padding = .(10, 5, 10, 5),
			Hover = .() { Background = itemHover }
		};

		// ComboBox style
		mStyles[new String("ComboBox")] = .()
		{
			Background = inputBase,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 6,
			Padding = .(10, 5, 10, 5),
			Hover = .() { BorderColor = hoverBorder },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// TabControl style
		mStyles[new String("TabControl")] = .()
		{
			Background = Color32(40, 45, 55, 255),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 6,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// TabItem style
		mStyles[new String("TabItem")] = .()
		{
			Background = tabItemBase,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 6,
			Padding = .(14, 8, 14, 8),
			Hover = .() { Background = tabItemHover }
		};

		// Expander style
		mStyles[new String("Expander")] = .()
		{
			Background = expanderBase,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 6,
			Hover = .() { Background = expanderHover },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// GroupBox style
		mStyles[new String("GroupBox")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 6,
			Padding = .(10, 10, 10, 10)
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
			Foreground = mPalette.Link,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 4,
			Padding = .(6, 3, 6, 3),
			Hover = .() { Background = itemHover, Foreground = mPalette.Accent }
		};

		// TreeView style
		mStyles[new String("TreeView")] = .()
		{
			Background = Color32(25, 28, 35, 255),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 6,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// TreeViewItem style
		mStyles[new String("TreeViewItem")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 4,
			Padding = .(6, 3, 6, 3),
			Hover = .() { Background = itemHover }
		};

		// TileView style
		mStyles[new String("TileView")] = .()
		{
			Background = Color32(25, 28, 35, 255),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 6,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// TileViewItem style
		mStyles[new String("TileViewItem")] = .()
		{
			Background = Color32.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color32.Transparent,
			BorderThickness = 0,
			CornerRadius = 6,
			Padding = .(6, 6, 6, 6),
			Hover = .() { Background = itemHover, BorderColor = mPalette.Accent }
		};

		// DockablePanel style
		mStyles[new String("DockablePanel")] = .()
		{
			Background = Color32(38, 42, 52, 255),  // Content background
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// DockablePanelHeader style (title bar)
		mStyles[new String("DockablePanelHeader")] = .()
		{
			Background = Color32(45, 50, 60, 255),  // Title bar background
			Foreground = mPalette.Text,  // Warm white/parchment
			BorderColor = mPalette.Border,  // Steel gray
			BorderThickness = 1,
			CornerRadius = 0
		};

		// DockTabGroup style
		mStyles[new String("DockTabGroup")] = .()
		{
			Background = Color32(30, 34, 42, 255),  // Tab strip background
			Foreground = mPalette.TextSecondary,  // Empty text
			BorderColor = mPalette.Border,  // Tab strip bottom border
			BorderThickness = 1,
			CornerRadius = 0
		};

		// DockTab style
		mStyles[new String("DockTab")] = .()
		{
			Background = Color32(35, 40, 48, 255),  // Normal tab
			Foreground = mPalette.TextSecondary,  // Normal text
			BorderColor = mPalette.Accent,  // Gold selected tab top border
			BorderThickness = 2,
			CornerRadius = 0,
			Hover = .() { Background = Color32(42, 47, 55, 255) },
			Pressed = .() { Background = Color32(50, 55, 65, 255), Foreground = mPalette.Text }  // Selected state
		};

		// DataGrid style
		mStyles[new String("DataGrid")] = .()
		{
			Background = Color32(25, 28, 35, 255),  // Dark slate background
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 6
		};

		// DataGridHeader style
		mStyles[new String("DataGridHeader")] = .()
		{
			Background = Color32(38, 42, 52, 255),  // Slate header background
			Foreground = mPalette.Text,
			BorderColor = Color32(55, 60, 70, 255),
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color32(48, 53, 65, 255) }
		};

		// DataGridCell style (for rows)
		mStyles[new String("DataGridCell")] = .()
		{
			Background = Color32(25, 28, 35, 255),  // Row background
			Foreground = mPalette.Text,
			BorderColor = Color32(40, 44, 54, 255),  // Cell border
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color32(38, 42, 52, 255) },
			Pressed = .() { Background = Color32(80, 65, 40, 255) }  // Gold-tinted selection
		};

		// PropertyGrid style
		mStyles[new String("PropertyGrid")] = .()
		{
			Background = Color32(25, 28, 35, 255),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 6
		};

		// PropertyGridCategory style
		mStyles[new String("PropertyGridCategory")] = .()
		{
			Background = Color32(38, 42, 52, 255),  // Category header background
			Foreground = mPalette.Text,
			BorderColor = Color32(50, 55, 65, 255),
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color32(48, 53, 65, 255) }
		};

		// PropertyGridProperty style
		mStyles[new String("PropertyGridProperty")] = .()
		{
			Background = Color32(28, 32, 40, 255),  // Property row background
			Foreground = mPalette.Text,
			BorderColor = Color32(35, 40, 48, 255),
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color32(38, 42, 52, 255) }
		};
	}

	public StringView Name => "Game";

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
			BorderThickness = 2,
			CornerRadius = 6
		};
	}

	public Color32 FocusIndicatorColor => mPalette.Accent;
	public float FocusIndicatorThickness => 3;
	public Color32 SelectionColor => Color32(255, 200, 80, 120);  // Gold selection
	public float DefaultFontSize => 16;  // Slightly larger for games

	// Control dimensions - slightly larger for game UI
	public float MenuItemHeight => 28;
	public float MenuCheckWidth => 24;
	public float MenuArrowWidth => 18;
	public float MenuShortcutGap => 28;
	public float TabStripHeight => 36;
	public float ScrollBarThickness => 18;
	public float SliderTrackThickness => 6;
	public float SliderThumbSize => 20;
	public float CheckBoxSize => 22;
	public float CheckBoxSpacing => 10;
	public float RadioButtonSize => 22;
	public float RadioButtonSpacing => 10;
	public float ToggleSwitchTrackWidth => 52;
	public float ToggleSwitchTrackHeight => 28;
	public float ToggleSwitchKnobSize => 24;
	public float SeparatorThickness => 2;
	public float DefaultCornerRadius => 6;
	public float ComboBoxDropDownButtonWidth => 24;
	public float ComboBoxDropDownMaxHeight => 240;
	public float MessageBoxIconSize => 32;

	// Docking system dimensions (slightly larger for game UI)
	public float DockPanelTitleBarHeight => 28;
	public float DockTabHeight => 28;
	public float DockFontSize => 13;
	public float DockTabPadding => 10;
}
