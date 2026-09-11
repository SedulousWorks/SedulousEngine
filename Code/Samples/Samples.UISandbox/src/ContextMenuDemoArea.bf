using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Samples.UISandbox;

/// A plain panel that answers a right click with a nested context menu.
///
/// Three levels deep on purpose: a submenu of a submenu is where popup ownership and the
/// dismissal chain actually get tested.
class ContextMenuDemoArea : View
{
	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);
		let border = ResolveStyleColor(.BorderColor, Color.Rgb(50, 55, 65));
		ctx.VG.FillRoundedRect(bounds, 4.0f, Palette.Darken(border, 0.3f));
		ctx.VG.StrokeRoundedRect(bounds, 4.0f, border, 1.0f);

		if (ctx.FontService == null)
			return;

		let family = scope String();
		ResolveStyleFontFamily(family);

		let font = ctx.FontService.GetFont(family, 14.0f);
		if (font == null)
			return;

		ctx.VG.DrawText("Right-click for context menu", font, bounds, TextAlignment.Center,
			VerticalAlignment.Middle, Color.Rgb(180, 185, 200));
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if ((e.Button != .Right) || (Context == null))
			return;

		let menu = new ContextMenu();
		menu.AddItem("Cut", new () => {});
		menu.AddItem("Copy", new () => {});
		menu.AddItem("Paste", new () => {});
		menu.AddSeparator();

		let submenu = (ContextMenu)menu.AddSubmenu("More").Submenu;
		submenu.AddItem("Select All", new () => {});
		submenu.AddItem("Find", new () => {});
		submenu.AddSeparator();

		let nested = (ContextMenu)submenu.AddSubmenu("Even More").Submenu;
		nested.AddItem("Nested Item 1", new () => {});
		nested.AddItem("Nested Item 2", new () => {});

		menu.AddSeparator();
		menu.AddItem("Disabled Item", new () => {}, false);

		let screen = LocalToScreen(.(e.X, e.Y));
		menu.Show(Context, screen.X, screen.Y);
		e.Handled = true;
	}

	protected override void OnMeasure(BoxConstraints constraints) =>
		MeasuredSize = .(constraints.ConstrainWidth(constraints.MaxWidth),
			constraints.ConstrainHeight(80));
}
