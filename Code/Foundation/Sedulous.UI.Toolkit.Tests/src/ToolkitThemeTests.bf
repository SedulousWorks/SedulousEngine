using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// The toolkit's styling fragments and the extension that merges them.
///
/// The fragments are authored against the shared design system, so what is pinned here are the
/// invariants a sheet can break silently: both parse non empty, every selector in them actually
/// resolves to a type, the type ramp holds, and the few properties read through
/// ResolveStyleColor stay raw COLOURS rather than drawables.
class ToolkitThemeTests
{
	/// The last rule targeting exactly this type with no class and no state, which is what the
	/// merged sheet resolves to.
	private static StyleValue FindValue(StyleSheet sheet, Type type, StringView pseudo,
		StyleProperty property)
	{
		StyleValue found = .None;

		for (int r < sheet.RuleCount)
		{
			let rule = sheet.GetRule(r);
			let selector = rule.Selector;
			if ((selector.ViewType != type) || (selector.StyleClasses.Count > 0) ||
				selector.State.HasValue)
				continue;

			let rulePseudo = (selector.PseudoElement != null)
				? StringView(selector.PseudoElement)
				: StringView();
			if (rulePseudo != pseudo)
				continue;

			for (int i < rule.PropertyCount)
			{
				if (rule.GetProperty(i).Prop == property)
				{
					found = rule.GetProperty(i).Value;
				}
			}
		}

		return found;
	}

	private static bool HasValue(StyleSheet sheet, Type type, StringView pseudo,
		StyleProperty property)
	{
		for (int r < sheet.RuleCount)
		{
			let rule = sheet.GetRule(r);
			let selector = rule.Selector;
			if ((selector.ViewType != type) || (selector.StyleClasses.Count > 0) ||
				selector.State.HasValue)
				continue;

			let rulePseudo = (selector.PseudoElement != null)
				? StringView(selector.PseudoElement)
				: StringView();
			if (rulePseudo != pseudo)
				continue;

			for (int i < rule.PropertyCount)
			{
				if (rule.GetProperty(i).Prop == property)
					return true;
			}
		}

		return false;
	}

	private static void AssertFontSize(StyleSheet sheet, Type type, float expected)
	{
		let value = FindValue(sheet, type, "", .FontSize);
		Test.Assert(value.AsFloat.HasValue, scope $"{type} declares no font size");
		Test.Assert(Math.Abs(value.AsFloat.Value - expected) < 0.001f,
			scope $"{type} font size was {value.AsFloat.Value}, expected {expected}");
	}

	/// Parses a fragment, then runs it through the REAL path, and checks both agree.
	private static void CheckFragment(StringView fragment, ThemePalette palette)
	{
		ToolkitThemeExtension.RegisterToolkitTypes();

		// The fragment itself has to parse non empty. Without this the checks below would be
		// testing an empty sheet and passing for the wrong reason.
		{
			let loader = scope StyleSheetLoader();
			loader.SetPalette(palette);
			let parsed = loader.Load(fragment);
			Test.Assert(parsed != null);
			defer parsed.ReleaseRef();
			Test.Assert(parsed.RuleCount > 0);
		}

		let toolkitTheme = scope ToolkitThemeExtension();
		let sheet = new StyleSheet();
		defer sheet.ReleaseRef();
		toolkitTheme.Apply(sheet, palette);
		Test.Assert(sheet.RuleCount > 0);

		// THE RAMP: compact chrome twelve, the menu bar fourteen. The explicit twelves are
		// regression gates, because a type rule matches subclasses and without one the View
		// base of sixteen wins. StatusBar section text is child labels, which a container rule
		// cannot reach, so the sheet deliberately sets none.
		AssertFontSize(sheet, typeof(DockTabGroup), 12.0f);
		AssertFontSize(sheet, typeof(DockablePanel), 12.0f);
		AssertFontSize(sheet, typeof(Toolbar), 12.0f);
		AssertFontSize(sheet, typeof(BreadcrumbBar), 12.0f);
		AssertFontSize(sheet, typeof(MenuBar), 14.0f);

		// The canvases and the drag ghost resolve their background as a raw COLOUR.
		Type[3] rawColorTypes = .(typeof(CurveCanvas), typeof(GradientEditor),
			typeof(DockDragPreview));
		for (let type in rawColorTypes)
		{
			let background = FindValue(sheet, type, "", .Background);
			Test.Assert(background.AsColor.HasValue, scope $"{type} background is not a colour");
		}

		// ToastCard reads its background through ResolveStyleColor, which IGNORES a drawable.
		// Declaring one here would leave the card silently on its hard coded fallback.
		let toastBackground = FindValue(sheet, typeof(ToastCard), "", .Background);
		Test.Assert(toastBackground.AsColor.HasValue);
		Test.Assert(toastBackground.AsDrawable == null);

		// Inactive dock tabs take the palette's dim text.
		Test.Assert(HasValue(sheet, typeof(DockTabGroup), "tab", .TextColor));
	}

	[Test]
	public static void TheDarkFragmentHoldsTheDesignSystem()
	{
		CheckFragment(EmbeddedToolkitThemes.Dark, ThemePalette.Dark());
		CheckFragment(EmbeddedToolkitThemes.Dark, ThemePalette.GraphiteOrange());
	}

	[Test]
	public static void TheLightFragmentHoldsTheDesignSystem()
	{
		CheckFragment(EmbeddedToolkitThemes.Light, ThemePalette.Light());
	}

	[Test]
	public static void TheExtensionAppliesRulesForEitherPalette()
	{
		let toolkitTheme = scope ToolkitThemeExtension();

		let dark = new StyleSheet();
		defer dark.ReleaseRef();
		toolkitTheme.Apply(dark, ThemePalette.Dark());
		Test.Assert(dark.RuleCount > 0);

		// The light branch of every control block has to run too, not just compile.
		let light = new StyleSheet();
		defer light.ReleaseRef();
		toolkitTheme.Apply(light, ThemePalette.Light());
		Test.Assert(light.RuleCount > 0);
	}

	/// THE TRIPWIRE. A selector naming a type nobody registered resolves to nothing and styles
	/// nothing, in silence, which is exactly how the fragments' Timeline block sat dead in
	/// Raptor. Reading the names out of the sheets rather than counting registrations is what
	/// makes this catch the next one.
	[Test]
	public static void EverySelectorInTheFragmentsResolves()
	{
		ToolkitThemeExtension.RegisterToolkitTypes();
		UITypeRegistry.RegisterBuiltins();

		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }

		CollectSelectorNames(EmbeddedToolkitThemes.Dark, names);
		CollectSelectorNames(EmbeddedToolkitThemes.Light, names);
		Test.Assert(names.Count > 0, "the fragments carry selectors at all");

		for (let name in names)
			Test.Assert(UITypeRegistry.Resolve(name) != null,
				scope $"the sheets style \"{name}\", which no one registered");
	}

	/// The type name starting each top level rule: the run of identifier characters at the
	/// beginning of a line, before any pseudo element or state.
	private static void CollectSelectorNames(StringView sheet, List<String> outNames)
	{
		var atLineStart = true;
		var inComment = false;
		var depth = 0;

		for (int i = 0; i < sheet.Length; i++)
		{
			let c = sheet[i];

			if (inComment)
			{
				if ((c == '*') && ((i + 1) < sheet.Length) && (sheet[i + 1] == '/'))
				{
					inComment = false;
					i++;
				}

				continue;
			}

			if ((c == '/') && ((i + 1) < sheet.Length) && (sheet[i + 1] == '*'))
			{
				inComment = true;
				i++;
				continue;
			}

			if (c == '\n')
			{
				atLineStart = true;
				continue;
			}

			if (c == '{')
				depth++;
			else if (c == '}')
				depth--;

			// Inside a block the same shape is a PROPERTY name, not a selector.
			if (!atLineStart || (depth > 0))
			{
				if (!((c == ' ') || (c == '\t') || (c == '\r')))
					atLineStart = false;

				continue;
			}

			if ((c == ' ') || (c == '\t') || (c == '\r'))
				continue;

			atLineStart = false;
			if (!(((c >= 'A') && (c <= 'Z')) || ((c >= 'a') && (c <= 'z'))))
				continue;

			var end = i;
			while ((end < sheet.Length) && IsNameChar(sheet[end]))
				end++;

			let name = sheet.Substring(i, end - i);
			if (!Contains(outNames, name))
				outNames.Add(new String(name));
		}
	}

	private static bool IsNameChar(char8 c) =>
		((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) || ((c >= '0') && (c <= '9')) ||
		(c == '_');

	private static bool Contains(List<String> names, StringView name)
	{
		for (let existing in names)
		{
			if (StringView(existing) == name)
				return true;
		}

		return false;
	}
}
