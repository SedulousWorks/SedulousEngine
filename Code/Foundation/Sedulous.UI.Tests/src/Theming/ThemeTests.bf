namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class ThemeTests
{
	[Test]
	public static void Palette_ComputeHover_Lightens()
	{
		let baseColor = Color(100, 100, 100, 255);
		let hover = Palette.ComputeHover(baseColor);
		// Should be lighter.
		Test.Assert(hover.R > baseColor.R);
		Test.Assert(hover.G > baseColor.G);
		Test.Assert(hover.B > baseColor.B);
	}

	[Test]
	public static void Palette_ComputePressed_Darkens()
	{
		let baseColor = Color(100, 100, 100, 255);
		let pressed = Palette.ComputePressed(baseColor);
		Test.Assert(pressed.R < baseColor.R);
		Test.Assert(pressed.G < baseColor.G);
		Test.Assert(pressed.B < baseColor.B);
	}

	[Test]
	public static void Palette_ComputeDisabled_Desaturates()
	{
		let baseColor = Color(200, 50, 50, 255);
		let disabled = Palette.ComputeDisabled(baseColor);
		// Should be closer to gray (R, G, B more similar).
		let rangeOrig = (int)baseColor.R - (int)baseColor.G;
		let rangeDis = (int)disabled.R - (int)disabled.G;
		Test.Assert(Math.Abs(rangeDis) < Math.Abs(rangeOrig));
	}

	[Test]
	public static void Theme_SetAndGetColor()
	{
		let theme = scope Theme();
		theme.SetColor("Test.Color", .(255, 0, 0, 255));
		let result = theme.GetColor("Test.Color");
		Test.Assert(result.R == 255 && result.G == 0 && result.B == 0);
	}

	[Test]
	public static void Theme_MissingKey_ReturnsDefault()
	{
		let theme = scope Theme();
		let result = theme.GetColor("NonExistent", .(42, 42, 42, 255));
		Test.Assert(result.R == 42);
	}

	[Test]
	public static void Theme_HasKey()
	{
		let theme = scope Theme();
		Test.Assert(!theme.HasKey("Test.X"));
		theme.SetColor("Test.X", .Red);
		Test.Assert(theme.HasKey("Test.X"));
	}

	class TestExtension : IThemeExtension
	{
		public void Apply(Theme theme)
		{
			theme.SetColor("Extension.Applied", .(0, 255, 0, 255));
		}
	}

	[Test]
	public static void ThemeExtension_AppliedAfterInit()
	{
		let ext = scope TestExtension();
		Theme.RegisterExtension(ext);

		let theme = scope Theme();
		Test.Assert(!theme.HasKey("Extension.Applied"));

		theme.ApplyExtensions();
		Test.Assert(theme.HasKey("Extension.Applied"));
		let color = theme.GetColor("Extension.Applied");
		Test.Assert(color.G == 255);

		// Clean up - extensions are static; must not leak into other tests.
		Theme.UnregisterExtension(ext);
	}

	[Test]
	public static void DarkTheme_HasButtonKeys()
	{
		let theme = DarkTheme.Create();
		defer delete theme;

		Test.Assert(theme.HasKey("Button.Background"));
		Test.Assert(theme.HasKey("Button.Foreground"));
		Test.Assert(theme.HasKey("Label.Foreground"));
		Test.Assert(theme.HasKey("Panel.Background"));
	}

	[Test]
	public static void LightTheme_DifferentFromDark()
	{
		let dark = DarkTheme.Create();
		let light = LightTheme.Create();
		defer { delete dark; delete light; }

		// Background colors should differ significantly.
		let darkBg = dark.Palette.Background;
		let lightBg = light.Palette.Background;
		Test.Assert(lightBg.R > darkBg.R + 100);
	}

	[Test]
	public static void Label_NullableOverride_FallsBackToTheme()
	{
		let ctx = scope UIContext();
		ctx.SetTheme(DarkTheme.Create(), true);
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let label = new Label();
		label.SetText("Test");
		root.AddView(label);
		ctx.UpdateRootView(root);

		// No explicit TextColor set -> should use theme's Label.Foreground.
		let themeColor = ctx.Theme.GetColor("Label.Foreground");
		Test.Assert(label.TextColor.R == themeColor.R);
		Test.Assert(label.TextColor.G == themeColor.G);

		// Set explicit override.
		label.TextColor = .(255, 0, 0, 255);
		Test.Assert(label.TextColor.R == 255 && label.TextColor.G == 0);
	}

	[Test]
	public static void ThemeSwitch_InvalidatesLayout()
	{
		let ctx = scope UIContext();
		ctx.SetTheme(DarkTheme.Create(), true);
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let label = new Label();
		label.SetText("Test");
		root.AddView(label);

		ctx.UpdateRootView(root);

		// Switch theme -> root should need re-layout.
		// SetTheme with ownsTheme=true deletes the old theme.
		ctx.SetTheme(LightTheme.Create(), true);

		Test.Assert(root.IsLayoutDirty);
	}

	[Test]
	public static void Theme_StringAndFontSize()
	{
		let theme = scope Theme();
		theme.SetString("App.Title", "My App");
		theme.SetFontSize("Header.FontSize", 24);

		let title = theme.GetString("App.Title");
		Test.Assert(title != null && title.Equals("My App"));

		let fontSize = theme.GetFontSize("Header.FontSize");
		Test.Assert(fontSize == 24);

		Test.Assert(theme.HasKey("App.Title"));
		Test.Assert(theme.HasKey("Header.FontSize"));
	}

	[Test]
	public static void Button_PaddingChange_InvalidatesLayout()
	{
		let ctx = scope UIContext();
		ctx.SetTheme(DarkTheme.Create(), true);
		let root = scope RootView();
		ctx.AddRootView(root);
		root.ViewportSize = .(400, 300);

		let btn = new Button();
		btn.SetText("X");
		root.AddView(btn);
		ctx.UpdateRootView(root);

		// Change padding -> should invalidate.
		btn.Padding = .(20);
		Test.Assert(btn.IsLayoutDirty);
	}
}
