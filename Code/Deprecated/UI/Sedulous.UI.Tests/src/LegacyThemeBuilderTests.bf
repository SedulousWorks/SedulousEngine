using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Tests;

/// The three hand built themes kept as parity oracles.
///
/// They are not what the engine renders with, so nothing else exercises them and they would rot
/// silently. What is pinned here is that each still BUILDS against the current style API, and
/// that the palette actually reaches the rules: a builder that ignored its palette would look
/// right in the default theme and wrong in every other, which is exactly the drift a parity
/// oracle exists to catch.
class LegacyThemeBuilderTests
{
	private static StyleValue? FindValue(StyleSheet sheet, Type type, StringView pseudo,
		StyleProperty property)
	{
		StyleValue? found = null;

		for (int r < sheet.RuleCount)
		{
			let rule = sheet.GetRule(r);
			let selector = rule.Selector;
			if ((selector.ViewType != type) || !selector.StyleClasses.IsEmpty ||
				(selector.State != null))
				continue;

			let rulePseudo = (selector.PseudoElement != null)
				? StringView(selector.PseudoElement)
				: "";
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

	/// Every control the builders style, checked as a set rather than one at a time: a rule
	/// dropped in a refactor is the failure this catches.
	private static void AssertStylesEveryControl(StyleSheet sheet)
	{
		Test.Assert(sheet.RuleCount > 0);

		Type[9] types = .(typeof(View), typeof(ButtonBase), typeof(EditText),
			typeof(NumericField), typeof(CheckBox), typeof(ComboBox), typeof(Separator),
			typeof(TabView), typeof(ListView));

		for (let type in types)
		{
			var any = false;
			for (int r < sheet.RuleCount)
			{
				if (sheet.GetRule(r).Selector.ViewType == type)
				{
					any = true;
					break;
				}
			}

			Test.Assert(any, scope $"nothing styles {type}");
		}

		// The pseudo elements a control cannot draw itself without.
		Test.Assert(FindValue(sheet, typeof(Slider), "track", .Background) != null);
		Test.Assert(FindValue(sheet, typeof(Slider), "thumb", .Background) != null);
		Test.Assert(FindValue(sheet, typeof(ProgressBar), "fill", .Background) != null);
		Test.Assert(FindValue(sheet, typeof(ScrollBar), "thumb", .Background) != null);
		Test.Assert(FindValue(sheet, typeof(NumericField), "spin-up", .Background) != null);
	}

	private static Color TextColorOf(StyleSheet sheet)
	{
		let value = FindValue(sheet, typeof(View), "", .TextColor);
		Test.Assert(value != null);
		Test.Assert(value.Value.AsColor.HasValue);
		return value.Value.AsColor.Value;
	}

	[Test]
	public static void TheDarkBuilderStylesEveryControl()
	{
		let sheet = DarkTheme.CreateLegacyForParity(ThemePalette.Dark());
		defer sheet.ReleaseRef();

		AssertStylesEveryControl(sheet);
		Test.Assert(TextColorOf(sheet).R > 0.5f, "dark chrome carries light text");
	}

	[Test]
	public static void TheLightBuilderStylesEveryControl()
	{
		let sheet = LightTheme.CreateLegacyForParity(ThemePalette.Light());
		defer sheet.ReleaseRef();

		AssertStylesEveryControl(sheet);
		Test.Assert(TextColorOf(sheet).R < 0.5f, "light chrome carries dark text");
	}

	[Test]
	public static void TheRoundedBuilderStylesEveryControlAndRounds()
	{
		let sheet = RoundedDarkTheme.CreateLegacyForParity(ThemePalette.Dark());
		defer sheet.ReleaseRef();

		AssertStylesEveryControl(sheet);

		// The whole identity of this one: a global corner radius the flat builders leave at
		// nought, which is what makes a self-rounding control round here and stay square there.
		let radius = FindValue(sheet, typeof(View), "", .CornerRadius);
		Test.Assert(radius != null);
		Test.Assert(radius.Value.AsFloat.Value == 6.0f);

		let flat = DarkTheme.CreateLegacyForParity(ThemePalette.Dark());
		defer flat.ReleaseRef();
		let flatRadius = FindValue(flat, typeof(View), "", .CornerRadius);
		Test.Assert((flatRadius == null) || (flatRadius.Value.AsFloat.Value == 0.0f));
	}

	/// The rounded builder derives every colour from the palette rather than writing literals,
	/// so a warm palette has to reach the rules. A builder that had drifted back to literals
	/// would answer the same colour for both.
	[Test]
	public static void TheRoundedBuilderFollowsItsPalette()
	{
		let cool = RoundedDarkTheme.CreateLegacyForParity(ThemePalette.Dark());
		defer cool.ReleaseRef();

		let warm = RoundedDarkTheme.CreateLegacyForParity(ThemePalette.GraphiteOrange());
		defer warm.ReleaseRef();

		let coolAccent = FindValue(cool, typeof(View), "", .AccentColor);
		let warmAccent = FindValue(warm, typeof(View), "", .AccentColor);
		Test.Assert(coolAccent != null);
		Test.Assert(warmAccent != null);
		Test.Assert(coolAccent.Value.AsColor.Value != warmAccent.Value.AsColor.Value);
	}
}
