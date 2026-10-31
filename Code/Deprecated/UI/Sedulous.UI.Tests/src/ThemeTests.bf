using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The built-in themes: that they build, that they resolve, and that the design system they
/// all share actually holds.
class ThemeTests
{
	/// Records that it was applied, which is how the extension hook is observed.
	private class RecordingExtension : IThemeExtension
	{
		public int32 Applications = 0;

		public void Apply(StyleSheet sheet, ThemePalette palette)
		{
			Applications++;
		}
	}

	private static void MakeTree(out UIContext context, out RootView root)
	{
		context = new UIContext();
		root = new RootView();
		UITest.Init(context, root);
	}

	/// The last rule targeting exactly this type, with no class, state or other pseudo.
	private static StyleValue? FindValue(StyleSheet sheet, Type type, StringView pseudo,
		StyleProperty property)
	{
		StyleValue? found = null;

		for (int r < sheet.RuleCount)
		{
			let rule = sheet.GetRule(r);
			let selector = rule.Selector;

			if ((selector.ViewType != type) || !selector.StyleClasses.IsEmpty || (selector.State != null))
				continue;

			let rulePseudo = (selector.PseudoElement != null) ? StringView(selector.PseudoElement) : "";
			if (rulePseudo != pseudo)
				continue;

			for (int i < rule.PropertyCount)
			{
				if (rule.GetProperty(i).Prop == property)
					found = rule.GetProperty(i).Value;
			}
		}

		return found;
	}

	private static void CheckFontSize(StyleSheet sheet, Type type, float expected)
	{
		let value = FindValue(sheet, type, "", .FontSize);
		Test.Assert(value != null, "no font size rule for this type");
		Test.Assert(value.Value.AsFloat != null);
		Test.Assert(value.Value.AsFloat.Value == expected);
	}

	private static int CountSvgIconRules(StyleSheet sheet)
	{
		var count = 0;
		for (int r < sheet.RuleCount)
		{
			let rule = sheet.GetRule(r);
			for (int i < rule.PropertyCount)
			{
				if (rule.GetProperty(i).Value.AsDrawable is SVGDrawable)
					count++;
			}
		}
		return count;
	}

	/// The contract every built-in sheet keeps, whatever it looks like.
	private static void CheckDesignSystem(StyleSheet sheet)
	{
		// The type ramp: 16 by default, 14 for inputs, 12 for compact chrome.
		CheckFontSize(sheet, typeof(View), 16.0f);
		CheckFontSize(sheet, typeof(ButtonBase), 12.0f);
		CheckFontSize(sheet, typeof(ComboBox), 12.0f);
		CheckFontSize(sheet, typeof(EditText), 14.0f);
		CheckFontSize(sheet, typeof(NumericField), 14.0f);
		CheckFontSize(sheet, typeof(Expander), 14.0f);

		// The global defaults, including the semantic status colours a toast or a validation
		// message resolves through the theme rather than hardcoding.
		Test.Assert(FindValue(sheet, typeof(View), "", .TextColor) != null);
		Test.Assert(FindValue(sheet, typeof(View), "", .AccentColor) != null);
		Test.Assert(FindValue(sheet, typeof(View), "", .SuccessColor) != null);
		Test.Assert(FindValue(sheet, typeof(View), "", .WarningColor) != null);
		Test.Assert(FindValue(sheet, typeof(View), "", .ErrorColor) != null);

		// The spacing scale. CSS writes vertical then horizontal, so `8 12` is a Thickness of
		// 12 either side and 8 above and below.
		let buttonPad = FindValue(sheet, typeof(ButtonBase), "", .Padding);
		Test.Assert(buttonPad != null);
		Test.Assert(buttonPad.Value.AsThickness.Value == Thickness(12, 8, 12, 8));

		let inputPad = FindValue(sheet, typeof(EditText), "", .Padding);
		Test.Assert(inputPad != null);
		Test.Assert(inputPad.Value.AsThickness.Value.Left == 6);
		Test.Assert(inputPad.Value.AsThickness.Value.Top == 4);

		// An icon button pads 2. A REGRESSION GATE: with no rule of its own it inherits
		// ButtonBase's button-bar padding by subtype matching and overflows a tight header.
		let iconPad = FindValue(sheet, typeof(IconButton), "", .Padding);
		Test.Assert(iconPad != null, "IconButton must not inherit the button bar padding");
		Test.Assert(iconPad.Value.AsThickness.Value.Left == 2);
		Test.Assert(iconPad.Value.AsThickness.Value.Top == 2);

		// The icon vocabulary: the two marks, close, four chevrons, the submenu arrow, the
		// combo arrow and two spin arrows, each resolved to a real drawable.
		Test.Assert(CountSvgIconRules(sheet) >= 11);

		// A sunken input carries a background of its own.
		Test.Assert(FindValue(sheet, typeof(EditText), "", .Background) != null);
	}

	// ---- The sheets ---------------------------------------------------------------------------

	/// Each shipped sheet parses and keeps the shared design system, whatever palette it is
	/// given: one sheet serves several looks because the .sss names palette variables.
	[Test]
	public static void EveryShippedSheetHoldsTheDesignSystem()
	{
		StyleSheetLoader.InitializeGlobals();

		let dark = DarkTheme.Create(ThemePalette.Dark());
		defer dark.ReleaseRef();
		Test.Assert(dark != null);
		Test.Assert(dark.RuleCount > 0);
		CheckDesignSystem(dark);

		let warm = DarkTheme.Create(ThemePalette.GraphiteOrange());
		defer warm.ReleaseRef();
		CheckDesignSystem(warm);

		let light = LightTheme.Create(ThemePalette.Light());
		defer light.ReleaseRef();
		CheckDesignSystem(light);

		let rounded = RoundedDarkTheme.Create(ThemePalette.GraphiteOrange());
		defer rounded.ReleaseRef();
		CheckDesignSystem(rounded);
	}

	/// The two dark themes are ONE look in two geometries: same palette, same colours, and
	/// the corner radius is the whole difference. Defaulting the rounded one to another
	/// palette made it a different theme entirely, which is what it looked like on screen.
	[Test]
	public static void TheRoundedDarkThemeIsTheDarkThemeRounded()
	{
		StyleSheetLoader.InitializeGlobals();

		let flat = DarkTheme.Create();
		defer flat.ReleaseRef();

		let rounded = RoundedDarkTheme.Create();
		defer rounded.ReleaseRef();

		let flatText = FindValue(flat, typeof(View), "", .TextColor);
		let roundedText = FindValue(rounded, typeof(View), "", .TextColor);
		Test.Assert(flatText != null);
		Test.Assert(roundedText != null);
		Test.Assert(flatText.Value.AsColor.Value == roundedText.Value.AsColor.Value,
			"the same palette, so the same text colour");

		// And the geometry is what differs.
		let flatRadius = FindValue(flat, typeof(View), "", .CornerRadius);
		let roundedRadius = FindValue(rounded, typeof(View), "", .CornerRadius);
		Test.Assert(roundedRadius != null);
		Test.Assert(roundedRadius.Value.AsFloat.Value == 6.0f);
		Test.Assert((flatRadius == null) || (flatRadius.Value.AsFloat.Value == 0.0f));
	}

	/// The rounded theme's own identity on top of the shared system.
	[Test]
	public static void TheRoundedThemeRoundsEverything()
	{
		StyleSheetLoader.InitializeGlobals();

		let sheet = RoundedDarkTheme.Create();
		defer sheet.ReleaseRef();

		let radius = FindValue(sheet, typeof(View), "", .CornerRadius);
		Test.Assert(radius != null);
		Test.Assert(radius.Value.AsFloat.Value == 6.0f);
	}

	/// The flat themes do NOT round, which is the difference between them.
	[Test]
	public static void TheFlatThemesDoNotRound()
	{
		StyleSheetLoader.InitializeGlobals();

		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		context.SetStyleSheet(DarkTheme.Create());
		let button = new Button("Test");
		root.AddView(button);

		Test.Assert(button.ResolveStyleDrawable(.Background) != null);
		Test.Assert(button.ResolveStyleThickness(.Padding).Left > 0);
		Test.Assert(button.ResolveStyleFloat(.CornerRadius) == 0.0f);
	}

	// ---- Resolution ---------------------------------------------------------------------------

	/// A dark theme's text is light and a light theme's is dark, which is the whole point, and
	/// switching sheets moves a view from one to the other without touching the view.
	[Test]
	public static void SwitchingThemesChangesWhatAViewResolves()
	{
		StyleSheetLoader.InitializeGlobals();

		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		let view = new TestView(10, 10);
		root.AddView(view);

		context.SetStyleSheet(DarkTheme.Create());
		let darkText = view.ResolveStyleColor(.TextColor);
		Test.Assert(darkText.R > 200 / 255.0f, "light text on a dark theme");
		Test.Assert(view.ResolveStyleFloat(.FontSize) == 16.0f);

		context.SetStyleSheet(LightTheme.Create());
		let lightText = view.ResolveStyleColor(.TextColor);
		Test.Assert(lightText.R < 50 / 255.0f, "dark text on a light theme");

		Test.Assert(darkText.R != lightText.R);
	}

	/// A custom palette reaches the sheet, which is what makes one .sss serve every variant.
	[Test]
	public static void ACustomPaletteReachesTheResolvedValues()
	{
		StyleSheetLoader.InitializeGlobals();

		var palette = ThemePalette.Dark();
		palette.Text = Color(1.0f, 0.0f, 0.0f, 1.0f);

		MakeTree(let context, let root);
		defer { root.ReleaseRef(); delete context; }

		context.SetStyleSheet(DarkTheme.Create(palette));
		let view = new TestView(10, 10);
		root.AddView(view);

		let color = view.ResolveStyleColor(.TextColor);
		Test.Assert((color.R == 1.0f) && (color.G == 0.0f) && (color.B == 0.0f));
	}

	/// The game themes are the shipped ones with their own accent, so they keep the whole
	/// design system and differ only where they mean to.
	[Test]
	public static void TheGameThemesAreTheShippedOnesWithTheirOwnAccent()
	{
		StyleSheetLoader.InitializeGlobals();

		let game = GameTheme.Create();
		defer game.ReleaseRef();
		CheckDesignSystem(game);

		let gameLight = GameLightTheme.Create();
		defer gameLight.ReleaseRef();
		CheckDesignSystem(gameLight);

		// The accent is the teal, not the editor's warm orange.
		Test.Assert(GameTheme.Palette().PrimaryAccent.G > GameTheme.Palette().PrimaryAccent.R);
		Test.Assert(GameLightTheme.Palette().PrimaryAccent.G > GameLightTheme.Palette().PrimaryAccent.R);
	}

	// ---- Extensions ---------------------------------------------------------------------------

	/// A registered extension is applied to every theme built, which is how a satellite adds
	/// its own controls' styling without editing the shipped sheets.
	[Test]
	public static void AnExtensionIsAppliedToEveryThemeBuilt()
	{
		StyleSheetLoader.InitializeGlobals();

		let themeExtension = scope RecordingExtension();
		ThemeRegistry.RegisterExtension(themeExtension);
		defer ThemeRegistry.UnregisterExtension(themeExtension);

		let dark = DarkTheme.Create();
		defer dark.ReleaseRef();
		Test.Assert(themeExtension.Applications == 1);

		let light = LightTheme.Create();
		defer light.ReleaseRef();
		Test.Assert(themeExtension.Applications == 2);

		let rounded = RoundedDarkTheme.Create();
		defer rounded.ReleaseRef();
		Test.Assert(themeExtension.Applications == 3);
	}

	/// Unregistering stops it, so a test or a plugin that goes away leaves no trace.
	[Test]
	public static void UnregisteringAnExtensionStopsIt()
	{
		StyleSheetLoader.InitializeGlobals();

		let themeExtension = scope RecordingExtension();
		ThemeRegistry.RegisterExtension(themeExtension);

		let first = DarkTheme.Create();
		defer first.ReleaseRef();
		Test.Assert(themeExtension.Applications == 1);

		ThemeRegistry.UnregisterExtension(themeExtension);

		let second = DarkTheme.Create();
		defer second.ReleaseRef();
		Test.Assert(themeExtension.Applications == 1, "no longer applied");
	}
}
