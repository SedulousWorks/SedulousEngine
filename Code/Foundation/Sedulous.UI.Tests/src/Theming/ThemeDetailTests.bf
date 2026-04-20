namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

/// Detailed theming + palette tests.
class ThemeDetailTests
{
	// === Palette ===

	[Test]
	public static void Palette_DefaultValues()
	{
		var p = default(Palette);
		// default zeroes the struct.
		Test.Assert(p.Background.R == 0 && p.Background.G == 0 && p.Background.B == 0);
	}

	[Test]
	public static void Palette_Lighten()
	{
		let c = Color(100, 100, 100, 255);
		let lighter = Palette.Lighten(c, 0.5f);
		Test.Assert(lighter.R > c.R);
		Test.Assert(lighter.G > c.G);
		Test.Assert(lighter.B > c.B);
		Test.Assert(lighter.A == c.A);
	}

	[Test]
	public static void Palette_Darken()
	{
		let c = Color(200, 200, 200, 255);
		let darker = Palette.Darken(c, 0.5f);
		Test.Assert(darker.R < c.R);
		Test.Assert(darker.G < c.G);
		Test.Assert(darker.B < c.B);
		Test.Assert(darker.A == c.A);
	}

	[Test]
	public static void Palette_ComputeHover()
	{
		let c = Color(100, 100, 100, 255);
		let hover = Palette.ComputeHover(c);
		Test.Assert(hover.R != c.R || hover.G != c.G || hover.B != c.B);
	}

	[Test]
	public static void Palette_ComputePressed()
	{
		let c = Color(100, 100, 100, 255);
		let pressed = Palette.ComputePressed(c);
		Test.Assert(pressed.R != c.R || pressed.G != c.G || pressed.B != c.B);
	}

	[Test]
	public static void Palette_ComputeDisabled()
	{
		let c = Color(100, 100, 100, 255);
		let disabled = Palette.ComputeDisabled(c);
		Test.Assert(disabled.A < c.A || disabled.R != c.R);
	}

	// === Theme color management ===

	[Test]
	public static void Theme_SetAndGetColor()
	{
		let theme = scope Theme();
		theme.SetColor("Test.Color", .(255, 0, 0, 255));
		let c = theme.GetColor("Test.Color");
		Test.Assert(c.R == 255);
		Test.Assert(c.G == 0);
	}

	[Test]
	public static void Theme_TryGetColor_Missing_ReturnsNull()
	{
		let theme = scope Theme();
		let c = theme.TryGetColor("NonExistent");
		Test.Assert(!c.HasValue);
	}

	[Test]
	public static void Theme_GetColor_WithFallback()
	{
		let theme = scope Theme();
		let c = theme.GetColor("Missing", .(42, 42, 42, 255));
		Test.Assert(c.R == 42);
	}

	[Test]
	public static void Theme_SetDimension()
	{
		let theme = scope Theme();
		theme.SetDimension("Test.Size", 12.5f);
		let d = theme.GetDimension("Test.Size");
		Test.Assert(Math.Abs(d - 12.5f) < 0.01f);
	}

	[Test]
	public static void Theme_SetPadding()
	{
		let theme = scope Theme();
		theme.SetPadding("Test.Padding", .(4, 8));
		let p = theme.GetPadding("Test.Padding");
		Test.Assert(p.Left == 4);
		Test.Assert(p.Top == 8);
	}

	[Test]
	public static void Theme_OverwriteColor()
	{
		let theme = scope Theme();
		theme.SetColor("Key", .(1, 2, 3, 255));
		theme.SetColor("Key", .(4, 5, 6, 255));
		let c = theme.GetColor("Key");
		Test.Assert(c.R == 4);
	}

	[Test]
	public static void Theme_Name()
	{
		let theme = scope Theme();
		theme.Name.Set("MyTheme");
		Test.Assert(theme.Name == "MyTheme");
	}

	// === DarkTheme / LightTheme ===

	[Test]
	public static void DarkTheme_HasButtonColors()
	{
		let theme = DarkTheme.Create();
		defer delete theme;
		let bg = theme.TryGetColor("Button.Background");
		let fg = theme.TryGetColor("Button.Foreground");
		Test.Assert(bg.HasValue);
		Test.Assert(fg.HasValue);
	}

	[Test]
	public static void LightTheme_HasButtonColors()
	{
		let theme = LightTheme.Create();
		defer delete theme;
		let bg = theme.TryGetColor("Button.Background");
		let fg = theme.TryGetColor("Button.Foreground");
		Test.Assert(bg.HasValue);
		Test.Assert(fg.HasValue);
	}

	[Test]
	public static void DarkTheme_PaletteSet()
	{
		let theme = DarkTheme.Create();
		defer delete theme;
		Test.Assert(theme.Palette.Background.A == 255);
		Test.Assert(theme.Palette.Surface.A == 255);
		Test.Assert(theme.Palette.Text.A == 255);
	}

	[Test]
	public static void LightTheme_PaletteSet()
	{
		let theme = LightTheme.Create();
		defer delete theme;
		Test.Assert(theme.Palette.Background.A == 255);
		Test.Assert(theme.Palette.Text.A == 255);
	}

	[Test]
	public static void DarkTheme_HasScrollBarColors()
	{
		let theme = DarkTheme.Create();
		defer delete theme;
		let track = theme.TryGetColor("ScrollBar.Track");
		let thumb = theme.TryGetColor("ScrollBar.Thumb");
		Test.Assert(track.HasValue);
		Test.Assert(thumb.HasValue);
	}

	[Test]
	public static void DarkTheme_HasFocusRing()
	{
		let theme = DarkTheme.Create();
		defer delete theme;
		let ring = theme.TryGetColor("Focus.Ring");
		Test.Assert(ring.HasValue);
	}

	// === Theme extension ===

	[Test]
	public static void ThemeExtension_AppliedOnCreate()
	{
		Theme.RegisterExtension(new TestThemeExtension());
		let theme = DarkTheme.Create();
		defer delete theme;
		let custom = theme.TryGetColor("TestExt.Custom");
		Test.Assert(custom.HasValue);
	}

	// === Theme switch invalidates layout ===

	[Test]
	public static void ThemeSwitch_InvalidatesAllRoots()
	{
		let ctx = scope UIContext();
		let root1 = scope RootView();
		let root2 = scope RootView();
		ctx.AddRootView(root1);
		ctx.AddRootView(root2);
		root1.ViewportSize = .(400, 300);
		root2.ViewportSize = .(200, 150);

		ctx.SetTheme(DarkTheme.Create(), true);
		ctx.UpdateRootView(root1);
		ctx.UpdateRootView(root2);

		// Switch theme - both roots should need re-layout.
		ctx.SetTheme(LightTheme.Create(), true);
		Test.Assert(root1.IsLayoutDirty);
		Test.Assert(root2.IsLayoutDirty);

		ctx.RemoveRootView(root2);
		ctx.RemoveRootView(root1);
	}

	// === ControlState ===

	[Test]
	public static void ControlState_DefaultIsNormal()
	{
		let state = ControlState.Normal;
		Test.Assert(state == .Normal);
	}
}

class TestThemeExtension : IThemeExtension
{
	public void Apply(Theme theme)
	{
		theme.SetColor("TestExt.Custom", .(123, 45, 67, 255));
	}
}
