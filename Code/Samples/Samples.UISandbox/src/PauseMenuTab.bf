using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.VG;

namespace Samples.UISandbox;

/// A screen loaded from MARKUP on disk rather than built in code, then wired up by name.
///
/// It is also the styling precedence demo, which is why the overrides look redundant: the
/// title's inline font family beats the local sheet's, the local sheet beats the theme, and the
/// two inline button backgrounds beat the local sheet's default. Each layer is visible on screen
/// at once.
static class PauseMenuTab
{
	public static void Build(UISandboxApp app, TabView tabView)
	{
		// Fills the element and property registry the loader reads. Idempotent.
		MarkupLoader.Initialize();

		let provider = app.ResourceProvider;
		if (provider == null)
			return;

		let markup = scope String();
		if (!provider.LoadText("screens/pause-menu.sml", markup) || markup.IsEmpty)
			return;

		let screen = MarkupLoader.LoadFromString(markup, app.Host.Context);
		if (screen == null)
			return;

		tabView.AddTab("Pause (.sml)", screen, true);

		let root = screen as ViewGroup;
		if (root == null)
			return;

		WireButtons(root);
		StyleTitle(root);
		ApplyLocalSheet(screen);
	}

	private static void WireButtons(ViewGroup root)
	{
		LogClick(root, "resume-btn", "Resume clicked!");
		LogClick(root, "settings-btn", "Settings clicked!");
		LogClick(root, "save-btn", "Save clicked!");
		LogClick(root, "load-btn", "Load clicked!");
		LogClick(root, "quit-btn", "Quit clicked!");

		// Inline state lists, which stay REACTIVE: the button hands its control state to the
		// drawable, so the hover and pressed variants still work through an inline override.
		Recolour(root, "resume-btn", Color.Rgb(45, 130, 70));
		Recolour(root, "quit-btn", Color.Rgb(150, 60, 60));
	}

	private static void LogClick(ViewGroup root, StringView name, StringView message)
	{
		if (let button = root.FindByName<Button>(name))
			button.OnClick.Add(new (sender) => Console.WriteLine(message));
	}

	private static void Recolour(ViewGroup root, StringView name, Color color)
	{
		if (let button = root.FindByName<Button>(name))
			button.SetStyle(.Background, Palette.CreateStateRounded(color, CornerRadii(6.0f)));
	}

	private static void StyleTitle(ViewGroup root)
	{
		let title = root.FindByName<Label>("title");
		if (title == null)
			return;

		title.SetStyle(.TextColor, Color.Rgb(255, 220, 100));
		title.SetStyle(.FontSize, 32.0f);
		// This family wins over the local sheet's, which is the point of setting both.
		title.SetStyle(.FontFamily, "AttackOfMonster");
	}

	/// Scopes a theme change to this subtree alone: the rest of the sandbox keeps the global
	/// one. CONSUMES the sheet.
	private static void ApplyLocalSheet(View screen)
	{
		let sheet = new StyleSheet();

		sheet.ForAll().Set(.FontFamily, "JungleAdventurer");
		sheet.ForType(typeof(Label))
			.Set(.FontSize, 14.0f)
			.Set(.TextColor, Color.Rgb(210, 215, 225));

		let buttonBackground = Palette.CreateStateRounded(Color.Rgb(60, 65, 80), CornerRadii(6.0f));
		sheet.OwnDrawable(buttonBackground);
		sheet.ForType(typeof(Button))
			.Set(.Padding, Thickness(14, 8))
			.Set(.Background, buttonBackground);

		screen.SetLocalStyleSheet(sheet);
	}
}
