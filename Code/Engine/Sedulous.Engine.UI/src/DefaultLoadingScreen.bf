using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.Engine.UI;

/// The loading screen a game shows while its first scene loads when it authors none (its
/// LoadingDocumentId is unset).
static class DefaultLoadingScreen
{
	/// The aspect (width over height) of the SedulousEngine logo with its wordmark.
	public const float cEngineLogoAspect = 885.0f / 200.0f;

	/// The SedulousEngine logo (`logoSvg`, the SVG text; left out when empty or unreadable)
	/// over a progress bar and a status line, centred on a dark screen. Its controls are named
	/// as an authored loading document's are: `progress` (the ProgressBar the player drives)
	/// and `status` (a Label). The caller's view.
	public static View Build(StringView logoSvg)
	{
		var fill = LayoutStyle();
		fill.Width = SizeSpec.Match();
		fill.Height = SizeSpec.Match();
		let screen = new Panel();
		screen.SetLayout(fill);
		screen.SetStyle(.Background, new RoundedRectDrawable(Color(0x0A / 255.0f, 0x0A / 255.0f, 0x0C / 255.0f, 1.0f), 0.0f));
		let column = new FlexLayout();
		column.Direction = .Vertical;
		column.JustifyContent = .Center;
		column.AlignItems = .Center;
		column.Spacing = 14;
		column.SetLayout(fill);
		if (!logoSvg.IsEmpty)
		{
			if (let logo = SVGDrawable.FromString(logoSvg))
			{
				const float cLogoHeight = 72.0f;
				let view = new DrawableView(logo, cLogoHeight * cEngineLogoAspect, cLogoHeight); // takes the reference
				view.KeepAspect = true;
				view.Name.Set("logo");
				var gap = LayoutStyle(); // the logo stands clear of the bar
				gap.Margin = Thickness(0, 0, 0, 22);
				column.AddView(view, gap);
			}
		}
		let bar = new ProgressBar();
		bar.Name.Set("progress");
		var barSize = LayoutStyle();
		barSize.Width = SizeSpec.Fixed(Unit.Dp(320.0f));
		barSize.Height = SizeSpec.Fixed(Unit.Dp(6.0f));
		column.AddView(bar, barSize);
		let status = new Label("Loading");
		status.Name.Set("status");
		status.FontSize.Value = 13.0f;
		status.TextColor.Value = Color(0x9A / 255.0f, 0xA3 / 255.0f, 0xB2 / 255.0f, 1.0f);
		column.AddView(status);
		screen.AddView(column);
		return screen;
	}
}
