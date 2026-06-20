namespace Sedulous.UI.Tests;

using System;
using Sedulous.UI;
using Sedulous.Core.Mathematics;

class ThemeTests
{
	// === ThemePalette ===

	[Test]
	public static void DarkPalette_HasDarkBackground()
	{
		let p = ThemePalette.Dark;
		Test.Assert(p.Background.R < 50 / 255.0f);
		Test.Assert(p.Background.G < 50 / 255.0f);
		Test.Assert(p.Background.B < 50 / 255.0f);
	}

	[Test]
	public static void LightPalette_HasLightBackground()
	{
		let p = ThemePalette.Light;
		Test.Assert(p.Background.R > 200 / 255.0f);
		Test.Assert(p.Background.G > 200 / 255.0f);
		Test.Assert(p.Background.B > 200 / 255.0f);
	}

	[Test]
	public static void DarkPalette_TextIsLight()
	{
		let p = ThemePalette.Dark;
		Test.Assert(p.Text.R > 200 / 255.0f);
	}

	[Test]
	public static void LightPalette_TextIsDark()
	{
		let p = ThemePalette.Light;
		Test.Assert(p.Text.R < 50 / 255.0f);
	}

	// === DarkTheme ===

	[Test]
	public static void DarkTheme_Creates()
	{
		let sheet = DarkTheme.Create();
		Test.Assert(sheet != null);
		Test.Assert(sheet.RuleCount > 0);
		sheet.ReleaseRef();
	}

	[Test]
	public static void DarkTheme_ResolvesTextColor()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = DarkTheme.Create();
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		// Dark theme text should be light
		Test.Assert(color.R > 200 / 255.0f);
	}

	[Test]
	public static void DarkTheme_ResolvesFontSize()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = DarkTheme.Create();
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();

		let view = new TestView();
		root.AddView(view);

		let size = view.ResolveStyleFloat(.FontSize);
		Test.Assert(size == 16.0f);
	}

	[Test]
	public static void DarkTheme_ButtonStyleClass()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = DarkTheme.Create();
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();

		let view = new Button("Test");
		root.AddView(view);

		// Button should have a background drawable (matched by type)
		let bg = view.ResolveStyleDrawable(.Background);
		Test.Assert(bg != null);

		// Button should have padding
		let pad = view.ResolveStyleThickness(.Padding);
		Test.Assert(pad.Left > 0);

		// Button corner radius (flat themes use 0)
		let radius = view.ResolveStyleFloat(.CornerRadius);
		Test.Assert(radius == 0.0f);
	}

	// === LightTheme ===

	[Test]
	public static void LightTheme_Creates()
	{
		let sheet = LightTheme.Create();
		Test.Assert(sheet != null);
		Test.Assert(sheet.RuleCount > 0);
		sheet.ReleaseRef();
	}

	[Test]
	public static void LightTheme_ResolvesTextColor()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = LightTheme.Create();
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		// Light theme text should be dark
		Test.Assert(color.R < 50 / 255.0f);
	}

	// === Theme switching ===

	[Test]
	public static void ThemeSwitching_ChangesResolvedValues()
	{
		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let view = new TestView();
		root.AddView(view);

		// Dark theme
		let dark = DarkTheme.Create();
		ctx.StyleSheet = dark;
		dark.ReleaseRef();
		let darkText = view.ResolveStyleColor(.TextColor);

		// Light theme
		let light = LightTheme.Create();
		ctx.StyleSheet = light;
		light.ReleaseRef();
		let lightText = view.ResolveStyleColor(.TextColor);

		// Colors should be different
		Test.Assert(darkText.R != lightText.R);
		// Dark text is light, light text is dark
		Test.Assert(darkText.R > 200 / 255.0f);
		Test.Assert(lightText.R < 50 / 255.0f);
	}

	// === Custom palette ===

	[Test]
	public static void DarkTheme_WithCustomPalette()
	{
		var palette = ThemePalette.Dark;
		palette.Text = .(255, 0, 0, 255); // red text

		let ctx = scope UIContext();
		let root = scope RootView();
		TestSetup.Init(ctx, root);

		let sheet = DarkTheme.Create(palette);
		ctx.StyleSheet = sheet;
		sheet.ReleaseRef();

		let view = new TestView();
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert(color.R == 1.0f && color.G == 0 && color.B == 0);
	}

	// === ThemeRegistry ===

	[Test]
	public static void ThemeRegistry_ExtensionApplied()
	{
		bool applied = false;
		let ext = scope TestThemeExtension(&applied);
		ThemeRegistry.RegisterExtension(ext);

		let sheet = DarkTheme.Create();
		Test.Assert(applied);
		sheet.ReleaseRef();

		ThemeRegistry.UnregisterExtension(ext);
	}

	[Test]
	public static void ThemeRegistry_ExtensionAppliedToBothThemes()
	{
		int applyCount = 0;
		let ext = scope CountingThemeExtension(&applyCount);
		ThemeRegistry.RegisterExtension(ext);

		let dark = DarkTheme.Create();
		let light = LightTheme.Create();
		Test.Assert(applyCount == 2);

		dark.ReleaseRef();
		light.ReleaseRef();

		ThemeRegistry.UnregisterExtension(ext);
	}
}

class TestThemeExtension : IThemeExtension
{
	bool* mApplied;
	public this(bool* applied) { mApplied = applied; }

	public void Apply(StyleSheet sheet, ThemePalette palette)
	{
		*mApplied = true;
	}
}

class CountingThemeExtension : IThemeExtension
{
	int* mCount;
	public this(int* count) { mCount = count; }

	public void Apply(StyleSheet sheet, ThemePalette palette)
	{
		(*mCount)++;
	}
}
