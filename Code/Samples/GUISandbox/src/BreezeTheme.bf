namespace GUISandbox;

using System;
using System.IO;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.GUI;
using Sedulous.Drawing;
using Sedulous.Imaging;

/// Image-based Breeze theme using eepp's UI theme PNGs.
/// Loads 9-patch images and maps them to ControlStyle BackgroundImages.
class BreezeTheme : ITheme
{
	private Palette mPalette;
	private Dictionary<String, ControlStyle> mStyles = new .() ~ DeleteDictionaryAndKeys!(_);
	private List<OwnedImageData> mImages = new .() ~ DeleteContainerAndItems!(_);

	// Stored brushes for per-instance property access
	private ImageBrush? mCheckboxChecked;
	private ImageBrush? mCheckboxUnchecked;
	private ImageBrush? mRadioSelected;
	private ImageBrush? mRadioUnselected;
	private ImageBrush? mListBoxItemSelected;
	private ImageBrush? mListBoxItemHover;
	private ImageBrush? mProgressFill;
	private ImageBrush? mHScrollThumb;
	private ImageBrush? mHScrollThumbHover;
	private ImageBrush? mVScrollThumb;
	private ImageBrush? mVScrollThumbHover;
	private ImageBrush? mHSliderThumb;
	private ImageBrush? mHSliderThumbHover;
	private ImageBrush? mVSliderThumb;
	private ImageBrush? mVSliderThumbHover;
	private ImageBrush? mComboArrow;
	private ImageBrush? mComboArrowHover;
	private ImageBrush? mMenuItemSelected;
	private ImageBrush? mMenuBarButtonSelected;
	private ImageBrush? mTableRowSelected;
	private ImageBrush? mTableRowHover;

	public this(StringView assetDirectory)
	{
		// Build base path to 1x images
		let basePath = scope String();
		Path.InternalCombine(basePath, assetDirectory, "GUI/Breeze/1x");

		// Initialize Breeze dark palette (from breeze.css)
		mPalette = .()
		{
			Primary = Color(61, 174, 233),       // #3daee9
			Secondary = Color(39, 174, 96),      // #27ae60
			Accent = Color(61, 174, 233),        // #3daee9
			Background = Color(49, 54, 59),      // #31363b
			Surface = Color(35, 38, 41),         // #232629
			Error = Color(218, 68, 83),          // #da4453
			Warning = Color(246, 116, 0),        // #f67400
			Success = Color(39, 174, 96),        // #27ae60
			Text = Color(239, 240, 241),         // #eff0f1
			TextSecondary = Color(189, 195, 199),// #bdc3c7
			Border = Color(118, 121, 124),       // #76797c
			Link = Color(61, 174, 233),          // #3daee9
			LinkVisited = Color(149, 117, 205)   // #9575cd
		};

		// Load images and build styles
		LoadImagesAndBuildStyles(basePath);
	}

	// === Image Loading ===

	/// Loads a PNG from the theme directory and returns an ImageBrush.
	/// Parses 9-slice from the eepp filename convention: name.L_T_R_B.9.png
	private ImageBrush? LoadThemeImage(StringView basePath, StringView filename)
	{
		let path = scope String();
		Path.InternalCombine(path, basePath, filename);

		let result = ImageLoaderFactory.LoadImage(path);
		if (result case .Err)
			return null;

		let image = result.Value;
		defer delete image;

		let imageData = new OwnedImageData(image.Width, image.Height, .RGBA8, image.Data);
		mImages.Add(imageData);

		let slices = ParseNineSlice(filename);
		return ImageBrush(imageData, slices, Color.White);
	}

	/// Parse 9-slice values from eepp filename: "name.L_T_R_B.9.png"
	private static NineSlice ParseNineSlice(StringView filename)
	{
		// Look for pattern: .digits_digits_digits_digits.9.png
		let nineIdx = filename.IndexOf(".9.png");
		if (nineIdx < 0)
			return NineSlice(0, 0, 0, 0);

		// Walk back from .9.png to find the slice spec
		let beforeNine = filename[0..<nineIdx];
		let dotIdx = beforeNine.LastIndexOf('.');
		if (dotIdx < 0)
			return NineSlice(0, 0, 0, 0);

		let sliceSpec = beforeNine[(dotIdx + 1)...];

		// Parse "L_T_R_B"
		float[4] values = .(0, 0, 0, 0);
		int vi = 0;
		for (let part in sliceSpec.Split('_'))
		{
			if (vi >= 4) break;
			if (float.Parse(part) case .Ok(let v))
				values[vi] = v;
			vi++;
		}

		if (vi == 4)
			return NineSlice(values[0], values[1], values[2], values[3]);

		return NineSlice(0, 0, 0, 0);
	}

	private void LoadImagesAndBuildStyles(StringView basePath)
	{
		// === Load images ===

		// Buttons
		let buttonNormal = LoadThemeImage(basePath, "uitheme_button_normal.4_3_4_3.9.png");
		let buttonHover = LoadThemeImage(basePath, "uitheme_button_hover.4_3_4_3.9.png");
		let buttonPressed = LoadThemeImage(basePath, "uitheme_button_pressed.4_3_4_3.9.png");
		let buttonSelected = LoadThemeImage(basePath, "uitheme_button_selected.4_3_4_3.9.png");
		LoadThemeImage(basePath, "uitheme_button_selectedhover.4_3_4_3.9.png");
		LoadThemeImage(basePath, "uitheme_button_selectedpressed.4_3_4_3.9.png");

		// Text input
		let textInputNormal = LoadThemeImage(basePath, "uitheme_textinput_normal.3_3_3_3.9.png");

		// ComboBox
		let comboNormal = LoadThemeImage(basePath, "uitheme_combobox_normal.4_10_3_10.9.png");
		mComboArrow = LoadThemeImage(basePath, "uitheme_combobox_button_normal.0_10_0_10.9.png");
		mComboArrowHover = LoadThemeImage(basePath, "uitheme_combobox_button_hover.0_10_0_10.9.png");

		// DropDownList
		let dropdownNormal = LoadThemeImage(basePath, "uitheme_dropdownlist_normal.3_11_25_11.9.png");
		let dropdownHover = LoadThemeImage(basePath, "uitheme_dropdownlist_hover.3_11_25_11.9.png");

		// ListBox
		let listboxNormal = LoadThemeImage(basePath, "uitheme_listbox_normal.1_1_1_1.9.png");
		mListBoxItemSelected = LoadThemeImage(basePath, "uitheme_listboxitem_selected.png");
		mListBoxItemHover = LoadThemeImage(basePath, "uitheme_listboxitem_hover.png");

		// Table
		mTableRowSelected = LoadThemeImage(basePath, "uitheme_tablerow_selected.png");
		mTableRowHover = LoadThemeImage(basePath, "uitheme_tablerow_hover.png");
		let genericGridNormal = LoadThemeImage(basePath, "uitheme_genericgrid_normal.5_1_5_1.9.png");

		// CheckBox / RadioButton
		mCheckboxChecked = LoadThemeImage(basePath, "uitheme_checkbox_active_normal.png");
		mCheckboxUnchecked = LoadThemeImage(basePath, "uitheme_checkbox_inactive_normal.png");
		mRadioSelected = LoadThemeImage(basePath, "uitheme_radiobutton_active_normal.png");
		mRadioUnselected = LoadThemeImage(basePath, "uitheme_radiobutton_inactive_normal.png");

		// Tabs
		let tabNormal = LoadThemeImage(basePath, "uitheme_tab_normal.2_0_3_0.9.png");
		let tabSelected = LoadThemeImage(basePath, "uitheme_tab_selected.2_0_2_0.9.png");
		let tabBarNormal = LoadThemeImage(basePath, "uitheme_tabbar_normal.3_0_3_3.9.png");

		// ProgressBar
		let progressNormal = LoadThemeImage(basePath, "uitheme_progressbar_normal.2_0_2_0.9.png");
		mProgressFill = LoadThemeImage(basePath, "uitheme_progressbar_filler_normal.png");

		// ScrollBar (horizontal)
		LoadThemeImage(basePath, "uitheme_hscrollbar_bg_normal.png");
		mHScrollThumb = LoadThemeImage(basePath, "uitheme_hscrollbar_button_normal.5_0_5_0.9.png");
		mHScrollThumbHover = LoadThemeImage(basePath, "uitheme_hscrollbar_button_hover.5_0_5_0.9.png");

		// ScrollBar (vertical)
		let vScrollBg = LoadThemeImage(basePath, "uitheme_vscrollbar_bg_normal.png");
		mVScrollThumb = LoadThemeImage(basePath, "uitheme_vscrollbar_button_normal.0_5_0_5.9.png");
		mVScrollThumbHover = LoadThemeImage(basePath, "uitheme_vscrollbar_button_hover.0_5_0_5.9.png");

		// Slider (horizontal)
		let hSliderBg = LoadThemeImage(basePath, "uitheme_hslider_bg_normal.7_0_7_0.9.png");
		mHSliderThumb = LoadThemeImage(basePath, "uitheme_hslider_button_normal.png");
		mHSliderThumbHover = LoadThemeImage(basePath, "uitheme_hslider_button_hover.png");

		// Slider (vertical)
		LoadThemeImage(basePath, "uitheme_vslider_bg_normal.0_7_0_7.9.png");
		mVSliderThumb = LoadThemeImage(basePath, "uitheme_vslider_button_normal.png");
		mVSliderThumbHover = LoadThemeImage(basePath, "uitheme_vslider_button_hover.png");

		// Menu
		let menuBarNormal = LoadThemeImage(basePath, "uitheme_menubar_normal.png");
		mMenuBarButtonSelected = LoadThemeImage(basePath, "uitheme_menubarbutton_selected.2_0_2_0.9.png");
		let menuItemNormal = LoadThemeImage(basePath, "uitheme_menuitem_normal.6_0_2_0.9.png");
		mMenuItemSelected = LoadThemeImage(basePath, "uitheme_menuitem_selected.5_0_2_0.9.png");

		// TextEdit
		LoadThemeImage(basePath, "uitheme_textedit_normal.5_1_5_1.9.png");

		// Tooltip
		let tooltipNormal = LoadThemeImage(basePath, "uitheme_tooltip_normal.2_2_2_3.9.png");

		// Separator
		let separatorNormal = LoadThemeImage(basePath, "uitheme_separator_normal.5_0_5_0.9.png");

		// SpinBox (NumericUpDown)
		let spinboxInput = LoadThemeImage(basePath, "uitheme_spinbox_input_normal.3_3_0_3.9.png");

		// Window decorations
		let winBack = LoadThemeImage(basePath, "uitheme_winback_normal.png");
		let winDeco = LoadThemeImage(basePath, "uitheme_windeco_normal.3_0_3_0.9.png");

		// === Build control styles ===

		// Default control style (color only)
		mStyles[new String("Control")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// Button
		mStyles[new String("Button")] = .()
		{
			Background = Color(49, 54, 59),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(10, 4, 10, 4),
			BackgroundImage = buttonNormal,
			Hover = .() { BackgroundImage = buttonHover },
			Pressed = .() { BackgroundImage = buttonPressed },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// RepeatButton (same as Button)
		mStyles[new String("RepeatButton")] = .()
		{
			Background = Color(49, 54, 59),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(10, 4, 10, 4),
			BackgroundImage = buttonNormal,
			Hover = .() { BackgroundImage = buttonHover },
			Pressed = .() { BackgroundImage = buttonPressed }
		};

		// ToggleButton
		mStyles[new String("ToggleButton")] = .()
		{
			Background = Color(49, 54, 59),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(10, 4, 10, 4),
			BackgroundImage = buttonNormal,
			Hover = .() { BackgroundImage = buttonHover },
			Pressed = .() { BackgroundImage = buttonSelected }
		};

		// Layout containers (transparent)
		for (let name in StringView[]("Panel", "StackPanel", "DockPanel", "Canvas", "WrapPanel", "Grid"))
		{
			mStyles[new String(name)] = .()
			{
				Background = Color.Transparent,
				Foreground = mPalette.Text,
				BorderColor = Color.Transparent,
				BorderThickness = 0,
				CornerRadius = 0
			};
		}

		// TextBox
		mStyles[new String("TextBox")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(6, 4, 6, 4),
			BackgroundImage = textInputNormal,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// PasswordBox (same as TextBox)
		mStyles[new String("PasswordBox")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(6, 4, 6, 4),
			BackgroundImage = textInputNormal,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// NumericUpDown
		mStyles[new String("NumericUpDown")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(4, 2, 4, 2),
			BackgroundImage = spinboxInput ?? textInputNormal,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// Label
		mStyles[new String("Label")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// TextBlock
		mStyles[new String("TextBlock")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0
		};

		// Border
		mStyles[new String("Border")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0
		};

		// Separator
		mStyles[new String("Separator")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0,
			BackgroundImage = separatorNormal
		};

		// ProgressBar
		mStyles[new String("ProgressBar")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Accent,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			BackgroundImage = progressNormal
		};

		// CheckBox (color-based, images set per-instance via ApplyToControl)
		mStyles[new String("CheckBox")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 0,
			Hover = .() { BorderColor = Sedulous.GUI.Palette.ComputeHover(mPalette.Border) },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// RadioButton
		mStyles[new String("RadioButton")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 2,
			CornerRadius = 0,
			Hover = .() { BorderColor = Sedulous.GUI.Palette.ComputeHover(mPalette.Border) },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// ToggleSwitch
		mStyles[new String("ToggleSwitch")] = .()
		{
			Background = Color(60, 60, 60),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 12,
			Hover = .() { BorderColor = Sedulous.GUI.Palette.ComputeHover(mPalette.Border) },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// Hyperlink
		mStyles[new String("Hyperlink")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Accent,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(2, 2, 2, 2),
			Hover = .() { Foreground = Sedulous.GUI.Palette.ComputeHover(mPalette.Accent) }
		};

		// Slider
		mStyles[new String("Slider")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Accent,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			BackgroundImage = hSliderBg
		};

		// ScrollBar
		mStyles[new String("ScrollBar")] = .()
		{
			Background = mPalette.Surface,
			Foreground = Color(80, 80, 80),
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			BackgroundImage = vScrollBg
		};

		// ScrollViewer
		mStyles[new String("ScrollViewer")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0
		};

		// Splitter
		mStyles[new String("Splitter")] = .()
		{
			Background = Color(45, 50, 55),
			Foreground = mPalette.Border,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Hover = .() { Background = Sedulous.GUI.Palette.ComputeHover(Color(45, 50, 55)) }
		};

		// ItemsControl
		mStyles[new String("ItemsControl")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0,
			BackgroundImage = listboxNormal
		};

		// ListBox
		mStyles[new String("ListBox")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0,
			BackgroundImage = listboxNormal,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// ListBoxItem
		mStyles[new String("ListBoxItem")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(8, 4, 8, 4),
			Hover = .() { Background = Color(61, 174, 233, 40) }
		};

		// ComboBox
		mStyles[new String("ComboBox")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(8, 4, 8, 4),
			BackgroundImage = comboNormal ?? dropdownNormal,
			Hover = .() { BackgroundImage = dropdownHover },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// TabControl
		mStyles[new String("TabControl")] = .()
		{
			Background = Color(45, 50, 55),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0,
			BackgroundImage = tabBarNormal,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// TabItem
		mStyles[new String("TabItem")] = .()
		{
			Background = Color(60, 65, 70),
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(12, 6, 12, 6),
			BackgroundImage = tabNormal,
			Hover = .() { BackgroundImage = tabNormal },
			Pressed = .() { BackgroundImage = tabSelected }
		};

		// Expander
		mStyles[new String("Expander")] = .()
		{
			Background = Color(40, 44, 48),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Sedulous.GUI.Palette.ComputeHover(Color(40, 44, 48)) },
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// GroupBox
		mStyles[new String("GroupBox")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0,
			Padding = .(8, 8, 8, 8)
		};

		// Breadcrumb
		mStyles[new String("Breadcrumb")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.TextSecondary,
			BorderColor = Color.Transparent,
			BorderThickness = 0
		};

		mStyles[new String("BreadcrumbItem")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Accent,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 2,
			Padding = .(4, 2, 4, 2),
			Hover = .() { Background = Color(61, 174, 233, 40) }
		};

		// TreeView
		mStyles[new String("TreeView")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0,
			BackgroundImage = genericGridNormal ?? listboxNormal,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		// TreeViewItem
		mStyles[new String("TreeViewItem")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(4, 2, 4, 2),
			Hover = .() { Background = Color(61, 174, 233, 40) }
		};

		// TileView
		mStyles[new String("TileView")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0,
			BackgroundImage = genericGridNormal ?? listboxNormal,
			Focused = .() { BorderColor = mPalette.Accent }
		};

		mStyles[new String("TileViewItem")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			Padding = .(4, 4, 4, 4),
			Hover = .() { Background = Color(61, 174, 233, 40) }
		};

		// Menu
		mStyles[new String("Menu")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			BackgroundImage = menuBarNormal
		};

		mStyles[new String("MenuItem")] = .()
		{
			Background = Color.Transparent,
			Foreground = mPalette.Text,
			BorderColor = Color.Transparent,
			BorderThickness = 0,
			CornerRadius = 0,
			BackgroundImage = menuItemNormal,
			Hover = .() { BackgroundImage = mMenuItemSelected }
		};

		// Tooltip
		mStyles[new String("Tooltip")] = .()
		{
			Background = Color(49, 54, 59),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0,
			BackgroundImage = tooltipNormal
		};

		// Docking system
		mStyles[new String("DockablePanel")] = .()
		{
			Background = Color(40, 44, 48),
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0,
			BackgroundImage = winBack
		};

		mStyles[new String("DockablePanelHeader")] = .()
		{
			Background = Color(50, 55, 60),
			Foreground = Color(220, 220, 220),
			BorderColor = Color(80, 85, 90),
			BorderThickness = 1,
			CornerRadius = 0,
			BackgroundImage = winDeco
		};

		mStyles[new String("DockTabGroup")] = .()
		{
			Background = Color(35, 38, 41),
			Foreground = mPalette.TextSecondary,
			BorderColor = Color(80, 85, 90),
			BorderThickness = 1,
			CornerRadius = 0
		};

		mStyles[new String("DockTab")] = .()
		{
			Background = Color(38, 42, 46),
			Foreground = Color(180, 180, 180),
			BorderColor = mPalette.Accent,
			BorderThickness = 2,
			CornerRadius = 0,
			Hover = .() { Background = Color(45, 50, 55) },
			Pressed = .() { Background = Color(50, 55, 60), Foreground = Color(255, 255, 255) }
		};

		// DataGrid
		mStyles[new String("DataGrid")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 0,
			CornerRadius = 0,
			BackgroundImage = genericGridNormal ?? listboxNormal
		};

		mStyles[new String("DataGridHeader")] = .()
		{
			Background = Color(35, 38, 41),
			Foreground = mPalette.Text,
			BorderColor = Color(50, 55, 60),
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color(45, 50, 55) }
		};

		mStyles[new String("DataGridCell")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = Color(35, 38, 41),
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color(35, 40, 45) },
			Pressed = .() { Background = Color(50, 80, 120) }
		};

		// PropertyGrid
		mStyles[new String("PropertyGrid")] = .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0
		};

		mStyles[new String("PropertyGridCategory")] = .()
		{
			Background = Color(35, 38, 41),
			Foreground = mPalette.Text,
			BorderColor = Color(45, 50, 55),
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color(45, 50, 55) }
		};

		mStyles[new String("PropertyGridProperty")] = .()
		{
			Background = Color(25, 28, 31),
			Foreground = mPalette.Text,
			BorderColor = Color(32, 35, 38),
			BorderThickness = 1,
			CornerRadius = 0,
			Hover = .() { Background = Color(35, 40, 45) }
		};
	}

	// === Public Image Accessors (for per-instance properties) ===

	public ImageBrush? CheckboxCheckedImage => mCheckboxChecked;
	public ImageBrush? CheckboxUncheckedImage => mCheckboxUnchecked;
	public ImageBrush? RadioSelectedImage => mRadioSelected;
	public ImageBrush? RadioUnselectedImage => mRadioUnselected;
	public ImageBrush? ListBoxItemSelectionImage => mListBoxItemSelected;
	public ImageBrush? ListBoxItemHoverImage => mListBoxItemHover;
	public ImageBrush? ProgressBarFillImage => mProgressFill;
	public ImageBrush? HScrollBarThumbImage => mHScrollThumb;
	public ImageBrush? VScrollBarThumbImage => mVScrollThumb;
	public ImageBrush? HSliderThumbImage => mHSliderThumb;
	public ImageBrush? VSliderThumbImage => mVSliderThumb;
	public ImageBrush? ComboBoxArrowImage => mComboArrow;
	public ImageBrush? MenuItemHighlightImage => mMenuItemSelected;
	public ImageBrush? TableRowSelectionImage => mTableRowSelected;
	public ImageBrush? TableRowHoverImage => mTableRowHover;

	/// Applies per-instance image properties to a control based on its type.
	/// Call this after creating controls to set CheckedImage, ThumbImage, etc.
	public void ApplyToControl(Control control)
	{
		if (let cb = control as CheckBox)
		{
			if (mCheckboxChecked.HasValue)
				cb.CheckedImage = mCheckboxChecked;
			if (mCheckboxUnchecked.HasValue)
				cb.UncheckedImage = mCheckboxUnchecked;
		}
		else if (let rb = control as RadioButton)
		{
			if (mRadioSelected.HasValue)
				rb.SelectedImage = mRadioSelected;
			if (mRadioUnselected.HasValue)
				rb.UnselectedImage = mRadioUnselected;
		}
		else if (let pb = control as ProgressBar)
		{
			if (mProgressFill.HasValue)
				pb.FillImage = mProgressFill;
		}
		else if (let sb = control as ScrollBar)
		{
			if (mVScrollThumb.HasValue)
				sb.ThumbImage = mVScrollThumb;
		}
		else if (let slider = control as Slider)
		{
			if (mHSliderThumb.HasValue)
				slider.ThumbImage = mHSliderThumb;
		}
		else if (let combo = control as ComboBox)
		{
			if (mComboArrow.HasValue)
				combo.ArrowImage = mComboArrow;
		}
		else if (let lbi = control as ListBoxItem)
		{
			if (mListBoxItemSelected.HasValue)
				lbi.SelectionImage = mListBoxItemSelected;
			if (mListBoxItemHover.HasValue)
				lbi.HoverImage = mListBoxItemHover;
		}
	}

	// === ITheme Implementation ===

	public StringView Name => "Breeze";
	public Palette Palette => mPalette;

	public ControlStyle GetControlStyle(StringView controlType)
	{
		for (let kv in mStyles)
		{
			if (StringView(kv.key) == controlType)
				return kv.value;
		}
		for (let kv in mStyles)
		{
			if (StringView(kv.key) == "Control")
				return kv.value;
		}
		return .()
		{
			Background = mPalette.Surface,
			Foreground = mPalette.Text,
			BorderColor = mPalette.Border,
			BorderThickness = 1,
			CornerRadius = 0
		};
	}

	public Color FocusIndicatorColor => mPalette.Accent;
	public float FocusIndicatorThickness => 2;
	public Color SelectionColor => Color(61, 174, 233, 100);
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
	public float DefaultCornerRadius => 0;
	public float ComboBoxDropDownButtonWidth => 20;
	public float ComboBoxDropDownMaxHeight => 200;
	public float MessageBoxIconSize => 24;

	// Docking system dimensions
	public float DockPanelTitleBarHeight => 24;
	public float DockTabHeight => 24;
	public float DockFontSize => 12;
	public float DockTabPadding => 8;
}
