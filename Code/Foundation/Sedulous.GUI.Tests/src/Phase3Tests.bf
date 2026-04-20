using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI.Tests;

/// Phase 3 tests: Theming system.
class Phase3Tests
{
	/// Simple test control that can be themed.
	class TestControl : Control
	{
		protected override StringView ControlTypeName => "Control";
	}

	/// Test control with custom type name for style lookup.
	class TestButton : Control
	{
		protected override StringView ControlTypeName => "Button";
	}

	// ========== Theme Property Tests ==========

	[Test]
	public static void Theme_DefaultIsDarkTheme()
	{
		let ctx = scope GUIContext();
		Test.Assert(ctx.Theme != null);
		Test.Assert(ctx.Theme.Name == "Dark");
	}

	[Test]
	public static void Theme_CanSetNewTheme()
	{
		let ctx = scope GUIContext();
		Test.Assert(ctx.Theme.Name == "Dark");

		ctx.Theme = new LightTheme();
		Test.Assert(ctx.Theme.Name == "Light");
	}

	[Test]
	public static void Theme_SettingSameThemeNoOp()
	{
		let ctx = scope GUIContext();
		let originalTheme = ctx.Theme;

		// Set same theme - should not change
		ctx.Theme = originalTheme;
		Test.Assert(ctx.Theme == originalTheme);
	}

	// ========== ThemeChanged Event Tests ==========

	[Test]
	public static void ThemeChanged_FiresOnThemeChange()
	{
		let ctx = scope GUIContext();
		bool eventFired = false;
		ITheme receivedTheme = null;

		delegate void(ITheme) handler = new [&] (theme) =>
		{
			eventFired = true;
			receivedTheme = theme;
		};
		ctx.ThemeChanged.Subscribe(handler);

		let newTheme = new LightTheme();
		ctx.Theme = newTheme;

		Test.Assert(eventFired);
		Test.Assert(receivedTheme == newTheme);

		ctx.ThemeChanged.Unsubscribe(handler);
	}

	[Test]
	public static void ThemeChanged_PassesCorrectTheme()
	{
		let ctx = scope GUIContext();
		StringView themeName = default;

		delegate void(ITheme) handler = new [&] (theme) =>
		{
			themeName = theme.Name;
		};
		ctx.ThemeChanged.Subscribe(handler);

		ctx.Theme = new LightTheme();
		Test.Assert(themeName == "Light");

		ctx.Theme = new DarkTheme();
		Test.Assert(themeName == "Dark");

		ctx.ThemeChanged.Unsubscribe(handler);
	}

	// ========== Control Theme Integration Tests ==========

	[Test]
	public static void Control_UsesThemeBackgroundWhenNotSet()
	{
		let ctx = scope GUIContext();
		let control = new TestControl();
		ctx.RootElement = control;

		// Control should use theme's Control style background
		let themeStyle = ctx.Theme.GetControlStyle("Control");
		let controlBg = control.Background;

		Test.Assert(controlBg == themeStyle.Background);

		ctx.RootElement = null;
		delete control;
	}

	[Test]
	public static void Control_ExplicitBackgroundOverridesTheme()
	{
		let ctx = scope GUIContext();
		let control = new TestControl();
		ctx.RootElement = control;

		let customColor = Color(255, 0, 0, 255);
		control.Background = customColor;

		Test.Assert(control.Background == customColor);

		ctx.RootElement = null;
		delete control;
	}

	[Test]
	public static void Control_UsesDifferentStyleByControlType()
	{
		let ctx = scope GUIContext();
		let panel = new Panel();
		ctx.RootElement = panel;

		let control = new TestControl();
		let button = new TestButton();
		panel.AddChild(control);
		panel.AddChild(button);

		// Different control types should get different styles
		let controlStyle = ctx.Theme.GetControlStyle("Control");
		let buttonStyle = ctx.Theme.GetControlStyle("Button");

		Test.Assert(control.Background == controlStyle.Background);
		Test.Assert(button.Background == buttonStyle.Background);

		ctx.RootElement = null;
		delete panel;
	}

	[Test]
	public static void Control_ThemeBorderColor()
	{
		let ctx = scope GUIContext();
		let control = new TestControl();
		ctx.RootElement = control;

		let themeStyle = ctx.Theme.GetControlStyle("Control");
		Test.Assert(control.BorderColor == themeStyle.BorderColor);

		ctx.RootElement = null;
		delete control;
	}

	[Test]
	public static void Control_ThemeBorderThickness()
	{
		let ctx = scope GUIContext();
		let control = new TestControl();
		ctx.RootElement = control;

		let themeStyle = ctx.Theme.GetControlStyle("Control");
		Test.Assert(control.BorderThickness == themeStyle.BorderThickness);

		ctx.RootElement = null;
		delete control;
	}

	// ========== Palette Tests ==========

	[Test]
	public static void Palette_ComputeHover_LightensColor()
	{
		let baseColor = Color(100, 100, 100, 255);
		let hoverColor = Palette.ComputeHover(baseColor);

		// Hover should be lighter
		Test.Assert(hoverColor.R > baseColor.R);
		Test.Assert(hoverColor.G > baseColor.G);
		Test.Assert(hoverColor.B > baseColor.B);
		Test.Assert(hoverColor.A == baseColor.A);
	}

	[Test]
	public static void Palette_ComputePressed_DarkensColor()
	{
		let baseColor = Color(100, 100, 100, 255);
		let pressedColor = Palette.ComputePressed(baseColor);

		// Pressed should be darker
		Test.Assert(pressedColor.R < baseColor.R);
		Test.Assert(pressedColor.G < baseColor.G);
		Test.Assert(pressedColor.B < baseColor.B);
		Test.Assert(pressedColor.A == baseColor.A);
	}

	[Test]
	public static void Palette_ComputeDisabled_ReducesAlpha()
	{
		let baseColor = Color(100, 100, 100, 255);
		let disabledColor = Palette.ComputeDisabled(baseColor);

		// Disabled should have reduced alpha
		Test.Assert(disabledColor.A < baseColor.A);
	}

	[Test]
	public static void Palette_Lighten_IncreasesRGB()
	{
		let color = Color(100, 100, 100, 255);
		let lightened = Palette.Lighten(color, 0.5f);

		Test.Assert(lightened.R > color.R);
		Test.Assert(lightened.G > color.G);
		Test.Assert(lightened.B > color.B);
	}

	[Test]
	public static void Palette_Darken_DecreasesRGB()
	{
		let color = Color(100, 100, 100, 255);
		let darkened = Palette.Darken(color, 0.5f);

		Test.Assert(darkened.R < color.R);
		Test.Assert(darkened.G < color.G);
		Test.Assert(darkened.B < color.B);
	}

	[Test]
	public static void Palette_Lerp_InterpolatesColors()
	{
		let a = Color(0, 0, 0, 255);
		let b = Color(100, 100, 100, 255);
		let mid = Palette.Lerp(a, b, 0.5f);

		Test.Assert(mid.R == 50);
		Test.Assert(mid.G == 50);
		Test.Assert(mid.B == 50);
	}

	// ========== Theme Switching Tests ==========

	[Test]
	public static void Control_UpdatesColorsOnThemeChange()
	{
		let ctx = scope GUIContext();
		let control = new TestControl();
		ctx.RootElement = control;

		// Get dark theme color
		let darkStyle = ctx.Theme.GetControlStyle("Control");
		let darkBg = darkStyle.Background;
		Test.Assert(control.Background == darkBg);

		// Switch to light theme
		ctx.Theme = new LightTheme();
		let lightStyle = ctx.Theme.GetControlStyle("Control");
		let lightBg = lightStyle.Background;

		// Control should now use light theme color
		Test.Assert(control.Background == lightBg);
		Test.Assert(control.Background != darkBg);

		ctx.RootElement = null;
		delete control;
	}

	[Test]
	public static void Control_ExplicitColorSurvivesThemeChange()
	{
		let ctx = scope GUIContext();
		let control = new TestControl();
		ctx.RootElement = control;

		let customColor = Color(255, 128, 64, 255);
		control.Background = customColor;

		// Switch theme
		ctx.Theme = new LightTheme();

		// Explicit color should still be set
		Test.Assert(control.Background == customColor);

		ctx.RootElement = null;
		delete control;
	}

	// ========== Focus Indicator Tests ==========

	[Test]
	public static void Theme_FocusIndicatorColor()
	{
		let ctx = scope GUIContext();
		let focusColor = ctx.Theme.FocusIndicatorColor;

		// Should be the theme's accent color
		Test.Assert(focusColor.A > 0);
	}

	[Test]
	public static void Theme_FocusIndicatorThickness()
	{
		let ctx = scope GUIContext();
		let thickness = ctx.Theme.FocusIndicatorThickness;

		// Should have a positive thickness
		Test.Assert(thickness > 0);
	}

	[Test]
	public static void Control_FocusBorderUsesThemeDefault()
	{
		let ctx = scope GUIContext();
		let control = new TestControl();
		ctx.RootElement = control;

		// Control's focus border should use theme defaults when not explicitly set
		Test.Assert(control.FocusBorderColor == ctx.Theme.FocusIndicatorColor);
		Test.Assert(control.FocusBorderThickness == ctx.Theme.FocusIndicatorThickness);

		ctx.RootElement = null;
		delete control;
	}

	[Test]
	public static void Control_ExplicitFocusBorderOverridesTheme()
	{
		let ctx = scope GUIContext();
		let control = new TestControl();
		ctx.RootElement = control;

		let customFocusColor = Color(255, 255, 0, 255);
		control.FocusBorderColor = customFocusColor;
		control.FocusBorderThickness = 5;

		Test.Assert(control.FocusBorderColor == customFocusColor);
		Test.Assert(control.FocusBorderThickness == 5);

		ctx.RootElement = null;
		delete control;
	}

	// ========== DarkTheme Specific Tests ==========

	[Test]
	public static void DarkTheme_HasExpectedPalette()
	{
		let theme = scope DarkTheme();

		// Dark theme should have dark background
		Test.Assert(theme.Palette.Background.R < 50);
		Test.Assert(theme.Palette.Background.G < 50);
		Test.Assert(theme.Palette.Background.B < 50);

		// And light text
		Test.Assert(theme.Palette.Text.R > 200);
		Test.Assert(theme.Palette.Text.G > 200);
		Test.Assert(theme.Palette.Text.B > 200);
	}

	[Test]
	public static void DarkTheme_HasControlStyles()
	{
		let theme = scope DarkTheme();

		let controlStyle = theme.GetControlStyle("Control");
		let buttonStyle = theme.GetControlStyle("Button");
		let panelStyle = theme.GetControlStyle("Panel");

		// Interactive controls should have opaque backgrounds
		Test.Assert(controlStyle.Background.A > 0);
		Test.Assert(buttonStyle.Background.A > 0);
		// Panel is a layout container - transparent background is correct
		Test.Assert(panelStyle.Background.A == 0);
	}

	// ========== LightTheme Specific Tests ==========

	[Test]
	public static void LightTheme_HasExpectedPalette()
	{
		let theme = scope LightTheme();

		// Light theme should have light background
		Test.Assert(theme.Palette.Background.R > 200);
		Test.Assert(theme.Palette.Background.G > 200);
		Test.Assert(theme.Palette.Background.B > 200);

		// And dark text
		Test.Assert(theme.Palette.Text.R < 100);
		Test.Assert(theme.Palette.Text.G < 100);
		Test.Assert(theme.Palette.Text.B < 100);
	}

	[Test]
	public static void LightTheme_HasControlStyles()
	{
		let theme = scope LightTheme();

		let controlStyle = theme.GetControlStyle("Control");
		let buttonStyle = theme.GetControlStyle("Button");
		let panelStyle = theme.GetControlStyle("Panel");

		// Interactive controls should have opaque backgrounds
		Test.Assert(controlStyle.Background.A > 0);
		Test.Assert(buttonStyle.Background.A > 0);
		// Panel is a layout container - transparent background is correct
		Test.Assert(panelStyle.Background.A == 0);
	}

	// ========== Unknown Control Type Fallback ==========

	[Test]
	public static void Theme_UnknownControlTypeFallsBackToControl()
	{
		let theme = scope DarkTheme();

		let unknownStyle = theme.GetControlStyle("UnknownWidget");
		let controlStyle = theme.GetControlStyle("Control");

		// Unknown type should return default Control style
		Test.Assert(unknownStyle.Background == controlStyle.Background);
	}
}
