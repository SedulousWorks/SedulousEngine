using System;
using Sedulous.Core;
using Sedulous.GUI;

namespace Sedulous.Engine.GUI;

/// The loading screen a game shows while its first scene loads when it authors none (its
/// GuiLoadingDocumentId is unset), on the GUI (Raptor's engine-ui-removal spec, layer 2): the
/// SedulousEngine logo (the SVG text; left out when empty or unreadable) over a progress bar and
/// "Loading", centred on a dark screen. Root holds a reference of the caller's; Progress is the bar
/// the player drives (0 to 1), in Root.
struct GuiLoadingScreen
{
	/// The aspect (width over height) of the SedulousEngine logo with its wordmark.
	public const float cEngineLogoAspect = 885.0f / 200.0f;

	public Node Root;
	public ProgressBar Progress;

	public static GuiLoadingScreen Build(StringView logoSvg)
	{
		var screen = GuiLoadingScreen();
		// The screen: dark, its column in the middle (the overlay layer stacks it over the window).
		let root = new UIWidget();
		root.Id = "loading-screen";
		root.SetInlineStyle("background-color", "#0a0a0c");
		root.EditLayoutStyle(scope (s) =>
			{
				s.Direction = .Column;
				s.JustifyContent = .Center;
				s.AlignItems = .Center;
				s.RowGap = 14.0f;
			});
		screen.Root = root;
		if (!logoSvg.IsEmpty)
		{
			if (let logo = SvgDrawable.FromText(logoSvg))
			{
				const float cLogoHeight = 72.0f;
				let image = new Image();
				image.Id = "logo";
				image.SetDrawable(logo);
				logo.ReleaseRef(); // the image's keeps it
				image.EditLayoutStyle(scope (s) =>
					{
						s.Width = LayoutLength.Px(cLogoHeight * cEngineLogoAspect);
						s.Height = LayoutLength.Px(cLogoHeight);
						s.Margin.Bottom = 22.0f; // the logo stands clear of the bar
					});
				root.AddChild(image);
				image.ReleaseRef(); // the root's keeps it
			}
		}
		let bar = new ProgressBar();
		bar.Id = "progress";
		bar.EditLayoutStyle(scope (s) =>
			{
				s.Width = LayoutLength.Px(320.0f);
				s.Height = LayoutLength.Px(6.0f);
			});
		root.AddChild(bar);
		bar.ReleaseRef(); // the root's keeps it
		screen.Progress = bar;
		let status = new Label();
		status.Id = "status";
		status.Text = "Loading";
		status.SetInlineStyle("font-size", "13px");
		status.SetInlineStyle("color", "#9aa3b2");
		root.AddChild(status);
		status.ReleaseRef();
		return screen;
	}
}
